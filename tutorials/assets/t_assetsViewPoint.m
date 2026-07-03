%% Change the viewing direction and position
%
% This tutorial moves one asset, points the camera at it, and renders once.
%
% See also
%   t_assets*

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Set up the base scene

thisR = piRecipeDefault('scene name','Simple Scene');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',2);

%% Move the blue asset and aim the camera

blueAssetName = 'figure_3m_O';
thisR.set('asset',blueAssetName,'translation',[-0.5 0 0]);
bluePos = thisR.get('asset',blueAssetName,'world position');

yellowAssetName = 'figure_6m_O';
yellowPos = thisR.get('asset',yellowAssetName,'world position');

thisR.set('from',yellowPos + [0 0 -0.2]);
thisR.set('to',bluePos);

fprintf('Camera from: [%.2f %.2f %.2f]\n',thisR.get('from'));
fprintf('Camera to:   [%.2f %.2f %.2f]\n',thisR.get('to'));

%% Render once

scene = piWRS(thisR,'render flag','hdr');
fprintf('Rendered viewpoint scene: %d x %d pixels\n',sceneGet(scene,'cols'),sceneGet(scene,'rows'));

%% END
