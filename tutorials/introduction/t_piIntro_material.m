%% Illustrates adding and setting object materials
%
% This tutorial creates a simple diffuse material, assigns it to the
% sphere, and renders once.  Longer material comparison workflows belong
% in examples rather than the tutorial smoke-test path.
%
% See also
%   piMaterialsInsert, piMaterialPresets, t_piIntro_*

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the sphere recipe and set modest render quality

thisR = piRecipeCreate('sphere');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',2);

%% Add a camera-space light

thisR.set('light','all','delete');
spotLight = piLightCreate('spot1','type','spot',...
    'spd','equalEnergy',...
    'specscale float',1,...
    'coneangle',20,...
    'cameracoordinate',true);
thisR.set('lights',spotLight,'add');

%% Build and assign a red diffuse material

redMatte = piMaterialCreate('redMatte','type','diffuse');
thisR.set('material','add',redMatte);

wave = 400:10:700;
reflectance = ones(size(wave));
reflectance(1:17) = 1e-3;
spdRef = piMaterialCreateSPD(wave,reflectance);
thisR.set('material',redMatte,'reflectance value',spdRef);

sphereID = piAssetSearch(thisR,'object name','Sphere');
thisR.set('asset',sphereID(1),'material name',redMatte.name);

thisR.show('materials');
fprintf('Additional presets can be inserted with piMaterialsInsert.\n');

%% Render once

scene = piWRS(thisR,'name','Red sphere','render flag','rgb');
fprintf('Sphere material: %s\n',thisR.get('asset',sphereID(1),'material name'));
fprintf('Mean luminance: %.3f cd/m2\n',mean(sceneGet(scene,'luminance'),'all'));

%% END
