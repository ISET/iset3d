function [status, result, containerCommand] = render(obj, thisR, commandonly)
% RENDER Renders a PBRT scene recipe using a Docker container, supporting
% local and remote execution.
%
% (Gemini documentation)
%
% Synopsis:
% [status, result, containerCommand] = obj.render(thisR, commandonly)
%
% Description:
%  This function constructs and executes the Docker command to run the
%  PBRT renderer. It handles configuration checks, ensures the PBRT
%  container is running, manages file synchronization for remote hosts
%  (uploading scene files and downloading results), and builds the
%  final `docker exec` command.
%
% The function automatically checks if a remote host is configured in the
% ISETDocker preferences and adjusts its behavior (local vs. remote
% execution, file synchronization) accordingly.
%
% Inputs:
%   obj:          The isetdocker object instance, containing configuration
%                 and connection information (e.g., remote host details).
%   thisR:        The RenderRecipe (piRecipe) object containing the scene
%                 definition, output file path, and rendering parameters.
%   commandonly:  (Optional) Boolean. If true, the function only builds and
%                 returns the Docker command string without executing it.
%                 Defaults to false.
%
% Outputs:
%   status:             Integer status code returned by the `system()` call
%                       (0 indicates success).
%   result:             Text output returned by the execution of the Docker
%                       command.
%   containerCommand:   The full string of the `docker exec` command that was
%                       either executed or constructed.
%
% Key/value Pairs:
%   N/A (All options are managed through the properties of the `obj` and `thisR`
%   inputs, and ISETDocker preferences.)
%
% Usage:
% 1. Local Rendering (PBRT container must be running locally):
%    [s, res, cmd] = obj.render(thisR);
%
% 2. Remote Rendering (Requires ISETDocker preferences to be set up
%    with 'remoteHost', 'workDir', and PBRT container running remotely):
%    [s, res, cmd] = obj.render(thisR);
%
% 3. Get Command String Only:
%    [~, ~, cmd] = obj.render(thisR, true);
%
% See also:
%   piDockerCurrentContext, isetdocker.startPBRT, isetdocker.upload,
%   isetdocker.download, piRender


%% Initialize
p = inputParser();

p.KeepUnmatched = true;

verbose = obj.verbosity; % 0, 1, 2, 3
if ~exist('commandonly','var')
    commandonly = false;
end

%% Build up the render command
pbrtOutputFile = thisR.get('output file'); 
outputFolder   = thisR.get('output folder'); 
sceneFolder    = thisR.get('input folder basename');
currName       = thisR.get('output basename');

iDockerPrefs   = getpref('ISETDocker');

% Check that the container is running remotely.  If not, start.
if isfield(iDockerPrefs,'PBRTContainer')
    % Test that the container is running remotely
    result = obj.dockercmd('psfind','string',iDockerPrefs.PBRTContainer);

    % Couldn't find it.  Restart.
    if isempty(result), obj.startPBRT; end
else
    % No PBRTContainer specified, so restart.
    obj.startPBRT();
end

ourContainer = getpref('ISETDocker','PBRTContainer');

if ispc,     flags = '-i ';
else,        flags = '-it ';
end

[~, sceneDir, ~] = fileparts(outputFolder);

% By the time we get here, we should know the context from the saved
% matlab prefs. If it is there, use it.  Otherwise, get the context
% from the current context (BW).
if isempty(getpref('ISETDocker','renderContext'))
     contextFlag = sprintf(' --context %s ',piDockerCurrentContext);
else
    contextFlag = [' --context ' getpref('ISETDocker','renderContext')];
end

if strcmpi(obj.device,'gpu')
    device = ' --gpu ';
else
    device = '';
end

% Running remotely.
if ~isempty(getpref('ISETDocker','remoteHost'))
    if ispc
        remoteSceneDir = [getpref('ISETDocker','workDir') '/' sceneFolder];
    else
        remoteSceneDir = fullfile(getpref('ISETDocker','workDir'),sceneFolder);
    end
    % sync files from local folder to remote
    % obj.upload(localDIR, remoteDIR, {'excludes','cellarray'}})
    obj.upload(outputFolder, remoteSceneDir,{'renderings',[currName,'.mat']});

    outF = fullfile(remoteSceneDir,'renderings',[currName,'.exr']);
    
    % check if there is renderings folder
    sceneFolder = dir(obj.sftpSession,fullfile(remoteSceneDir));
    renderingsDir = true;
    for ii = 1:numel(sceneFolder)
        if sceneFolder(ii).isdir && strcmp(sceneFolder(ii).name,'renderings')
            renderingsDir = false;
        end
    end
    if renderingsDir
        mkdir(obj.sftpSession,fullfile(remoteSceneDir,'renderings'));
    end

    renderCommand = sprintf('pbrt %s --outfile %s %s', device, outF, ...
        fullfile(getpref('ISETDocker','workDir'),sceneDir,[currName, '.pbrt']));

    containerCommand = sprintf('docker %s exec %s %s sh -c " %s "',...
        contextFlag, flags, ourContainer, renderCommand);

    if verbose > 0
        fprintf('[INFO]: USE Docker: %s\n', containerCommand);
    end
    if ~commandonly
        renderStart = tic;
        if verbose > 1
            [status, result] = system(containerCommand, '-echo');
            fprintf('[INFO]: Rendered in: %4.2f sec\n', toc(renderStart))
            fprintf('[INFO]: Returned parameter result is\n***\n%s', result);
        elseif verbose == 1

            [status, result] = system(containerCommand);
            if status == 0
                fprintf('[INFO]: Rendered remotely in: %4.2f sec\n', toc(renderStart))
            else
                cprintf('red','[ERROR]: Docker Command: %s\n', containerCommand);
                error('Error Rendering: %s', result);
            end

        else
            [status, result] = system(containerCommand);
        end

        if status == 0
            if ~isempty(getpref('ISETDocker','remoteHost'))
                if ~getpref('ISETDocker','batch',false)
                    obj.download(fullfile(remoteSceneDir,'renderings'), fullfile(outputFolder,'renderings'));
                else
                    return;
                end
            end
        end
    end
else
    % Running locally. -- TODO
    % SceneDir = [getpref('ISETDocker','workDir') '/' sceneFolder]; % this should be local folder
    % outF = fullfile(SceneDir,'renderings',[currName,'.exr']);
    if ~exist(fullfile(outputFolder,'renderings'),'dir'),mkdir(fullfile(outputFolder,'renderings'));end
    outF = fullfile(outputFolder,'renderings',[currName,'.exr']);
    
    % Add support for 'remoteResources' even in local case
    renderCommand = sprintf('pbrt %s --outfile %s %s', device, outF, pbrtOutputFile);

    containerCommand = sprintf('docker %s exec %s %s sh -c " %s "',...
        contextFlag, flags, ourContainer, renderCommand);

    renderStart = tic;
    [status, result] = system(containerCommand);
    if verbose > 0
        if status == 0
            fprintf('[INFO]: Rendered remotely in: %4.2f sec\n', toc(renderStart))
        else
            cprintf('red','[ERROR]: Docker Command: %s\n', containerCommand);
            error('Error Rendering: %s', result);
        end
    end
end

end
