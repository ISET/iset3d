function lightSourceText = piLightWrite(thisR, varargin)
% Write a file with the lights for this recipe
%
% Synopsis
%   piLightWrite(thisR)
%
% Brief description
%  This function writes out the file containing the descriptions of the
%  scene lights for the PBRT scene. The scene_lights file is included by
%  the main scene file.
%
% Input
%   thisR - ISET3d recipe
%
% Optional key/value pairs
%   N/A
%
% Outputs
%   N/A
%
% See also
%  piWrite


%% parse inputs
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisR', @(x)isequal(class(x), 'recipe'));
p.addParameter('writefile', true);
p.parse(thisR, varargin{:});

writefile = p.Results.writefile;

%% Write out light sources one by one
lightSourceText = cell(1, numel(thisR.lights));

%% Check all applicable parameters for every light
for ii = 1:numel(thisR.lights)

    thisLight = thisR.lights{ii};

    %% Write out lightspectrum if the data is from file
    specVal = piLightGet(thisLight, 'spd val');
    if ~isempty(specVal)
        if ischar(specVal)
            [~,~,ext] = fileparts(specVal);
            if isequal(ext,'.spd')
                % User has a local file that will be copied
            else
                % Read the mat file.  Should have a mat extension.
                % This is the wavelength hardcoded in PBRT V3
                %
                % wavelength = 365:5:705;
                %
                % In Version 4 the wavelength sampling changed
                % (BW,ZhengLyu)
                wavelength = 400:10:710;
                if isequal(ext,'.mat') || isempty(ext)
                    data = ieReadSpectra(specVal, wavelength, 0);
                else
                    error('Light extension seems wrong: %s\n',ext);
                end

                % Saving the light information in the spd sub-directory
                outputDir = thisR.get('output dir');
                lightSpdDir = fullfile(outputDir, 'spds', 'lights');

                thisLightfile = fullfile(lightSpdDir,...
                    sprintf('%s.spd', ieParamFormat(specVal)));
                if ~exist(lightSpdDir, 'dir'), mkdir(lightSpdDir); end

                fid = fopen(thisLightfile, 'w');
                for jj = 1: length(data)
                    fprintf(fid, '%d %d \n', wavelength(jj), data(jj));
                end
                fclose(fid);

            end
        elseif isnumeric(specVal)
            % Numeric.  Do nothing
        else
            % Not numeric or char but not empty.  So, something wrong.
            error('Incorrect light spectrum.');
        end
    end

    %% Construct a lightsource structure

    % These are the elements common to all of the different light types.
    
    % Force the line to be a cell array
    lightSourceText{ii}.line = {'# Light'};

    % Construct the light definition line
    [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

    % Different types of lights that we know how to add.
    type = piLightGet(thisLight, 'type');

    % spectrum
    if ~isequal(type,'infinite') && isfield(thisLight,'spd')
        [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
        if ~isempty(spdTxt)
            lghtDef = strcat(lghtDef, spdTxt);
        end
    end

    % In the code below, when we set the parameter to 'pbrt text' we get
    % the string we need for the PBRT file as the second returned argument.
    switch type
        case 'point'

            % From
            [~, fromTxt] = piLightGet(thisLight, 'from val', 'pbrt text', true);
            if ~isempty(fromTxt)
                lghtDef = strcat(lghtDef, fromTxt);
            end
            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end
            
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

        case 'distant'

           % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);
            [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
            lghtDef = strcat(lghtDef, spdTxt);
            % lghtDef = sprintf('LightSource "distant" "%s L" %s', spectrumType, lightSpectrum);

            % We should understand what cameracoordinate does to the
            % from and to when we have a distant light.  The code here
            % assumes that 'from' and 'to' exists.

            % From
            [~, fromTxt] = piLightGet(thisLight, 'from val', 'pbrt text', true);
            if ~isempty(fromTxt)
                lghtDef = strcat(lghtDef, fromTxt);
            end

            % To
            [~, toTxt] = piLightGet(thisLight, 'to val', 'pbrt text', true);
            if ~isempty(toTxt)
                lghtDef = strcat(lghtDef, toTxt);
            end

            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end
            
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];


        case 'goniometric'

            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

            % spectrum
            [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
            if ~isempty(spdTxt)
                lghtDef = strcat(lghtDef, spdTxt);
            end

            % mapname
            [~, mapnameTxt] = piLightGet(thisLight, 'filename val', 'pbrt text', true);
            if ~isempty(mapnameTxt)
                lghtDef = strcat(lghtDef, mapnameTxt);
            else
                error('Goniometric lights need a filename.');
            end

            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end

            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

            % We keep the goniometric maps in the root directory for now
            fname = thisLight.filename.value;

            % First check to see if we have an instanced version
            if isfile(fullfile(thisR.get('output dir'), 'instanced', fname))
                % we haven't verified that this works for gonio lights yet
                gonioFile = fullfile(thisR.get('output dir'), 'instanced', fname);
            elseif ~isfile(fullfile(thisR.get('output dir'),'skymaps',fname))
                % Look for it in the skymaps directory
                gonioFile = fullfile(piDirGet('skymaps'),fname);                
                if isfile(gonioFile)
                    gonioDir = fullfile(thisR.get('output dir'),'skymaps');
                    if ~isfolder(gonioDir), mkdir(gonioDir); end
                    copyfile(gonioFile,gonioDir);
                    fprintf('Copying goniometric light file from skymaps directory. %s\n',gonioFile);
                else
                    warning('Could not find the goniometric light file %s\n',fname)
                end
            end

        case 'infinite'

            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

            if isempty(thisLight.filename.value)
                % No skymap.  So assign a uniform spectrum
                [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
                if ~isempty(spdTxt)
                    lghtDef = strcat(lghtDef, spdTxt);
                end
            else
                % Retrieve filename and pbrt text for thisLight, assuming 'true' specifies detailed retrieval
                % All this path stuff should be figured out before we
                % get this deep into the process.
                [mapNamePath, mapnameTxt] = piLightGet(thisLight, 'filename val', 'pbrt text', true);
                if ispref('ISETDocker','PBRTResources') && contains(mapNamePath,getpref('ISETDocker','PBRTResources'))
                    useRemoteSkymap = 1;
                else
                    useRemoteSkymap = 0;
                end
                % Define the directory path for skymaps
                skymapDir = fullfile(thisR.get('output dir'), 'skymaps');
                % Create the skymap directory if it doesn't already exist
                if ~isfolder(skymapDir), mkdir(skymapDir); end

                % Extract file parts for further use
                [~, fileName, ext] = fileparts(mapNamePath);
                mapName = [fileName, ext]; % Combine filename and extension

                % Check if the skymap file exists in the output directory
                if ~(thisR.useDB || useRemoteSkymap)
                    if exist(fullfile(thisR.get('output dir'), mapNamePath), 'file')
                        % Copy the file to skymap directory if it doesn't exist there
                        destinationFile = fullfile(skymapDir, mapName);
                        if ~exist(destinationFile, "file")
                            copyfile(fullfile(thisR.get('output dir'), mapNamePath), skymapDir);
                        end
                        % Update mapnameTxt to reflect the new location
                        mapnameTxt = sprintf(' "string filename" "skymaps/%s"', mapName);
                    else
                        % Handle case where skymap might be in a different directory and useDB flag is off
                        skymapDestination = fullfile(thisR.get('output dir'), 'skymaps', mapName);
                        if ~exist(skymapDestination, 'file')
                            % Attempt to find the skymap file in the skymaps directory
                            mapFile = fullfile(piDirGet('skymaps'), mapName);
                            if isfile(mapFile)
                                copyfile(mapFile, skymapDir);
                            else
                                error('Skymap not found: %s\n', mapFile);
                            end
                        end
                    end
                end
                
                % If the skymap is in users local scene folder, we do not
                % give the server full path to it, it might be a local
                % skymap added by the user.
          
                if ~exist(fullfile(thisR.get('output dir'),'skymaps',mapName),'file')
                    % Handle remote file path replacement for Docker preferences and database use
                    if ~isempty(getpref('ISETDocker', 'remoteHost')) && thisR.useDB && ~strncmpi(mapNamePath, '/', 1)
                        remoteFolder = fileparts(thisR.inputFile);
                        mapNameFullpath = fullfile(remoteFolder, mapNamePath);
                        mapnameTxt = strrep(mapnameTxt, mapNamePath, mapNameFullpath);
                    end
                end

                % Append the updated mapname text to the light definition
                lghtDef = strcat(lghtDef, mapnameTxt);

            end

            % nsamples
            [~, nsamplesTxt] = piLightGet(thisLight, 'nsamples val', 'pbrt text', true);
            if ~isempty(nsamplesTxt)
                lghtDef = strcat(lghtDef, nsamplesTxt);
            end

            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

        case 'projection'
            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

            % filename -- used to be mapname -- this is our projected image
            [~, filenameTxt] = piLightGet(thisLight, 'filename val', 'pbrt text', true);
            if ~isempty(filenameTxt)
                lghtDef = strcat(lghtDef, filenameTxt);
            end

            % fov
            [~, fovTxt] = piLightGet(thisLight, 'fov val', 'pbrt text', true);
            if ~isempty(fovTxt)
                lghtDef = strcat(lghtDef, fovTxt);
            end

            % power
            [~, powerTxt] = piLightGet(thisLight, 'power val', 'pbrt text', true);
            if ~isempty(powerTxt)
                lghtDef = strcat(lghtDef, powerTxt);
            end

            % scale
            [~, scaleTxt] = piLightGet(thisLight, 'scale val', 'pbrt text', true);
            if ~isempty(scaleTxt)
                lghtDef = strcat(lghtDef, scaleTxt);
            end

            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

        case {'spot', 'spotlight'}
            % Construct the light definition line
            [~, lghtDef] = piLightGet(thisLight, 'type', 'pbrt text', true);

            % spectrum
            [~, spdTxt] = piLightGet(thisLight, 'spd val', 'pbrt text', true);
            if ~isempty(spdTxt)
                lghtDef = strcat(lghtDef, spdTxt);
            end

            % If the spot light is in camera coordinate, we assume the
            % from is the camera location.  Perhaps the to is where
            % the camera is looking?  Lord help us.
            cameracoordinate = piLightGet(thisLight,'cameracoordinate');
            if ~cameracoordinate
                % From
                [~, fromTxt] = piLightGet(thisLight, 'from val', 'pbrt text', true);
                if ~isempty(fromTxt)
                    lghtDef = strcat(lghtDef, fromTxt);
                end

                % To
                [~, toTxt] = piLightGet(thisLight, 'to val', 'pbrt text', true);
                if ~isempty(toTxt)
                    lghtDef = strcat(lghtDef, toTxt);
                end
            end

            % Cone angle
            [~, coneangleTxt] = piLightGet(thisLight, 'coneangle val', 'pbrt text', true);
            if ~isempty(coneangleTxt)
                lghtDef = strcat(lghtDef, coneangleTxt);
            end

            % Cone delta angle
            [~, conedeltaangleTxt] = piLightGet(thisLight, 'conedeltaangle val', 'pbrt text', true);
            if ~isempty(conedeltaangleTxt)
                lghtDef = strcat(lghtDef, conedeltaangleTxt);
            end

            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end
            
            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

        case 'area'
            % lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];
            %
            % if thisLight.ReverseOrientation.value==true
            %     rOTxt = 'ReverseOrientation';
            %     lightSourceText{ii}.line = [lightSourceText{ii}.line rOTxt];

            % nsamples
            [~, nsamplesTxt] = piLightGet(thisLight, 'nsamples val', 'pbrt text', true);
            if ~isempty(nsamplesTxt)
                lghtDef = strcat(lghtDef, nsamplesTxt);
            end

            % scale
            [~, specscaleTxt] = piLightGet(thisLight, 'specscale val', 'pbrt text', true);
            if ~isempty(specscaleTxt)
                lghtDef = strcat(lghtDef, specscaleTxt);
            end

            % spread
            [~, spreadTxt] = piLightGet(thisLight, 'spread val', 'pbrt text', true);
            if ~isempty(spreadTxt)
                lghtDef = strcat(lghtDef, spreadTxt);
            end

            % twosided
            [~, twosidedTxt] = piLightGet(thisLight, 'twosided val', 'pbrt text', true);
            if ~isempty(twosidedTxt)
                lghtDef = strcat(lghtDef, twosidedTxt);
            end

            lightSourceText{ii}.line = [lightSourceText{ii}.line lghtDef];

            % Specify the shape            
            for nshape = 1:numel(thisLight.shape) % allow multiple shape
                if ~iscell(thisLight.shape)
                    dummylight.shape = thisLight.shape;
                else
                    dummylight.shape = thisLight.shape{nshape};
                end

                if isfield(dummylight.shape,'value')
                    [~, shpTxt] = piLightGet(dummylight, 'shape val', 'pbrt text', true);
                else
                    [~, shpTxt] = piLightGet(dummylight, 'shape struct', 'pbrt text', true);
                end
                
                lightSourceText{ii}.line = [lightSourceText{ii}.line shpTxt];
            end
    end

    % lightSourceText{ii}.line{end+1} = 'AttributeEnd';

end

if writefile
    %% Write to scene_lights.pbrt file

    % We get here when writing out a skymap.  That is relatively
    % recent, as part of the mongodb skymap management. (BW).

    % warning('Writing to scene_lights.  Not sure we ever get here.')

    [workingDir, n] = fileparts(thisR.outputFile);
    fname_lights = fullfile(workingDir, sprintf('%s_lights.pbrt', n));

    fid = fopen(fname_lights, 'w');
    fprintf(fid, '# Exported by piLightWrite on %i/%i/%i %i:%i:%0.2f \n',clock);

    for ii = 1:numel(lightSourceText)
        for jj = 1:numel(lightSourceText{ii}.line)
            fprintf(fid, '%s \n',lightSourceText{ii}.line{jj});
        end
        fprintf(fid,'\n');
    end
    fclose(fid);
end

end
