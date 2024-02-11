function result = saveDataFiles(obj)
% find base storage folder, can leverage off prepData for DB
% version
arguments
    obj;
end

% Save as file system files
oi = obj.oi;
scene = obj.scene;
cMosaic = obj.cMosaic;

% Save as JSON for the database & in the file system
metadata = obj.metadata;
previews = obj.previews;


% Where do we want our root folder?
% right now seedling someplace
% IRL we'll put them on acorn or a public version of seedline
% or a more powerful server if needed
sampleDataRoot = 'v:\characters';
sampleDataFileType = 'MATLAB'; % could be JSON
switch sampleDataFileType
    case 'MATLAB'
        suffix = '.mat';
    case 'JSON'
        suffix = '.json';
end
try
    % can probably group these:)
    if ~isempty(oi)
        saveDataFileDir = fullfile(sampleDataRoot, 'oi');
        if ~isfolder(saveDataFileDir), mkdir(saveDataFileDir); end
        save(fullfile(saveDataFileDir,['oi_' obj.ID suffix]), 'oi');
    end
    if ~isempty(scene)
        saveDataFileDir = fullfile(sampleDataRoot, 'scene');
        if ~isfolder(saveDataFileDir), mkdir(saveDataFileDir); end
        save(fullfile(saveDataFileDir,['scene_' obj.ID suffix]), 'scene');
    end
    if ~isempty(cMosaic)
        saveDataFileDir = fullfile(sampleDataRoot, 'mosaic');
        if ~isfolder(saveDataFileDir), mkdir(saveDataFileDir); end
        save(fullfile(saveDataFileDir,['mosaic_' obj.ID suffix]), 'cMosaic');
    end
    if ~isempty(metadata)
        % Do we need to store filenames here, or can we compute?
        saveDataFileDir = fullfile(sampleDataRoot, 'metadata');
        if ~isfolder(saveDataFileDir), mkdir(saveDataFileDir); end
        jsonwrite(fullfile(saveDataFileDir,['csample_' obj.ID '.json']), metadata);
    end
    % save preview jpegs, need to conver RGB 0-1 to sRGB
    if ~isempty(previews)
        saveDataFileDir = fullfile(sampleDataRoot, 'previews');
        if ~isfolder(saveDataFileDir), mkdir(saveDataFileDir); end
        try
        imwrite(previews.scene, ...
            fullfile(saveDataFileDir,['scenePreview_' obj.ID '.jpg']));
        imwrite(previews.oi, ...
            fullfile(saveDataFileDir,['oiPreview_' obj.ID '.jpg']));
        imwrite(previews.mosaic,...
            fullfile(saveDataFileDir,['mosaicPreview_' obj.ID '.jpg']));
        catch
            warning("Unable to save previews");
        end
    end
catch
    result = -1; % something failed
    return
end
result = 0;


end

