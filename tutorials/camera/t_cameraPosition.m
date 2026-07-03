%% t_cameraPosition
%
% Adjust the camera position and rotation for the MCC scene.  The lookat
% structure contains from, to, and up vectors.
%
% See also
%   t_camera*, tls_camera*

%% Initialize a default recipe and replace the light

ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeDefault;
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('nbounces',2);

thisR.set('light','all','delete');
newDistLight = piLightCreate('new dist light',...
    'type','distant',...
    'spd','equalEnergy',...
    'cameracoordinate',true);
thisR.set('light',newDistLight,'add');

%% Move and rotate the camera

thisR.set('to',[0 0 0]);
fprintf('Initial direction: [%.2f %.2f %.2f]\n',thisR.get('lookat direction'));

thisR = piCameraTranslate(thisR,'z shift',1);
thisR = piCameraTranslate(thisR,'x shift',-2,'fromto','both');
thisR = piCameraRotate(thisR,'y rot',-20);

fprintf('Camera from: [%.2f %.2f %.2f]\n',thisR.get('from'));
fprintf('Camera to:   [%.2f %.2f %.2f]\n',thisR.get('to'));

%% Render once

scene = piWRS(thisR,'render flag','hdr');
fprintf('Rendered camera-position scene: %d x %d pixels\n',sceneGet(scene,'cols'),sceneGet(scene,'rows'));

%% END
