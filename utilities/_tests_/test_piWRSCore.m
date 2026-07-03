function tests = test_piWRSCore()
% TEST_PIWRSCORE Core tests for piWRS orchestration without Docker/PBRT.

tests = functiontests(localfunctions);

end

%% ------------------------------------------------------------------------
function testRecipeStateRestoredAfterSuccessfulRender(testCase)
stubDir = localInstallPiWRSStubs(testCase);
cleanupPath = onCleanup(@() rmpath(stubDir)); %#ok<NASGU>

thisR = localSimpleRecipe();
originalRenderType = thisR.get('render type');
originalResolution = thisR.get('film resolution');
originalBounces = thisR.get('nbounces');
originalRays = thisR.get('rays per pixel');

piWRS(thisR, ...
    'docker', struct(), ...
    'show', false, ...
    'rendertype', 'normal', ...
    'speed', 2);

testCase.verifyEqual(thisR.get('render type'), originalRenderType);
testCase.verifyEqual(thisR.get('film resolution'), originalResolution);
testCase.verifyEqual(thisR.get('nbounces'), originalBounces);
testCase.verifyEqual(thisR.get('rays per pixel'), originalRays);
end

%% ------------------------------------------------------------------------
function testRecipeStateRestoredAfterRenderFailure(testCase)
stubDir = localInstallPiWRSStubs(testCase);
cleanupPath = onCleanup(@() rmpath(stubDir)); %#ok<NASGU>
save(fullfile(stubDir, 'piRenderThrow.mat'), 'stubDir');

thisR = localSimpleRecipe();
originalRenderType = thisR.get('render type');
originalResolution = thisR.get('film resolution');
originalBounces = thisR.get('nbounces');
originalRays = thisR.get('rays per pixel');

testCase.verifyError(@() piWRS(thisR, ...
    'docker', struct(), ...
    'show', false, ...
    'rendertype', 'normal', ...
    'speed', 2), ...
    'Stub:piRender');

testCase.verifyEqual(thisR.get('render type'), originalRenderType);
testCase.verifyEqual(thisR.get('film resolution'), originalResolution);
testCase.verifyEqual(thisR.get('nbounces'), originalBounces);
testCase.verifyEqual(thisR.get('rays per pixel'), originalRays);
end

%% ------------------------------------------------------------------------
function testWriteOptionsForwardedToPiWrite(testCase)
stubDir = localInstallPiWRSStubs(testCase);
cleanupPath = onCleanup(@() rmpath(stubDir)); %#ok<NASGU>

thisR = localSimpleRecipe();
piWRS(thisR, ...
    'docker', struct(), ...
    'show', false, ...
    'main file only', true);

call = load(fullfile(stubDir, 'piWriteCall.mat'));
testCase.verifyTrue(localHasName(call.writeArgs, 'mainfileonly'), ...
    'piWRS should forward mainfileonly to piWrite.');
testCase.verifyEqual(localValueForName(call.writeArgs, 'mainfileonly'), true);
end

%% ------------------------------------------------------------------------
function thisR = localSimpleRecipe()
thisR = piRecipeDefault('scene name', 'SimpleScene');
thisR.set('film resolution', [64 48]);
thisR.set('rays per pixel', 16);
thisR.set('nbounces', 3);
thisR.set('render type', {'radiance', 'depth'});
end

%% ------------------------------------------------------------------------
function stubDir = localInstallPiWRSStubs(testCase)
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
