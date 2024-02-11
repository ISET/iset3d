function piTexturePrint(thisR)
% List texture names in recipe to the command window
%
% Synopsis
%   piTexturePrint(thisR)
%
% Description
%   Summarize the texture properties. Needs more work.
%
% Inputs:
%   thisR   - recipe
%
% Outputs:
%   None
%
% See also
%   recipe.show
%
%%

textureNames = thisR.get('texture', 'names');
fprintf('\n--- Texture names ---\n');
if isempty(textureNames)
    disp('No textures')
    return;
else
    nTextures = numel(textureNames);
    rows      = cell(nTextures,1);     
    names = rows; format = rows; types = rows; filenames = rows;
    for ii =1:numel(textureNames)
        rows{ii, :}  = num2str(ii);
        names{ii,:}  = textureNames{ii};
        thisTexture = thisR.textures.list(textureNames{ii});
        format{ii,:}    = thisTexture.format;
        types{ii,:}     = thisTexture.type;
        if isfield(thisTexture,'filename')
            filenames{ii,:} = thisTexture.filename.value;
        else
            filenames{ii,:} = '(no file)';
        end
    end
    T = table(categorical(names), categorical(format),categorical(types),categorical(filenames),'VariableNames',{'names','format', 'types','file'}, 'RowNames',rows);
    % T = table(categorical(names), categorical(format),categorical(types),'VariableNames',{'names','format', 'types'}, 'RowNames',rows);
    disp(T);
end
fprintf('---------------------\n');

end
