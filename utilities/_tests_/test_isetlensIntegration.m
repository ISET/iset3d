function tests = test_isetlensIntegration()
% TEST_ISETLENSINTEGRATION - ISET3d-side tests for optional isetlens paths.
%
% These tests protect the ISET3d integration points that should become safer
% before isetlens is merged into this repository.  Tests that require isetlens
% skip when lensC/lensFocus are not on the MATLAB path.

tests = functiontests(localfunctions);

end

%% ------------------------------------------------------------------------
function testRecipeLensQueriesWithoutIsetlens(testCase)
%% Current no-isetlens behavior: lens-derived quantities are unavailable.

localRequireNoLensFocus(testCase);

thisR = localOmniRecipe();
thisR.set('film diagonal',3);
thisR.set('focal distance',1);

lastwarn('');
evalc('filmDistance = thisR.get(''film distance'',''mm'');');
[warnMsg,~] = lastwarn();
testCase.verifyEmpty(filmDistance);
testCase.verifyTrue(contains(warnMsg,'Add isetlens to your path'), ...
    'Missing lensFocus should produce an actionable film-distance warning.');

lastwarn('');
evalc('fov = thisR.get(''fov'');');
[warnMsg,~] = lastwarn();
testCase.verifyEmpty(fov);
testCase.verifyTrue(contains(warnMsg,'To calculate FOV of a lens'), ...
    'Missing lensFocus should produce an actionable FOV warning.');

end

%% ------------------------------------------------------------------------
function testRecipeLensQueriesWithIsetlens(testCase)
%% Recipe lens queries should agree with the underlying isetlens calculation.

localRequireIsetlens(testCase);

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

localRequireIsetlens(testCase);

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

localRequireIsetlens(testCase);

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
function localRequireNoLensFocus(testCase)
if ~isempty(which('lensFocus'))
    testCase.assumeFail('lensFocus is already on the path; no-isetlens behavior is not applicable.');
end
end

%% ------------------------------------------------------------------------
function localRequireIsetlens(testCase)
if isempty(which('lensC')) || isempty(which('lensFocus'))
    repoRoot = fullfile(piRootPath,'..','isetlens');
    if isfolder(repoRoot)
        oldPath = path;
        addpath(genpath(repoRoot));
        testCase.addTeardown(@() path(oldPath));
    end
end

if isempty(which('lensC')) || isempty(which('lensFocus'))
    testCase.assumeFail('isetlens is not available on the MATLAB path.');
end
end

%% ------------------------------------------------------------------------
function localRemoveDir(dirName)
if exist(dirName,'dir')
    rmdir(dirName,'s');
end
end
