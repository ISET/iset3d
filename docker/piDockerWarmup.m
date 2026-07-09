function report = piDockerWarmup(varargin)
% Warm up the ISET3d PBRT Docker container.
%
% Syntax:
%   report = piDockerWarmup
%   report = piDockerWarmup('remoteOnly',true,'quiet',true)
%   report = piDockerWarmup('force',true)
%   report = piDockerWarmup('render',true)
%
% Inputs:
%   remoteOnly - Only warm up remote rendering contexts. Default true.
%   force      - Reset any saved PBRT container before warming. Default false.
%   render     - Run a tiny acceptance render after warm-up. Default false.
%   quiet      - Suppress normal status output. Default false.
%
% Returns:
%   report - Struct describing whether warm-up ran, skipped, or failed.
%
% Description:
%   This function is intended for explicit user startup.m use.  It starts the
%   PBRT container through isetdocker without running a tutorial render, so the
%   first real render does not pay the container startup cost.
%
% Example:
%   if exist('piDockerWarmup','file')
%       piDockerWarmup('remoteOnly',true,'quiet',true);
%   end
%
% See also
%   piDockerConfig, piDockerDiagnose, piDockerExists, isetdocker.startPBRT

varargin = ieParamFormat(varargin);

p = inputParser;
p.addParameter('remoteonly',true,@islogical);
p.addParameter('force',false,@islogical);
p.addParameter('render',false,@islogical);
p.addParameter('quiet',false,@islogical);

% Test seams.  Not part of the user-facing API.
p.addParameter('prefs',[]);
p.addParameter('docker',[]);
p.addParameter('dockerfactory',[]);
p.addParameter('systemfcn',@system);
p.parse(varargin{:});

args = p.Results;
report = localEmptyReport();

if isempty(args.prefs)
    if ~ispref('ISETDocker')
        report.skipped = true;
        report.skipReason = 'ISETDocker preferences are not configured.';
        report = localAddWarning(report,'Run piDockerConfig before warming the PBRT container.');
        localPrint(report,args.quiet);
        return;
    end
    prefs = getpref('ISETDocker');
    usingInjectedPrefs = false;
else
    prefs = args.prefs;
    usingInjectedPrefs = true;
end
report.prefs = prefs;
report.renderContext = localStringField(prefs,'renderContext');
report.remoteHost = localStringField(prefs,'remoteHost');

if args.remoteonly && ~localIsRemotePrefs(prefs)
    report.skipped = true;
    report.skipReason = 'Configured ISETDocker context is not remote.';
    localPrint(report,args.quiet);
    return;
end

report = localCheckDockerCommand(report,args.systemfcn);
if ~report.ok
    localPrint(report,args.quiet);
    return;
end

try
    if isempty(args.docker)
        if isempty(args.dockerfactory)
            thisDocker = isetdocker('verbosity',double(~args.quiet));
        else
            thisDocker = args.dockerfactory();
        end
    else
        thisDocker = args.docker;
    end
catch err
    report = localAddError(report,'ISETDocker object',err.message);
    localPrint(report,args.quiet);
    return;
end

if args.force
    report = localResetContainer(report,thisDocker);
    if ~report.ok
        localPrint(report,args.quiet);
        return;
    end
elseif localHasContainer(prefs)
    [isRunning, report] = localContainerRunning(report,thisDocker,prefs);
    if isRunning
        report.warmed = false;
        report.containerAlreadyRunning = true;
        report.containerName = char(localStringField(prefs,'PBRTContainer'));
        if args.render
            report = localAcceptanceRender(report,args,thisDocker,prefs);
        end
        localPrint(report,args.quiet);
        return;
    elseif ~usingInjectedPrefs && ispref('ISETDocker','PBRTContainer')
        rmpref('ISETDocker','PBRTContainer');
    end
end

try
    containerName = thisDocker.startPBRT();
    report.warmed = true;
    report.containerName = char(string(containerName));
catch err
    report = localAddError(report,'PBRT container warm-up',err.message);
    localPrint(report,args.quiet);
    return;
end

