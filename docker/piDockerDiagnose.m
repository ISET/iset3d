function report = piDockerDiagnose(varargin)
% Diagnose ISET3d Docker and remote rendering readiness.
%
% Syntax:
%   report = piDockerDiagnose
%   report = piDockerDiagnose('render',true)
%
% Inputs:
%   render              - Run a tiny render check. Default false.
%   resetStaleContainer - Reset a stale PBRTContainer preference/container.
%                         Default false.
%   verbosity           - Print summary level. Default 1.
%
% Returns:
%   report - Struct with ok, errors, warnings, checks, repairHints, prefs.
%
% See also
%   piDockerConfig, piDockerExists, isetdocker, piWRS

varargin = ieParamFormat(varargin);

p = inputParser;
p.addParameter('render',false,@islogical);
p.addParameter('resetstalecontainer',false,@islogical);
p.addParameter('verbosity',1,@isnumeric);

% Test seams.  Not part of the user-facing API.
p.addParameter('systemfcn',@system);
p.addParameter('prefs',[]);
p.addParameter('docker',[]);
p.parse(varargin{:});

runSystem = p.Results.systemfcn;
prefs = p.Results.prefs;
thisDocker = p.Results.docker;

report = localEmptyReport();

if isempty(prefs)
    if ispref('ISETDocker')
        prefs = getpref('ISETDocker');
    else
        report = localAddCheck(report,'ISETDocker preferences',false, ...
            'ISETDocker preferences are not configured.');
        report.repairHints(end+1,1) = "Run piDockerConfig.";
        report = localFinish(report,p.Results.verbosity);
        return;
    end
end
report.prefs = prefs;

report = localCheckCommand(report,runSystem,'docker','Docker command');
report = localCheckCommand(report,runSystem,'rsync','rsync command');

prefReport = isetdocker.validatePrefStruct(prefs);
if prefReport.ok
    report = localAddCheck(report,'ISETDocker preferences',true,'Preferences are structurally valid.');
else
    report = localAddCheck(report,'ISETDocker preferences',false, ...
        isetdocker.validationMessage(prefReport));
    report.repairHints = [report.repairHints; prefReport.repairCommands(:)];
end
report.warnings = [report.warnings; prefReport.warnings(:)];

if ~localPrefsUsable(prefReport)
    report = localFinish(report,p.Results.verbosity);
    return;
end

if isempty(thisDocker)
    try
        thisDocker = isetdocker('verbosity',0);
    catch err
        report = localAddCheck(report,'ISETDocker object',false,err.message);
        report = localFinish(report,p.Results.verbosity);
        return;
    end
end

contextReport = thisDocker.validateDockerContext('checkversion',true);
if contextReport.ok
    report = localAddCheck(report,'Docker context',true,'Docker context is usable.');
else
    report = localAddCheck(report,'Docker context',false, ...
        isetdocker.validationMessage(contextReport));
    report.repairHints = [report.repairHints; contextReport.repairCommands(:)];
end

remoteHost = localStringField(prefs,'remoteHost');
remoteUser = localStringField(prefs,'remoteUser');
if strlength(remoteHost) > 0
    report = localCheckRemoteHost(report,runSystem,remoteUser,remoteHost);
end

device = localStringField(prefs,'device');
if strcmpi(device,'gpu')
    report = localCheckGpuHost(report,runSystem,remoteUser,remoteHost);
    report = localCheckPBRTContainer(report,runSystem,thisDocker,prefs, ...
        p.Results.resetstalecontainer);
end

if p.Results.render
    report = localCheckTinyRender(report);
end

report = localFinish(report,p.Results.verbosity);

end

function report = localEmptyReport()
report = struct();
report.ok = true;
report.errors = strings(0,1);
report.warnings = strings(0,1);
report.checks = struct('name',{},'ok',{},'message',{});
report.repairHints = strings(0,1);
report.prefs = struct();
end

function report = localAddCheck(report,name,ok,message)
check = struct('name',char(name),'ok',logical(ok),'message',char(message));
report.checks(end+1) = check;
if ~ok
    report.ok = false;
    report.errors(end+1,1) = string(sprintf('%s: %s',name,message));
end
end

function report = localCheckCommand(report,runSystem,commandName,checkName)
if ispc
    cmd = sprintf('where %s',commandName);
else
    cmd = sprintf('which %s',commandName);
end
[status,result] = runSystem(cmd);
if status == 0
    report = localAddCheck(report,checkName,true,strtrim(result));
else
    report = localAddCheck(report,checkName,false, ...
        sprintf('%s was not found: %s',commandName,strtrim(result)));
end
end

function tf = localPrefsUsable(prefReport)
tf = prefReport.ok;
end

function report = localCheckRemoteHost(report,runSystem,remoteUser,remoteHost)
if strlength(remoteUser) == 0 || strlength(remoteHost) == 0
    report = localAddCheck(report,'Remote SSH',false, ...
        'remoteUser and remoteHost are required for remote rendering.');
    return;
