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

% remote should be passed in to us if needed
p.addParameter('remoteRender', false);

p.parse(texture, thisR, varargin{:});

remoteRender = p.Results.remoteRender;

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
            thisText = sprintf(' "%s %s" "%s" ',...
                thisType, textureParams{ii}, thisVal);
        elseif isnumeric(thisVal)
            if isinteger(thisType)
                thisText = sprintf(' "%s %s" [%s] ',...
                    thisType, textureParams{ii}, num2str(thisVal, '%d'));
            else
                thisText = sprintf(' "%s %s" [%s] ',...
                    thisType, textureParams{ii}, num2str(thisVal, '%.4f '));
            end
        end


        % Deal with the case of a filename.  Make sure the file is
        % copied into the output directory.
        if isequal(textureParams{ii}, 'filename')

            % This should generally be a string or potentially
            % textures/string.  In the end, we will make this
            % textures/string and put the image file into the textures
            % sub-directory.
            [texturePath,n,e] = fileparts(thisVal);
            thisVal = [n,e];

            % Maybe a file named thisVal already exists. It could be
            % in the base or in textures/*.  If it does, we do not
            % need to copy it.
            oDir = thisR.get('output dir');

            if remoteRender
                remoteWorkDir = getpref('ISETDockerPrefs','remoteWorkDir');
                texturePath = fullfile(remoteWorkDir,texturePath);  
            end
            if exist(fullfile(oDir,thisVal),'file')
                % If the file is in the root of the scene, move it
                % into the 'textures' sub-directory and assign the
                % text to be textures/filename
                texturesDir = [thisR.get('output dir'),'/textures'];
                if ~exist(texturesDir,'dir'), mkdir(texturesDir); end
                movefile(fullfile(oDir,thisVal),fullfile(oDir,'textures'));
                thisText = strrep(thisText, thisVal, ['textures/',thisVal]);
            elseif exist(fullfile(oDir,'textures',thisVal),'file')
                % Do nothing.  It was already in the textures
                % subdirectory.  We make sure that the string in the
                % texturePath is correct.
                if ~isequal(texturePath,'textures')
                    % warning('Texture path in the recipe is not correct.  Adjusting.')
                    thisText = strrep(thisText, fullfile(texturePath,thisVal), ['textures/',thisVal]);
                end

            else 
                % So we have the case
                %    ~exist(fullfile(oDir,'textures',thisVal),'file')
                %
                % The file was not found either in the base directory
                % or in the textures directory. So we locate it and
                % copy it.

                % PBRT V4 files from Matt had references to
                % ../landscape/mumble ... For the barcelona-pavillion
                % I copied the files.  But this may happen again.
                % Very annoying that one scene refers to textures and
                % geometry from a completely different scene.  This is
                % a hack, but probably I should fix the original scene
                % directories. I am worried how often this happens. (BW)

                % Check whether we have it a texture file
                if remoteRender
                    % We trust that the texture will be there on the server
                    remoteWorkDir = getpref('ISETDockerPrefs','remoteWorkDir');
                    imgFile = fullfile(remoteWorkDir,'textures',thisVal);
                else
                    imgFile = piResourceFind('texture',thisVal);
                end
                % At this point, either we have imgFile or it is empty.
                if isempty(imgFile) 
                    thisText = '';
                    val = strrep(val,'imagemap', 'constant');
                    val = strcat(val, ' "rgb value" [0.7 0.7 0.7]');
                    warning('Texture %s not found! Changing it to diffuse', thisVal);
                else
                    if ispc % try to fix filename for the Linux docker container
                        imgFile = pathToLinux(imgFile);
                    end

                    if isempty(texturePath) || isequal('/',texturePath(1))
                        % Replaced this text Jan 4 2023 (BW)
                        % thisText = strrep(thisText, thisVal, ['textures/',thisVal]);
                        thisText = strrep(thisText, imgFile, ['textures/',thisVal]);
                    end

                    if ~remoteRender
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

%                     end
%
%                 % If the texture file is in the imageTextures
%                 % directory, we are good.  If it is not, then we do
%                 % this.
%                     % Do we have the file in textures?
%                     thisVal = fullfile(thisR.get('output dir'),'textures',[n,e]);
%                     if exist(thisVal,'file')
%                         imgFile = thisVal;
%                         warning('Texture file found, but not in specified directory.');
%                     else
%                         % impatient "fix" by DJC
%                         imgFile = which([n e]);
%                         % force it
%                     end