%% Rotation examples in object and world coordinates
%
% This tutorial applies object and world rotations, checks the resulting
% angles, and renders once.
%
% See also
%   t_assetsWorldPos, t_assets*

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Set up a simple scene

thisR = piRecipeDefault('scene name','simple scene');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',2);

%% Rotate one asset in object coordinates

assetName = 'figure_3m_O';
initialAng = thisR.get('asset',assetName,'world rotation angle');
fprintf('Initial %s rotation: [%.1f %.1f %.1f]\n',assetName,initialAng);

thisR.set('asset',assetName,'rotation',[0 90 45]);
rotAng = thisR.get('asset',assetName,'world rotation angle');
fprintf('After object rotation: [%.1f %.1f %.1f]\n',rotAng);

%% Rotate two assets in world coordinates and move the camera

thisR.set('asset','figure_3m_O','world rotate',[0 0 90]);
thisR.set('asset','figure_6m_O','world rotate',[0 0 90]);

oDist = thisR.get('object distance');
piCameraTranslate(thisR,'z shift',0.3*oDist,'fromto','both');
piCameraTranslate(thisR,'y shift',0.8*oDist,'fromto','both');
piCameraTranslate(thisR,'x shift',0.2*oDist,'fromto','to');

%% Render once

scene = piWRS(thisR,'render flag','hdr');
fprintf('Rendered rotation scene: %d x %d pixels\n',sceneGet(scene,'cols'),sceneGet(scene,'rows'));

%% END
