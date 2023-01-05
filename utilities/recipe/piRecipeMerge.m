function sceneR = piRecipeMerge(sceneR, objectRs, varargin)
% Add multiple object recipes into a base scene recipe
%
% Synopsis:
%   sceneR = piRecipeMerge(sceneR, objects, varargin)
%
% Brief description:
%   Merges two recipes (material, texture, assets) into one.
%
% Inputs:
%   sceneR    - scene recipe
%   objectRs  - a single object recipe or a cell array of object recipes
%
% Optional key/val pairs
%   material  -  The user can decide to NOT add materials.  Default is true
%                meaning (add)
%   texture   -  Same as material
%   asset     -  Same as material
%   node name -  Top node of the subtree. Default is the node with id = 2.
%   object instance - Add object as an object instance, then we 
%                can reuse(instance) it by function piObjectInstanceCreate.
%
% Returns:
%   sceneR   - scene recipe with added objects
%
% See also
%   piAssetLoad, piAssetList

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
p.addParameter('nodename', '', @ischar);  % Name of the top node in the subtree
p.addParameter('copyfiles', 1 , @islogical);

p.parse(sceneR, objectRs, varargin{:});

sceneR         = p.Results.sceneR;
materialFlag   = p.Results.material;
textureFlag    = p.Results.texture;
assetFlag      = p.Results.asset;
objectInstance = p.Results.objectinstance;
nodeName       = p.Results.nodename;
copyFiles      = p.Results.copyfiles;
copyTextureFlag = 1;
%%  The objects can be a cell or a recipe

if ~iscell(objectRs)
    % Make it a cell
    recipelist{1} = objectRs;
else
    % A cell array of recipes
    recipelist = objectRs;
end

%% For each object recipe, add the object to the main scene

for ii = 1:length(recipelist)
    thisR = recipelist{ii};

    if assetFlag

        if isempty(sceneR.assets)
            % Main scene has no assets.  Add in the assets from the object.
            % Then we also have to set the nodeName for the return.
            sceneR.assets = thisR.assets;
        else
            if isempty(nodeName)
                % Get the asset names in the object
                % The problem with this is we don't get the geometry node above
                % it.
                %   names = thisR.get('assetnames');
                %   nodeName = names{2};

            end
            children = thisR.assets.getchildren(1);
            % Get the subtree starting just below the specified node
            % thisOBJsubtree = thisR.get('asset', nodeName, 'subtree');

            % Graft the asset three into the scene.  We graft it onto the root
            % of the main scene.
            % Changed to root_B on Jan 23, 2022.  Worried (BW).
            % The new field 'isObjectInstancer' broke reading in one of the
            % assets.  I do not understand that field from its name; the
            % comment below has me confused, so I will ask Zhenyi about it.
            % For the moment merging some assets (like the bunny) does not
            % work. (BW)
            for nChild = 1:numel(children)
                thisNodeTree = thisR.get('asset', children(nChild), 'subtree');
                [~,thisNode] = piAssetFind(thisR.assets, 'asset',children(nChild));
                if objectInstance && isfield(thisNode{1},'isObjectInstance')
                    if thisNode{1}.isObjectInstance == 1
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
                    sceneR = sceneR.set('asset', 1, 'graft', thisNodeTree);
                end
            end
        end
        
        if copyFiles
            % Copy meshes from objects folder to scene folder here
            sourceDir = thisR.get('input dir');
            dstDir    = sceneR.get('output dir');

            % Copy the assets from source to destination
            sourceAssets_v1 = fullfile(sourceDir, 'scene/PBRT/pbrt-geometry');
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



