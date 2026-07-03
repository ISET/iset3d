function tests = test_piDockerWarmup()
% TEST_PIDOCKERWARMUP Unit tests for PBRT Docker warm-up behavior.

tests = functiontests(localfunctions);

end

%% ------------------------------------------------------------------------
function testMissingPrefsSkips(testCase)
report = piDockerWarmup( ...
    'prefs',struct(), ...
    'remoteOnly',true, ...
    'quiet',true, ...
    'systemfcn',@localHealthySystem);

testCase.verifyTrue(report.skipped);
testCase.verifyFalse(report.warmed);
end

%% ------------------------------------------------------------------------
function testLocalContextSkipsByDefault(testCase)
prefs = localBasePrefs();
prefs.renderContext = "default";
prefs.remoteHost = "";

report = piDockerWarmup( ...
    'prefs',prefs, ...
    'quiet',true, ...
    'systemfcn',@localHealthySystem);

testCase.verifyTrue(report.skipped);
testCase.verifyEqual(report.skipReason,'Configured ISETDocker context is not remote.');
end

%% ------------------------------------------------------------------------
function testRemoteStartsContainer(testCase)
fakeDocker = localFakeDocker('',1);

report = piDockerWarmup( ...
    'prefs',localBasePrefs(), ...
    'docker',fakeDocker, ...
    'quiet',true, ...
    'systemfcn',@localHealthySystem);

testCase.verifyTrue(report.ok);
testCase.verifyTrue(report.warmed);
testCase.verifyEqual(report.containerName,'pbrt-gpu-test');
end

%% ------------------------------------------------------------------------
function testRunningContainerDoesNotStart(testCase)
prefs = localBasePrefs();
prefs.PBRTContainer = "pbrt-gpu-existing";
fakeDocker = localFakeDocker('pbrt-gpu-existing',0);

report = piDockerWarmup( ...
    'prefs',prefs, ...
    'docker',fakeDocker, ...
    'quiet',true, ...
    'systemfcn',@localHealthySystem);

testCase.verifyTrue(report.ok);
testCase.verifyFalse(report.warmed);
testCase.verifyTrue(report.containerAlreadyRunning);
testCase.verifyEqual(report.containerName,'pbrt-gpu-existing');
end

%% ------------------------------------------------------------------------
function prefs = localBasePrefs()
prefs = struct( ...
    'label',"orange 3090 remote", ...
    'renderContext',"remote-orange", ...
    'remoteHost',"orange.stanford.edu", ...
    'device',"gpu", ...
    'deviceID',"0", ...
    'dockerImage',"vistalab/pbrt-v4-gpu", ...
    'remoteUser',"wandell", ...
    'workDir',"/home/wandell/ISETRemoteRender", ...
    'PBRTResources',"/acorn/data/iset/PBRTResources");
end

%% ------------------------------------------------------------------------
function fakeDocker = localFakeDocker(psResult,psStatus)
fakeDocker = struct();
fakeDocker.startPBRT = @() 'pbrt-gpu-test';
fakeDocker.reset = @() [];
fakeDocker.dockercmd = @(varargin) deal(psResult,'docker ps',psStatus);
fakeDocker.dockerContextFlag = @() ' --context remote-orange ';
fakeDocker.validateDockerContext = @(varargin) localOkContextReport();
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
if contains(cmd,'docker')
    status = 0;
    result = '/usr/local/bin/docker';
else
    status = 0;
    result = '';
end
end
