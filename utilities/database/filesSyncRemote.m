function filesSyncRemote(sftpObj, localDir,  remoteDir, varargin)
% Synchronize a folder with a remote folder
%
% Synopsis
%
% Inputs
%
%

% another version of dw.upload, if only upload is needed.
% List local files
localFiles = dir(localDir);

% Establish an SFTP connection and point the sftp into the remote
% directory.
try
    mkdir(sftpObj,remoteDir);
catch
end
cd(sftpObj,remoteDir);

%% List remote files.
remoteFiles = dir(sftpObj, remoteDir);
if isempty(remoteFiles)
    % If it is a new directory we just made, this will be empty.
    remoteFileNames = '';
else
    % Otherwise we will be overwriting these files.
    remoteFileNames = {remoteFiles.name};
end

% Iterate through each file in the local directory
for i = 1:length(localFiles)
    fileName = localFiles(i).name;

    % Skip directories, files starting with '.' or '_'
    if ~localFiles(i).isdir && ~startsWith(fileName, '.') && ~startsWith(fileName, '_')
        localFilePath = fullfile(localDir, fileName);

        % Check if the file exists remotely and has been modified
        if ismember(fileName, remoteFileNames)
            % File exists remotely, check if it has been modified
            remoteFileIndex = find(strcmp(remoteFileNames, fileName));
            remoteFile = remoteFiles(remoteFileIndex);

            % Compare modification dates or sizes (local file info is in localFiles(i))
            if localFiles(i).datenum > remoteFile.datenum || localFiles(i).bytes ~= remoteFile.bytes
                % File has been modified, upload it
                mput(sftpObj, localFilePath);
                disp(['[INFO] Updated: ', localFilePath, ' to ', remoteDir]);
            end
        else
            % File does not exist remotely, upload it
            mput(sftpObj, localFilePath);
            disp(['[INFO] Uploaded: ', localFilePath, ' to ', remoteDir]);
        end
    end
end

% Close the SFTP connection
% close(sftpObj);

disp('Synchronization complete. sftp still open.');

end
