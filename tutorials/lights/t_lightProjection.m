%% t_lightProjection
%
%   Initial Experiments with Projected Lights
%
%   D. Cardinal, Stanford University, August, 2023
%
% See also
%  t_lightGonimetric
%  t_piIntro_lights

%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file
%thisR = piRecipeCreate('checkerboard');
thisR = piRecipeDefault('scene name','flatSurface');

thisR.set('name','ProjectionLight');  % Name of the recipe

thisR.show('lights');

% By default in checkerboard, camera is [0 0 10], looking at [0 0 0].
%thisR.lookAt.from = [0 0 5];

% for flat surface
thisR.lookAt.from = [3 5 0];

%% show original
piWRS(thisR,'mean luminance',-1);

%% Add projection lights

% scale appears to be how much to scale the image intensity. We haven't
% seen a difference yet between scale and power fov seems to be working
% well, changing how widely the projection spread.
%
% Remember when you render a collection of scenes, set the mean luminance
% parameter to a negative number so that we don't scale everything back to
% mean luminance of 100 cd/m2.
%

% filename is the "slide" being projected

% I think the ideal is a floating point exr from 0-1 in RGB
% but png works, but I think scales the power from 1 to 255
%
% fov is the field of view covered by the slide
% power is total power of the projection lamp

imageMap = 'skymaps/headlamp_highbeam.exr'; % cheat, should use all white
projectionLight_Left = piLightCreate('Left_Light', ...
    'type','projection',...
    'fov', 80, ...
    'scale', 10, ...
    'power', 0, ...  % pbrt checks for < 0, but not sure why
    'cameracoordinate', 1, ...
    'filename string', imageMap);
projectionLight_Right = piLightCreate('Right_Light', ...
    'type','projection',...
    'fov', 80, ...
    'scale', 10, ...
    'power', 0, ...  % pbrt checks for < 0, but not sure why
    'cameracoordinate', 1, ...
    'filename string', imageMap);

% On the surface scale & power do "the same thing" but they
% definitely don't in the pbrt code.

% Example outputs:
% scale power meanluminance
%  10,   20,   254
%  10,   10,   127
%  20,   10,   254
%  20,   -1,     5.9
%  10,   -1,     3
%  10,    1,    12.7
%  10,    0,     3

% Light transforms aren't currently working
%piLightTranslate(projectionLight, 'zshift', -5);

% Remove all the lights
thisR.set('light', 'all', 'delete');

% Add the projection lights
thisR.set('light', projectionLight_Left, 'add');
thisR.set('light', projectionLight_Right, 'add');


% piLightTranslate(projectionLight, 'zshift', -5);

pLight_Left = piAssetSearch(thisR,'light name', 'Left_Light');
pLight_Right = piAssetSearch(thisR,'light name', 'Right_Light');

thisR.show('lights');

%%
piWRS(thisR,'mean luminance',-1);

%% Rotate the light

thisR.set('asset',pLight_Left,'rotation',[0 0 30]);
piWRS(thisR,'mean luminance',-1);

% thisR.set('render type',{'radiance','depth'});
% scene = piRender(thisR);
% sceneWindow(scene);

%%
thisR.set('asset',pLight_Right,'translate',[1 1 0]);
thisR.show('lights');

piWRS(thisR);

%% Now try a mirrored sphere

% Can we make an empty scene?
thisR = piRecipeCreate('flat surface');

% Remove all the lights
thisR.set('light', 'all', 'delete');

% remove the flat surface
surface = piAssetSearch(thisR,'object name','Cube_O');
piAssetDelete(thisR, surface);

thisR.lookAt.from = [0 0 0];
thisR.lookAt.to = [0 0 100];
thisR.lookAt.up = [0 1 0];

% Add the projection lights
thisR.set('light', projectionLight_Left, 'add');
thisR.set('light', projectionLight_Right, 'add');

sphere = piAssetLoad('sphere');
assetSphere = piAssetSearch(sphere.thisR,'object name','Sphere');

piAssetTranslate(sphere.thisR,assetSphere,[0 0 50]);

% Default sphere is huge, scale it to use in scene
piAssetScale(sphere.thisR,assetSphere,[.002 .002 .002]);

% Mirror should give us most accurate light reading
piMaterialsInsert(sphere.thisR,'name','mirror');
piMaterialsInsert(sphere.thisR,'name','glossy-white');

sphere.thisR.set('asset', assetSphere, 'material name', 'mirror');

thisR = piRecipeMerge(thisR,sphere.thisR, 'node name',sphere.mergeNode,'object instance', false);
piWRS(thisR, 'mean luminance', -1);


%% Things that don't work or are alternates:)
%{
thisR.set('asset',pLight,'world position',[0 0 0]);

% Account for camera coordinate setting when we get the world position
thisR.get('light',pLight,'world position')

% We do account for it correctly with the show command
thisR.show('lights')
%}
%% if using cube
%{
cube = piAssetSearch(thisR,'objectname', 'Cube');
thisR.set('asset',cube,'rotation',[10 10 10]);
piWrite(thisR);
scene = piRender(thisR);
sceneWindow(scene);
%}
%%
%{
for ii = 1 % 0:3 in case we want to try options
    % Not sure if this is working
    %thisR.set('asset', pLight, 'rotation', [ii * 30, ii * 60, ii * 90]);
    %piAssetRotate(thisR, pLight, [0 0 90]);

    % try to move the light to a nominal headlamp
    % but our tranform matrix doesn't seem to get written out
    %piAssetTranslate(thisR, pLight, [2 -0.5 2]);
    piWRS(thisR,'mean luminance',-1);
end
%}


