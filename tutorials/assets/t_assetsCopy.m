%% t_assetCopy
%
%  Make copies of an object in a recipe at different positions.
%
%  The original recipe is transformed by adding an 'instance' node of
%  each of the objects.  The instance is additional branch nodes with
%  the syntax 
%
%     id_originalName_B_I_1
%
%  The nodes are all modified to include
%      isObjectInstance,
%      referenceObject
%      instanceCount
%
% The original object with the data has
%      isObjectInstance 1
%      referenceObject is empty
%      instanceCount 1
%
%  The duplicate duplicate branch nodes have names like
%
%     id_originalName_B_I_N
%
% And the slots are
%
%      isObjectInstance 0
%      referenceObject string to the reference object
%      instanceCount [1 ... N]
%      
%
%
%
%  where id is the node id, originalName matches the original object.
% See also
%   t_piSceneInstances

%% Init

ieInit;
if ~piDockerExists, piDockerConfig; end
%%

% Maybe we should have an instance flag?
thisR = piRecipeCreate('sphere');

% Turn this into an instance recipe
piObjectInstance(thisR);

%% Find the object
%
% Maybe this should be thisR.get('asset',idx,'top branch')
sphereID = piAssetSearch(thisR,'object name','Sphere');
thisR.set('asset',sphereID,'scale',0.5);

p2Root = thisR.get('asset',sphereID,'pathtoroot');
idx = p2Root(end);

% Create copies at a position is relative to the position of the original
% object 
for ii=1:3
    thisR = piObjectInstanceCreate(thisR, idx, 'position',ii*[-0.3 0.1 0.0]);
end

% We need to adjust the names of the nodes after inserting.  Not sure why
% this can't happen in piObjectInstanceCreate.  I think speed was the
% issue.  We do not want to call this function every time we add an
% instance.  Once at the end is enough.
thisR.assets = thisR.assets.uniqueNames;

%%  Show the multiple spheres

piWRS(thisR,'name','Multiple spheres');  %%  Multiple copies of spheres

%%
thisR = piRecipeCreate('chessset');
thisR.set('fov',40);
piObjectInstance(thisR);

piWRS(thisR,'name','original');

%% Turn this into an instance recipe

% This is the ruler
id1 = 312;
id2 = 308;

% Delete the ruler
thisR.set('asset',id1,'delete');
thisR.set('asset',id2,'delete');
piWRS(thisR,'name','deleted ruler');

%% Copy the ruler
thisR = piRecipeCreate('chessset');
thisR.set('fov',40);
piObjectInstance(thisR);

% The ruler elements
id1 = 312;
id2 = 308;

% Find the object
%
% Maybe this should be thisR.get('asset',idx,'top branch')
p2Root = thisR.get('asset',id1,'pathtoroot');
id1end = p2Root(end);
p2Root = thisR.get('asset',id2,'pathtoroot');
id2end = p2Root(end);

sz1 = localAssetObjectSize(thisR,id1);
sz2 = localAssetObjectSize(thisR,id2);
if isempty(sz1) || numel(sz1) < 2 || isempty(sz2) || numel(sz2) < 2
    copySpacing = 1;
else
    copySpacing = max([sz1(2), sz2(2)]);
end

% Create copies at a position is relative to the position of the original
% object.  I am confused about the size units.
for ii=1:6
    thisR = piObjectInstanceCreate(thisR, id1end, 'position',ii*[0 copySpacing 0.0]/8);
    thisR = piObjectInstanceCreate(thisR, id2end, 'position',ii*[0 copySpacing 0.0]/8);
end

% We need to adjust the names of the nodes after inserting.  Not sure why
% this can't happen in piObjectInstanceCreate.  I think speed was the
% issue.  We do not want to call this function every time we add an
% instance.  Once at the end is enough.
thisR.assets = thisR.assets.uniqueNames;

%%  Show the multiple copies

piWRS(thisR,'name','ruler copies');

%%

function sz = localAssetObjectSize(thisR,assetID)
% Return the size of an asset or the first object contained in its subtree.

sz = [];
assetType = thisR.get('asset',assetID,'type');
if strcmp(assetType,'object')
    sz = localSafeAssetSize(thisR,assetID);
    if ~isempty(sz), return; end
end

subtree = thisR.get('asset',assetID,'subtree','false');
for nodeIndex = 1:subtree.nnodes
    thisNode = subtree.get(nodeIndex);
    if isfield(thisNode,'type') && strcmp(thisNode.type,'object')
        [objectID,~] = piAssetFind(thisR,'name',thisNode.name);
        sz = localSafeAssetSize(thisR,objectID);
        if ~isempty(sz), return; end
    end
end

end

function sz = localSafeAssetSize(thisR,assetID)
% Return object size when the optional mesh reader is available.

try
    sz = thisR.get('asset',assetID,'size');
catch ME
    if contains(ME.message,'readSurfaceMesh')
        sz = [];
    else
        rethrow(ME);
    end
end

end
