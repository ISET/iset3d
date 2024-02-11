function [status, result] = render(obj, renderCommand, outputFolder, varargin)
% Render radiance and depth using the dockerWrapper method
%
% Synopsis
%   [status, result] = render(obj, renderCommand, outputFolder)
%
% Inputs
%  obj - a dockerWrapper
%  renderCommand - the PBRT command for rendering
%  outputFolder  - the output for the rendered data
%
% Outputs
%  status - 0 means it worked well
%  result - Stdout text returned here
%
% Notes:
%   DJC: Currently we have an issue where GPU rendering ignores
%   objects that have ActiveTranforms. Maybe scan for those & set
%   container back to CPU (perhaps ideally a beefy, remote, CPU).
%
% See also
%  piRender, sceneEye.render

p = inputParser();

addParameter(p, 'denoiseflag', false, @islogical);
addParameter(p, 'rendertype',[]);

% Okay to get params we don't understand
p.KeepUnmatched = true;

p.parse(varargin{:});

denoiseFlag = p.Results.denoiseflag;
renderType  = p.Results.rendertype;

%% Build up the render command

% How chatty to the stdout
verbose = obj.verbosity; % 0, 1, 2

% Determine the container
if obj.gpuRendering
    useContainer = obj.getContainer('PBRT-GPU');
    if ~strcmp(renderType,'instance')
        renderCommand = strrep(renderCommand, 'pbrt ', 'pbrt --gpu ');
    end
else
    useContainer = obj.getContainer('PBRT-CPU');
end

%% Windows doesn't seem to like the t flag
if ispc,     flags = '-i ';
else,        flags = '-it ';
end

[~, sceneDir, ~] = fileparts(outputFolder);

% ASSUME that if we supply a context it is on a Linux server
nativeFolder = outputFolder;
if ~isempty(obj.renderContext)
    useContext = obj.renderContext;
elseif ~ismpty(getpref('docker','renderContext'))
    useContext = getpref('docker','renderContext','');
elseif ~isempty(dockerWrapper.staticVar('get','renderContext',''))
    useContext = dockerWrapper.staticVar('get','renderContext','');
end
% container is Linux, so convert
outputFolderDocker = dockerWrapper.pathToLinux(outputFolder);

denoiseCommand = ''; %default

% As a "fail-safe" way to populate that volume and the recipes
% we copy any correctly placed resources into the shared resource
% folders and delete the per-recipe sub-folders that were synced
% over so that we can replace them with symbolic links to the shared
% versions.
if obj.remoteResources
    symLinkCommand = ['&&' getSymLinks()];
else
    symLinkCommand = ''; %Use whatever we have locally
end


