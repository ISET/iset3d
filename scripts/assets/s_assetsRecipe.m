%% Store small asset recipes as mat-files in the data/assets directory
%
% We save certain small assets and specific test chart recipes in
% data/assets. 
%
% The goal is to simplify inserting these objeccts into arbitrary scenes
% easily. We save more complex scenes in the data/scenes directories.
%
% This script is used to produce the assets, which have
%   * a recipe  (thisAsset.thisR)
%   * a node where the recipe is merged into the root of the larger scene
%      (thisAsset.mergeNode)
%
% In the asset recipe is the
%
%  'from' is [0,0,0]
%  'to'   is [0 0 1];
%  'up'   is [0 1 0];
%
% An asset has one object (asset) and no light.  To check the appearance of
% the asset, you can run this code:
%
% To visualize an asset
%{
  thisA = piAssetLoad('Bunny');
  thisR = thisA.thisR;
  lgt = piLightCreate('point','type','point'); 
  thisR.set('object distance',1);
  thisR.set('light',lgt,'add');
  piWRS(thisR,'render flag','rgb');
%}
%
% To merge an asset into an existing scene, use code like this
% Fix the code below for the ordering of translate and scale. 
%{
   mccR = piRecipeCreate('macbeth checker');
   thisA = piAssetLoad('Bunny');
   mccR = piRecipeMerge(mccR,thisA.thisR);
   bunny = piAssetSearch(mccR,'object name','Bunny');
   mccR.set('asset',bunny,'world position',[0 0 -2]);
   mccR.set('asset',bunny,'scale',4);
   piWRS(mccR,'render flag','rgb');
%}
% 
% See also
%   s_scenesRecipe
%

%% Init

ieInit;
if ~piDockerExists, piDockerConfig; end

assetDir = piDirGet('assets');

%% The Stanford bunny

sceneName = 'bunny';
thisR = piRecipeCreate(sceneName);
% piWRS(thisR);

thisR.set('lights','all','delete');
thisR.set('node',2,'delete');
thisR.show;
thisR.show('objects');

% There is just one object.
bunnyID = piAssetSearch(thisR,'object name','Bunny');

oFile = thisR.save(fullfile(assetDir,[sceneName,'.mat']));
mergeNode = 'Bunny_B';
save(oFile,'mergeNode','-append');

%{
lgt = piLightCreate('point','type','point');
thisR.set('light',lgt,'add');
piWRS(thisR);
%}
%% A head - maybe we should scale this to a smaller size

thisR = piRecipeCreate('head');
thisR.set('lights','all','delete');
oFile = thisR.save(fullfile(assetDir,'head.mat'));

mergeNode = 'head_B';
save(oFile,'mergeNode','-append');
% thisR.show('materials');

%%  Coordinate axes at 000

sceneName = 'coordinate';
thisR = piRecipeDefault('scene name', sceneName);
oNames = thisR.get('object names no id');

% Put a merge node (branch type) above all the objects
geometryNode = piAssetCreate('type','branch');
geometryNode.name = 'mergeNode_B';
thisR.set('asset','root_B','add',geometryNode);

% Move the axes by adjusting the mergeNode_B.
thisR.set('asset','mergeNode_B','translate',[0 0 1]);

% piWRS(thisR);
mergeNode = geometryNode.name;
% thisR.show('textures');   % The filename should be textures/mumble.png
% piAssetShow(thisR);

oFile = thisR.save(fullfile(assetDir,[sceneName,'.mat']));
save(oFile,'mergeNode','-append');
thisR.show('materials');

%% We need a light to see it.
%
% Camera at 000 to 001 sphere at 001
%
sceneName = 'sphere';
thisR = piRecipeCreate(sceneName);
thisR.set('lights','all','delete');
% piAssetShow(thisR);

oFile = thisR.save(fullfile(assetDir,[sceneName,'.mat']));
mergeNode = 'Sphere_B';
save(oFile,'mergeNode','-append');

%% Test charts

% The merge node is used for
%
%   piRecipeMerge(thisR,chartR,'node name',mergeNode);
%

% EIA Chart
[thisR, mergeNode] = piChartCreate('EIA');
% piAssetShow(thisR,'object distance',3);
oFile = thisR.save(fullfile(assetDir,'EIA.mat'));
save(oFile,'mergeNode','-append');

%% Ringsrays
[thisR, mergeNode]= piChartCreate('ringsrays');
% piAssetShow(thisR,'object distance',3);

oFile = thisR.save(fullfile(assetDir,'ringsrays.mat'));
save(oFile,'mergeNode','-append');

%% Slanted bar
[thisR, mergeNode] = piChartCreate('slanted bar');
% piAssetShow(thisR,'object distance',3);

oFile = thisR.save(fullfile(assetDir,'slantedbar.mat'));
save(oFile,'mergeNode','-append');

%% Grid lines
[thisR, mergeNode] = piChartCreate('grid lines');
% piAssetShow(thisR,'object distance',3);

oFile = thisR.save(fullfile(assetDir,'gridlines.mat'));
save(oFile,'mergeNode','-append');

%% face
[thisR, mergeNode] = piChartCreate('face');
% piAssetShow(thisR,'object distance',3);

oFile = thisR.save(fullfile(assetDir,'face.mat'));
save(oFile,'mergeNode','-append');

%% Macbeth not sure why this is not working just now
[thisR, mergeNode] = piChartCreate('macbeth');
% piAssetShow(thisR,'object distance',3);

oFile = thisR.save(fullfile(assetDir,'macbeth.mat'));
save(oFile,'mergeNode','-append');

%% point array
[thisR, mergeNode] = piChartCreate('pointarray_512_64');
oFile = thisR.save(fullfile(assetDir,'pointarray512.mat'));
save(oFile,'mergeNode','-append');

%% END



