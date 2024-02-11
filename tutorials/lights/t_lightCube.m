%% Illustrate the piLightCube method
%
% The cube light has six sides the emit different colors in each
% direction.  Placing the cube near the camera lets you determine how
% to rotate the planar surface of the area light to point in the
% direction of the camera.
%
% When the plane is a mirror, you can see the cube reflected from some
% positions, but not others.
%
% See also
%   piLightCube, t_areaLight*

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Flat curface
thisR = piRecipeCreate('flat surface');
cubeID = piAssetSearch(thisR,'object name','Cube');

piMaterialsInsert(thisR,'names',{'mirror','diffuse-white','marble-beige','wood-mahogany'});
thisR.set('asset',cubeID,'material name', 'diffuse-white');
thisR.set('skymap','room.exr');

%% Create the cube light
% We move the cube out of the way of the camera.
piLightCube(thisR,'shape scale',0.1,'translate',[0.1 0.1 -0.1]);
thisR.set('skymap','room.exr');

% We can see the reflected light in the mirror.  
piWRS(thisR);

% Its color tells us the rotation of the plane of the area light that
% will aim at the surface.
piLightCube('help');

%% Save original camera and plane positions

% And have a look in a mirror
cameraP = thisR.get('camera position');
planeP  = thisR.get('asset','Cube_O','world position');
thisR.set('asset',cubeID,'material name', 'mirror');
piWRS(thisR);

%% Adjust camera position
% Behind, below
thisR.set('from',[-3 -3 -3]); thisR.set('to',cameraP);
piWRS(thisR,'render flag','hdr');

%% Behind, top
thisR.set('from',[3 3 -3]); thisR.set('to',cameraP);
piWRS(thisR,'render flag','hdr');

%% Above
thisR.set('from',[3 3 3]); thisR.set('to',cameraP);
piWRS(thisR,'render flag','hdr');

%% Below
thisR.set('from',[3 -3 3]); thisR.set('to',cameraP);
piWRS(thisR,'render flag','hdr');

%% END