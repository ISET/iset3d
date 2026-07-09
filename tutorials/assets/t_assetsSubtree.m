%% Assets: chop and graft a subtree
%
% Assets are stored as trees.  This short tutorial removes a subtree,
% grafts it back, and renders once at the end.
%
% See also
%   tls_assets.mlx, t_assets*

%% Initialize

close all; ieInit;
if ~piDockerExists, piDockerConfig; end

%% Simple base scene

thisR = piRecipeDefault('scene name','simple scene');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',2);

%% Select and remove a subtree

assetName = 'mirror_B';
initialNodeCount = numel(thisR.assets.names);
mirrorSubtree = thisR.get('asset',assetName,'subtree');
mirrorNames = mirrorSubtree.names;
fprintf('Mirror subtree contains %d nodes\n',numel(mirrorNames));

id = thisR.get('assets',assetName,'id');
thisR.assets = thisR.assets.chop(id);
fprintf('Node count after chop: %d\n',numel(thisR.assets.names));

%% Graft the subtree back onto the root

thisR.set('asset','root_B','graft',mirrorSubtree);
fprintf('Node count after graft: %d (started with %d)\n',numel(thisR.assets.names),initialNodeCount);

%% Render once

scene = piWRS(thisR,'render flag','hdr');
fprintf('Rendered subtree scene: %d x %d pixels\n',sceneGet(scene,'cols'),sceneGet(scene,'rows'));

%% END