if strlength(string(report.containerName)) == 0 && ispref('ISETDocker','PBRTContainer')
    report.containerName = getpref('ISETDocker','PBRTContainer');
end

if args.render
    report = localAcceptanceRender(report,args,thisDocker,prefs);
end

localPrint(report,args.quiet);

end

function report = localEmptyReport()
report = struct();
report.ok = true;
report.warmed = false;
report.skipped = false;
report.skipReason = '';
report.containerAlreadyRunning = false;
report.containerName = '';
report.renderContext = "";
report.remoteHost = "";
report.errors = strings(0,1);
report.warnings = strings(0,1);
report.checks = struct('name',{},'ok',{},'message',{});
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

function report = localAddError(report,name,message)
report = localAddCheck(report,name,false,message);
end

function report = localAddWarning(report,message)
report.warnings(end+1,1) = string(message);
end

function report = localCheckDockerCommand(report,runSystem)
if ispc
    cmd = 'where docker';
else
    cmd = 'which docker';
end
[status,result] = runSystem(cmd);
if status == 0
    report = localAddCheck(report,'Docker command',true,strtrim(result));
else
    report = localAddCheck(report,'Docker command',false, ...
        sprintf('Docker command was not found: %s',strtrim(result)));
end
end

function tf = localIsRemotePrefs(prefs)
renderContext = lower(localStringField(prefs,'renderContext'));
remoteHost = localStringField(prefs,'remoteHost');
tf = strlength(remoteHost) > 0 || startsWith(renderContext,'remote');
end

function tf = localHasContainer(prefs)
tf = isstruct(prefs) && isfield(prefs,'PBRTContainer') && ...
    strlength(localStringField(prefs,'PBRTContainer')) > 0;
end

function [isRunning, report] = localContainerRunning(report,thisDocker,prefs)
isRunning = false;
containerName = char(localStringField(prefs,'PBRTContainer'));
try
    [result,~,cmdStatus] = thisDocker.dockercmd('psfind','string',containerName);
    isRunning = (cmdStatus == 0) && ~isempty(strtrim(result));
    if isRunning
        report = localAddCheck(report,'PBRT container',true, ...
            sprintf('%s is already running.',containerName));
    else
        report = localAddCheck(report,'PBRT container',true, ...
            sprintf('%s is not running; starting a new container.',containerName));
    end
catch err
    report = localAddCheck(report,'PBRT container',true, ...
        sprintf('Could not verify saved container; starting a new one. %s',err.message));
end
end

function report = localResetContainer(report,thisDocker)
try
    thisDocker.reset();
    report = localAddCheck(report,'PBRT container reset',true, ...
        'Reset requested before warm-up.');
catch err
    report = localAddError(report,'PBRT container reset',err.message);
end
end

function report = localAcceptanceRender(report,args,thisDocker,prefs)
try
    diagReport = piDockerDiagnose( ...
        'render',true, ...
        'verbosity',double(~args.quiet), ...
        'systemfcn',args.systemfcn, ...
        'prefs',prefs, ...
        'docker',thisDocker);
    report.acceptanceRender = diagReport;
    if diagReport.ok
        report = localAddCheck(report,'Acceptance render',true, ...
            'Tiny render completed.');
    else
        report = localAddError(report,'Acceptance render', ...
            strjoin(cellstr(diagReport.errors),'; '));
    end
catch err
    report = localAddError(report,'Acceptance render',err.message);
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

function localPrint(report,quiet)
if quiet
    return;
end

if report.skipped
    fprintf('piDockerWarmup: skipped - %s\n',report.skipReason);
elseif report.ok && report.containerAlreadyRunning
    fprintf('piDockerWarmup: PBRT container already running (%s)\n',report.containerName);
elseif report.ok && report.warmed
    fprintf('piDockerWarmup: started PBRT container (%s)\n',report.containerName);
elseif report.ok
    fprintf('piDockerWarmup: OK\n');
else
    fprintf('piDockerWarmup: failed\n');
end

for ii = 1:numel(report.errors)
    fprintf('  ERROR: %s\n',report.errors(ii));
end
for ii = 1:numel(report.warnings)
    fprintf('  WARNING: %s\n',report.warnings(ii));
end
end
