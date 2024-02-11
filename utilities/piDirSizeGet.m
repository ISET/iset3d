function totalSize = piDirSizeGet(remoteServer, dirPath)
    % Calculate the total size of a directory in bytes
    % Inputs:
    %   dirPath - A string or character vector specifying the directory path

    % Get a list of all files and subdirectories in the directory

    % Initialize total size
    totalSize = 0;

    if exist('remoteServer','var')
        items = dir(remoteServer,dirPath);
    else
        items = dir(dirPath);
    end
    if isempty(items), return;end
    % Filter out the '.' and '..' entries
    items = items(~ismember({items.name}, {'.', '..'}));


    % Loop over each item in the directory
    for i = 1:length(items)
        % Full path of the current item
        currentItem = fullfile(items(i).folder, items(i).name);
        
        if items(i).isdir
            % If the item is a directory, recursively calculate its size
            if exist('remoteServer','var')
                totalSize = totalSize + piDirSizeGet(remoteServer, currentItem);
            else
                totalSize = totalSize + piDirSizeGet(currentItem);
            end
        else
            % Otherwise, add the file size to the total
            totalSize = totalSize + items(i).bytes;
        end
    end
end
