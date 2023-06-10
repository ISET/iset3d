function id = piAssetInsert(thisR, assetInfo, newNode, varargin)
% Insert a new node between an existing node and its parent
%
% Synopsis:
%   id = piAssetInsert(thisR, assetInfo, node)
%
% Brief description:
%   The assetInfo defines an existing node.  The newNode is inserted
%   between the existing node and its parent.
%
%   There are cases when we want the insertion between a node and all of
%   its children.  See piRecipeRectify for that method.  Add it here some
%   day.
%
% Inputs:
%   thisR      - recipe.
%   assetInfo  - an existing asset node name or id.
%   newNode    - the node to insert.
%
% Returns:
%   id         - id of the newly inserted node.
%
% See also
%   Only appears to be called in recipeSet.  Maybe not necessary any more?

% Examples:
%{
 thisR = piRecipeDefault('scene name', 'Simple scene');
 thisR.assets.show;

 newNode = piAssetCreate('type', 'branch');
 newNode.name = 'New node';
 id = thisR.set('asset', 'Sky1_L', 'insert', newNode);
%}

%% Parse input
p = inputParser;
p.addRequired('thisR', @(x)isequal(class(x),'recipe'));
p.addRequired('assetInfo', @(x)(ischar(x) || isscalar(x)));
p.addRequired('newNode', @isstruct);

p.parse(thisR, assetInfo, newNode, varargin{:});
thisR = p.Results.thisR;
assetInfo = p.Results.assetInfo;
newNode = p.Results.newNode;

%% If assetInfo is a node name, find the id.  If an id, find the name

if isnumeric(assetInfo)
    assetID   = assetInfo;
    assetName = thisR.assets.get(assetID).name;
else
    assetName = assetInfo;
    assetID   = piAssetFind(thisR.assets,'name',assetName);
end

%% Specify the current node and the new node

% Get node and its parent.
thisNode     = thisR.get('asset', assetName);
parentNodeID = thisR.assets.getparent(assetID);
parentNode   = thisR.assets.get(parentNodeID);

% Attach the new node under parent of thisNode.
newNode.type = 'branch'; % Enforce it is branch node

% The newNode is added below the parent node.
% NOTE: The name of newNode name will be changed to force it to be unique
% when it is addded to the tree.
[~, id] = thisR.set('asset', parentNodeID, 'add', newNode);

% Change the parent of thisNode to be the newNode
thisR.set('asset', thisNode.name, 'parent', id);

end
