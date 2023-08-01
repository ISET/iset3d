function thisR = piTextureFileFormat(thisR)
% Convert textures in a recipe to PNG format
%
%     thisR = piTextureFileFormat(thisR)
%
% Brief description:
%   Some texture files are not in PNG format, which is required by
%   PBRT.  We convert them to PNG format here.
%
% Inputs:
%   thisR - render recipe.
%
% Outputs:
%   thisR - render recipe with updated textures.
%
%
% Note (Zhenyi): There is a weird case for me, when I use a JPG texture, the
%                PBRT runs without error, however the surface reflection
%                which used a JPG texture is missing.
%
% ZL Scien Stanford, 2022
%
% See also
%   piRead

%%
textureList = values(thisR.textures.list);

inputDir = thisR.get('input dir');

%% Textures
for ii = 1:numel(textureList)

    if ~isfield(textureList{ii},'filename')
        continue;
    end
    [path, name, ext] = fileparts(textureList{ii}.filename.value);
    texSlotName = textureList{ii}.filename.value;
    thisImgPath = fullfile(inputDir, texSlotName);

    if ~exist(thisImgPath,'file')
        % It could be the material presets
        thisImgPath = which(texSlotName);
    end

    if isempty(find(strcmp(ext, {'.png','.PNG','.exr','.jpg'}),1))
        if exist(thisImgPath, 'file')
            outputFile = fullfile(path,[name,'.png']);
            outputPath = fullfile(inputDir, outputFile);
            if ~exist(outputPath,'file')
                if isequal(ext,'.tga')
                    thisImg = tga_read_image(thisImgPath);
                else
                    thisImg = imread(thisImgPath);
                end
                imwrite(thisImg, outputPath);
            end

            % update texture slot
            if ispc
                textureList{ii}.filename.value = dockerWrapper.pathToLinux(outputFile);
            else
                textureList{ii}.filename.value = outputFile;
            end

            thisR.textures.list(textureList{ii}.name) = textureList{ii};

            fprintf('Texture: %s is converted \n',textureList{ii}.filename.value);

        else
            fprintf("Texture: %s is not available locally.\n",textureList{ii}.filename.value);
        end
    end

    % convert RGB to alpha map
    if contains(textureList{ii}.name,{'tex_'}) && ...
            exist(fullfile(inputDir, texSlotName),'file') && ...
            contains(textureList{ii}.name,{'.alphamap.'})

        outputFile = fullfile(path,[name,'_alphamap.png']);
        outputPath = fullfile(inputDir, outputFile);
        [img, ~, alphaImage] = imread(thisImgPath);

        if size(img,3)~=1 && isempty(alphaImage) && ~isempty(find(img(:,:,1) ~= img(:,:,2), 1))
            disp('No alpha texture map is available.');
            return;
        end

        % It's an alpha map, do nothing.
        if size(img,3) ==1, continue;end

        if ~isempty(alphaImage)
            imwrite(alphaImage,outputPath);
        else
            imwrite(img(:,:,1),outputPath);
        end
        if ispc
            textureList{ii}.filename.value = dockerWrapper.pathToLinux(outputFile);
        else
            textureList{ii}.filename.value = outputFile;
        end
        thisR.textures.list(textureList{ii}.name) = textureList{ii};

        fprintf('Texture: %s is converted \n',textureList{ii}.filename.value);
    end
end

%% Update materials

matKeys = keys(thisR.materials.list);

for ii = 1:numel(matKeys)
    thisMat = thisR.materials.list(matKeys{ii});

    if ~isfield(thisMat, 'normalmap') || isempty(thisMat.normalmap.value)
        % No normalmap is set.
        continue;
    end
    normalImgPath = thisMat.normalmap.value;
    thisMat.normalmap.type = 'string';
    thisImgPath = fullfile(inputDir, normalImgPath);

    if ~exist(thisImgPath,'file')
        % It could be the material presets
        thisImgPath = which(normalImgPath);
    end
    if isempty(normalImgPath)
        continue;
    end

    if exist(thisImgPath, 'file') && ~isempty(normalImgPath)

        [path, name, ext] = fileparts(dockerWrapper.pathToLinux(normalImgPath));
        if strcmp(ext, '.exr') || strcmp(ext, '.png') || strcmp(ext, '.jpg')
            % do nothing with exr
            continue;
        end

        thisImg = imread(thisImgPath);

<<<<<<< Updated upstream
        %         outputFile = fullfile(path,[sceneName,'_',name,'.png']);
=======
        % outputFile = fullfile(path,[sceneName,'_',name,'.png']);
>>>>>>> Stashed changes
        outputFile = fullfile(path,[name,'.png']);
        outputPath = fullfile(inputDir, outputFile);

        imwrite(thisImg,outputPath);
        % update texture slot
        % This is a problem if we are running on Windows and
        % rendering on Linux
        if ispc
            thisMat.normalmap.value = dockerWrapper.pathToLinux(outputFile);
        else
            thisMat.normalmap.value = outputFile;
        end
        thisR.materials.list(matKeys{ii}) = thisMat;

        fprintf('Normal Map: %s is converted \n',normalImgPath);

    else
        warning('Normal Map: %s is missing',normalImgPath);
    end

end


end
