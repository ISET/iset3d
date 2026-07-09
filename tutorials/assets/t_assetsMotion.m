%% Move an asset during rendering to simulate motion
%
% This tutorial adds motion transforms to one asset and renders once.
%
% See also
%   t_piIntro_*, t_assets*

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read a simple scene

thisR = piRecipeDefault('scene name','SimpleScene');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',2);

%% Add asset motion blur

assetName = 'figure_3m_O';
assetPos = thisR.get('asset',assetName,'world position');
fprintf('Moving asset %s from [%.2f %.2f %.2f]\n',assetName,assetPos);

thisR.set('camera exposure',0.5);
thisR.set('asset',assetName,'motion','translation',[0.1 0.1 0]);
thisR.set('asset',assetName,'motion','rotation',[0 0 30]);

motionNode = thisR.get('asset',assetName,'subtree');
fprintf('Motion subtree nodes after update: %d\n',numel(motionNode.names));

%% Render once

scene = piWRS(thisR,'name','motionblur','render flag','hdr');
fprintf('Rendered motion scene: %d x %d pixels\n',sceneGet(scene,'cols'),sceneGet(scene,'rows'));

%% END
