function val = piTextureText(texture, thisR, varargin)
% Compose a text line for a texture
%
% Input:
%   texture - texture struct
%
% Outputs:
%   val     - text line to included in the _materials.pbrt file.
%
% ZLY, 2021
%
% See also
%  piMaterialText, piTextureFileFormat


%% Parse input
p = inputParser;
p.addRequired('texture', @isstruct);
p.addRequired('thisR', @(x)(isa(x,'recipe')));

p.parse(texture, thisR, varargin{:});


%% String starts with Texture name

% Name
if ~strcmp(texture.name, '')
    valName = sprintf('Texture "%s" ', texture.name);
else
    error('Bad texture structure')
end

% format
formTxt = sprintf(' "%s" ', texture.format);
val = strcat(valName, formTxt);

% type
tyTxt = sprintf(' "%s" ', texture.type);
val = strcat(val, tyTxt);

%% For each field that is not empty, concatenate it to the text line
textureParams = fieldnames(texture);

for ii=1:numel(textureParams)
    if ~isequal(textureParams{ii}, 'name') && ...
            ~isequal(textureParams{ii}, 'type') && ...
            ~isequal(textureParams{ii}, 'format') && ...
            ~isempty(texture.(textureParams{ii}).value)
        thisType = texture.(textureParams{ii}).type;
        thisVal = texture.(textureParams{ii}).value;
        
        if ischar(thisVal)
            if contains(lower(thisVal),{'true','false'}) && strcmp(thisType,'bool')
                thisText = sprintf(' "%s %s" [%s] ',...
                    thisType, textureParams{ii}, thisVal);
            else
                thisText = sprintf(' "%s %s" "%s" ',...
                    thisType, textureParams{ii}, thisVal);
            end
        elseif isnumeric(thisVal)

            if isinteger(thisType)
                thisText = sprintf(' "%s %s" [%s] ',...
                    thisType, textureParams{ii}, num2str(thisVal, '%d'));
            else
                thisText = sprintf(' "%s %s" [%s] ',...
                    thisType, textureParams{ii}, num2str(thisVal, '%.4f '));
            end
        elseif islogical(thisVal)
            if strcmp(thisType,'bool')
                if thisVal == 1
                    thisText = sprintf(' "%s %s" [true] ',...
                        thisType, textureParams{ii});
                elseif thisVal == 0
                    thisText = sprintf(' "%s %s" [false] ',...
                        thisType, textureParams{ii});
                else
                    error('Bool value can only be 0 or 1.')
                end
            end
        end

        % Deal with the case of a filename.  Make sure the file is
        % copied into the output directory.
        if isequal(textureParams{ii}, 'filename')
            oDir = thisR.get('output dir');
            oTexDir = fullfile(oDir,'textures');
            if ~exist(oTexDir,'dir'),mkdir(oTexDir);end
            % This should generally be a string or potentially
            % textures/string.  In the end, we will make this
            % textures/string and put the image file into the textures
            % sub-directory.
            [texturePath,n,e] = fileparts(thisVal);
            
            % This is a texture with absolute path, which normally means 
            % that it's not in scene root path
            texturePathTmp = 'textures';
            if ~isempty(texturePath) && exist(thisVal,'file')
                if ~exist(fullfile(oDir,'textures',[n,e]),'file')
                    fullpathTex = dir(thisVal);
                    copyfile(fullfile(fullpathTex.folder, fullpathTex.name), ...
                        fullfile(oDir,'textures'));
                end
                texturePathTmp = texturePath;
                texturePath = 'textures';
            end

            thisVal = [n,e];

            % Maybe a file named thisVal already exists. It could be
            % in the base or in textures/*.  If it does, we do not
            % need to copy it.
           
            if ~isempty(getpref('ISETDocker','remoteHost')) && thisR.useDB
                remoteSceneDir = getpref('ISETDocker','remoteSceneDir');
                texturePath = fullfile(remoteSceneDir,texturePath);
            end

            if exist(fullfile(oDir,thisVal),'file')
                % If the file is in the root of the scene, move it
                % into the 'textures' sub-directory and assign the
                % text to be textures/filename
                texturesDir = [thisR.get('output dir'),'/textures'];
                if ~exist(texturesDir,'dir'), mkdir(texturesDir); end
                movefile(fullfile(oDir,thisVal),fullfile(oDir,'textures'));
                texPathString = ['textures/',thisVal];
                if ~contains(thisText, texPathString)
                    thisText = strrep(thisText, thisVal, ['textures/',thisVal]);
                end
            elseif exist(fullfile(oDir,'textures',thisVal),'file')
                % Do nothing.  It was already in the textures
                % subdirectory.  We make sure that the string in the
                % texturePath is correct.
                if ~isequal(texturePath,'textures') 
                    % warning('Texture path in the recipe is not correct.  Adjusting.')
                    thisText = strrep(thisText, fullfile(texturePath,thisVal), ['textures/',thisVal]);
                elseif ~isequal(texturePathTmp,'textures')
                    thisText = strrep(thisText, fullfile(texturePathTmp,thisVal), ['textures/',thisVal]);
                end
            else 
                % Check whether we have it a texture file
                if ~isempty(getpref('ISETDocker','remoteHost'))&& thisR.useDB ...
                        && ~strncmpi(thisVal,'/',1)
                    % We trust that the texture will be there on the server
                    remoteFolder = fileparts(thisR.inputFile);
                    imgFile = fullfile(remoteFolder,'textures',thisVal);
                    thisText = sprintf(' "%s %s" "%s" ',...
                        thisType, textureParams{ii}, imgFile);
                else
                    imgFile = piResourceFind('texture',thisVal);
                    if isempty(imgFile)
                        imgFile = findFileRecursive(oDir, thisVal);
                    end
                end
                % At this point, either we have imgFile or it is empty.
                if isempty(imgFile)
                    
                    thisText = '';
                    val = strrep(val,'imagemap', 'constant');
                    val = strcat(val, ' "rgb value" [0.7 0.7 0.7]');
                    warning('Texture %s not found! Changing it to diffuse', thisVal);
                    texture.invert.value = [];
                else
                    if ispc % try to fix filename for the Linux docker container
                        imgFile = pathToLinux(imgFile);
                    end

                    if isempty(texturePath) 
                        thisText = strrep(thisText, imgFile, ['textures/',thisVal]);
                    end

                    if isempty(getpref('ISETDocker','remoteHost'))
                        texturesDir = [thisR.get('output dir'),'/textures'];
                        if ~exist(texturesDir,'dir'), mkdir(texturesDir); end
                        copyfile(imgFile,texturesDir);
                    end
                end
            end
            
        end
        val = strcat(val, thisText);
    end
end

end
