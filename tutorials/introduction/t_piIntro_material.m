%% Illustrates adding and setting object materials
%
% The first part illustrates how to create the materials.
% 
% The latter two cells illustrate how to include preset materials
% using the piMaterialPresets and piMaterialsInsert methods.
%
% Dependencies:
%    ISET3d-v4, (ISETCam or ISETBio), JSONio
%
% ZL, BW SCIEN 2018
%
% See also
%   piMaterialsInsert, piMaterialPresets, t_piIntro_*

%% Initialize ISET and Docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read pbrt file, set the rendering parameters, and show it.

sceneName = 'sphere';
thisR = piRecipeCreate(sceneName);
% thisR.show;

% Low resolution, but multiple bounces for the glass and mirror at the
% end.
thisR.set('film resolution',[200 150]*2);
thisR.set('rays per pixel',64);
thisR.set('fov',45);
thisR.set('nbounces',5);

piWRS(thisR,'name',sprintf('Uber %s',sceneName));

%% The material library

% Print out the named materials in this scene.
thisR.show('materials');

% We have additional materials in a piMaterialPresets.
piMaterialPresets('list');

%% Here is how we build a red matte (diffuse) surface

% Create a red matte material
redMatte = piMaterialCreate('redMatte', 'type', 'diffuse');

% Add the material to the materials list
thisR.set('material', 'add', redMatte);
thisR.get('materials print');

%% Set the spectral reflectance of the matte material to be very red.

wave = 400:10:700;
reflectance = ones(size(wave));
reflectance(1:17) = 1e-3;

% Put it in the PBRT spd format.
spdRef = piMaterialCreateSPD(wave, reflectance);

% Store the reflectance as the diffuse reflectance of the redMatte
% material
thisR.set('material', redMatte, 'reflectance value', spdRef);

%% Set the material
sphereID = piAssetSearch(thisR,'object name','Sphere');
thisR.set('asset',sphereID(1),'material name',redMatte.name);

% Show that we set it
thisR.show('materials');

% Let's have a look
piWRS(thisR,'name',sprintf('Red %s',sceneName),'render flag','rgb');

%%  Now Put the sphere in an environment

% Add an environmental light
thisR.set('light', 'all', 'delete');
spotLight = piLightCreate('spot1','type','spot');
thisR.set('lights',spotLight,'add');

thisR.set('skymap', 'room.exr');

scene = piWRS(thisR,'name',sprintf('Red in environment %s',sceneName),'render flag','hdr');

%% White sphere

thisR.set('asset', sphereID, 'material name', 'white');
thisR.show('materials');

piWRS(thisR, 'name', 'Sphere is white diffuse');

%% Make the sphere glass

piMaterialsInsert(thisR,'names','glass');
thisR.set('asset', sphereID, 'material name', 'glass');
thisR.show('materials')

piWRS(thisR, 'name', 'Change sphere to glass');

%% Change the sphere to a mirror

piMaterialsInsert(thisR,'names',{'mirror'});
thisR.set('asset', sphereID, 'material name', 'mirror');
thisR.show('materials');

piWRS(thisR, 'name', 'Change glass to mirror');

%% END
