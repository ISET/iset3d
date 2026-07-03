%% Make scenes with a PNG defined target on a flat surface
%
% There are two ways to make such images.  One is to literally use a PNG.
% The other is to use some of the builtin PBRT methods.  This script is for
% the PNG method.
%
% Materials with textures are different from simple materials.  These
% materials have two slots
%
%  thisM.material
%  thisM.texture
%
% The standard material is a struct with multiple slots.
%
% To learn about how to use the standard PBRT textures, see the examples in
% t_piIntro_material and t_materials

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Find the Cube face and adjust its size

thisR = piRecipeCreate('flat surface');
idx = piAssetSearch(thisR,'object name','Cube');

% Control the Cube size so we see the whole shape
% Units are meters, I think.
thisR.set('asset',idx,'size',[100 1 100]);
thisR.show('objects');

%% This is how to make a texture

% We have example png textures files in the materials/textures directory.
% To make a material with a texture, we create the texture and the
% material.
%
% To see the textures that are in there now, have a look at this:
%
%      dir(piDirGet('textures'))
%
materialName = 'squarewave_h_04';   % 'squarewave_h_04';

% First the texture
textureMap = fullfile(piDirGet('textures'),[materialName,'.png']);
thisM.texture = piTextureCreate(materialName,...
    'format', 'spectrum',...
    'type', 'imagemap',...
    'filename', textureMap);

% Then the material
thisM.material = piMaterialCreate(materialName,...
    'type','diffuse',...
    'reflectance val',materialName);

% Finally, add the material and texture object to the recipe
thisR.set('material', 'add', thisM);

%  Attach the material to the surface and render
thisR.set('asset',idx,'material name',materialName);
% thisR.show('objects');

% I get an error the first time I run this, and then it runs the second
% time.  Must debug. (BW).
piWRS(thisR);
    
%% You can scale the pattern this way

sfactor = 3;
thisR.set('texture',materialName,'vscale',sfactor);
piWRS(thisR,'name',sprintf('hbars %02d',sfactor));

%% To see the properties you can change

validTextures = piTextureCreate('help');

%%