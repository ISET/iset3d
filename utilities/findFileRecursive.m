function relativePath = findFileRecursive(startPath, targetFileName)
    % Initialize the relative path as empty
    relativePath = '';

    % List all files and folders in the current directory
    items = dir(startPath);

    % Filter out the current and parent directory entries ('.' and '..')
    items = items(~ismember({items.name}, {'.', '..'}));

    % Iterate over each item in the directory
    for k = 1:length(items)
        % If the item is a directory, recurse into it
        if items(k).isdir
            % Construct the path to the subdirectory
            subfolderPath = fullfile(startPath, items(k).name);
            % Recursively search this subdirectory
            relativePath = findFileRecursive(subfolderPath, targetFileName);

            % If the file is found in a subdirectory, break out of the loop
            if ~isempty(relativePath)
                break;
            end
        elseif strcmp(items(k).name, targetFileName)
            % If the target file is found, construct its relative path
            relativePath = fullfile(startPath, items(k).name);
            % Adjust the path to be relative by removing the initial part
            % of the path that corresponds to the search starting point
            relativePath = strrep(relativePath, [pwd, filesep], '');
            break; % Exit the loop once the file is found
        end
    end
end
