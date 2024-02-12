classdef dw < handle
    properties
        % common
        device
        dockerImage
        % remote
        remoteHost
        remoteUser
        remoteWorkDir
        remoteContext
        sftpSession
        
        % local
        % to add, a flag is needed in init.
    end

    methods
        function obj = dw(remoteHost, remoteUser, remoteWorkDir)
            % Constructor to initialize the remote manager
            obj.remoteHost = remoteHost;
            obj.remoteUser = remoteUser;
            obj.remoteWorkDir = remoteWorkDir;
            obj.remoteContext = remoteContext;
            obj.device = device; % gpu or cpu
            obj.dockerImage = dockerImage;
        end

        function connect(obj)
            % Establish an SFTP connection 
            obj.sftpSession = sftp(obj.remoteHost, obj.remoteUser);
        end

        function disconnect(obj)
            % Disconnect the SFTP session
            close(obj.sftpSession);
        end

        function upload(obj, localDir, remoteWorkDir)

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
                    disp(['Uploaded: ', localFilePath, ' to ', remoteFilePath]);
                end
            end

            disp('Upload complete.');
        end

        function output = runDockerCommand(obj, command)
            % Run a Docker command remotely using Docker context
            dockerCmd = ['docker ' command];
            [status, cmdout] = system(dockerCmd);
            if status == 0
                disp('Docker command executed successfully.');
                output = cmdout;
            else
                disp('Error executing Docker command.');
                output = '';
            end
        end
    end
end
