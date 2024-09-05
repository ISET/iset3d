function [recipe,referenceOBJName] = piObjectInstanceConvert(recipe)
    % convert old recipe into new recipe, mainly for day time scenes
    % --Zhenyi, 2024
    branchID = recipe.assets.getchildren(1);
    assetBranch = recipe.get('asset', branchID(1), 'subtree','false');
    branchNode = assetBranch.Node{1};
    branchNode.isObjectInstance = 1;
    if isequal(branchNode.name(5:6),'ID')
        branchNode.name = branchNode.name(8:end);
        branchNode.name = strrep(branchNode.name,'_B','_m_B');
        referenceOBJName = branchNode.name;
    end
    branchNode.scale = {branchNode.scale};
    branchNode.translation = {branchNode.translation};
    branchNode.rotation = {branchNode.rotation};
    branchNode.transorder = 'TRS';
    branchNode.referenceObject = '';
    branchNode.extraNode = [];
    branchNode.camera = [];
    recipe.assets = recipe.assets.set(branchID(1), branchNode);

    % strip IDs for objects
    objIDs = recipe.get('objects');
    for ii = 1:numel(objIDs)
        thisOBJ = recipe.assets.Node{objIDs(ii)};
        if isequal(thisOBJ.name(5:6),'ID')
            thisOBJ.name = thisOBJ.name(8:end);
            recipe.assets = recipe.assets.set(objIDs(ii), thisOBJ);
        end
    end
    recipe.assets = recipe.assets.uniqueNames;
    recipe = piObjectInstanceCreate(recipe, branchNode.name);

    %% deal with materials and textures order
    if ~isfield(recipe.materials,'order')
        recipe.materials.order = keys(recipe.materials.list);
    end
    if ~isfield(recipe.textures,'order')
        recipe.textures.order = keys(recipe.textures.list);
    end
end