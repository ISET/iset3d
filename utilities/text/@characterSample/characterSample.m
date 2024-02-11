classdef characterSample < handle
    % Class to handle creation, storage, and retrieval of character data
    % samples used for the analysis of readability in 3D, VR, AR, and MR
    %
    % Currently requires ISETbio, but could easily just save ISETCam
    % objects if that's desirable
    %
    % Parameters (properties):
    %
    % Methods:
    %
    %
    % Examples:
    %
    %
    % D. Cardinal, Stanford University, 2022
    %

    properties
        %% Flesh out Metadata, much is in recipe, but is called out
        % separately to make it easier to do db searches, and in case
        % we have large recipes that won't fit in the database
        type = 'character';
        ourRecipe; % includes mapping to uc_
        character = ''; % the character being rendered
        characterMaterial = ''; % passed in or from recipe
        backgroundMaterial = ''; %passed in or from recipe
        illumination = ''; % short-hand for what's in recipe?

        % Currently these get filled in by mosaic rendering
        oi = [];
        scene = [];
        cMosaic = [];
        previews = []; 

        %To be filled with data we want saved as JSON
        metadata = [];
        % Gets filled in with at least these entries:
        % fov; % gotten from recipe
        % filmResolution = []; % gotten from recipe
        % raysPerPixel = []; % passed in or from recipe
        % recipeMetaData, mosaicMetaData, oiMetaData;

        %% Get ID
        ID = 0; % Needs to be set in constructor

        % Preview Images that are small enough to fit in DB
        sceneJPEG = [];
        oiJPEG = [];
        mosaicJPEG = [];

        % Stored Files that are too big for the database
        % keyed off foldername/ID(.mat or .json or .jpeg)
        sceneStoreFile = '';
        oiStoreFile = '';
        mosaicStoreFile = '';
    end

    methods
        function cSample = characterSample()
            %% Create a usable sample image and mosaic for


        end

        % can't call object specific functions in creation code
        function init(obj, recipe)
            obj.ourRecipe = recipe;
            obj.ID = getDataSampleID(obj, ''); % figure out a prefix
            obj.metadata.ID = obj.ID;
            obj.metadata.recipeMetaData = obj.ourRecipe.metadata;

            % some of these probably duplicate recipe.metadata
            % might not be needed unless we want them at top level

            obj.metadata.character = ''; % Need to figure out how to find
            obj.metadata.filmResolution = [obj.ourRecipe.film.xresolution.value, ...
                obj.ourRecipe.film.xresolution.value];
            obj.metadata.fov = obj.ourRecipe.camera.fov;
            obj.metadata.raysPerPixel = obj.ourRecipe.sampler.pixelsamples.value;

        end

        function  ID =  getDataSampleID(obj, prefix)

            timeStampSeparator = '__'; % keep timestamp accessible
            %prefix = ''; % this is confusing, as we have prefix for each sub-object
            % that work with their files, but do we need one for the db?

            % figure out a uniqueID that would be helpful
            % Time should be GMT (I think) although mostly it needs to help
            % with local values. I guess we could store timezone.
            % NOTE: They want us to use datetime, but I can't find an easy way
            % to get it to use milliseconds. Example code in the doc doesn't
            % work.
            timeStamp = datestr(now,'yyyy_mm_dd_HH_MM_SS_FFF'); %#ok<TNOW1,DATST>
            ID = [prefix timeStampSeparator timeStamp];

        end
        function saveCharacterSample(obj)

            [obj.scene, obj.oi, obj.cMosaic, obj.previews] = computeConeMosaic(obj);
            %obj.mosaicMetaData = obj.cMosaic.metadata;

            % We now have a recipe, an oi and/or scene, and a cone mosaic with absorbtions
            % We get both a scene and an oi if the scene has been rendered with pinhole
            % The next step is to save it for analysis
            % The mosaic and oi/scene are too large for a mongoDB data item

            % Current thought is to create a unique ID, then store the oi, scene, and
            % cone mosaic with that ID in separate folders. .mat seems okay, since it
            % is smaller than .json, and I don't know if we have other tools that need
            % .json (if the pytorch code uses it, we can switch).

            % Then save the overall metadata (including recipe) to a mongoDB item with
            % that same ID. Need to figure out what/which indices we have.

            % If we also save the metadata to a .json in the metadata folder, then it
            % will be easier to re-create the mongoDB. In fact as a first pass we might
            % want to write out all the files and then bulk import them into a db.


            %% Save oi/scene/mosaic each in their own folders
            % but file names that are "<type>___ID.mat" (unless JSON is needed/practical).

            % NEED TO ADD SAVING PREVIEWS and METADATA!

            result = saveDataFiles(obj);
            if result == 0
                % Can save in DB if desired
            else
                warning("unable to save data files");
            end

        end


    end
end



