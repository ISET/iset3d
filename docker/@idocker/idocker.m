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

            % set user preferences
            if ~ispref('ISETDockerPrefs')
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
                setpref('ISETDockerPrefs', 'device', args.device); % Save to preferences
            else
                obj.device = getpref('ISETDockerPrefs', 'device'); % Retrieve from preferences
            end

            % Check and set 'deviceID' preference
            if ~isempty(args.deviceid)
                obj.deviceID = args.deviceid; % Set from input argument
                setpref('ISETDockerPrefs', 'deviceID', args.deviceid); % Save to preferences
            else
                obj.deviceID = getpref('ISETDockerPrefs', 'deviceID'); % Retrieve from preferences
            end

            % Check and set 'dockerImage' preference
            if ~isempty(args.dockerimage)
                obj.dockerImage = args.dockerimage; % Set from input argument
                setpref('ISETDockerPrefs', 'dockerImage', args.dockerimage); % Save to preferences
            else
                obj.dockerImage = getpref('ISETDockerPrefs', 'dockerImage'); % Retrieve from preferences
            end

            % Check and set 'remoteHost' preference
            if ~isempty(args.remotehost)
                obj.remoteHost = args.remotehost; % Set from input argument
                setpref('ISETDockerPrefs', 'remoteHost', args.remotehost); % Save to preferences
            else
                obj.remoteHost = getpref('ISETDockerPrefs', 'remoteHost'); % Retrieve from preferences
            end

            % Check and set 'remoteUser' preference
            if ~isempty(args.remoteuser)
                obj.remoteUser = args.remoteuser; % Set from input argument
                setpref('ISETDockerPrefs', 'remoteUser', args.remotehser); % Save to preferences
            else
                obj.remoteUser = getpref('ISETDockerPrefs', 'remoteUser'); % Retrieve from preferences
            end

            % Check and set 'remoteWorkDir' preference
            if ~isempty(args.remoteworkdir)
                obj.remoteWorkDir = args.remoteworkdir; % Set from input argument
                setpref('ISETDockerPrefs', 'remoteWorkDir', args.remoteworkdir); % Save to preferences
            else
                obj.remoteWorkDir = getpref('ISETDockerPrefs', 'remoteWorkDir'); % Retrieve from preferences
            end

            % Check and set 'renderContext' preference
            if ~isempty(args.rendercontext)
                obj.renderContext = args.rendercontext; % Set from input argument
                setpref('ISETDockerPrefs', 'renderContext', args.rendercontext); % Save to preferences
            else
                obj.renderContext = getpref('ISETDockerPrefs', 'renderContext'); % Retrieve from preferences
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
    end
end
