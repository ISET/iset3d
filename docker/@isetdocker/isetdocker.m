classdef isetdocker < handle
    properties (GetAccess=public, SetAccess = public)
        % common
        name = 'ISET Docker Controls'
        device = ''
        deviceID = [];
        dockerImage = '';
        % remote
        remoteHost = '';
        remoteUser = ''
        workDir = '';
        renderContext = ''; % control remote docker from local
        sftpSession = [];
        verbosity = 1;

        % local
        % to add, a flag is needed in init.
        % if remoteHost is empty, local is used, no further flag is needed.
    end

    methods
        function obj = isetdocker(varargin)
            % Constructor to initialize the remote manager
            varargin = ieParamFormat(varargin);

            p = inputParser;
            p.addParameter('preset','',@ischar);

            p.addParameter('device','', @ischar);
            p.addParameter('deviceid',[], @isnumeric);
            p.addParameter('dockerimage', '', @ischar);

            p.addParameter('remotehost','',@ischar);
            p.addParameter('remoteuser','',@ischar);
            p.addParameter('workdir', '', @ischar);
            p.addParameter('rendercontext', '', @ischar);
            p.addParameter('remotemachine','',@ischar);
            p.addParameter('verbosity',1,@isnumeric);

            piDockerConfig;
            % set user preferences
            if ~ispref('ISETDocker')
                % First time through, this is called.
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

            % Check and set 'workDir' preference
            if ~isempty(args.workdir)
                obj.workDir = args.workdir; % Set from input argument
                setpref('ISETDocker', 'workDir', args.workdir); % Save to preferences
            else
                obj.workDir = getpref('ISETDocker', 'workDir'); % Retrieve from preferences
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
                try
                    mkdir(obj.sftpSession,getpref('ISETDocker', 'workDir'));
                catch ME
                    if ~contains(ME.message,"It already exists")
                        disp('Error Message:')
                        disp(ME.message)
                    end
                end
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


        function upload(obj,localDir, remoteDir, excludePattern)
            % Construct the rsync command
            rsyncCommand = "rsync -avz --progress --update";

            % Add exclusion patterns if specified
            if exist('excludePattern', 'var') && iscell(excludePattern)
                for i = 1:length(excludePattern)
                    rsyncCommand = rsyncCommand + " --exclude='" + excludePattern{i} + "'";
                end
            end

            % Ensure remote directory syntax is correct for rsync (e.g., user@host:/path)
            remoteHostPath = sprintf('%s@%s:',obj.remoteUser, obj.remoteHost);
            if ~startsWith(remoteDir, {strcat(obj.remoteUser,'@')})
                remoteDir = strcat(remoteHostPath,remoteDir);
            end

            % Finalize the rsync command with source and destination paths
            rsyncCommand = rsyncCommand + " '" + localDir + "/' '" + remoteDir + "/'";

            % Execute the rsync command
            [status, cmdout] = system(rsyncCommand);

            if status ~= 0
                error(['Rsync failed with the following message: ', cmdout]);
            else
                obj.formatAndPrint(string(cmdout));
                disp('[INFO]: Data uploaded successfully.');
            end
        end



        function download(obj,remoteDir, localDir, excludePattern)
            % Construct the rsync command
            rsyncCommand = "rsync -avz --progress";

            % Add exclusion patterns if specified
            if exist('excludePattern', 'var') && iscell(excludePattern)
                for i = 1:length(excludePattern)
                    rsyncCommand = rsyncCommand + " --exclude='" + excludePattern{i} + "'";
                end
            end

            % Ensure the local directory exists
            if ~exist(localDir, 'dir')
                mkdir(localDir);
            end

            % Ensure remote directory syntax is correct for rsync (e.g., user@host:/path)
            remoteHostPath = sprintf('%s@%s:',obj.remoteUser, obj.remoteHost);
            if ~startsWith(remoteDir, {strcat(obj.remoteUser,'@')})
                remoteDir = strcat(remoteHostPath,remoteDir);
            end

            % Finalize the rsync command with source and destination paths
            rsyncCommand = rsyncCommand + " '" + remoteDir + "/' '" + localDir + "/'";

            % Execute the rsync command
            [status, cmdout] = system(rsyncCommand);

            if status ~= 0
                error(['Rsync failed with the following message: ', cmdout]);
            else
                obj.formatAndPrint(cmdout);
                disp('[INFO]: Data downloaded successfully.');
            end
        end




        %% PBRT
        function ourContainer = startPBRT(obj)
            % Start the PBRT docker container.  Called when rendering,
            % say by piWRS() or piRender().
            %
            % See also
            %
            verbose = obj.verbosity;
            useImage = getpref('ISETDocker','dockerImage');
            rng('shuffle'); % make random numbers random
            uniqueid = randi(20000);
            if ispc
                uName = ['Windows' int2str(uniqueid)];
            else
                uName = [getenv('USER') int2str(uniqueid)];
            end

            if strcmpi(obj.device, 'gpu')
                ourContainer = ['pbrt-gpu-' uName];
            else
                ourContainer = ['pbrt-cpu-' uName];
            end
            % save container name
            setpref('ISETDocker','PBRTContainer',ourContainer);
            % attach all
            remotePBRTResources = getpref('ISETDocker','remotePBRTResources');
            workDirPBRT = getpref('ISETDocker','workDir');
            volumeMap = sprintf("-v %s:%s -v %s:%s ", ...
                workDirPBRT, workDirPBRT, ...
                remotePBRTResources, remotePBRTResources);
            placeholderCommand = 'bash';

            % We use the default context for local docker containers
            if isempty(getpref('ISETDocker','remoteHost'))
                contextFlag = ' --context default ';
            else
                contextFlag = [' --context ' getpref('ISETDocker','renderContext')];
            end

            if strcmpi(obj.device, 'gpu')
                % want: --gpus '"device=#"'
                gpuString = sprintf(' --gpus device=%s ',num2str(obj.deviceID));
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
                cprintf('red','[ERROR]: Runing Command: %s \n',cmd);
                error("[ERROR]:Failed to start Docker container: %s", result);
            else
                % obj.dockerContainerID = result; % hex name for it
                if verbose > 0
                    fprintf("[INFO]: STARTED Docker successfully\n");
                end
            end
        end
        %% reset - Resets the running Docker containers
        function reset(obj)
            iDockerPrefs = getpref('ISETDocker');
            if isfield(iDockerPrefs,'PBRTContainer')
                containerName = getpref('ISETDocker','PBRTContainer');
                if ~isempty(containerName)

                    if isempty(getpref('ISETDocker','remoteHost'))
                        contextFlag = ' --context default ';
                    else
                        contextFlag = [' --context ' getpref('ISETDocker','renderContext')];
                    end

                    % Removes the Docker container in renderContext
                    cleanupCmd = sprintf('docker %s rm -f %s', ...
                        contextFlag, containerName);
                    [status, result] = system(cleanupCmd);

                    if status == 0
                        sprintf('[INFO]: Removed container %s\n',containerName);
                    else
                        warning("[WARNING]: Failed to cleanup.\n System message:\n %s", result);
                    end
                end
                rmpref('ISETDocker','PBRTContainer');
            end

            % disconnect SFTP session
            obj.disconnect();
        end

        %% utilities
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

        function formatAndPrint(obj,cmdout)
            % Split the output into lines
            lines = strsplit(cmdout, '\n');

            % Iterate through each line and selectively display relevant information
            for i = 1:length(lines)
                line = strtrim(lines{i});

                % Display only lines that indicate transferred files or important info
                if contains(line, {'sent','bytes','bytes/sec'})
                    disp(strcat('[INFO]:',' ',strrep(line,'sent',' Sent')));
                end
            end

        end


end
end
