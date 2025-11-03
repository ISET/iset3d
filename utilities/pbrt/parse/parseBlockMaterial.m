function newMat = parseBlockMaterial(currentLine)
% Parse a line in a scene pbrt file to interpret the material
%
% See also
%

%
thisLine = strrep(currentLine,'[','');
thisLine = strrep(thisLine,']','');
if iscell(thisLine)
    thisLine = thisLine{1};
end

% Substitute the spaces in material name with _
% dQuotePos = strfind(thisLine, '"');
% thisLine(dQuotePos(1):dQuotePos(2)) = strrep(thisLine(dQuotePos(1):dQuotePos(2)), ' ', '-');

% Continue processing
dQuotePos = strfind(thisLine, '"');
tmpLine = strsplit(thisLine,{' "', '" ', '"', '  '});
switch tmpLine{1}
    case 'Material'
        matName = '';
        matType = tmpLine{2};
    case 'MakeNamedMaterial'
        % Substitute the spaces in material name with _
        thisLine(dQuotePos(1):dQuotePos(2)) = strrep(thisLine(dQuotePos(1):dQuotePos(2)), ' ', '_');
        matName = thisLine(dQuotePos(1):dQuotePos(2));
        matName = erase(matName,'"');
        matType = piParameterGet(currentLine,'string type');
end
% thisLine = strsplit(thisLine, {' "', '" ', '"', '  '});
thisLine = strsplit(thisLine(dQuotePos(2):end), {'" "','"'});

if ~isempty(matType)
    newMat = piMaterialCreate(matName, 'type', matType);
else
    newMat = [];
    return;
end
% Split the text line with ' "', '" ' and '"' to get key/val pair

% trim each token + remove empty/whitespace-only cells
thisLine = cellfun(@strtrim, thisLine, 'uni', false);
thisLine = thisLine(~cellfun(@(s) isempty(s) || all(isspace(s)), thisLine));

% deal with mix material
stringTypeIndex = find(contains(thisLine, 'string type'));
if ~isempty(stringTypeIndex)
    if strcmp(thisLine{stringTypeIndex+1},'mix')
        % only deal with two mixed materials here.
        % https://pbrt.org/fileformat-v4#shapes
        index = find(contains(thisLine, 'string materials'));
        
        if isempty(index)
            error('String Materials are not defined!');
        end
        mat1 = strrep(thisLine{index+1}, ' ', '_');
        mat2 = strrep(thisLine{index+2}, ' ', '_');

        mixMaterials = {mat1,mat2};
        thisLine{index+1}=mixMaterials;
        thisLine{index+2}=[];
        thisLine = thisLine(~cellfun('isempty', thisLine));
    end
end

isOnlySpaces = cellfun(@(x) all(isspace(x)), thisLine);
thisLine = thisLine(~isOnlySpaces);

% For strings 3 to the end, parse
for ss = 1:2:numel(thisLine)-1
    % Get parameter type and name
    keyTypeName = strsplit(thisLine{ss}, ' ');
    keyType = ieParamFormat(keyTypeName{1});
    keyName = ieParamFormat(keyTypeName{2});

    if piContains(keyName,'.')
        keyName = strrep(keyName,'.','');
    end

    % Some corner cases
    % "index" should be replaced with "eta"
    switch keyName
        case 'index'
            keyName = 'eta';
    end

    switch keyType
        case {'string', 'texture'}
              % handling mix materials   
             thisVal = thisLine{ss+1};

        case {'float', 'rgb', 'color', 'photolumi'}
            % Parse a float number from string
            % str2num can convert string to vector. str2double can't.
            thisVal = str2num(thisLine{ss + 1});
        case {'spectrum'}
            [~, ~, e] = fileparts(thisLine{ss + 1});
            if isequal(e, '.spd') || isempty(str2num(thisLine{ss + 1}))
                % Is a file
                thisVal = thisLine{ss + 1};
            else
                % Is vector
                thisVal = str2num(thisLine{ss + 1});
            end
        case 'bool'
            if isequal(strrep(thisLine{ss + 1},' ',''), 'true')
                thisVal = true;
            elseif isequal(strrep(thisLine{ss + 1},' ',''), 'false')
                thisVal = false;
            end
        case ''
            continue
        otherwise
            warning('Could not resolve the parameter type: %s', keyType);
            continue;
    end

    newMat = piMaterialSet(newMat, sprintf('%s value', keyName),...
        thisVal);

end
end
