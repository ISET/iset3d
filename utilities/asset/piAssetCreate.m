function obj = piAssetCreate(varargin)
% Creates the format for different types of assets
%
% Synopsis
%   obj = piAssetCreate(varargin)
%
% Inputs
%
% Optional key/val pairs
%   type - Possible asset node types are 'branch','object' and 'light'.
%
% Return
%   obj - An object structure
%
% Description
%
%  A marker is a leaf of the tree.  We have these from Cinema4D and maybe
%  other graphics programs
%
%  A light is always a leaf of the tree.  Lights are not always included in
%  the assets.  There is a separate 'lights' slot in the recipe.  Sorry
%  about that.
%
%  An object is always a leaf of the tree.  This is an honest to God aset.
%
%  A branch is a branch of the tree.  This includes position, rotation,
%  scale and other branch information.  The contents apply to all assets
%  below this branch Node
%
%  There are occasions in which the nodes are incorrectly labeled.  Please
%  be aware, and sorry.
%
% See also
%

% Examples:
%{
n = piAssetCreate('type', 'branch');
%}
%{
n = piAssetCreate('type','marker')
%}

%%
p = inputParser;
p.addParameter('type', 'branch', @(x)(ismember(x,{'branch','object','light','marker','trianglemesh'})));
p.parse(varargin{:});

type = p.Results.type;

%% Initialize the asset
obj.type = type;

switch ieParamFormat(type)
    case 'branch'
        obj.name = 'branch';
        obj.size.l = 0;
        obj.size.w = 0;
        obj.size.h = 0;
        obj.size.pmin = [0 0];
        obj.size.pmax = [0 0];
        obj.scale = {[1 1 1]};
        obj.translation = {[0 0 0]};
        obj.rotation = {[0 0 0;
            0 0 1;
            0 1 0;
            1 0 0]};
        obj.concattransform=[];
        obj.motion = [];
        obj.transorder = ['T', 'R', 'S']; % Order of translation, rotation and scale
        obj.isObjectInstance = false; % switch to true if the branch has been used more than once.
       
        % If the branch is referencing an object instance, we save the name of that object.
        obj.referenceObject = ''; 

    case 'object'
        obj.name = 'object';
        obj.mediumInterface = [];
        obj.material = [];
        obj.shape = [];
        % Different parts can be part of the same object, not clear.
        obj.index = [];
    case 'light'
        obj.name = 'light';
        obj.lght = [];
    case 'marker'
        obj.name = 'marker';
        obj.size.l = 0;
        obj.size.w = 0;
        obj.size.h = 0;
        obj.size.pmin = [0 0];
        obj.size.pmax = [0 0];
        obj.scale = [1 1 1];
        obj.translation = [0 0 0];
        obj.rotation = [0 0 0;
            0 0 1;
            0 1 0;
            1 0 0];
        obj.concattransform=[];
        obj.motion = [];
    case 'trianglemesh'
        obj.meshshape = 'trianglemesh';
        obj.filename = '';
        obj.integerindices = [];
        obj.point3p = [];
        obj.point2uv = [];
        obj.normaln = [];
        obj.height = '';
        obj.radius = '';
        obj.zmin = '';
        obj.zmax = '';
        obj.p2 = '';
        obj.phimax = '';
        obj.alpha = '';
    otherwise
        error('Unknown asset type %s\n',type);
end

end
