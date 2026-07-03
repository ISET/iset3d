function tests = test_sceneEyePiWRS()
% TEST_SCENEEYEPIWRS Core tests for sceneEye.piWRS wrapper behavior.

tests = functiontests(localfunctions);

end

%% ------------------------------------------------------------------------
function testShowFalseDoesNotOpenWindow(testCase)
stubDir = localInstallSceneEyeStubs(testCase);
cleanupPath = onCleanup(@() rmpath(stubDir)); %#ok<NASGU>

thisSE = sceneEye('simple scene', 'eye model', 'navarro');
thisSE.set('use pinhole', true);

thisSE.piWRS('show', false);

testCase.verifyTrue(isfile(fullfile(stubDir, 'piRenderCall.mat')));
testCase.verifyFalse(isfile(fullfile(stubDir, 'sceneWindowCalled.mat')), ...
    'sceneEye.piWRS(''show'', false) should not open sceneWindow.');
end

%% ------------------------------------------------------------------------
function testPinholeCameraRestoredAfterRenderFailure(testCase)
stubDir = localInstallSceneEyeStubs(testCase);
cleanupPath = onCleanup(@() rmpath(stubDir)); %#ok<NASGU>
save(fullfile(stubDir, 'piRenderThrow.mat'), 'stubDir');

thisSE = sceneEye('simple scene', 'eye model', 'navarro');
thisSE.set('use pinhole', true);
originalCamera = thisSE.recipe.get('camera');

testCase.verifyError(@() thisSE.piWRS('show', false), 'Stub:piRender');
testCase.verifyEqual(thisSE.recipe.get('camera'), originalCamera);
end

%% ------------------------------------------------------------------------
function testDockerWrapperAliasForwardedAsDocker(testCase)
stubDir = localInstallSceneEyeStubs(testCase);
cleanupPath = onCleanup(@() rmpath(stubDir)); %#ok<NASGU>

thisSE = sceneEye('simple scene', 'eye model', 'navarro');
thisSE.set('use pinhole', true);
legacyDocker = struct('label', 'legacy docker wrapper');

thisSE.piWRS('docker wrapper', legacyDocker, 'show', false);

call = load(fullfile(stubDir, 'piRenderCall.mat'));
testCase.verifyTrue(localHasName(call.renderArgs, 'docker'), ...
    'Legacy docker wrapper input should be forwarded to piRender as docker.');
testCase.verifyEqual(localValueForName(call.renderArgs, 'docker'), legacyDocker);
end

%% ------------------------------------------------------------------------
function stubDir = localInstallSceneEyeStubs(testCase)
stubDir = tempname;
mkdir(stubDir);
testCase.addTeardown(@() localRemoveDir(stubDir));

localWriteFunction(fullfile(stubDir, 'piWrite.m'), sprintf([ ...
    'function workingDir = piWrite(thisR,varargin)\n' ...
    'writeArgs = varargin;\n' ...
    'save(''%s'', ''writeArgs'');\n' ...
    'workingDir = thisR.get(''output dir'');\n' ...
    'end\n'], localMatlabPath(fullfile(stubDir, 'piWriteCall.mat'))));

localWriteFunction(fullfile(stubDir, 'piRender.m'), sprintf([ ...
    'function [obj, results, thisD] = piRender(thisR,varargin)\n' ...
    'if exist(''%s'', ''file'')\n' ...
    '    error(''Stub:piRender'', ''Stub piRender requested failure.'');\n' ...
    'end\n' ...
    'renderArgs = varargin;\n' ...
    'save(''%s'', ''renderArgs'');\n' ...
    'obj = struct(''type'', ''scene'');\n' ...
    'results = ''stub results'';\n' ...
    'thisD = [];\n' ...
    'end\n'], ...
    localMatlabPath(fullfile(stubDir, 'piRenderThrow.mat')), ...
    localMatlabPath(fullfile(stubDir, 'piRenderCall.mat'))));

localWriteFunction(fullfile(stubDir, 'sceneWindow.m'), sprintf([ ...
    'function sceneWindow(varargin)\n' ...
    'save(''%s'', ''varargin'');\n' ...
    'end\n'], localMatlabPath(fullfile(stubDir, 'sceneWindowCalled.mat'))));

localWriteFunction(fullfile(stubDir, 'oiWindow.m'), sprintf([ ...
    'function oiWindow(varargin)\n' ...
    'save(''%s'', ''varargin'');\n' ...
    'end\n'], localMatlabPath(fullfile(stubDir, 'oiWindowCalled.mat'))));

addpath(stubDir, '-begin');
end

%% ------------------------------------------------------------------------
function tf = localHasName(args, name)
tf = false;
for ii = 1:2:numel(args)
    if ischar(args{ii}) || isstring(args{ii})
        tf = strcmpi(ieParamFormat(args{ii}), name);
        if tf, return; end
    end
end
end

%% ------------------------------------------------------------------------
function value = localValueForName(args, name)
value = [];
for ii = 1:2:numel(args)
    if ischar(args{ii}) || isstring(args{ii})
        if strcmpi(ieParamFormat(args{ii}), name)
            value = args{ii+1};
            return;
        end
    end
end
end

%% ------------------------------------------------------------------------
function localWriteFunction(fileName, contents)
fid = fopen(fileName, 'w');
assert(fid > 0, 'Could not create stub function: %s', fileName);
cleaner = onCleanup(@() fclose(fid));
fprintf(fid, '%s', contents);
clear cleaner;
end

%% ------------------------------------------------------------------------
function pathText = localMatlabPath(pathText)
pathText = strrep(pathText, '''', '''''');
end

%% ------------------------------------------------------------------------
function localRemoveDir(dirName)
if exist(dirName, 'dir')
    rmdir(dirName, 's');
end
end
