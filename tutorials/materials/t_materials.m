%% ISET3d: Materials
%
% This tutorial shows how to inspect materials, edit a material property,
% assign a new material to an asset, and render once.
%
% See also
%   piMaterialCreate, piMaterialsInsert, t_assets, t_piIntro*

%% The base scene

ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeDefault('scene name','SimpleScene');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',2);

%% List the scene materials and inspect one

thisR.show('materials');

assetFig3m = piAssetSearch(thisR,'object name','figure_3m');
matName = thisR.get('asset',assetFig3m,'material name');
fprintf('figure_3m material: %s\n',matName);

roughness = thisR.get('material',matName,'roughness');
reflectance = thisR.get('material',matName,'reflectance');
fprintf('Material type: %s\n',thisR.get('material',matName,'type'));
fprintf('Roughness: %.2f\n',roughness.value);
fprintf('Reflectance value: [%.2f %.2f %.2f]\n',reflectance.value);

%% Edit material color and assign a new glass material

thisR.set('material',matName,'reflectance',[0 0.5 0]);

glassMaterial = 'blueGuyGlass';
newMat = piMaterialCreate(glassMaterial,'type','dielectric');
thisR.set('material','add',newMat);
thisR.set('asset',assetFig3m,'material name',glassMaterial);

assetName = thisR.get('asset',assetFig3m,'name');
curName = thisR.get('asset', assetFig3m, 'material name');
fprintf('The material for %s is %s\n',assetName,curName);

assetMirror = piAssetSearch(thisR,'object name','mirror');
mirrorMaterial = 'newMirror';
newMat = piMaterialCreate(mirrorMaterial,'type','conductor');
thisR.set('material','add',newMat);
thisR.set('asset',assetMirror,'material name',mirrorMaterial);

fprintf('Updated figure_3m material: %s\n',thisR.get('asset',assetFig3m,'material name'));
fprintf('Updated mirror material: %s\n',thisR.get('asset',assetMirror,'material name'));

%% Render once

scene = piWRS(thisR,'name','material edits','render flag','hdr');
fprintf('Rendered material scene: %d x %d pixels\n',sceneGet(scene,'cols'),sceneGet(scene,'rows'));

%% END
