% t_piIntro_texture
%
% Textures are part of the material definition.  We have routines that
% create materials with pre-assigned textures, and some of the parameters
% of these textures can be modified. 
% 
% See the tutorial t_material* for examples of inserting materials that
% have been predefined.  That tutorial uses piMaterialsInsert, which
% depends on piMaterialPresets, to insert materials with pre-assigned
% textures into a recipe.
% 
% This recipe expands on how to create a material using an image as a
% texture, and then to control the properties of the texture.
%
% An exploration of the other materials and textures we have defined
% in piMaterialPresets is in v_material.m
%
% See also
%  v_Materials, t_materials, t_materials*

%% Init
ieInit;
if ~piDockerExists, piDockerConfig; end

%%

% Fix piRecipeCreate for this object.  (BW, 9/22/2023).
thisR = piRecipeDefault('scene name','flatSurfaceWhiteTexture');

%% Add a light and render

% thisR.set('lights','all','delete');
% newDistLight = piLightCreate('Distant 1',...
%     'type', 'distant',...
%     'cameracoordinate', true,...
%     'spd', 'equalEnergy');
% thisR.set('light',  newDistLight, 'add');

% This is a description of the scene properties
thisR.show('objects');

% To see the individual types, you can also call this
thisR.show('lights');
thisR.show('materials');
thisR.show('textures');

piWRS(thisR,'name','random color');

%% Change the texture of the checkerboard.

% There are several built-in texture types that PBRT provides.  These
% include
%
%  checkerboard, dots, imagemap
%
% You set the parameters of the checks and dots.  You specify a PNG or an
% EXR file for the image map.
%

% Textures are attached to a material.  The checks, dots and others are
% created and inserted this way - see the code there if you want to do it
% yourself.
thisR   = piMaterialsInsert(thisR,'names','checkerboard');

cubeIDX = piAssetSearch(thisR,'object name','Cube');

% Set the material to the object
thisR.set('asset',cubeIDX,'material name','checkerboard');

thisR.show('materials');
thisR.show('objects');
thisR.get('asset',cubeIDX,'material name')

% Write and render the recipe with the new texture
piWRS(thisR,'name','checks');


%%  That felt good.  Let's make colored dots.

% Set the material to the object
thisR = piMaterialsInsert(thisR,'names','dots');
thisR.set('asset',cubeIDX,'material name','dots');

thisR.get('texture','dots','uscale')

% Write and render the recipe with the new texture
piWRS(thisR,'name','dots-orig');

%% These scale factor change the dot densities
% Other parameters change other visual properties.
thisR.set('texture','dots','vscale',16);
thisR.set('texture','dots','uscale',16);

% Write and render the recipe with the new texture
piWRS(thisR,'name','dots16');

%% Now we change the texture of a material in a more complex scene

thisR = piRecipeDefault('scene name', 'SimpleScene');
piMaterialsInsert(thisR,'groups','testpatterns');

planeIDX = piAssetSearch(thisR,'object name','Plane');
thisR.set('asset',planeIDX,'material name','dots');

piWRS(thisR);

%%  We have many more complex textures, including those based on images.

% Pull in a couple of wood types
piMaterialsInsert(thisR,'groups','wood');
thisR.get('print materials');
thisR.set('asset',planeIDX,'material name','wood-medium-knots');

piWRS(thisR);

%% Let's change the texture of a the sphere to checkerboard

sphereIDX = piAssetSearch(thisR,'object name','Sphere');
thisR.set('asset',sphereIDX,'material name','checkerboard');

% We should figure out what all these parameters do
%{
thisR.get('texture','checkerboard')
%}

thisR.set('texture','checkerboard','uscale',1);
thisR.set('texture','checkerboard','vscale',0.5);

piWRS(thisR);

%% END