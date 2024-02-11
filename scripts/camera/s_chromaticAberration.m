%% s_chromaticAberration.m
%
% Calculate chromatic aberration present in lens rendering.
%
% See also
%
%% Initialize ISET and Docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the pbrt scene

% Read the main scene pbrt file.  
% Return it as a recipe
% (used to use textured plane, but it's not in v4)
thisR = piRecipeDefault('scene name', 'cornell_box');

% add a light so we can see
pointLight = piLightCreate('point','type','point','cameracoordinate', true);
thisR.set('light',pointLight, 'add');

%% Attach a desired texture to part of the scene
ourAsset = '001_large_box_O';
piMaterialsInsert(thisR,'names','slantededge');
piAssetTranslate(thisR,ourAsset,[.15 .11 0]);
thisR.set('asset',ourAsset,'material name','slantededge');

piWRS(thisR,'name','pinhole');


%% Attach a camera with a lens

%{
% To see the list of available lenses
 theLenses = lensList;
 theLenses(19).name
%}
theLens = 'dgauss.22deg.6.0mm.json';
% theLens = 'fisheye.87deg.6.0mm.json';
camera = piCameraCreate('omni','lens file',theLens);
thisR.set('camera',camera);          
thisR.set('aperture',7);             % mm
thisR.set('film resolution',512);    % Spatial samples
thisR.set('rays per pixel',128);     % Rendering samples
thisR.set('film diagonal', 2);       % Size of film in mm
thisR.set('focusdistance',1.6);      % to the large box

fprintf('Rendering with lens:   %s\n',thisR.get('lens file'));

% Turn on chromatic aberration and render
thisR.set('chromatic aberration',true);
piWRS(thisR,'name',sprintf('8band %s',theLens));

%% Render without chromatic aberration
thisR.set('chromatic aberration',false);
oi = piWRS(thisR,'name',sprintf('no CA %s',theLens));

%% Now with 15 bands
thisR.set('chromatic aberration',15);
oiCA = piWRS(thisR,'name','CA 15 bands','name',sprintf('15band %s',theLens));

%% End