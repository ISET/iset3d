%% Illustrate use of material presents
%
% We have some materials with easy to understand names that we can
% insert in a scene.  This script illustrates how to find one of them,
% insert it into a recipe, and assign it to an asset.
%
%  See also
%  t_material, t_piIntro_material

%% 
ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Set up a scene
sceneName = 'materialball'; 
thisR = piRecipeDefault('scene name',sceneName);

% add a skymap
fileName = 'room.exr';
thisR.set('skymap',fileName);

thisR.set('filmresolution',[1200,900]/3);
thisR.set('pixelsamples',128);

%% Add checkerboard texture to the InnerBall materials
piMaterialsInsert(thisR,'name','checkerboard');
outerBallidx = piAssetSearch(thisR,'object name','OuterBall');
thisR.set('asset',outerBallidx,'material name','checkerboard');
piWRS(thisR,'gamma',0.85,'name','checker board');

%% How do we set the texture properties of the material ....

thisR.set('texture','checkerboard','vscale',16);
thisR.set('texture','checkerboard','vscale',16);
piWRS(thisR,'gamma',0.85,'name','checker board');

%{
% Should work because it does with piTextureCreate. But something not
% clear in the set/get....
thisR.set('texture','checkerboard','tex1', [.5 .01 .01]); 
thisR.set('texture','checkerboard','tex2', [.01 .5 .01]);
%}

%%  Asphalt road material
piMaterialsInsert(thisR,'name','asphalt-uniform');
thisR.set('asset',outerBallidx,'material name','asphalt-uniform');
piWRS(thisR,'gamma',0.85,'name','asphalt');

%% Asphalt with a crack
piMaterialsInsert(thisR,'name','asphalt-crack');
thisR.set('asset',outerBallidx,'material name','asphalt-crack');
piWRS(thisR,'gamma',0.85,'name','asphalt-crack');

%%
groundPlaneIdx = piAssetSearch(thisR,'material name','Ground');
thisR.set('asset',groundPlaneIdx,'material name','asphalt-crack');
piWRS(thisR,'gamma',0.85,'name','asphalt-crack');

%% Show all the preset materials
piMaterialPresets('list material');

%%  Create a new material from the presents

piMaterialsInsert(thisR,'name','metal-spotty-discoloration');
thisR.set('asset',outerBallidx,'material name','metal-spotty-discoloration');
piWRS(thisR,'gamma',0.85,'name','spotty metal');

%% Add a red glass material

piMaterialsInsert(thisR,'name','red-glass');
scene = piWRS(thisR,'gamma',0.85,'name','red-glass');

%% render leather material

piMaterialsInsert(thisR,'name','fabric-leather-var2'); 
thisR.set('asset',outerBallidx,'material name','fabric-leather-var2');
piWRS(thisR,'gamma',0.85,'name','fabric-leather-var2');

%% END