function newTexture = parseBlockTexture(currentLine,thisR)

thisLine = strrep(currentLine,'[','');
thisLine = strrep(thisLine,']','');
if iscell(thisLine)
    thisLine = thisLine{1};
end
thisLine = strsplit(thisLine, {' "', '" ', '"', '  '});
switch thisLine{1}
    case 'Texture'
        textName = thisLine{2};
        form = thisLine{3};
        textType = thisLine{4};
    otherwise
        warning('Unable to resolve the texture line.')
        return
end

thisLine = cellfun(@(x) strtrim(x), thisLine, 'UniformOutput', false);
thisLine = thisLine(~cellfun(@(x) strncmp(x,'#',1),thisLine));

newTexture = piTextureCreate(textName, 'type', textType, 'format', form);

% Split the text line with ' "', '" ' and '"' to get key/val pair
thisLine = thisLine(~cellfun('isempty',thisLine));

for ss = 5:2:numel(thisLine)
    % Get parameter type and name
    keyTypeName = strsplit(thisLine{ss}, ' ');
    keyType = ieParamFormat(keyTypeName{1});
    keyName = ieParamFormat(keyTypeName{2});

    switch keyType
        case {'string','texture'}
            
            thisVal = thisLine{ss + 1};
        case {'float', 'rgb', 'color','float scale','vector3'}
            
            thisVal = str2num(thisLine{ss + 1});
        case {'integer'}
            
            thisVal = uint64(str2num(thisLine{ss + 1}));
        case {'spectrum'}
            
            [~, ~, e] = fileparts(thisLine{ss + 1});
            if isequal(e, '.spd')
                % Is a file
                thisVal = thisLine{ss + 1};
            else
                % Is vector
                thisVal = str2num(thisLine{ss + 1});
            end
            
        case 'bool'
            
            if isequal(thisLine{ss + 1}, 'true')
                thisVal = true;
            elseif isequal(thisLine{ss + 1}, 'false')
                thisVal = false;
            end
        case ''
            % Sometimes we have empty keyType and we just skip on
            continue
        otherwise
            warning('Could not resolve the parameter type: %s', keyType);
            continue;
    end

    if isequal(keyName,'filename')
        [p,n,e] = fileparts(thisVal);
        if ~isequal(p,'textures')
            % Do we have the file in textures?
            if exist(fullfile(thisR.get('input dir'),'textures',[n,e]),'file')
                thisVal = fullfile('textures',[n e]);
            elseif exist(fullfile(thisR.get('input dir'),[n,e]),'file')
                thisVal = [n e];
            else
                % handle mmp scenes with relative paths
                sceneDir = thisR.get('input dir');
                fullpath = fullfile(sceneDir,thisVal);
                if exist(fullpath,'file')
                    thisVal = fullpath;
                else
                    error('Cannot find file %s\n',thisVal);
                end
            end
        end
    end

    newTexture = piTextureSet(newTexture, sprintf('%s value', keyName),thisVal);
end

end
