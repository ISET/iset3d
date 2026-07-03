%% t_piSceneInstances
%
% Show how to add multiple instances of an object into a scene.  Instances
% reuse the original mesh with different transforms.
%
% See also
%   piObjectInstanceCreate, piObjectInstanceRemove

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create instances in a simple scene

thisR = piRecipeDefault('scene name','simple scene');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',2);

piObjectInstance(thisR);

yellowID = piAssetSearch(thisR,'object name','figure_6m');
p2Root = thisR.get('asset',yellowID,'pathtoroot');
idx = p2Root(end);

for ii = 1:3
    thisR = piObjectInstanceCreate(thisR,idx,'position',ii*[-0.3 0 0.0]);
end
thisR.assets = thisR.assets.uniqueNames;

blueID = piAssetSearch(thisR,'object name','figure_3m');
p2Root = thisR.get('asset',blueID,'pathtoroot');
idx = p2Root(end);

steps = [-0.3 0.3];
for ii = 1:numel(steps)
    thisR = piObjectInstanceCreate(thisR,idx,'position',[steps(ii) 0 0.0],'unique',true);
end

fprintf('Added %d yellow and %d blue instances\n',3,numel(steps));

%% Render once

scene = piWRS(thisR,'render flag','hdr');
fprintf('Rendered instance scene: %d x %d pixels\n',sceneGet(scene,'cols'),sceneGet(scene,'rows'));

%% END
