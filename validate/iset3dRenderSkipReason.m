function reason = iset3dRenderSkipReason(filePath)
% Return a skip reason when a script needs rendering but Docker is not ready.
%
% Syntax:
%   reason = iset3dRenderSkipReason(filePath)
%
% Brief:
%   Tutorial/example smoke tests should not fail with a long PBRT stack trace
%   when the configured Docker renderer is unavailable.  This helper is used
%   as a conditional skip hook by the tutorial and example runners.
%
% See also
%   iset3dExampleTest, iset3dTutorialTest, ieRunTutorialExampleTests

reason = '';
if ~localRequiresRender(filePath), return; end

[ready,details] = localRendererReady();
if ~ready
    reason = sprintf('rendering unavailable: %s',details);
end

end

function tf = localRequiresRender(filePath)
%% Detect scripts that invoke the PBRT render path.

fileText = fileread(filePath);
patterns = {'piWRS','piRender','eyeRender','thisSE.render'};
tf = false;
for ii = 1:numel(patterns)
    if contains(fileText,patterns{ii})
        tf = true;
        return;
    end
end

end

function [ready,details] = localRendererReady()
%% Cache the renderer preflight result for a whole smoke-test run.

persistent cachedReady cachedDetails
if ~isempty(cachedReady)
    ready = cachedReady;
    details = cachedDetails;
    return;
end

[ready,details] = localCheckRenderer();
cachedReady = ready;
cachedDetails = details;

end

function [ready,details] = localCheckRenderer()
%% Verify Docker preferences, context, and GPU visibility when required.

ready = false;
localEnsureISETCam();

[dockerExists,~,dockerResult] = piDockerExists();
if ~dockerExists
    details = sprintf('Docker command not found: %s',strtrim(dockerResult));
    return;
end

if ~ispref('ISETDocker')
    details = 'ISETDocker preferences are not configured; run piDockerConfig';
    return;
end

try
    thisDocker = isetdocker('verbosity',0);
catch err
    details = localOneLine(err.message);
    return;
end

try
    report = thisDocker.validateDockerContext('checkversion',true);
catch err
    details = localOneLine(err.message);
    return;
end
if ~report.ok
    details = localOneLine(isetdocker.validationMessage(report));
    return;
end

if ~strcmpi(thisDocker.device,'gpu')
    ready = true;
    details = 'renderer configured for CPU';
    return;
end

try
    if ~ispref('ISETDocker','PBRTContainer')
        thisDocker.startPBRT();
    end
    [gpuStatus,gpuResult] = localCheckContainerGPU(thisDocker);
    if localGPUCheckFailed(gpuStatus,gpuResult)
        thisDocker.reset();
        thisDocker.startPBRT();
        [gpuStatus,gpuResult] = localCheckContainerGPU(thisDocker);
    end
catch err
    details = localOneLine(err.message);
    return;
end

if localGPUCheckFailed(gpuStatus,gpuResult)
    details = sprintf('configured GPU is not visible in PBRT Docker container: %s', ...
        localOneLine(gpuResult));
    return;
end

ready = true;
details = 'renderer configured for GPU';

end

function [status,result] = localCheckContainerGPU(thisDocker)
%% Run nvidia-smi inside the PBRT container without printing its output.

containerName = char(getpref('ISETDocker','PBRTContainer'));
if isempty(regexp(containerName,'^[A-Za-z0-9_.-]+$','once'))
    error('ISET3D:InvalidPBRTContainer', ...
        'PBRT container name contains unsafe characters: "%s"',containerName);
end

contextFlag = thisDocker.dockerContextFlag();
cmd = sprintf('docker %s exec %s sh -c "nvidia-smi"', ...
    contextFlag,containerName);
cmd = sprintf('%s 2>&1 || true',cmd);
[status,result] = system(cmd);

end

function tf = localGPUCheckFailed(status,result)
%% True when the PBRT container cannot use the configured GPU.

tf = status ~= 0 || contains(result,'Failed to initialize NVML') || ...
    contains(result,'No devices were found') || ...
    contains(result,'no CUDA-capable device') || ...
    contains(result,'Error response from daemon');

end

function localEnsureISETCam()
%% Add the sibling ISETCam dependency when core helpers are unavailable.

if ~isempty(which('ieParamFormat')), return; end

repoRoot = iset3dRootPath;
dependencyRoot = fullfile(fileparts(repoRoot),'isetcam');
if isfolder(dependencyRoot)
    addpath(genpath(dependencyRoot));
end

end

function text = localOneLine(text)
%% Collapse command and exception output for skip summaries.

text = strtrim(regexprep(char(text),'\s+',' '));
if strlength(text) > 220
    text = char(extractBefore(string(text),221));
end

end
