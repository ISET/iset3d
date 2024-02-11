function [thisR, instanceBranchName, OBJsubtreeNew] = piObjectInstanceCreate(thisR, assetname, varargin)
%% Create an object copy (instance)
%
% Synopsis:
%   [thisR, instanceBranchName, OBJsubtreeNew]  = piObjectInstanceCreate(thisR, assetname, varargin)
%
% Brief
%   Instancing enables the system to store a single copy of the object
%   mesh and render multiple copies (instances) that differ based on
%   the transformations that place it in the scene. Instancing is an
%   efficient method of copying.
%
%   Running this function can change the node indices and potentially
%   introduce some name changes. See the discussion at the end about
%   'uniqueNames'
%
% Inputs:
%   thisR     - scene recipe
%   assetName - Identifier of the object we want to copy.  Either an
%               integer index or an asset (object) name
%
% Optional key/val
%   position  - 1x3 position (translation re: original, should rename)
%   rotation  - 3x4 rotation
%   scale     - 1x3 scale
%   motion    - motion struct which contains animated position and rotation
%   unique    - run uniquenames prior to exit (default:  false)
%
% Outputs:
%   thisR     - scene recipe
%   instanceBranchName - The new instance is in a new branch
%   OBJsubtreeNew - this is the subtree of the instance
%
% Description
%   Instances can be used with scenes that have created an 'assets'
%   slot.  To use instances, we first prepare the recipe using the
%   function (piObjectInstanceText). This code finds the
%   ObjectBegin/End code and makes an instance of these objects.
% 
%   The code is explained in the tutorial script
%
%       t_piSceneInstances. 
%
% Zhenyi, 2021
%
% See also
%   piObjectInstance, t_piSceneInstances

% Example
%{
fileName = fullfile('low-poly-taxi.pbrt');
thisR = piRead(fileName);
thisR.set('skymap','sky-rainbow.exr');

carName = 'taxi';
rotationMatrix = piRotationMatrix('z', -15);
position = [-4 0 0];
thisR = piObjectInstanceCreate(thisR, [carName,'_m_B'], ...
    'rotation',rotationMatrix, 'position',position,'unique',true);
piWRS(thisR,'remote resources',true);
%}
%% Read the parameters

p = inputParser;
p.addRequired('thisR', @(x)isequal(class(x),'recipe'));
p.addRequired('assetname',@(x)(ischar(x) || isnumeric(x)));
p.addParameter('position',[0, 0, 0]);
p.addParameter('rotation',piRotationMatrix);
p.addParameter('scale',[1,1,1]);
p.addParameter('motion',[], @(x)isstruct);
p.addParameter('graftnow',1);
p.addParameter('unique',false,@(x)(islogical(x)));

p.parse(thisR, assetname, varargin{:});

thisR    = p.Results.thisR;
position = p.Results.position;
rotation = p.Results.rotation;
scale    = p.Results.scale;
motion   = p.Results.motion;
graftNow = p.Results.graftnow;

%% Find the asset idx and properties
[idx,asset] = piAssetFind(thisR, 'name', assetname);

% ZL only addressed the first entry of the cell.  So, this seems OK.
if iscell(asset)
    if numel(asset) > 1
        warning('Multiple assets returned. There should just be 1.');
    end
    asset = asset{1}; 
end

if ~strcmp(asset.type, 'branch')
    warning('Only branch name is supported.');
    return;
end

%% We have a valid index.  Start the operations.

% Get the subtree of the object instance. 
OBJsubtree = thisR.get('asset', idx, 'subtree','false');

OBJsubtree_branch = OBJsubtree.get(1);
if ~isfield(OBJsubtree_branch, 'instanceCount')
    OBJsubtree_branch.instanceCount = 1;
    indexCount = 1;
else
    if OBJsubtree_branch.instanceCount(end)==numel(OBJsubtree_branch.instanceCount)
        OBJsubtree_branch.instanceCount = [OBJsubtree_branch.instanceCount,...
            OBJsubtree_branch.instanceCount(end)+1];
        indexCount = numel(OBJsubtree_branch.instanceCount);
    else
        indexCount = 1;
        while ~isempty(find(OBJsubtree_branch.instanceCount==indexCount,1))
            indexCount = indexCount+1;
        end
        OBJsubtree_branch.instanceCount = sort([OBJsubtree_branch.instanceCount,indexCount]);
    end
end

% Add instance to parent object - on dev-kitchen the branch name has no ID
thisR.assets = thisR.assets.set(idx, OBJsubtree_branch);

InstanceSuffix = sprintf('_I_%d',indexCount);
if ~isempty(position)
    OBJsubtree_branch.translation{1} = position(:);
end
if ~isempty(rotation)
    OBJsubtree_branch.rotation{1}    = rotation;
end
if ~isempty(scale)
    OBJsubtree_branch.scale{1}    = scale;
end

if ~isempty(motion)
    OBJsubtree_branch.motion.translation = motion.translation;
    OBJsubtree_branch.motion.rotation = motion.rotation;
    OBJsubtree_branch.motion.scale = motion.scale;
end

OBJsubtreeNew = tree();

OBJsubtree_branch.referenceObject = OBJsubtree_branch.name(1:end-2); % remove '_B'
OBJsubtree_branch.isObjectInstance = 0;
OBJsubtree_branch.name = strcat(OBJsubtree_branch.name, InstanceSuffix);

% replace branch
OBJsubtreeNew = OBJsubtreeNew.set(1, OBJsubtree_branch);

%% Apply transformation to lights

% Check wheather there are extra nodes attached.
if isfield(OBJsubtree_branch,'extraNode') && ~isempty(OBJsubtree_branch.extraNode)
    extraNode = OBJsubtree_branch.extraNode;

    extraNodeNew = extraNode;
    for tt = 1:numel(extraNode.Node)
        thisNode = extraNode.Node{tt};
        if isfield(thisNode,'referenceObject')
            thisNode = rmfield(thisNode,'referenceObject'); % do not write as instance
            extraNodeNew = extraNodeNew.set(tt, thisNode);
        end
    end

    % graft lightsNode
    OBJsubtreeNew = OBJsubtreeNew.graft(1, extraNodeNew);
end

if graftNow
    % graft object tree to scene tree
    try
        id = thisR.get('node', 'root', 'id');
        thisR.assets = thisR.assets.append(id, OBJsubtreeNew);
    catch
        disp('ERROR: Failed to graft subtree to main tree');
    end
end
% Returned
instanceBranchName = OBJsubtree_branch.name;

% The uniqueNames call takes a quite a long time to run for driving
% scene. Though, I (DJC?) fixed some lazy coding in the tree and this
% runs a lot faster. Hopefully that means we can leave it in place
% (DJC?)
%
% Zhenyi said he wanted it removed.  So BW turned it into an option.
%
if p.Results.unique, thisR.assets = thisR.assets.uniqueNames; end


end