%% Introduce texture materials
%
% Textures are part of material definitions.  This tutorial inserts one
% predefined checkerboard material, assigns it to an object, and changes a
% texture scale parameter.
%
% See also
%   piMaterialsInsert, recipe/get, recipe/set

%% Init

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Start with a textured flat surface

thisR = piRecipeDefault('scene name','flatsurfacewhitetexture');
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);

cubeIDX = piAssetSearch(thisR,'object name','Cube');

%% Insert and assign a checkerboard material

thisR = piMaterialsInsert(thisR,'names','checkerboard');
thisR.set('asset',cubeIDX,'material name','checkerboard');

thisR.set('texture','checkerboard','uscale',4);
thisR.set('texture','checkerboard','vscale',4);

materialName = thisR.get('asset',cubeIDX,'material name');
fprintf('Cube material: %s\n',materialName);
fprintf('Checkerboard uscale: %.1f\n',thisR.get('texture','checkerboard','uscale'));

%% Render once

scene = piWRS(thisR,'name','checker texture','render flag','hdr');
fprintf('Rendered texture scene mean luminance %.3f cd/m2\n',sceneGet(scene,'mean luminance'));

%% END
