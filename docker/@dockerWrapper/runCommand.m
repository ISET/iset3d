function [outputArg, result] = runCommand(obj)
%RUN Execute Docker command (except Render)

% Set up the output folder.  This folder will be mounted by the Docker
% image if needed. Some commands don't need one:
if ~isequal(obj.outputFile, '')
    outputFolder = fileparts(obj.outputFile);

    %if isequal(obj.command, 'pbrt')
    %    % maybe this is now de-coupled from the working folder?
    %    if(~exist(outputFolder,'dir'))
    %        error('We need an absolute path for the working folder.');
    %    end
    %    pbrtFile = obj.outputFile;
    %end
    % not sure if this is general enough?
    pbrtFile = obj.outputFile;
    [~,currName,~] = fileparts(pbrtFile);
else
    % need currName?
end
% Make sure renderings folder exists
if (isequal(obj.command,'pbrt'))
    if(~exist(fullfile(outputFolder,'renderings'),'dir'))
        mkdir(fullfile(outputFolder,'renderings'));
    end
end


builtCommand = obj.dockerCommand; % baseline
if ispc
    flags = strrep(obj.dockerFlags, '-ti ', '-i ');
    flags = strrep(flags, '-it ', '-i ');
    flags = strrep(flags, '-t', '-t ');
else
    flags = obj.dockerFlags;
end
builtCommand = [builtCommand ' ' flags];

if ~isequal(obj.dockerContainerName, '')
    builtCommand = [builtCommand obj.dockerContainerName];
end

if ~isequal(obj.workingDirectory, '')
    builtCommand = [builtCommand ' -w ' obj.pathToLinux(obj.workingDirectory)];
end
if ~isequal(obj.localVolumePath, '') && ~isequal(obj.targetVolumePath, '')
    if ispc && ~isequal(obj.dockerContainerType, 'windows')
        % need to rewrite targetVolumePath
        %folderBreak = split(obj.targetVolumePath, filesep());
        %fOut = strcat('/', [char(folderBreak(end-1)) '/' char(folderBreak(end))]);
        fOut = obj.pathToLinux(obj.targetVolumePath);
    else
        fOut = obj.targetVolumePath;
    end
    builtCommand = [builtCommand ' -v ' obj.localVolumePath ':' fOut];
end
if isequal(obj.dockerImageName, '')
    %assume running container
    builtCommand = [builtCommand ''];
else
    builtCommand = [builtCommand ' ' obj.dockerImageName];
end
if ~isequal(obj.command, '')
    % we put the redirect in the wrong place, so disable for now.
    if false; % getpref('docker','verbosity', 0) == 0 && contains(obj.command,'exr2bin')
        builtCommand = [builtCommand ' ' [obj.command ' > /dev/null']];
    else
        builtCommand = [builtCommand ' ' obj.command];
    end
end

%in cases where we don't use an of prefix then inputfile comes before
%outputfile
if ispc
    outFileName = obj.pathToLinux(obj.outputFile);
else
    outFileName = obj.outputFile;
end
if ~isequal(obj.outputFilePrefix, '')
    builtCommand = [builtCommand ' ' obj.outputFilePrefix ' ' outFileName];
    if ~isequal(obj.inputFile, '')
        if ispc
            fOut = obj.pathToLinux(obj.inputFile);
        else
            fOut = obj.inputFile;
        end
    else
        %not sure if we need this?
        folderBreak = split(obj.outputFile, filesep());
        if isequal(obj.command, 'assimp export')
            % total hack, need to decide when we need
            % folder paths
            fOut = strcat(char(folderBreak(end)));
        else
            fOut = obj.pathToLinux(obj.outputFile);
        end
    end
    builtCommand = [builtCommand ' ' fOut];
else
    if ~isequal(obj.inputFile, '')
        if ispc
            fOut = obj.pathToLinux(obj.inputFile);
        else
            fOut = obj.inputFile;
        end
        builtCommand = [builtCommand ' ' fOut];
        builtCommand = [builtCommand ' ' obj.outputFilePrefix ' ' outFileName];
    end
end


if ispc
    [outputArg, result] = system(builtCommand, '-echo');
else
    [outputArg, result] = system(buitCommand);
end

end
