function piMediaWrite(thisR)
% Write the material file from PBRT V4, as input from Cinema 4D
%
% The main scene file (scene.pbrt) includes a scene_materials.pbrt
% file.  This routine writes out the materials file from the
% information in the recipe.
%
% HB, SCIEN STANFORD, 2020

%%
p = inputParser;
p.addRequired('thisR',@(x)isequal(class(x),'recipe'));
p.parse(thisR);


%% Create txtLines for the material struct array
if isfield(thisR.media, 'list') && ~isempty(thisR.media.list)
    mediaTxt = cell(1, thisR.media.list.Count);
    mediaTypeList = cell(1, thisR.media.list.Count);

    mediaKeys = keys(thisR.media.list);
        
    for ii=1:length(mediaTxt)
        % Converts the material struct to text
        mediaTxt{ii} = piMediumText(thisR.media.list(mediaKeys{ii}));
        mediaTypeList{ii} = thisR.media.list(mediaKeys{ii}).type;
    end
else
    mediaTxt{1} = '';
end

%% Write the texture and material information into scene_material.pbrt
output = thisR.get('media output file');
fileID = fopen(output,'w');
fprintf(fileID,'# Exported by piMediaWrite on %i/%i/%i %i:%i:%0.2f \n',clock);

for row=1:length(mediaTxt)
    fprintf(fileID,'%s\n',mediaTxt{row});
end


fclose(fileID);

end


%% function that converts the struct to text
function val = piMediumText(medium, varargin)
%% function that converts the struct to text
% For each type of material, we have a method to write a line in the
% material file.
%

%% Parse input
p = inputParser;
p.addRequired('medium', @isstruct);

p.parse(medium, varargin{:});

%% Concatatenate string
if ~strcmp(medium.name, '')
    valName = sprintf('MakeNamedMedium "%s" ',medium.name);
    if isfield(medium,'type')
        valType = sprintf(' "string type" [ "%s" ] ',medium.type);
    else
        error('Bad medium structure. %s.', medium.name)
    end

    val = strcat(valName, valType);
else
    % For material which is not named.
    val = sprintf('Medium "%s" ',medium.type);
end

%% For each field that is not empty, concatenate it to the text line
matParams = fieldnames(medium);
for ii=1:numel(matParams)
    if ~isequal(matParams{ii}, 'name') && ...
            ~isequal(matParams{ii}, 'type') && ...
            ~isempty(medium.(matParams{ii}).value)
        thisType = medium.(matParams{ii}).type;
        thisVal = medium.(matParams{ii}).value;

        
        if ischar(thisVal)
            thisText = sprintf(' "%s %s" "%s" ',...
                thisType, matParams{ii}, thisVal);
        elseif isnumeric(thisVal)
            
                thisText = sprintf(' "%s %s" [%s] ',...
                    thisType, matParams{ii}, num2str(thisVal, '%.4f '));
            
        elseif iscell(thisVal)
            thisText = sprintf(' "%s %s" [ "%s" "%s" ] ',thisType, matParams{ii}, thisVal{1}, thisVal{2});
        end

        val = strcat(val, thisText);
    end
end
end
