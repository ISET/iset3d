%% Show how to render with camera motion blur
% VERSION TO test with MMP scenes
% This script shows how to add camera motion blur while keeping the
% scene itself stationary.
%
% Dependencies:
%
%    ISET3d, ISETCam 
%
%
% Modified by D. Cardinal from Zhenyi SCIEN 2019 original
%
% See also
%   t_piIntro_*

%% Initialize ISET and Docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read in an MMP Scene Recipe
% Use full path unless the scenes are in your matlab path
%thisR = piRead('pavilion-night.pbrt', 'exporter', 'Copy');
%thisR = piRead('pavilion-day.pbrt', 'exporter', 'Copy');
thisR = piRead('bistro_cafe.pbrt', 'exporter', 'Copy');

%% Set render quality
%
% This is a low resolution for speed.
thisR.set('film resolution',[200 150]);
thisR.set('rays per pixel',128);

thisR.set('film render type',{'radiance','depth'});

%% Rendering properites
%
% This value determines the number of ray bounces.  The scene has
% glass so we need to have at least 2 or more.
thisR.set('bounces',2);

% Field of view
thisR.set('fov',45);

%% Write out the pbrt scene file, based on thisR.
piWrite(thisR);

%% Render the scene with no camera motion
%
% Speed up by only returning radiance, and display
scene = piRender(thisR);
sceneWindow(scene);
if isequal(piCamBio,'isetcam')
    sceneSet(scene,'display mode','hdr');
else
    sceneSet(scene,'gamma',0.5);
end

%% Motion blur from camera
%
% Specify the initial position and pose (rotation), translate,
% and then set camera motion end position.
%
% Findthe current camera position and rotation
from = thisR.get('from');
thisR.set('camera motion translate start',from(:));
thisR.set('camera motion rotate start',piRotationMatrix);

% Move in the direction camera is looking, but just a small amount.
fromto = thisR.get('from to');
endPos = [1 0 0] + thisR.lookAt.from(:);

% Set camera motion end parameters, no change in rotation yet.
thisR.set('camera motion translate end',endPos);
thisR.set('camera motion rotate end',piRotationMatrix);

% Write and render
piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance');
scene = sceneSet(scene,'name','Camera Motionblur: Translation');
sceneWindow(scene);

%%  Now, rotate the camera
%
% No translation, end position is where camera is now.
endPos = thisR.lookAt.from(:);

% The angle specification is piRotationMatrix.  Here the angle is changed
% by 5 degrees around the z-axis.
endRotation = piRotationMatrix('zrot',15);

% Set camera motion end parameters.
thisR.set('camera motion translate end',endPos);
thisR.set('camera motion rotate end',endRotation);

%% Write an render
piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance');
scene = sceneSet(scene,'name','Camera Motionblur: rotation');
sceneWindow(scene);

%% END







