classdef idocker < handle
    properties (GetAccess=public, SetAccess = public)
        % common
        name = 'ISET Docker Controls'
        device = ''
        deviceID = [];
        dockerImage = '';
        % remote
        remoteHost = '';
        remoteUser = ''
        remoteWorkDir = '';
        renderContext = ''; % control remote docker from local
        sftpSession = [];
        verbosity = 1;

        % local
        % to add, a flag is needed in init.
        % if remoteHost is empty, local is used, no further flag is needed.
    end

    methods
        function obj = idocker(varargin)
            % Constructor to initialize the remote manager
            varargin = ieParamFormat(varargin);

            p = inputParser;
            p.addParameter('preset','',@ischar);

            p.addParameter('device','', @ischar);
            p.addParameter('deviceid',[], @isnumeric);
            p.addParameter('dockerimage', '', @ischar);

            p.addParameter('remotehost','',@ischar);
            p.addParameter('remoteuser','',@ischar);
            p.addParameter('remoteworkdir', '', @ischar);
            p.addParameter('rendercontext', '', @ischar);
            p.addParameter('remotemachine','',@ischar);
            p.addParameter('verbosity',1,@isnumeric);
            
            % set user preferences
            if ~ispref('ISETDocker')
                obj.setUserPrefs();
            end

            p.parse(varargin{:});

            args = p.Results;

            if ~isempty(args.preset)
                obj.preset(args.preset);
            end

            % Check and set 'device' preference
            if ~isempty(args.device)
                obj.device = args.device; % Set from input argument
                setpref('ISETDocker', 'device', args.device); % Save to preferences
            else
                obj.device = getpref('ISETDocker', 'device'); % Retrieve from preferences
            end

            % Check and set 'deviceID' preference
            if ~isempty(args.deviceid)
                obj.deviceID = args.deviceid; % Set from input argument
                setpref('ISETDocker', 'deviceID', args.deviceid); % Save to preferences
            else
                obj.deviceID = getpref('ISETDocker', 'deviceID'); % Retrieve from preferences
            end

            % Check and set 'dockerImage' preference
            if ~isempty(args.dockerimage)
                obj.dockerImage = args.dockerimage; % Set from input argument
                setpref('ISETDocker', 'dockerImage', args.dockerimage); % Save to preferences
            else
                obj.dockerImage = getpref('ISETDocker', 'dockerImage'); % Retrieve from preferences
            end

            % Check and set 'remoteHost' preference
            if ~isempty(args.remotehost)
                obj.remoteHost = args.remotehost; % Set from input argument
                setpref('ISETDocker', 'remoteHost', args.remotehost); % Save to preferences
            else
                obj.remoteHost = getpref('ISETDocker', 'remoteHost'); % Retrieve from preferences
            end

            % Check and set 'remoteUser' preference
            if ~isempty(args.remoteuser)
                obj.remoteUser = args.remoteuser; % Set from input argument
                setpref('ISETDocker', 'remoteUser', args.remotehser); % Save to preferences
            else
                obj.remoteUser = getpref('ISETDocker', 'remoteUser'); % Retrieve from preferences
            end

            % Check and set 'remoteWorkDir' preference
            if ~isempty(args.remoteworkdir)
                obj.remoteWorkDir = args.remoteworkdir; % Set from input argument
                setpref('ISETDocker', 'remoteWorkDir', args.remoteworkdir); % Save to preferences
            else
                obj.remoteWorkDir = getpref('ISETDocker', 'remoteWorkDir'); % Retrieve from preferences
            end

            % Check and set 'renderContext' preference
            if ~isempty(args.rendercontext)
                obj.renderContext = args.rendercontext; % Set from input argument
                setpref('ISETDocker', 'renderContext', args.rendercontext); % Save to preferences
            else
                obj.renderContext = getpref('ISETDocker', 'renderContext'); % Retrieve from preferences
            end
            if ~isempty(obj.remoteHost)
                % connect the server
                obj.connect();
            else
                disp('[INFO]:Remote Host is empty, use local.')
            end
        end

        function connect(obj)
            % Establish an SFTP connection
            obj.sftpSession = sftp(obj.remoteHost, obj.remoteUser);
        end

        function disconnect(obj)
            % Disconnect the SFTP session
            close(obj.sftpSession);
        end

        % similar with rsync and filesSyncRemote
        function sync(obj, localDir, remoteWorkDir)

            % List local files
            localFiles = dir(localDir);
            try
                mkdir(obj.sftpSession,remoteWorkDir);
            catch
            end
            cd(obj.sftpSession,remoteWorkDir);
            % Iterate through each file in the local directory
            for i = 1:length(localFiles)
                fileName = localFiles(i).name;

                % Skip directories, files starting with '.' or '_'
                if ~localFiles(i).isdir && ~startsWith(fileName, '.') && ~startsWith(fileName, '_')
                    localFilePath = fullfile(localDir, fileName);
                    remoteFilePath = fullfile(remoteWorkDir, fileName);

                    % Upload the file
                    mput(obj.sftpSession, localFilePath);
                    disp(['[INFO]: Uploaded: ', localFilePath, ' to ', remoteFilePath]);
                end
            end

            disp('[INFO]: Upload complete.');
        end
        %% PBRT
        function ourContainer = startPBRT(obj, processorType)
            % Start the PBRT docker container.  Called when rendering,
            % say by piWRS() or piRender().
            %
            % See also
            %
            verbose = obj.verbosity;
            if isequal(processorType, 'GPU')
                useImage = obj.getPBRTImage('GPU');
            else
                useImage = obj.getPBRTImage('CPU');
            end
            rng('shuffle'); % make random numbers random
            uniqueid = randi(20000);
            if ispc
                uName = ['Windows' int2str(uniqueid)];
            else
                uName = [getenv('USER') int2str(uniqueid)];
            end

            if isequal(processorType, 'GPU')
                ourContainer = ['pbrt-gpu-' uName];
            else
                ourContainer = ['pbrt-cpu-' uName];
            end
            setpref('ISETDocker','PBRTContainer',ourContainer);
            % attach all
            remotePBRTResources = getpref('ISETDocker','remotePBRTResources');
            volumeMap = sprintf("-v %s:%s -v %s:%s ", ...
                hostLocalPath, containerLocalPath, ...
                isetResourceFolder, remotePBRTResources);
            placeholderCommand = 'bash';

            % We use the default context for local docker containers
            if isempty(getpref('ISETDocker','remoteHost'))
                contextFlag = ' --context default ';
            else
                contextFlag = [' --context ' getpref('ISETDocker','renderContext')];
            end

            if isequal(processorType, 'GPU')
                % want: --gpus '"device=#"'
                gpuString = sprintf(' --gpus device=%s ',num2str(obj.whichGPU));
                dCommand = sprintf('docker %s run -d -it %s --name %s  %s', contextFlag, gpuString, ourContainer, volumeMap);
            else
                dCommand = sprintf('docker %s run -d -it --name %s %s', contextFlag, ourContainer, volumeMap);
            end

            cmd = sprintf('%s %s %s', dCommand, useImage, placeholderCommand);
            
            % Test Connection to the remote docker context
            [status, result] = system(sprintf('docker %s version',contextFlag));
            if status ~= 0
                error("Failed to connect to Docker context: %s", result);
            end

            [status, result] = system(cmd);

            if status ~= 0
                error("Failed to start Docker container: %s", result);
            else
                % obj.dockerContainerID = result; % hex name for it
                if verbose > 0
                    fprintf("[INFO]: STARTED Docker successfully\n");
                    cprintf('black','CMD: %s',cmd);
                end
            end
        end


        function output = pathToLinux(inputPath)

            if ispc
                % Windows PC
                if isequal(fullfile(inputPath), inputPath)
                    % assume we have a drive letter
                    output = inputPath(3:end);
                    output = strrep(output, '\','/');
                else
                    output = strrep(inputPath, '\','/');
                end
            else
                output = inputPath;
            end
        end

    end
end
