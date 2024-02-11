function thisR = piAssetDelete(thisR, assetInfo, varargin)
% Delete a single node of the asset tree
%
% Synopsis:
%   thisR = piAssetDelete(thisR, assetInfo)
%
% Brief description:
%   assetInfo:  The node name or the id
%
% Inputs:
%   thisR     - recipe.
%   assetInfo - asset node name or id.
%
% Optional key/val
%   TODO:  Remove all the nodes in the tree below this node.
%          Remove all the nodes in the tree from this node to the root
%
% Returns:
%   thisR     - modified recipe.

% Examples:
%{
 thisR = piRecipeDefault('scene name', 'Simple scene');
 disp(thisR.assets.tostring)
 thisR = thisR.set('asset', '004ID_Sky1', 'delete');
 disp(thisR.assets.tostring)
%}

%% Parse
p = inputParser;
p.addRequired('thisR', @(x)isequal(class(x),'recipe'));
p.addRequired('assetInfo', @(x)(ischar(x) || isscalar(x)));
p.parse(thisR, assetInfo, varargin{:});

thisR        = p.Results.thisR;
assetInfo    = p.Results.assetInfo;

%% If assetInfo is a name, convert it to an id
if ischar(assetInfo)
    assetName = assetInfo;
    assetID = piAssetFind(thisR.assets, 'name', assetInfo);
    if isempty(assetID)
        warning('Could not find an asset with name %s:', assetName);
        thisR.show('objects');
        return;
    end
end
%% Remove the node

% BW - I am worried about this logic.  I fear the nodes get renumbered
% after removal.
if ~isempty(thisR.assets.get(assetID))
    while true

        % First get the parrent of current node
        parentID = thisR.assets.Parent(assetID);
        
        % Has the parent node changed after the remove?  It seemed OK
        % after a few tests.  Leaving this here as a memory.
        % check = thisR.assets.get(parentID);

        thisR.assets = thisR.assets.removenode(assetID);
        
        % assert(isequal(check,thisR.assets.get(parentID)));

        if isempty(thisR.assets.getchildren(parentID))
            % No children of this node, so we delete it too.
            assetID = parentID;
        else
            % There are children of this node, so we are done pruning.
            break;
        end
    end
else
    warning('Node: %d is not in the tree, returning.', assetID);
end

end
