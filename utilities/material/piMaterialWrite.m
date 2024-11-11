function piMaterialWrite(thisR, varargin)
% Write the contents of the _material file
%
% In addition to writing the material file, we should make sure the texture
% files are present in the output directory. As of 8/19/23, BW can't see
% where this is done any more!  Still checking.  We do this for lights, but
% apparently not for textures?  Weird.
%
% Synopsis:
%   piMaterialWrite(thisR)
%
% Brief description:
%   Write material and texture information in material pbrt file.
%
% Inputs:
%   thisR   - recipe.
%
% Outputs:
%   None
%
% Description:
%   Write the material file from PBRT
%
%   The main scene file (scene.pbrt) includes a scene_materials.pbrt
%   file.  This routine writes out the materials file from the
%   information in the recipe.
%
% ZL, SCIEN STANFORD, 2018
% ZLY, SCIEN STANFORD, 2020

%%
p = inputParser;
p.addRequired('thisR',@(x)isequal(class(x),'recipe'));
p.parse(thisR, varargin{:});

%% Create txtLines for texture struct array

if isfield(thisR.textures,'list') && ~isempty(thisR.textures.list)
    
    % textureKeys = thisR.textures.order;
    if isfield(thisR.textures,'order')
        % Added by Zheng Lyu so we can use material and texture
        % mixtures.
        textureKeys = thisR.textures.order;
    else
        % Some day this might go away, but we do not always have the
        % order field.  So, BW put this back in.
        textureKeys= keys(thisR.textures.list);
    end

    tt = 1;
    nn = 1;
    TextureTex = [];
    textureTxt = [];
    % When the texture is remote, piTextureText has the full path. 
    for ii = 1:numel(textureKeys)
        tmpTxt = piTextureText(thisR.textures.list(textureKeys{ii}), thisR);
        if piContains(tmpTxt,'texture tex')
            % This texture has a property defined by another texture
            TextureTex{tt} = tmpTxt;
            tt=tt+1;
        else
            textureTxt{nn} = tmpTxt;
            nn=nn+1;
        end
    end

    % ZLY: if special texture cases exist, append them to the end
    if numel(TextureTex) > 0
        textureTxt(nn:nn+numel(TextureTex)-1) = TextureTex;
    end
else
    textureTxt = {};
end


%% Create text lines for the material struct array

if isfield(thisR.materials, 'list') && ~isempty(thisR.materials.list)
    materialTxt = cell(1, thisR.materials.list.Count);
    matTypeList = cell(1, thisR.materials.list.Count);

    if isfield(thisR.materials,'order')
        % Added by Zheng Lyu so we can use material and texture
        % mixtures.
        materialKeys = thisR.materials.order;
    else
        % Some day this might go away, but we do not always have the
        % order field.  So, BW put this back in.
        materialKeys= keys(thisR.materials.list);
    end
    for ii=1:length(materialTxt)
        % Converts the material struct to text
        materialTxt{ii} = piMaterialText(thisR.materials.list(materialKeys{ii}), thisR);
        matTypeList{ii} = thisR.materials.list(materialKeys{ii}).type;
    end
else
    materialTxt{1} = '';
end

% check for mixture materials.
% These are two materials that are combined.
mixMatIndex = piContains(matTypeList,'mix');
mixMaterialText = materialTxt(mixMatIndex);
nonMixMaterialText = materialTxt(~mixMatIndex);

%% Write the texture and material information into scene_material.pbrt
output = thisR.get('materials output file');
fileID = fopen(output,'W');
fprintf(fileID,'# Exported by piMaterialWrite on %i/%i/%i %i:%i:%0.2f \n',clock);

if ~isempty(textureTxt)
    % Add textures
    for row=1:length(textureTxt)
        fprintf(fileID,'%s\n',textureTxt{row});
    end
end

% write out nonMix materials first
for row=1:length(nonMixMaterialText)
    fprintf(fileID,'%s\n',nonMixMaterialText{row});
end
% write out mix materials
for row=1:length(mixMaterialText)
    fprintf(fileID,'%s\n',mixMaterialText{row});
end

fclose(fileID);

% [~,n,e] = fileparts(output);

end


%% function that converts the struct to text
function val = piMediumText(medium, workDir)
% For each type of material, we have a method to write a line in the
% material file.
%

val_name = sprintf('MakeNamedMedium "%s" ',medium.name);
val = val_name;
val_string = sprintf(' "string type" "%s" ',medium.type);
val = strcat(val, val_string);

resDir = fullfile(fullfile(workDir,'spds'));
if ~exist(resDir,'dir')
    mkdir(resDir);
end

if ~isempty(medium.absFile)
    fid = fopen(fullfile(resDir,sprintf('%s_abs.spd',medium.name)),'w');
    fprintf(fid,'%s',medium.absFile);
    fclose(fid);

    val_floatindex = sprintf(' "string absFile" "spds/%s_abs.spd"',medium.name);
    val = strcat(val, val_floatindex);
end

if ~isempty(medium.vsfFile)
    fid = fopen(fullfile(resDir,sprintf('%s_vsf.spd',medium.name)),'w');
    fprintf(fid,'%s',medium.vsfFile);
    fclose(fid);

    val_floatindex = sprintf(' "string vsfFile" "spds/%s_vsf.spd"',medium.name);
    val = strcat(val, val_floatindex);
end
end

