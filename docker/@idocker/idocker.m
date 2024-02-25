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
        workDir = '';
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
            p.addParameter('workdir', '', @ischar);
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
                    disp('Error Message:')
                    disp(ME.message)
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

        % similar with rsync and filesSyncRemote
        function upload(obj, localDir, remoteDir)
            % Ensure the remote directory exists
            try
                mkdir(obj.sftpSession, remoteDir);
            catch
            end
            cd(obj.sftpSession, remoteDir);

            % List local items (files and directories)
            localItems = dir(localDir);

            % Iterate through each item in the local directory
            for i = 1:length(localItems)
                itemName = localItems(i).name;

                % Skip items starting with '.' (current and parent directory entries)
                if startsWith(itemName, '.')
                    continue;
                end

                localItemPath = fullfile(localDir, itemName);
                remoteItemPath = fullfile(remoteDir, itemName);

                if localItems(i).isdir
                    if strcmpi(itemName,'renderings')
                        continue;
                    end
                    % Item is a directory, recursively call upload for the directory
                    disp(['[INFO] Entering directory: ', localItemPath]);
                    upload(obj, localItemPath, remoteItemPath); % Recursive call
                else
                    % Item is a file, upload if it doesn't exist remotely or is modified
                    uploadFile(obj, localItems(i), localItemPath, remoteItemPath);
                end
            end

            disp('[INFO] Synchronization complete.');
        end

        function uploadFile(obj, localFile, localFilePath, remoteFilePath)
            % List remote files to check if the file exists
            [remoteDir, ~, ~] = fileparts(remoteFilePath);
            cd(obj.sftpSession, remoteDir);
            remoteFiles = dir(obj.sftpSession);
            if ~isempty(remoteFiles)
               remoteFileNames = {remoteFiles.name};
            else
                remoteFileNames = [];
            end
            

            % Check if the file exists remotely and has been modified
            if ~isempty(remoteFileNames) && ismember(localFile.name, remoteFileNames)
                % File exists remotely, check if it has been modified
                remoteFileIndex = find(strcmp(remoteFileNames, localFile.name));
                remoteFile = remoteFiles(remoteFileIndex);

                % Compare modification dates or sizes
                if localFile.datenum > remoteFile.datenum ||...
                        (localFile.datenum - remoteFile.datenum)/24/60 > 1||...
                        localFile.bytes ~= remoteFile.bytes
                    % File has been modified, upload it
                    mput(obj.sftpSession, localFilePath);
                    disp(['[INFO] Updated: ', localFilePath, ' to ', remoteFilePath]);
                end
            else
                % File does not exist remotely, upload it
                mput(obj.sftpSession, localFilePath);
                disp(['[INFO] Uploaded: ', localFilePath, ' to ', remoteFilePath]);
            end
        end


        function download(obj, remoteDir, localDir)
            % Ensure local directory exists
            if ~exist(localDir, 'dir')
                mkdir(localDir);
            end
            cd(obj.sftpSession, remoteDir);
            % List remote files and directories
            remoteItems = dir(obj.sftpSession);

            % Iterate through each item in the remote directory
            for i = 1:length(remoteItems)
                itemName = remoteItems(i).name;

                % Skip items starting with '.' (like . and ..)
                if startsWith(itemName, '.')
                    continue;
                end

                remoteItemPath = fullfile(remoteDir, itemName);
                localItemPath = fullfile(localDir, itemName);

                if remoteItems(i).isdir
                    % Item is a directory, create it locally if it doesn't exist
                    if ~exist(localItemPath, 'dir')
                        mkdir(localItemPath);
                    end
                    % Recursively download the contents of the directory
                    download(obj, remoteItemPath, localItemPath);
                else
                    % Item is a file, download it
                    % Check if local file exists and compare modification dates
                    if exist(localItemPath, 'file')
                        localFileInfo = dir(localItemPath);
                        % Download if remote file is newer or sizes differ
                        if (remoteItems(i).datenum > localFileInfo.datenum && ...
                                (remoteItems(i).datenum - localFileInfo.datenum)/24/60 > 1)||...
                                remoteItems(i).bytes ~= localFileInfo.bytes
                            cd(obj.sftpSession, remoteDir);
                            mget(obj.sftpSession, itemName, localDir);
                            disp(['[INFO]: Updated: ', remoteItemPath, ' to ', localItemPath]);
                        end
                    else
                        % Local file does not exist, download the remote file
                        cd(obj.sftpSession, remoteDir);
                        mget(obj.sftpSession, itemName, localDir);
                        disp(['[INFO]: Downloaded: ', remoteItemPath, ' to ', localItemPath]);
                    end
                end
            end

            disp('[INFO]: Synchronization complete.');
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
                if ~isempty(getpref('ISETDocker','PBRTContainer'))
                    obj.cleanup(getpref('ISETDocker','PBRTContainer'));
                end
                rmpref('ISETDocker','PBRTContainer');
            end

            % disconnect SFTP session
            obj.disconnect();
        end

        function cleanup(containerName)
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

    end
end