end
cmd = sprintf('ssh -o BatchMode=yes -o ConnectTimeout=10 %s@%s hostname', ...
    remoteUser,remoteHost);
[status,result] = runSystem(cmd);
if status == 0
    report = localAddCheck(report,'Remote SSH',true,strtrim(result));
else
    report = localAddCheck(report,'Remote SSH',false,strtrim(result));
    report.repairHints(end+1,1) = "Check VPN, SSH keys, remote username, and Docker context host.";
end
end

function report = localCheckGpuHost(report,runSystem,remoteUser,remoteHost)
if strlength(remoteHost) > 0
    cmd = sprintf('ssh -o BatchMode=yes -o ConnectTimeout=10 %s@%s nvidia-smi', ...
        remoteUser,remoteHost);
else
    cmd = 'nvidia-smi';
end
[status,result] = runSystem(cmd);
if status == 0 && contains(result,'NVIDIA-SMI')
    report = localAddCheck(report,'GPU host visibility',true,localFirstLine(result));
else
    report = localAddCheck(report,'GPU host visibility',false,strtrim(result));
    report.repairHints(end+1,1) = "Verify NVIDIA driver and nvidia-smi on the render host.";
end
end

function report = localCheckPBRTContainer(report,runSystem,thisDocker,prefs,resetStale)
containerName = localStringField(prefs,'PBRTContainer');
if strlength(containerName) == 0
    report = localAddCheck(report,'PBRT container',true, ...
        'No saved PBRTContainer preference; rendering will start a new container.');
    return;
end

if isempty(regexp(char(containerName),'^[A-Za-z0-9_.-]+$','once'))
    report = localAddCheck(report,'PBRT container',false, ...
        sprintf('Unsafe PBRTContainer value: %s',containerName));
    return;
end

contextFlag = thisDocker.dockerContextFlag();
cmd = sprintf('docker %s exec %s sh -c "nvidia-smi" 2>&1 || true', ...
    contextFlag,containerName);
[~,result] = runSystem(cmd);

if contains(result,'NVIDIA-SMI') && ~localGpuFailureText(result)
    report = localAddCheck(report,'PBRT container GPU visibility',true, ...
        sprintf('%s can see NVIDIA-SMI.',containerName));
    return;
end

report = localAddCheck(report,'PBRT container GPU visibility',false, ...
    sprintf('%s cannot see the GPU: %s',containerName,localOneLine(result)));
report.repairHints(end+1,1) = "Remove the stale PBRT container or run piDockerDiagnose('resetStaleContainer',true).";

if resetStale
    try
        thisDocker.reset();
        report.warnings(end+1,1) = sprintf('Reset stale PBRT container %s.',containerName);
    catch err
        report.warnings(end+1,1) = sprintf('Could not reset stale PBRT container %s: %s', ...
            containerName,err.message);
    end
end
end

function report = localCheckTinyRender(report)
try
    thisR = piRecipeDefault('scene name','SimpleScene');
    thisR.set('film resolution',[64 48]);
    thisR.set('rays per pixel',8);
    thisR.set('nbounces',1);
    piWRS(thisR,'show',false,'name','piDockerDiagnose');
    report = localAddCheck(report,'Tiny render',true,'SimpleScene rendered successfully.');
catch err
    report = localAddCheck(report,'Tiny render',false,err.message);
end
end

function value = localStringField(s,fieldName)
if isstruct(s) && isfield(s,fieldName)
    value = string(s.(fieldName));
else
    value = "";
end
value = strtrim(value);
end

function tf = localGpuFailureText(text)
tf = contains(text,'Failed to initialize NVML') || ...
    contains(text,'No devices were found') || ...
    contains(text,'no CUDA-capable device') || ...
    contains(text,'Error response from daemon');
end

function line = localFirstLine(text)
lines = splitlines(string(text));
lines = lines(strlength(strtrim(lines)) > 0);
if isempty(lines)
    line = '';
else
    line = char(strtrim(lines(1)));
end
end

function text = localOneLine(text)
text = char(strtrim(regexprep(string(text),'\s+',' ')));
if strlength(text) > 220
    text = char(extractBefore(string(text),221));
end
end

function report = localFinish(report,verbosity)
report.errors = unique(report.errors,'stable');
report.warnings = unique(report.warnings,'stable');
report.repairHints = unique(report.repairHints,'stable');
report.ok = isempty(report.errors);
if verbosity > 0
    localPrintReport(report);
end
end

function localPrintReport(report)
if report.ok
    fprintf('piDockerDiagnose: OK\n');
else
    fprintf('piDockerDiagnose: ISSUES FOUND\n');
end
for ii = 1:numel(report.checks)
    if report.checks(ii).ok
        statusText = 'OK';
    else
        statusText = 'FAIL';
    end
    fprintf('  [%s] %s - %s\n',statusText, ...
        report.checks(ii).name,report.checks(ii).message);
end
if ~isempty(report.repairHints)
    fprintf('Repair hints:\n');
    for ii = 1:numel(report.repairHints)
        fprintf('  - %s\n',report.repairHints(ii));
    end
end
end
