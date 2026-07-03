%% Camera settings: object distance and field of view
%
% This tutorial uses the Chess Set scene with the default pinhole camera.
% It introduces camera get/set calls and renders one low-resolution image.
%
% See also
%   piCameraCreate, recipe/get, recipe/set

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the recipe and inspect camera parameters

thisR = piRecipeDefault('scene name','ChessSet');
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('nbounces',2);

cameraSubtype = thisR.get('camera subtype');
objectDistance = thisR.get('object distance');
fov = thisR.get('fov');

fprintf('Camera subtype: %s\n',cameraSubtype);
fprintf('Object distance: %.2f m\n',objectDistance);
fprintf('Field of view: %.1f deg\n',fov);

%% Move the camera closer and narrow the field of view

thisR.set('object distance',objectDistance - 0.2);
thisR.set('fov',20);

fprintf('Updated object distance: %.2f m\n',thisR.get('object distance'));
fprintf('Updated field of view: %.1f deg\n',thisR.get('fov'));

%% Render once

scene = piWRS(thisR,'render flag','hdr');
fprintf('Depth range: %.2f to %.2f m\n',sceneGet(scene,'depth range'));

%% END
