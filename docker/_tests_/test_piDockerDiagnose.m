function tests = test_piDockerDiagnose()
% TEST_PIDOCKERDIAGNOSE Unit tests for Docker diagnostic reports.

tests = functiontests(localfunctions);

end

%% ------------------------------------------------------------------------
function testHealthyRemoteGpuReport(testCase)
prefs = localBasePrefs();
fakeDocker = localFakeDocker();

report = piDockerDiagnose( ...
    'prefs',prefs, ...
    'docker',fakeDocker, ...
    'systemfcn',@localHealthySystem, ...
    'verbosity',0);

testCase.verifyTrue(report.ok);
testCase.verifyEmpty(report.errors);
testCase.verifyTrue(localHasCheck(report,'PBRT container GPU visibility',true));
end

%% ------------------------------------------------------------------------
function testMissingDockerCommandReportsFailure(testCase)
prefs = localBasePrefs();
fakeDocker = localFakeDocker();

report = piDockerDiagnose( ...
    'prefs',prefs, ...
    'docker',fakeDocker, ...
    'systemfcn',@localMissingDockerSystem, ...
    'verbosity',0);

testCase.verifyFalse(report.ok);
testCase.verifyTrue(any(contains(report.errors,'Docker command')));
end

%% ------------------------------------------------------------------------
function testStaleContainerReportsRepairHint(testCase)
prefs = localBasePrefs();
fakeDocker = localFakeDocker();

report = piDockerDiagnose( ...
    'prefs',prefs, ...
    'docker',fakeDocker, ...
    'systemfcn',@localStaleContainerSystem, ...
    'verbosity',0);

testCase.verifyFalse(report.ok);
testCase.verifyTrue(localHasCheck(report,'PBRT container GPU visibility',false));
testCase.verifyTrue(any(contains(report.repairHints,'stale PBRT container')));
end

%% ------------------------------------------------------------------------
function prefs = localBasePrefs()
prefs = struct( ...
    'label', "orange 3090 remote", ...
    'renderContext', "remote-orange", ...
    'remoteHost', "orange.stanford.edu", ...
    'device', "gpu", ...
    'deviceID', "0", ...
    'dockerImage', "vistalab/pbrt-v4-gpu", ...
    'remoteUser', "wandell", ...
    'workDir', "/home/wandell/ISETRemoteRender", ...
    'PBRTResources', "/acorn/data/iset/PBRTResources", ...
    'PBRTContainer', "pbrt-gpu-wandell123");
end

%% ------------------------------------------------------------------------
function fakeDocker = localFakeDocker()
fakeDocker = struct();
fakeDocker.dockerContextFlag = @() ' --context remote-orange ';
fakeDocker.validateDockerContext = @(varargin) localOkContextReport();
fakeDocker.reset = @() [];
end

%% ------------------------------------------------------------------------
function report = localOkContextReport()
report = struct();
report.ok = true;
report.errors = strings(0,1);
report.warnings = strings(0,1);
report.repairCommands = strings(0,1);
end

%% ------------------------------------------------------------------------
function [status,result] = localHealthySystem(cmd)
if contains(cmd,'which docker')
    status = 0; result = '/usr/local/bin/docker';
elseif contains(cmd,'which rsync')
    status = 0; result = '/usr/bin/rsync';
elseif contains(cmd,'hostname')
    status = 0; result = 'orange';
elseif contains(cmd,'nvidia-smi')
    status = 0; result = 'NVIDIA-SMI 550.163.01 Driver Version: 550.163.01 CUDA Version: 12.4';
else
    status = 0; result = '';
end
end

%% ------------------------------------------------------------------------
function [status,result] = localMissingDockerSystem(cmd)
if contains(cmd,'which docker')
    status = 1; result = 'docker not found';
else
    [status,result] = localHealthySystem(cmd);
end
end

%% ------------------------------------------------------------------------
function [status,result] = localStaleContainerSystem(cmd)
if contains(cmd,'docker') && contains(cmd,'exec') && contains(cmd,'nvidia-smi')
    status = 0; result = 'Failed to initialize NVML: Unknown Error';
else
    [status,result] = localHealthySystem(cmd);
end
end

%% ------------------------------------------------------------------------
function tf = localHasCheck(report,name,ok)
tf = false;
for ii = 1:numel(report.checks)
    if strcmp(report.checks(ii).name,name) && report.checks(ii).ok == ok
        tf = true;
        return;
    end
end
end
