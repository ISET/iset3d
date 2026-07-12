%% Rotation examples in object and world coordinates
% SkipFile
%
%  ZLy/BW
%
%  This is a useful interactive rotation walkthrough, but it overlaps with
%  the broader t_assets tutorial and the faster t_assetsWorldTrans tutorial.
%  Keep it available for exploration, but skip it in automated tutorial runs.
%
% See also
%  t_assetsWorldPos, t_assets*
%

%%  Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Set up a simple scene as an example

thisR = piRecipeDefault('scene name', 'simple scene');

thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',5); 

% Render
piWrite(thisR)
scene = piRender(thisR, 'render type', 'radiance');
sceneWindow(scene);
sceneSet(scene, 'render flag', 'hdr');

%% Setting a rotation for this asset

% This is the blue stick figure at 3 meters distance
assetName = 'figure_3m_O';

initialAng = thisR.get('asset', assetName, 'world rotation angle');
disp(initialAng)

% First rotation
[~,R1] = thisR.set('asset', assetName, 'rotation', [0 90 45]);

% Check rotation angle
rotAng = thisR.get('asset', assetName, 'world rotation angle');
disp(rotAng)

% Render
piWrite(thisR)
scene = piRender(thisR, 'render type', 'radiance');
sceneWindow(scene);

%% Check if we can use the rotation angle to reproduce the rotation.

% Notice the rotation of the figure_3m
% The asset-tree display and pause are useful interactively but slow and
% brittle in automated tutorial runs.
% thisR.assets.show; pause(2); close;

% Delete the rotation we applied above
thisR.set('asset', R1.name, 'removelasttrans');

% Apply the rotation angle
thisR.set('asset', assetName, 'rotation', rotAng);

%% Rotate two assets, specified in world space and move the camera

thisR = piRecipeDefault('scene name', 'simple scene');
saveFrom = thisR.get('from');

thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',5); 

thisR.set('asset', 'figure_3m_O', 'world rotate', [0 0 90]);
thisR.set('asset', 'figure_6m_O', 'world rotate', [0 0 90]);

% Move the camera for a better look
oDist = thisR.get('object distance');
piCameraTranslate(thisR,'z shift',0.3*oDist,'fromto','both');
piCameraTranslate(thisR,'y shift',0.8*oDist,'fromto','both');
piCameraTranslate(thisR,'x shift',0.2*oDist,'fromto','to');

% This final render duplicates the previous visual check with a two-asset
% world-space rotation.  Re-enable it for a fuller interactive example.
%{
piWrite(thisR)
[scene,result] = piRender(thisR, 'render type', 'radiance');
sceneWindow(scene);
sceneSet(scene, 'render flag', 'hdr');
%}

%% END
