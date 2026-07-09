%% Introducing iset3d calculations with the Chess Set
%
% This short tutorial renders the chess set once and shows the basic
% recipe controls used throughout the introductory scripts.
%
% See also
%   t_piIntro_*, piRecipeDefault, @recipe

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the recipe and set modest render quality

thisR = piRecipeDefault('scene name','chessset');
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',2);
thisR.set('render type',{'radiance','depth'});

%% Add one camera-space point light and one room skymap

thisR.show('lights');
thisR.set('light','all','delete');

pointLight = piLightCreate('point',...
    'type','point',...
    'spd','equalEnergy',...
    'specscale float',0.6,...
    'cameracoordinate',true);
thisR.set('light',pointLight,'add');

[~, skyMap] = thisR.set('skymap','room.exr');
thisR.set('light',skyMap.name,'rotate',[30 0 0]);
thisR.show('lights');

%% Render once and inspect the returned scene

scene = piWRS(thisR,'render flag','hdr');
depthMap = sceneGet(scene,'depth map');
fprintf('Rendered chess set: %d x %d pixels\n',sceneGet(scene,'cols'),sceneGet(scene,'rows'));
fprintf('Depth range: %.2f to %.2f m\n',min(depthMap(:)),max(depthMap(:)));

scenePlot(scene,'depth map');

%% END
