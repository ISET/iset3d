function [status, result] = sceneDataStore(obj, sceneData,varargin)
%STORESCENEDDATA Create a DB document of general information for a scene
%   Work in progress for helping keep track of our scenes & related data

% Need code to ensure we have a unique name-key 

p = inputParser;

%addRequired(p, 'itemid'); % Needs to be unique across the collection
addParameter(p, 'collection','isetScenesPBRT',@ischar);
addParameter(p, 'update', false); % update existing record

varargin = ieParamFormat(varargin);
p.parse(varargin{:});

useCollection = p.Results.collection;

% Create collection if needed
try
    obj.connection.createCollection(useCollection);
catch
    % in case there already is a collection
end

% Now iterate all the pbrt files for our iset3d scenes
% and add them to the db
% with fields similar to the ones we've used for auto scenes

%{
% Sample code from storing assets:
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

% or here from Auto scene store
parfor ii = 1:numel(sceneDataFiles)
    meta = load(fullfile(sceneDataFiles(ii).folder, ...
        sceneDataFiles(ii).name)); % get sceneMeta struct
    scene = meta.scene;

    % start with scene metadata
    sceneMeta = scene.metadata;
    sceneMeta.project = "Ford";
    sceneMeta.creator = "Zhenyi Liu";
    sceneMeta.sceneSource = "Blender";
    sceneMeta.imageID = scene.name;
    sceneMeta.scenario = scenarioName;

    % maintain the lighting parameters, which currently
    % are the only items we change between experiments
    if ~isempty(scene.metadata.lightingParams)
        sceneMeta.lightingParams = scene.metadata.lightingParams;
    end

    % Update dataset folder to new layout
    sceneMeta.datasetFolder = EXRFolder;

    % Maybe try to copy over the GTObjects from the original scene
    % or leave it to a db query to find them?

    % instance and depth maps are too large as currently stored
    sceneMeta.instanceMap = [];
    sceneMeta.depthMap = [];
    threadDB = idb();
    threadDB.store(sceneMeta, 'collection', useCollection);
end


%}




end

