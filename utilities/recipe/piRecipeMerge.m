function sceneR = piRecipeMerge(sceneR, objectRs, varargin)
% Add multiple object recipes into a base scene recipe
%
% Synopsis:
%   sceneR = piRecipeMerge(sceneR, objectRs, varargin)
%
% Brief description:
%   Merges two recipes (material, texture, assets) into one.
%
% Inputs:
%   sceneR    - scene recipe
%   objectRs  - a recipe whose objects, materials, textures will be added
%               into the sceneR.  This can also be a cell array of
%               objectRs that will each be added into sceneR.
%
% Optional key/val pairs
%   material  -  Add materials from the asset.  (Default is true)
%   texture   -  Same as material (Default true)
%   asset     -  Same as material (Default true)
%   copyfiles -  Not sure, TBD
%   mergenode -  Index of the node of the asset whose children will merge into the
%                recipe. Default is the root node (1).
%   object instance - Add object as an object instance, then we 
%                can reuse(instance) it by function piObjectInstanceCreate.
%                (help needed in explaining this).
%
% Returns:
%   sceneR   - scene recipe with the added objects
%
% See also
%   piAssetLoad, s_assetsRecipe (where assets are made and tested)

% Example:
%{
% We need an example
%}

%% Parse input
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('sceneR', @(x)isequal(class(x),'recipe'));
p.addRequired('objectRs', @(x)isequal(class(x),'recipe') || iscell);

% So far, we add materials, textures, and assets.  We have not yet
% addressed lights.  The user can
p.addParameter('material', true);
p.addParameter('texture', true);
p.addParameter('asset', true);
p.addParameter('objectinstance', false); 
p.addParameter('copyfiles', 1 , @islogical);
p.addParameter('mergenode', 1 , @islogical);

p.parse(sceneR, objectRs, varargin{:});

sceneR         = p.Results.sceneR;
materialFlag   = p.Results.material;
textureFlag    = p.Results.texture;
assetFlag      = p.Results.asset;
objectInstance = p.Results.objectinstance;
copyFiles      = p.Results.copyfiles;
mergenode      = p.Results.mergenode;
copyTextureFlag = 1;
%%  The objects can be a cell or a recipe

% Make it a cell
if ~iscell(objectRs), recipelist{1} = objectRs;
else,                 recipelist = objectRs;
end

%% For each asset recipe, add its objects to the main scene

for ii = 1:length(recipelist)
    % The asset recipe
    thisR = recipelist{ii};

    if assetFlag
        if isempty(sceneR.assets)
            % Main scene has no assets.  Use the loaded asset.
            sceneR.assets = thisR.assets;
        else
            % These are the assets below the mergenode.  By default,
            % the merge node is the root node (1).            
            children = thisR.assets.getchildren(mergenode);
            % Get the subtree starting just below the root node

            % Graft the assets in this subtree into the main scene.  We
            % graft it onto the root of the main scene.  There appear to be
            % fields called isObjectInstance and isObjectInstancer
            for nChild = 1:numel(children)
                thisNodeTree = thisR.get('asset', children(nChild), 'subtree');
                [~,thisNode] = piAssetFind(thisR.assets, 'asset',children(nChild));
                if objectInstance 
                    % User wants us to deal with objectInstances
                    %
                    % If this node has isObjectInstance 0, or it doesn't
                    % even have the field, we do not add it to the root of
                    % the tree.  If the isObjectInstance is 1, add it.
                    if isfield(thisNode{1},'isObjectInstance') && thisNode{1}.isObjectInstance == 1
                        % For an asset tree, we save the parent object and
                        % set isObjectInstancer flag to be 1, when the instance
                        % is called the node's isObjectInstancer flag is 0; In
                        % this case, when we merge the scene, we would like
                        % to only merge the parent object, we will add
                        % instance later using piObjectInstanceCreate.
                        % --Zhenyi
                        sceneR = sceneR.set('asset', 1, 'graft', thisNodeTree);
                    end
                else
                    % User did not ask for objectInstance work.
                    sceneR = sceneR.set('asset', 1, 'graft', thisNodeTree);
                end
            end
        end
        
        if copyFiles
            % Copy meshes from objects folder to scene folder here
            sourceDir = thisR.get('input dir');
            dstDir    = sceneR.get('output dir');

            % Copy the assets from source to destination
            sourceAssets_v1 = fullfile(sourceDir, 'scene','PBRT','pbrt-geometry');
            sourceAssets_v2 = fullfile(sourceDir, 'geometry');
            if isfolder(sourceAssets_v1) && ~isempty(dir(fullfile(sourceAssets_v1,'*.pbrt')))
                
                dstAssets = fullfile(dstDir, 'scene/PBRT/pbrt-geometry');
                copyfile(sourceAssets_v1, dstAssets);
            elseif isfolder(sourceAssets_v2) && ...
                    (~isempty(dir(fullfile(sourceAssets_v2,'*.pbrt'))) ||...
                    ~isempty(dir(fullfile(sourceAssets_v2,'*.ply'))))
                dstAssets = fullfile(dstDir, 'geometry');
                copyfile(sourceAssets_v2, dstAssets);                
            else
                if isfolder(sourceDir)
                    if ~isfolder(dstDir), mkdir(dstDir), end
                    piCopyFolder(sourceDir, dstDir);
                    copyTextureFlag = 0;
                end
            end
        else
            copyTextureFlag = 0;
        end
    end

    if materialFlag
        % Combines the material lists in the two recipes
        if ~isempty(sceneR.materials)
            if ~isfield(sceneR.materials,'order')
                sceneR.materials.order = keys(sceneR.materials.list);
            end
            if ~isfield(thisR.materials,'order')
                thisR.materials.order = keys(thisR.materials.list);
            end
            sceneR.materials.list = [sceneR.materials.list; thisR.materials.list];
            for oo=1:numel(thisR.materials.order)
                if ~any(strcmp(sceneR.materials.order, thisR.materials.order{oo}))
                    sceneR.materials.order{end + 1} = thisR.materials.order{oo};
                end
            end
        else
            sceneR.materials = thisR.materials;
        end
    end

    if textureFlag
        % Combines the lists in the recipes, and then the files
        if ~isempty(sceneR.textures)
            if ~isfield(sceneR.textures,'order')
                sceneR.textures.order = keys(sceneR.textures.list);
            end
            if ~isfield(thisR.textures,'order')
                thisR.textures.order = keys(thisR.textures.list);
            end
            sceneR.textures.list = [sceneR.textures.list; thisR.textures.list];
            for oo=1:numel(thisR.textures.order)
                if ~any(strcmp(sceneR.textures.order, thisR.textures.order{oo}))
                    sceneR.textures.order{end + 1} = thisR.textures.order{oo};
                end
            end
        else
            sceneR.textures = thisR.textures;
        end

        if copyTextureFlag
            % Copy texture files
            % sourceDir = thisR.get('output dir');
            sourceDir = thisR.get('input dir');
            dstDir    = sceneR.get('output dir');
            sourceTextures = fullfile(sourceDir, 'textures');
            % dstTextures    = fullfile(dstDir, 'textures');
            if exist(sourceTextures, 'dir')
                piCopyFolder(sourceTextures, dstDir);
                % copyfile(sourceTextures, dstTextures);
            else
                % sprintf('No textures for (%s).\n',sourceDir)
            end
        end
        
    end

end

end



