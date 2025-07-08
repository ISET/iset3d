function output = pathToLinux(inputPath)

if ispc
    % Windows PC
    if isequal(fullfile(inputPath), inputPath) && ...
            ~isequal(inputPath(1:4), 'http')
        % If local we have a drive letter
        % If SDR there is no drive letter
        output = inputPath(3:end);
        output = strrep(output, '\','/');
    else
        output = strrep(inputPath, '\','/');
    end
else
    output = inputPath;
end
end