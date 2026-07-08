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
status = 0;

%% Build up the render command
pbrtOutputFile = thisR.get('output file'); 
outputFolder   = thisR.get('output folder'); 
sceneFolder    = thisR.get('input folder basename');
currName       = thisR.get('output basename');

iDockerPrefs   = getpref('ISETDocker');

contextReport = obj.validateDockerContext('checkversion', false);
if ~contextReport.ok
    error('ISETDocker:InvalidDockerContext', '%s', isetdocker.validationMessage(contextReport));
end

% Check that the container is running remotely.  If not, start.
if isfield(iDockerPrefs,'PBRTContainer')
    containerName = iDockerPrefs.PBRTContainer;
    % Test that the container is running remotely
    [result, ~, cmdStatus] = obj.dockercmd('psfind','string',containerName);

    % Couldn't find it.  Restart.
    if cmdStatus ~= 0 || isempty(result)
        rmpref('ISETDocker','PBRTContainer');
        obj.startPBRT;
    elseif ~localContainerMatchesDevice(containerName,obj.device)
        savedDevice = localContainerDeviceLabel(containerName);
        requestedDevice = upper(char(string(obj.device)));
        warning('ISETDocker:ContainerDeviceMismatch', ...
            ['Saved PBRT container "%s" is a %s container, but this render ' ...
            'requested %s rendering. Restarting PBRT with a matching container.'], ...
            containerName,savedDevice,requestedDevice);
        obj.reset();
        if ~isempty(obj.remoteHost)
            obj.connect();
        end
        obj.startPBRT();
    elseif strcmpi(obj.device,'gpu') && ~localContainerGPUReady(obj,containerName)
        warning('ISETDocker:StaleGPUContainer', ...
            'PBRT container "%s" is running but cannot see the GPU. Restarting it.', ...
            containerName);
        obj.reset();
        if ~isempty(obj.remoteHost)
            obj.connect();
        end
        obj.startPBRT();
    end
else
    % No PBRTContainer specified, so restart.
    obj.startPBRT();
end

ourContainer = getpref('ISETDocker','PBRTContainer');

if ispc,     flags = '-i ';
else,        flags = '-it ';
end

[~, sceneDir, ~] = fileparts(outputFolder);

contextFlag = obj.dockerContextFlag();

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
    outF = fullfile(remoteSceneDir,'renderings',[currName,'.exr']);

    renderCommand = sprintf('pbrt %s --outfile %s %s', device, outF, ...
        fullfile(getpref('ISETDocker','workDir'),sceneDir,[currName, '.pbrt']));

    containerCommand = sprintf('docker %s exec %s %s sh -c " %s "',...
        contextFlag, flags, ourContainer, renderCommand);

    if commandonly
        result = containerCommand;
        return;
    end

    localEnsureRemoteSession(obj);

    % sync files from local folder to remote
    % obj.upload(localDIR, remoteDIR, {'excludes','cellarray'}})
    obj.upload(outputFolder, remoteSceneDir,{'renderings',[currName,'.mat']});

    % check if there is a remote renderings folder
    sceneListing = localRemoteDir(obj,remoteSceneDir);
    renderingsDir = true;
    for ii = 1:numel(sceneListing)
        if sceneListing(ii).isdir && strcmp(sceneListing(ii).name,'renderings')
            renderingsDir = false;
        end
    end
    if renderingsDir
        mkdir(obj.sftpSession,fullfile(remoteSceneDir,'renderings'));
    end

    if verbose > 0
        fprintf('[INFO]: USE Docker: %s\n', containerCommand);
    end
    renderStart = tic;
    if verbose > 1
        [status, result] = system(containerCommand, '-echo');
        fprintf('[INFO]: Rendered in: %4.2f sec\n', toc(renderStart))
        fprintf('[INFO]: Returned parameter result is\n***\n%s', result);
    else

        [status, result] = system(containerCommand);
        if status == 0
            if verbose == 1
                fprintf('[INFO]: Rendered remotely in: %4.2f sec\n', toc(renderStart))
            end
        else
            if verbose > 0
                cprintf('red','[ERROR]: Docker Command: %s\n', containerCommand);
            end
            error('ISETDocker:RenderFailed', ...
                'Docker render failed with status %d.\nCommand:\n%s\nResult:\n%s', ...
                status, containerCommand, result);
        end
    end

    if status == 0
        if ~isempty(getpref('ISETDocker','remoteHost'))
            if ~getpref('ISETDocker','batch',false)
                localEnsureRemoteSession(obj);
                obj.download(fullfile(remoteSceneDir,'renderings'), fullfile(outputFolder,'renderings'));
            else
                return;
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

    if commandonly
        result = containerCommand;
        return;
    end

    renderStart = tic;
    [status, result] = system(containerCommand);
    if verbose > 0
        if status == 0
            fprintf('[INFO]: Rendered remotely in: %4.2f sec\n', toc(renderStart))
        else
            cprintf('red','[ERROR]: Docker Command: %s\n', containerCommand);
            error('ISETDocker:RenderFailed', ...
                'Docker render failed with status %d.\nCommand:\n%s\nResult:\n%s', ...
                status, containerCommand, result);
        end
    end
end

end

function ready = localContainerGPUReady(obj,containerName)
%% Verify that a running GPU PBRT container still sees CUDA.

ready = false;
containerName = char(string(containerName));
if isempty(regexp(containerName,'^[A-Za-z0-9_.-]+$','once'))
    return;
end

contextFlag = obj.dockerContextFlag();
cmd = sprintf('docker %s exec %s sh -c "nvidia-smi" 2>&1 || true', ...
    contextFlag,containerName);
[~,result] = system(cmd);

result = char(result);
if isempty(strtrim(result)), return; end
if contains(result,'Failed to initialize NVML') || ...
        contains(result,'No devices were found') || ...
        contains(result,'no CUDA-capable device') || ...
        contains(result,'Error response from daemon')
    return;
end

ready = contains(result,'NVIDIA-SMI');

end

function tf = localContainerMatchesDevice(containerName,device)
%% True when the saved PBRT container type matches the requested renderer.

containerName = char(string(containerName));
device = lower(char(string(device)));

switch device
    case 'gpu'
        tf = startsWith(containerName,'pbrt-gpu-');
    case 'cpu'
        tf = startsWith(containerName,'pbrt-cpu-');
    otherwise
        tf = true;
end

end

function deviceLabel = localContainerDeviceLabel(containerName)
%% Return a user-facing device label inferred from a PBRT container name.

containerName = char(string(containerName));

if startsWith(containerName,'pbrt-gpu-')
    deviceLabel = 'GPU';
elseif startsWith(containerName,'pbrt-cpu-')
    deviceLabel = 'CPU';
else
    deviceLabel = 'PBRT';
end

end

function localEnsureRemoteSession(obj)
%% Ensure an SFTP session exists before remote filesystem calls.

if isempty(obj.remoteHost), return; end
if isempty(obj.sftpSession)
    obj.connect();
end

end

function listing = localRemoteDir(obj,remoteDir)
%% List a remote directory, reconnecting once if the SFTP session is stale.

try
    listing = dir(obj.sftpSession,fullfile(remoteDir));
catch firstErr
    try
        obj.disconnect();
        obj.connect();
        listing = dir(obj.sftpSession,fullfile(remoteDir));
    catch secondErr
        error('ISETDocker:SFTPDirFailed', ...
            'Could not list remote render directory "%s". First error: %s Second error: %s', ...
            remoteDir, firstErr.message, secondErr.message);
    end
end

end
