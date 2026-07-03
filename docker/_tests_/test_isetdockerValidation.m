function tests = test_isetdockerValidation()
% TEST_ISETDOCKERVALIDATION Unit tests for ISETDocker preference validation.

tests = functiontests(localfunctions);

end

%% ------------------------------------------------------------------------
function testValidRemotePrefsWithMatchingContext(testCase)
prefs = localBasePrefs();
contextInspect = localContextInspect('ssh://wandell@orange.stanford.edu');

report = isetdocker.validatePrefStruct(prefs, ...
    'checkDockerContext', true, ...
    'contextInspect', contextInspect);

testCase.verifyTrue(report.ok);
testCase.verifyEmpty(report.errors);
testCase.verifyEmpty(report.repairCommands);
end

%% ------------------------------------------------------------------------
function testMissingRequiredField(testCase)
prefs = rmfield(localBasePrefs(), 'dockerImage');

report = isetdocker.validatePrefStruct(prefs);

testCase.verifyFalse(report.ok);
testCase.verifyTrue(any(contains(report.errors, ...
    'ISETDocker.dockerImage is required.')));
end

%% ------------------------------------------------------------------------
function testValidLocalPrefsDoNotRequireRemoteResources(testCase)
prefs = localBasePrefs();
prefs.remoteHost = "";
prefs.remoteUser = "";
prefs.renderContext = "";
prefs = rmfield(prefs, 'PBRTResources');

report = isetdocker.validatePrefStruct(prefs);

testCase.verifyTrue(report.ok);
testCase.verifyEmpty(report.errors);
testCase.verifyTrue(any(contains(report.warnings, ...
    'local Docker will use the active Docker context')));
end

%% ------------------------------------------------------------------------
function testGpuPrefsRequireDeviceId(testCase)
prefs = localBasePrefs();
prefs.device = "gpu";
prefs.deviceID = "";

report = isetdocker.validatePrefStruct(prefs);

testCase.verifyFalse(report.ok);
testCase.verifyTrue(any(contains(report.errors, ...
    'ISETDocker.deviceID is required.')));
end

%% ------------------------------------------------------------------------
function testCpuPrefsDoNotRequireDeviceId(testCase)
prefs = localBasePrefs();
prefs.device = "cpu";
prefs.deviceID = "";

report = isetdocker.validatePrefStruct(prefs);

testCase.verifyTrue(report.ok);
testCase.verifyEmpty(report.errors);
end

%% ------------------------------------------------------------------------
function testNumericDeviceIdIsNormalized(testCase)
prefs = localBasePrefs();
prefs.deviceID = 1;

report = isetdocker.validatePrefStruct(prefs);

testCase.verifyTrue(report.ok);
testCase.verifyEqual(report.prefs.deviceID, "1");
end

%% ------------------------------------------------------------------------
function testRemoteUserRequiredForRemotePrefs(testCase)
prefs = localBasePrefs();
prefs.remoteUser = "";

report = isetdocker.validatePrefStruct(prefs);

testCase.verifyFalse(report.ok);
testCase.verifyTrue(any(contains(report.errors, ...
    'ISETDocker.remoteUser is required.')));
end

%% ------------------------------------------------------------------------
function testTransientContainerWarnsButDoesNotFail(testCase)
prefs = localBasePrefs();
prefs.PBRTContainer = "pbrt-gpu-wandell8872";

report = isetdocker.validatePrefStruct(prefs);

testCase.verifyTrue(report.ok);
testCase.verifyTrue(any(contains(report.warnings, ...
    'ISETDocker.PBRTContainer is transient')));
end

%% ------------------------------------------------------------------------
function testContextHostMismatchReportsRepairCommand(testCase)
prefs = localBasePrefs();
contextInspect = localContextInspect('ssh://wandell@orange');

report = isetdocker.validatePrefStruct(prefs, ...
    'checkDockerContext', true, ...
    'contextInspect', contextInspect);

testCase.verifyFalse(report.ok);
testCase.verifyTrue(any(contains(report.errors, ...
    'Docker context remote-orange points to ssh://wandell@orange')));
testCase.verifyEqual(report.repairCommands, ...
    "docker context update remote-orange --docker ""host=ssh://wandell@orange.stanford.edu""");
end

%% ------------------------------------------------------------------------
function testUnsafeContextValueFailsBeforeCommandConstruction(testCase)
prefs = localBasePrefs();
prefs.renderContext = "remote-orange;rm";

report = isetdocker.validatePrefStruct(prefs);

testCase.verifyFalse(report.ok);
testCase.verifyTrue(any(contains(report.errors, ...
    'must use shell-safe characters')));
end

%% ------------------------------------------------------------------------
function testUnknownFieldsWarnButDoNotFail(testCase)
prefs = localBasePrefs();
prefs.unexpectedField = "ignored";

report = isetdocker.validatePrefStruct(prefs);

testCase.verifyTrue(report.ok);
testCase.verifyTrue(any(contains(report.warnings, ...
    'Ignoring unknown ISETDocker field "unexpectedField"')));
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
    'PBRTResources', "/acorn/data/iset/PBRTResources");
end

%% ------------------------------------------------------------------------
function jsonText = localContextInspect(host)
jsonText = sprintf(['[{"Name":"remote-orange","Metadata":{},' ...
    '"Endpoints":{"docker":{"Host":"%s","SkipTLSVerify":false}},' ...
    '"TLSMaterial":{},"Storage":{}}]'], host);
end
