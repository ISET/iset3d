%% Show how to render with camera motion blur
%
% This script shows how to add camera motion blur while keeping the
% scene itself stationary.
%
% Dependencies:
%
%    ISET3d, ISETCam 
%
%
% Zhenyi SCIEN 2019
%
% Updated for pbrt-v4 Translate -- D.Carinal 2024
%
% See also
%   t_piIntro_*

% History:
%   10/28/20  dhb  Comments, simplify some aspects of code, remove stray
%                  commented out lines that had no explanation.

%% Initialize ISET and Docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read in a scene recipe
thisR = piRecipeDefault('scene name','SimpleScene');

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

thisR.set('light', 'Sky1', 'rotate', [-90 0 0]);
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

% As of pbrt-v4 it seems like we want to start from "0" not .from
thisR.set('camera motion translate start',[0 0 0]);

% shift camera to the side by .1 meters by setting camera motion end parameters
endPos = [.1 0 0];
thisR.set('camera motion translate end',endPos);

% No rotation yet
thisR.set('camera motion rotate start',piRotationMatrix);
thisR.set('camera motion rotate end',piRotationMatrix);

% Write and render
piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance');
scene = sceneSet(scene,'name','Camera Motionblur: Translation');
sceneWindow(scene);

%%  Now, rotate the camera
%

% The angle specification is piRotationMatrix.  Here the angle is changed
% by 5 degrees around the z-axis.
endRotation = piRotationMatrix('zrot',5);

% Set camera motion end parameters.
thisR.set('camera motion translate end',endPos);
thisR.set('camera motion rotate end',endRotation);

%% Write an render
piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance');
scene = sceneSet(scene,'name','Camera Motionblur: rotation');
sceneWindow(scene);

%% END







