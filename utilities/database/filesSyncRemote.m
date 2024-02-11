function filesSyncRemote(localDir, hostname, username, remoteDir)

    % List local files
    localFiles = dir(localDir);
    
    % Establish an SFTP connection
    sftpObj = sftp(hostname, username);
    try
        mkdir(sftpObj,remoteDir);
    catch
    end
    cd(sftpObj,remoteDir);
    % Iterate through each file in the local directory
    for i = 1:length(localFiles)
        fileName = localFiles(i).name;

        % Skip directories, files starting with '.' or '_'
        if ~localFiles(i).isdir && ~startsWith(fileName, '.') && ~startsWith(fileName, '_')
            localFilePath = fullfile(localDir, fileName);
            remoteFilePath = fullfile(remoteDir, fileName);

            % Upload the file
            mput(sftpObj, localFilePath);
            disp(['Uploaded: ', localFilePath, ' to ', remoteFilePath]);
        end
    end

    % Close the SFTP connection
    close(sftpObj);
    disp('Synchronization complete.');
end
