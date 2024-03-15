function [materialMap, textureMap, txtLines, matNameList, texNameList] = parseMaterialTexture(thisR)
% Parse the txtLines to specify the materials and textures
%
% Synopsis
%   [materialMap, textureMap, txtLines, matNameList, texNameList] = parseMaterialTexture(thisR)
%
% Input
%   txtLines - Usually thisR.world text
%
% Outputs
%   materialMap - The material key-value pairs map (containers.Map)
%   textureMap  - The texture key-value pairs map  (containers.Map)
%   txtLines    -  The txtLines that are NOT material or textures
%   matNameList - MaterialName list (order is important for mixed material and textures!!)
%   texNameList - TextureName list (order is important for mixed material and textures!!)
%
% ZL and ZYL
%
% See also
%   piRead, parseBlockMaterial

%% Initialize the parameters we return

txtLines = thisR.world;
textureList    = [];
materialList  = [];
texNameList = {};
matNameList = {};

% Counters for the textures and materials
t_index = 0;
m_index = 0;
% map for textures and materials
textureMap  = containers.Map;
materialMap = containers.Map;
%% Loop over each line
for ii = numel(txtLines):-1:1
    % From the end to the beginning so we don't screw up line ordering.

    % Parse this line now
    thisLine = txtLines{ii};

    if strncmp(thisLine,'Texture',length('Texture'))
        % Assign the textureMap container
        %
        %     textureMap(textureName) = textureStruct;
        %
        t_index = t_index+1;
        
        textureList{t_index}   = parseBlockTexture(thisLine,thisR);  
        % textureMap(textureList{t_index}.name) = textureList{t_index};
        % texNameList{t_index} = textureList{t_index}.name;
        % Avoid duplicated material definition
        if ~isKey(textureMap, textureList{t_index}.name)
            textureMap(textureList{t_index}.name) = textureList{t_index};
            texNameList{t_index} = textureList{t_index}.name;
        else
            t_index = t_index - 1;
        end
    elseif strncmp(thisLine,'MakeNamedMaterial',length('MakeNamedMaterial')) ||...
            strncmp(thisLine,'Material',length('Material'))
        % Assign the materialMap container
        %
        %   materialMap(matName) = materialStruct;
        %
        m_index = m_index+1;
        thisMat = parseBlockMaterial(thisLine);
        if ~isempty(thisMat)
            materialList{m_index}  = thisMat;
        else
            m_index = m_index-1;
        end
        if isempty(materialList{m_index}), return; end
        % Avoid dubplicated material definition
        if ~isKey(materialMap, materialList{m_index}.name)
            materialMap(materialList{m_index}.name) = materialList{m_index};
            matNameList{m_index} = materialList{m_index}.name;
        else
            m_index = max(m_index - 1, 0);
        end
    elseif strncmp(thisLine, 'NamedMaterial', length('NamedMaterial'))
        % We have removed ' ' with '_' in materials, so do the same thing
        % with NamedMaterial for assets.
        % Substitute the spaces in material name with _
        dQuotePos = strfind(thisLine, '"');
        thisLine(dQuotePos(1):dQuotePos(2)) = strrep(thisLine(dQuotePos(1):dQuotePos(2)), ' ', '_');
    end
    txtLines{ii} = thisLine;
end

% Flip the order because we parse the material and texture from back to
% front.
matNameList = flip(matNameList);
texNameList = flip(texNameList);

end
