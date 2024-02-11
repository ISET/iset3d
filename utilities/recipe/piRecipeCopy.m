function newR = piRecipeCopy(thisR)
newR  = recipe;
params = fieldnames(thisR);
for ii = 1:numel(params)

    switch params{ii}
        case 'materials'
            newR.(params{ii}) = thisR.(params{ii});
            if ~isempty(thisR.materials.list.keys)
                newR.materials.list = containers.Map(thisR.materials.list.keys, thisR.materials.list.values);
            end
        case 'textures'
            newR.(params{ii}) = thisR.(params{ii});
            if ~isempty(thisR.textures.list.keys)
                newR.textures.list = containers.Map(thisR.textures.list.keys, thisR.textures.list.values);
            end
        case 'assets'
            if ~isempty(thisR.assets)
                newR.assets = tree(thisR.assets);
                newR.assets = newR.assets.uniqueNames;
            end
        otherwise
            newR.(params{ii}) = thisR.(params{ii});
    end
end
end