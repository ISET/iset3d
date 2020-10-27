function val = piAssetGet(thisR, id, param, varargin)
%%
% Get the value(s) of a node parameter(s) in the asset tree. If you want to
% get more than one parameter values, pass param as a cell array.
% 
%% Parse input
varargin = ieParamFormat(varargin);
p = inputParser;
p.addParameter('printinfo', false);
p.parse(varargin{:});
printinfo = p.Results.printinfo;
%% 
thisTree = thisR.assets;
thisNode = thisTree.get(id);

if ~exist('param', 'var')
    val = thisNode;
else
    if ischar(param)
        if ~isfield(thisNode, param)
            if ischar(thisNode) % In the case of a string
                name = thisNode;
            else
                name = thisNode.name;
            end
            if printinfo
                warning('Node %s does not have field: %s. Empty return', name, param)
            end
            val = [];
        else
            val = thisNode.(param);
        end
    elseif iscell(param)
        val = cell(1, numel(param));
        for ii = 1:numel(param)
            val{ii} = piAssetGet(thisR, id, param{ii});
        end
    end
end
end