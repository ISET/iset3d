function val = piAssetGet(thisAsset, param, varargin)
% Return a parameter value for a specific node in an asset tree
%
% Synopsis:
%   val = piAssetGet(thisAsset, param)
%
% Brief description:
%   The asset is a node in a tree.  This routine returns the value of one
%   of the node parameters.  To return the parent or children of a node,
%   you must call the tree functions.
%
% Inputs:
%   thisAsset - A Node from the tree of assets.
%
% Optional:
%   param     - the parameter to look for, or empty to return the node.
%
% Returns:
%   val       - the parameter value or the node (if param is empty or
%               omitted).
%
% See also
%    assets.getparent(nodeID)  (assets is a tree).

% Examples:
%{
  thisR = piRecipeDefault;
  disp(thisR.assets.tostring)
  thisName = 'colorChecker_material_Patch09Material';
  [~, thisAsset] = piAssetFind(thisR.assets, 'name',thisName);
  thisAsset
  shape = piAssetGet(thisAsset, 'shape');
  scale = thisR.get('asset', 'colorChecker', 'scale');
%}
%%
% if notDefined('param'), param = ''; end

%% Parse input
p = inputParser;
p.addRequired('thisAsset', @isstruct);
p.addRequired('param', @ischar);
p.parse(thisAsset,param, varargin{:});

param = ieParamFormat(param);
%%

val = [];

switch thisAsset.type
    case 'object'
        switch param
            case {'name'}
                val = thisAsset.name;
            case {'type'}
                val = thisAsset.type;
            case {'mediuminterface'}
                val = thisAsset.mediumInterface;
            case {'material'}
                val = thisAsset.material;
            case {'materialname'}
                if isempty(thisAsset.material)
                    % Possibly a light or a marker or mislabeled.
                    return;
                else
                    if iscell(thisAsset.material)
                        % This needs to be resolved between Zhenyi and
                        % Zheng and me.  We need to decide if we allow the
                        % materials to be a cell, or we just make sure we
                        % put any transforms in the tree above the multiple
                        % parts.  Also, notice, we would have to specify
                        % which of the materials in the list.  We did this
                        % now only to make the auto demonstration run.
                        val = thisAsset.material{1}.namedmaterial;
                    else
                        val = thisAsset.material.namedmaterial;
                    end
                end
            case {'shape'}
                val = thisAsset.shape;
            case {'output'}
                val = thisAsset.output;
            otherwise
                warning('Node %s does not have field: %s. Empty return', thisAsset.name, param)
                return;
        end
    case 'light'
        switch param
            case {'name','names'}
                val = thisAsset.name;
            case {'type'}
                val = thisAsset.type;
            case {'lght'}
                val = thisAsset.lght;
            otherwise
                warning('Node %s does not have field: %s. Empty return', thisAsset.name, param)
                return;
        end
    case 'branch'
        switch param
            case {'name','names'}
                val = thisAsset.name;
            case {'namenoid'}
                % Should be a better way.
                val = thisAsset.name(10:end);
            case {'type'}
                val = thisAsset.type;
            case {'size'}
                val = thisAsset.size;
            case {'scale'}
                val = thisAsset.scale;
            case {'translation', 'translate'}
                val = thisAsset.translation;

            case {'rotation', 'rotate'}
                val = thisAsset.rotation;
            case {'motion'}
                val = thisAsset.motion;
            otherwise
                warning('Node %s does not have field: %s. Empty return', thisAsset.name, param)
                return;
        end
end

end
