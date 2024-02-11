function result = assetStore(obj, assetFolder)
%ASSETSTORE Store pointers to folder of PBRT assets in the database
%   If available, also stores a thumbnail for previewing
%
% Example:
%
%  assetStore('v:\data\iset\isetauto\PBRT_Assets\car');
%

assetStruct = [];
assetCollectionName = 'assetsPBRT';

if ~isfolder(assetFolder)
    warning("Asset folder: %s does not exist", assetFolder);
    result = -1;
    return;
else
    % make sure we have a collection for storing PBRT assets
    try
        % use try block in case they exist and we get an error
        createCollection(obj.connection, assetCollectionName);
    catch
        %warning("Problems creating schema");
    end

    [~, assetType, ~] = fileparts(assetFolder);
    potentialAssets = dir(assetFolder);
    for ii = 1:numel(potentialAssets)
        % identify sub-folders, as these are likely assets
        if isfolder(fullfile(potentialAssets(ii).folder, ...
                potentialAssets(ii).name)) && ~isequal(potentialAssets(ii).name(1),'.')
            % we probably have an asset
            assetStruct.assetType = assetType;
            assetStruct.folder = fullfile(potentialAssets(ii).folder, ...
                potentialAssets(ii).name);
            assetStruct.name = potentialAssets(ii).name;
            if isfile(fullfile(potentialAssets(ii).folder, [potentialAssets(ii).name '.png']))
                % We could probably read in the thumbnail and store it
                % directly?
                assetStruct.thumbnail = ...
                    fullfile(potentialAssets(ii).folder, [potentialAssets(ii).name '.png']);
            else
                assetStruct.thumbnail = [];
            end
            % disp(assetStruct)
            obj.store(assetStruct,"collection",assetCollectionName);
        end
    end

end

