function [id, thisAsset] = piAssetFind(assets, param, val)
% Find the id of an asset whose parameter value matches the input val
%
% Synopsis:
%   [id, theAsset] = piAssetFind(assets, param, val)
%
% Inputs:
%   assets  - An ISET3d recipe or the assets from a recipe (a tree object)
%   param   - parameter  (e.g., name)
%   val     - value to match
%
% Returns:
%   id       - id of the matching node
%   theAsset - the asset struct
%
% See also:
%   piAssetGet, piAssetSet;

% Examples:
%{
 thisR = piRecipeDefault('scene name','simple scene');

 [~, theAsset] = piAssetFind(thisR,'',13);   % Returns asset for id 13.
 piAssetFind(thisR,'',theAsset{1}.name)        % Returns the same asset

 id = piAssetFind(thisR.assets, 'name', 'root');
 [id, theAsset]  = piAssetFind(thisR, 'name', 'Camera_B');
 [id, theAsset]  = piAssetFind(thisR, 'id', 13);
 theAsset{1}
 [~,theAsset] = piAssetFind(thisR.assets, '', 15);
 theAsset{1}
%}

%%  In the past, we allowed a recipe

% So now we check if it is a recipe and then we get the assets.
if isa(assets,'recipe')
    assets = assets.assets;
end
if ~isa(assets,'tree'), error('Assets must be a tree.'); end

% If the input is a node id (number), return the node
if isscalar(val) && ~isstring(val)
    id = val;
    thisAsset = {assets.get(val)};
    return;
end

%% Check two 
id = [];
thisAsset = {};
if isKey(assets.mapFullName2Idx, val)
    id = assets.mapFullName2Idx(val);
    thisAsset = assets.get(id);
elseif isKey(assets.mapShortName2Idx, val)
    id = assets.mapShortName2Idx(val);
    thisAsset = {assets.get(id)};
elseif strcmp(val, 'root')
    % not sure why there is no 'root' name
    id = 1;
    thisAsset= {assets.get(1)};
end

end
