function thisR = piObjectInstanceRemove(thisR,assetname)
% Remove an instance from the asset tree
%
% Synopsis
%    thisR = piObjectInstanceRemove(thisR,assetname)
%
% Inputs
%   thisR     - Recipe
%   assetname - Name of the asset (instance)
%   
% See also
%    piObjectInstanceCreate
%

%%  Find all the instances with this asset name
[assetIdx,~] = piAssetFind(thisR, 'name', assetname);

% Find the instances, which have a name assetname_I_XXX
index = strfind(assetname,'_I_');

% Get the index number
instanceIndex = str2double(assetname(index+3:end));

% Find reference branch for the instance.  This is the branch that contains
% the main information about the asset.   Perhaps this could become
%
%   thisR.get('instance',idx,'reference branch name');
%
referenceBranchName = thisR.assets.Node{assetIdx}.referencebranch;
[idx_ref,referenceBranch] = piAssetFind(thisR, 'name', referenceBranchName);

% Remove the slot for this instance index of this asset.  Setting it to
% empty effectively deletes the slot
referenceBranch{1}.instanceCount(referenceBranch{1}.instanceCount==instanceIndex) = [];
thisR.assets = thisR.assets.set(idx_ref, referenceBranch{1});

% Remove the asset from tree with the asset.chop.  
thisR.assets=thisR.assets.chop(assetIdx);

end