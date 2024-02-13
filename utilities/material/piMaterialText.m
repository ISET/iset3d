function val = piMaterialText(material, thisR, varargin)
%% function that converts the struct to text
% For each type of material, we have a method to write a line in the
% material file.
%

%% Parse input
p = inputParser;
varargin = ieParamFormat(varargin);

p.addRequired('material', @isstruct);
p.addRequired('thisR', @(x)(isa(x,'recipe')));
p.addParameter('remoterender', false);

p.parse(material, thisR, varargin{:});

remoterender = p.Results.remoterender;

%% Concatatenate string
if ~strcmp(material.name, '')
    valName = sprintf('MakeNamedMaterial "%s" ',material.name);
    if isfield(material,'type')
        valType = sprintf(' "string type" [ "%s" ] ',material.type);
    elseif isfield(material,'stringtype')
        valType = sprintf(' "string type" "%s" ',material.stringtype);
    else
        error('Bad material structure. %s.', material.name)
    end

    val = strcat(valName, valType);
else
    % For material which is not named.
    val = sprintf('Material "%s" ',material.type);
end
%% For each field that is not empty, concatenate it to the text line
matParams = fieldnames(material);
for ii=1:numel(matParams)
    if ~isequal(matParams{ii}, 'name') && ...
            ~isequal(matParams{ii}, 'type') && ...
            ~isempty(material.(matParams{ii}).value)
        thisType = material.(matParams{ii}).type;
        thisVal = material.(matParams{ii}).value;

        if piContains(matParams{ii}, 'conductor')
            matParams{ii} = strcat('conductor.',strrep(matParams{ii},'conductor',''));
        end
        if piContains(matParams{ii}, 'interface')
            matParams{ii} = strcat('interface.',strrep(matParams{ii},'interface',''));
        end
        if ischar(thisVal)
            thisText = sprintf(' "%s %s" "%s" ',...
                thisType, matParams{ii}, thisVal);
        elseif isnumeric(thisVal)
            if isequal(thisType, 'photolumi')
                % Fluorescence EEM needs more precision
                thisText = sprintf(' "%s %s" [%s] ',...
                    thisType, matParams{ii}, num2str(thisVal, '%.10f '));
            else
                thisText = sprintf(' "%s %s" [%s] ',...
                    thisType, matParams{ii}, num2str(thisVal, '%.4f '));
            end
        elseif iscell(thisVal)
            thisText = sprintf(' "%s %s" [ "%s" "%s" ] ',thisType, matParams{ii}, thisVal{1}, thisVal{2});
        end

        val = strcat(val, thisText);


        if strcmp(matParams{ii},'normalmap')
            if ~remoterender

                if ~exist(fullfile(thisR.get('output dir'),thisVal),'file')
                    imgFile = which(thisVal);
                    if isempty(imgFile)||isequal(imgFile,'')
                        warning('Normal Map %s not found! Changing it to diffuse', thisVal);
                    else
                        if ispc % try to fix filename for the Linux docker container
                            imgFile = pathToLinux(imgFile);
                        end

                        thisText = strrep(thisText,thisVal, imgFile);
                        copyfile(imgFile,thisR.get('output dir'));
                    end
                end
            end
        end
    end
end
end