if ~obj.localRender
    % Running remotely.

    % Remove previous renders
    if isfolder(fullfile(outputFolder, 'renderings'))
        rmdir(fullfile(outputFolder, 'renderings'),'s');
        mkdir(fullfile(outputFolder, 'renderings'),'s');
    end
    if ispc
        rSync = 'wsl rsync';
        nativeFolder = [obj.localRoot outputFolderDocker '/'];
    else
        rSync = 'rsync';
    end
    if isempty(obj.remoteRoot)
        obj.remoteRoot = '~';
        % if no remote root, then we need to look up our local root and use it!
    end
    if ~isempty(obj.remoteUser)
        remoteAddress = [obj.remoteUser '@' obj.remoteMachine];
    else
        remoteAddress = obj.remoteMachine;
    end

    % in the case of Mac (& Linux?) outputFolder includes both
    % our iset dir and then the relative path
    [~, sceneDir, ~] = fileparts(outputFolderDocker);
    remoteScenePath = dockerWrapper.pathToLinux(fullfile(obj.remoteRoot, obj.relativeScenePath, sceneDir));

    %remoteScenePath = [obj.remoteRoot outputFolder];
    remoteScenePath = strrep(remoteScenePath, '//', '/');
    remoteScene = [remoteAddress ':' remoteScenePath '/'];

    % use -c for checksum if clocks & file times won't match
    % using -z for compression, but doesn't seem to make a difference?
    putData = tic;
    speedup = ' --protocol=29  -e "ssh -x -T -o Compression=no"';
    % -c arcfour might help if we have it on both sides
    if ismac || isunix
        % We needed the extra slash for the mac.  But still investigation
        % (DJC)
        % add deletion of extraneous files
        putCommand = sprintf('%s %s -r -t --delete %s %s',rSync, speedup, [nativeFolder,'/'], remoteScene);
    else
        putCommand = sprintf('%s %s -r -t --delete %s %s',rSync, speedup, nativeFolder, remoteScene);
    end

    if verbose > 0
        fprintf('Put: %s ...\n', putCommand);
    end
    [rStatus, rResult] = system(putCommand);

    if verbose > 0
        fprintf('Done (%4.2f sec)\n', toc(putData))
    end
    if rStatus ~= 0, error(rResult); end

    % We currently only offer optix for the remote case
    if denoiseFlag
        % this pathing is sort of ugly, but needed
        % since pbrt is on Linux and we might be on Windows
        renderOutFile = ['renderings/' sceneDir '.exr'];
        noiseOutFile = ['renderings/' sceneDir '-denoise.exr'];
        denoiseCommand = sprintf(' imgtool denoise-optix --outfile %s %s', ...
            noiseOutFile, renderOutFile);
    end
    renderStart = tic;
    % our output folder path starts from root, not from where the volume is
    % mounted
    shortOut = dockerWrapper.pathToLinux(fullfile(obj.relativeScenePath, sceneDir));

    % Moving forward, we will start assuming that needed resource files are
    % available to our docker container on the rendering server via a
    % volume mounted as /ISETResources.


    % need to cd to our scene, and remove all old renders
    % some leftover files can start with "." so need to get them also

    if ~isempty(denoiseCommand)
        % Use the optix denoiser if asked
        containerCommand = sprintf('docker --context %s exec %s %s sh -c "cd %s && rm -rf renderings/{*}  %s && %s && %s"',...
            useContext, flags, useContainer, shortOut, symLinkCommand, renderCommand, denoiseCommand);
    else
        containerCommand = sprintf('docker --context %s exec %s %s sh -c "cd %s && rm -rf renderings/{*}  %s && %s "',...
            useContext, flags, useContainer, shortOut, symLinkCommand, renderCommand);
    end
    if verbose > 0
        cprintf('*Blue', 'USE Docker: %s\n', containerCommand);
    end

    if verbose > 1
        [status, result] = system(containerCommand, '-echo');
        fprintf('Rendered remotely in: %4.2f sec\n', toc(renderStart))
        fprintf('Returned parameter result is\n***\n%s', result);
    elseif verbose == 1
        [status, result] = system(containerCommand);
        if status == 0
            fprintf('Rendered remotely in: %4.2f sec\n', toc(renderStart))
        else
            cprintf('*Red', "Error Rendering: %s", result);
        end
    else
        [status, result] = system(containerCommand);
    end
    if status == 0 && ~isempty(obj.remoteMachine)

        % sync data back -- renderings sub-folder
        % This assumes that all output is in that folder!
        getOutput = tic;
        % this speedup works for put, but so far not for pull
        %speedup = ' --protocol=29  -e "ssh -x -T -o Compression=no"';
        speedup = '';
        pullCommand = sprintf('%s -r %s %s %s',rSync, speedup, ...
            [remoteScene 'renderings/'], dockerWrapper.pathToLinux(fullfile(nativeFolder, 'renderings')));
        if verbose > 0
            fprintf('Pull: %s ...\n', pullCommand);
        end

        % bring back results
        system(pullCommand);
        if verbose > 0
            fprintf('done (%6.2f sec)\n', toc(getOutput))
        end
    end
else
    % Running locally.
    shortOut = dockerWrapper.pathToLinux(fullfile(obj.relativeScenePath,sceneDir));

    % Add support for 'remoteResources' even in local case
    if obj.remoteResources
        symLinkCommand = ['&&' getSymLinks()];
        containerCommand = sprintf('docker --context default exec %s %s sh -c "cd %s && rm -rf renderings/{*,.*}  %s && %s "',...
            flags, useContainer, shortOut, symLinkCommand, renderCommand);
    else
        containerCommand = sprintf('docker --context default exec %s %s sh -c "cd %s && %s"', flags, useContainer, shortOut, renderCommand);
    end

    tic;
    [status, result] = system(containerCommand);
    if verbose > 0
        fprintf('Rendered time %6.2f\n', toc)
    end
end

%% For debugging.  Will write a method to just return these before long (BW).

%fprintf('\n------------------\n');
%cprintf('Blue', 'USE Docker: %s\n',containerCommand);
%cprintf('Blue', 'PBRT command: %s\n',renderCommand);
%fprintf('\n------------------\n');

end

function getLinks = getSymLinks()
cpCommand = 'cp -n -r 2>/dev/null ';

geoCommand =  [cpCommand 'geometry/* /ISETResources/geometry ; rm -rf geometry ; ln -s /ISETResources/geometry geometry'];
texCommand =  [cpCommand 'textures/* /ISETResources/textures ; rm -rf textures ; ln -s /ISETResources/textures textures'];
spdCommand =  [cpCommand 'spds/* /ISETResources/spds ; rm -rf spds ; ln -s /ISETResources/spds spds'];
lgtCommand =  [cpCommand 'lights/* /ISETResources/lights ; rm -rf lights ; ln -s /ISETResources/lights lights'];
skyCommand =  [cpCommand 'skymaps/* /ISETResources/skymaps ; rm -rf skymaps ; ln -s /ISETResources/skymaps skymaps'];
lensCommand = [cpCommand 'lens/* /ISETResources/lens ; rm -rf lens ; ln -s /ISETResources/lens lens'];

getLinks =  sprintf(' %s ;  %s ; %s ; %s ; %s ; %s', ...
    geoCommand, texCommand, spdCommand, lgtCommand, skyCommand, lensCommand);

end



