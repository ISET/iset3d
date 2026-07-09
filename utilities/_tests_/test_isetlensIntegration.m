function tests = test_isetlensIntegration()
% TEST_ISETLENSINTEGRATION - ISET3d-side tests for in-tree lens paths.
%
% These tests protect ISET3d integration points that depend on the imported
% ISETLens runtime code.

tests = functiontests(localfunctions);

end

%% ------------------------------------------------------------------------
function testLensRootCompatibility(testCase)
%% ilensRootPath should point at the imported in-tree lens subtree.

localRequireLensRuntime(testCase);

lensRoot = ilensRootPath();
testCase.verifyEqual(lensRoot,fullfile(piRootPath,'lens'));
testCase.verifyTrue(isfolder(fullfile(lensRoot,'@lensC')));
testCase.verifyTrue(isfolder(fullfile(lensRoot,'utility','lens')));

end

%% ------------------------------------------------------------------------
function testRecipeLensQueriesWithInTreeLens(testCase)
%% Recipe lens queries should agree with the imported lens calculation.

localRequireLensRuntime(testCase);

thisR = localOmniRecipe();
thisR.set('film diagonal',3);
thisR.set('focal distance',1);

lensFile = thisR.get('lens file');
expectedFilmDistanceMM = lensFocus(lensFile,1e3);
expectedFov = 2*atand((3/2) / lensFocus(lensFile,1e6));

testCase.verifyEqual(thisR.get('film distance','mm'), ...
    expectedFilmDistanceMM,'RelTol',1e-10);
testCase.verifyEqual(thisR.get('fov'),expectedFov,'RelTol',1e-10);

% Golden values from the current dgauss.22deg.3.0mm.json local lens model.
testCase.verifyEqual(expectedFilmDistanceMM,2.17551665624,'RelTol',1e-9);
testCase.verifyEqual(expectedFov,69.3978027947,'RelTol',1e-9);

end

%% ------------------------------------------------------------------------
function testMicrolensInsertWithStandardLenses(testCase)
%% piMicrolensInsert should produce a stable combined-lens JSON structure.

localRequireLensRuntime(testCase);

tempDir = fullfile(piRootPath,'local','test_isetlensIntegration');
if ~isfolder(tempDir), mkdir(tempDir); end
testCase.addTeardown(@() localRemoveDir(tempDir));

microLensFile = fullfile(piDirGet('lens'),'microlens.json');
imagingLensFile = fullfile(piDirGet('lens'),'dgauss.22deg.3.0mm.json');
combinedLensFile = fullfile(tempDir,'microlens-combined.json');

[combinedLensName,info] = piMicrolensInsert( ...
    microLensFile,imagingLensFile, ...
    'output name',combinedLensFile, ...
    'n microlens',[2 3], ...
    'quiet',true);

testCase.verifyEqual(combinedLensName,combinedLensFile);
testCase.verifyTrue(isfile(combinedLensFile));
testCase.verifyEqual(info.combinedLens.microlens.dimensions,[2; 3]);
testCase.verifySize(info.combinedLens.microlens.offsets,[6 2]);
testCase.verifyEqual(info.combinedLens.microlens.offsets,zeros(6,2));
testCase.verifyGreaterThan(numel(info.combinedLens.surfaces),0);
testCase.verifyGreaterThan(numel(info.combinedLens.microlens.surfaces),0);

end

%% ------------------------------------------------------------------------
function testStandardLensLocalIntegration(testCase)
%% Non-Docker integration with a standard lens file.

localRequireLensRuntime(testCase);

lensFile = fullfile(piDirGet('lens'),'dgauss.22deg.3.0mm.json');
thisLens = lensC('filename',lensFile);

testCase.verifyEqual(thisLens.get('n surfaces'),11);
testCase.verifyEqual(thisLens.get('lens diameter','mm'),1.51199996471, ...
    'RelTol',1e-9);
testCase.verifyEqual(thisLens.get('lens thickness'),1.92240003310, ...
    'RelTol',1e-9);

filmDistanceInf = lensFocus(thisLens,1e6);
filmDistance1m = lensFocus(thisLens,1e3);

testCase.verifyEqual(filmDistanceInf,2.16636385915,'RelTol',1e-9);
testCase.verifyEqual(filmDistance1m,2.17551665624,'RelTol',1e-9);
testCase.verifyGreaterThan(filmDistance1m,filmDistanceInf);

end

%% ------------------------------------------------------------------------
function thisR = localOmniRecipe()
thisR = piRecipeDefault('scene name','chessset');
thisR.camera = piCameraCreate('omni','lens file','dgauss.22deg.3.0mm.json');
end

%% ------------------------------------------------------------------------
function localRequireLensRuntime(testCase)
lensRoot = fullfile(piRootPath,'lens');
oldPath = path;
addpath(genpath(lensRoot),'-begin');
testCase.addTeardown(@() path(oldPath));

lensConstructor = which('lensC');
lensFocusFile = which('lensFocus');

testCase.assertNotEmpty(lensConstructor, ...
    'lensC should be available from the in-tree ISET3D lens runtime.');
testCase.assertNotEmpty(lensFocusFile, ...
    'lensFocus should be available from the in-tree ISET3D lens runtime.');
testCase.verifyTrue(startsWith(lensConstructor,fullfile(lensRoot,'@lensC')), ...
    'lensC should resolve to the imported ISET3D lens subtree.');
testCase.verifyTrue(startsWith(lensFocusFile,fullfile(lensRoot,'utility','lens')), ...
    'lensFocus should resolve to the imported ISET3D lens subtree.');
end

%% ------------------------------------------------------------------------
function localRemoveDir(dirName)
if exist(dirName,'dir')
    rmdir(dirName,'s');
end
end
