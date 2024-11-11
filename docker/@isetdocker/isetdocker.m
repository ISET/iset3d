classdef isetdocker < handle
    % Creates a new docker environment for remote execution.
    %
    % Isetdocker relies on parameters stored in Matlab
    %
    % getpref('ISETDocker')
    %
    % The ISETDocker parameters can be initialized, or changed, by
    % running
    %
    %   thisDocker = isetdocker;
    %   thisDocker.setUserPrefs;
    %
    % You will be asked a set of questions.  Answer them, and your
    % info Matlab prefs will be updated.    
    %
    % See also
    %  
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

            % We only need the local docker command interface, not
            % the whole docker engine.  This tests for the local
            % docker command, which is normally installed on Apple.  A
            % 0 means we are good.
            [status, result] = system('docker -v');
            assert(isequal(result(1:6),'Docker'), 'Docker engine may not be running');
            if status
                % status is not zero, so command failed. Maybe it is a
                % path issue. 
                disp('Configuring local docker path with piDockerConfig.');
                piDockerConfig;
            end

            % set user preferences
            if ~ispref('ISETDocker')
                % First time through, this is called.
                obj.setUserPrefs();
            end

            p.parse(varargin{:});

            args = p.Results;

            if ~isempty(args.preset)
                validPreset = obj.preset(args.preset);
                if validPreset == false && isequal(args.preset, 'help')
                    return; % user just wants info
                elseif validPreset == false
                    error("Invalid preset selected. Exiting.");
                end
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
                if obj.verbosity, disp('[INFO]:Remote Host is empty, use local.'); end
            end
        end

        function connect(obj)
            % Establish an SFTP connection
            try
                obj.sftpSession = sftp(obj.remoteHost, obj.remoteUser);
            catch ME
                disp(ME.message)
                error('sftp session did not succeed.')
            end
        end

        function disconnect(obj)
            % Disconnect the SFTP session
            close(obj.sftpSession);
        end


        function upload(obj,localDir, remoteDir, excludePattern)
            % Construct the rsync command
            if ispc
                rsyncCommand = "wsl rsync -avz --progress --update";
            else
                rsyncCommand = "rsync -avz --progress --update";
            end
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
            if obj.verbosity, disp('[INFO]: Uploading data:'); end
            % Execute the rsync command
            [status, cmdout] = system(rsyncCommand);

            if status ~= 0
                error(['Rsync failed with the following message: ', cmdout]);
            else
                obj.formatAndPrint(string(cmdout));
                if obj.verbosity, disp('[INFO]: Data uploaded successfully.'); end
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
            if obj.verbosity, disp('[INFO]: Downloading data:'); end
            % Execute the rsync command
            [status, cmdout] = system(rsyncCommand);

            if status ~= 0
                error(['Rsync failed with the following message: ', cmdout]);
            else
                obj.formatAndPrint(cmdout);
                if obj.verbosity, disp('[INFO]: Data downloaded successfully.'); end
            end
        end




        %% PBRT
        function ourContainer = startPBRT(obj)
            % Start the PBRT docker container.  Called when rendering,
            % say by piWRS() or piRender().
            %
            % See also
            %
            % verbose = obj.verbosity;
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

            % attach all
            
            workDirPBRT = getpref('ISETDocker','workDir');
            volumeMap = sprintf("-v %s:%s", ...
                workDirPBRT, workDirPBRT);
            if ispref('ISETDocker','PBRTResources')
                PBRTResources = getpref('ISETDocker','PBRTResources');
                volumeMap = strcat(volumeMap,sprintf(" -v %s:%s ",PBRTResources, PBRTResources));
            end
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
            elseif strcmpi(obj.device, 'cpu')
                gpuString = ' ';
            else
                gpuString = sprintf(' --gpus device=%s ',num2str(0));
            end
            dCommand = sprintf('docker %s run -d -it %s --name %s  %s', contextFlag, gpuString, ourContainer, volumeMap);

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
                if obj.verbosity, fprintf("[INFO]: STARTED Docker successfully\n"); end
            end
            % save container name
            setpref('ISETDocker','PBRTContainer',ourContainer);
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
                    if obj.verbosity, disp(strcat('[INFO]:',' ',strrep(line,'sent',' Sent'))); end
                end
            end

        end

        function [rStatus, gpuAttrs] = getGpuAttrs(obj, remoteUser, remoteHost)
            % getGpuAttrs
            % Get a vector of strings with descriptions of the GPU resources
            %
            % Synopsis
            %   [status, gpuAttrs] = getGpuAttrs(system)
            %
            %arguments (Input)
            %    string remoteMachine
            %    string remoteUser
            %end

            %arguments (Output)
            %   rStatus int32
            %   gpuAttrs() struct ???
            %end

            %  remoteMachine - a string containing the hostname of the target machine
            %  remoteUser - User name on remote system
            %
            % Outputs
            %  status - 0 means it worked well
            %  gpuAttrs - An array of strucutres of text strings describing the GPUs on "system"


            %% Build the query command
            if ~exist('remoteUser','var'), remoteUser = obj.remoteUser;end
            if ~exist('remoteHost','var'), remoteHost = obj.remoteHost;end

            rShell = 'ssh';
            remoteCommand = 'nvidia-smi --query-gpu="index","name","memory.total","driver_version" --format="csv","noheader"';
            remoteCommand = sprintf('%s %s@%s %s',rShell, remoteUser, remoteHost, remoteCommand);

            [rStatus, gpuString] = system(remoteCommand);

            if rStatus ~= 0, error(gpuString);
            end

            gpuString = splitlines(gpuString);
            gpuString = gpuString(strlength(gpuString) > 0);
            gpuString = split(gpuString,', ');

            % Should preallocate or ignore warning.
            for i=1:size(gpuString,1)
                gpuAttrs(i).id     = gpuString(i,1);
                gpuAttrs(i).name   = gpuString(i,2);
                gpuAttrs(i).mem    = gpuString(i,3);
                gpuAttrs(i).driver = gpuString(i,4);
            end

        end

    end
end
