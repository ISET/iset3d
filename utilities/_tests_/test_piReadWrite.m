function tests = test_piReadWrite()
% TEST_PIREADWRITE - Unit tests for PBRT file reading (piRead) and writing (piWrite)
%
% This test builds a self-contained mock PBRT file structure, parses it into
% a recipe, modifies it, writes it back, and verifies the parsed round-trip properties.
%
% See also:
%   piRead, piWrite, recipe

tests = functiontests(localfunctions);

end

function testRemoteScenePrefCleanedAfterWriteFailure(testCase)
%% Test transient remoteSceneDir preference cleanup on piWrite errors.

localSaveISETDockerPrefs(testCase);
setpref('ISETDocker','remoteHost','orange.stanford.edu');
setpref('ISETDocker','workDir','/home/wandell/ISETRemoteRender');

thisR = piRecipeDefault('scene name', 'SimpleScene');
thisR.outputFile = fullfile('/dev/null','bad_scene.pbrt');

didError = false;
try
    piWrite(thisR);
catch
    didError = true;
end
testCase.verifyTrue(didError);
testCase.verifyFalse(ispref('ISETDocker','remoteSceneDir'));

end

function testReadWriteRoundTrip(testCase)
%% Test reading a minimal PBRT file and writing it back with updates.

% 1. Create a minimal valid PBRT structure
mockContent = { ...
    'LookAt 0 0 0  0 0 -1  0 1 0', ...
    'Camera "pinhole" "float fov" [45]', ...
    'Film "rgb" "integer xresolution" [200] "integer yresolution" [150]', ...
    'Sampler "halton" "integer pixelsamples" [32]', ...
    'Integrator "path"', ...
    'WorldBegin', ...
    'LightSource "distant" "point3 from" [0 10 0]', ...
    'Material "diffuse"', ...
    'Shape "sphere" "float radius" [1]', ...
    'WorldEnd' ...
};

tempDir = fullfile(piRootPath, 'local', 'test_temp');
if ~isfolder(tempDir), mkdir(tempDir); end
cleanupFolder = onCleanup(@() rmdir(tempDir, 's'));

inputFile = fullfile(tempDir, 'mock_scene.pbrt');
outputFile = fullfile(tempDir, 'mock_scene_out.pbrt');

fid = fopen(inputFile, 'w');
testCase.assertGreaterThan(fid, 0);
for ii = 1:numel(mockContent)
    fprintf(fid, '%s\n', mockContent{ii});
end
fclose(fid);

% 2. Read the mock PBRT file
[thisR, ~] = piRead(inputFile);

% Verify parsed camera and film options
testCase.verifyEqual(thisR.get('camera subtype'), 'pinhole');
testCase.verifyEqual(thisR.get('fov'), 45);
testCase.verifyEqual(thisR.get('film resolution'), [200, 150]);

% 3. Modify options
thisR.set('film resolution', [400, 300]);
thisR.set('fov', 60);
thisR.outputFile = outputFile;

% 4. Write out the modified PBRT file
piWrite(thisR);

% Verify output file exists
testCase.verifyTrue(isfile(outputFile));

% 5. Read the output file back and verify updates
[roundTripR, ~] = piRead(outputFile);

testCase.verifyEqual(roundTripR.get('film resolution'), [400, 300]);
testCase.verifyEqual(roundTripR.get('fov'), 60);

end

function testRemoteLensPathRestoredAfterWrite(testCase)
%% Test piWrite restores lens paths temporarily rewritten for remote render.

localSaveISETDockerPrefs(testCase);
setpref('ISETDocker','remoteHost','orange.stanford.edu');
setpref('ISETDocker','workDir','/home/wandell/ISETRemoteRender');

tempDir = fullfile(piRootPath, 'local', 'test_lens_restore');
if ~isfolder(tempDir), mkdir(tempDir); end
testCase.addTeardown(@() localRemoveDir(tempDir));

thisR = piRecipeDefault('scene name', 'SimpleScene');
thisR.camera = piCameraCreate('omni','lens file','dgauss.22deg.3.0mm.json');
thisR.outputFile = fullfile(tempDir, 'lens_restore.pbrt');

originalLensFile = thisR.get('lensfile');
piWrite(thisR);

testCase.verifyEqual(thisR.get('lensfile'), originalLensFile);
testCase.verifyFalse(ispref('ISETDocker','remoteSceneDir'));

end

function testLocalWriteCopiesLensFile(testCase)
%% Test a local render finds the lens file the PBRT scene file refers to.

localSaveISETDockerPrefs(testCase);
setpref('ISETDocker','remoteHost','');

[thisR, lensCopy] = localLensRecipe(testCase, 'test_lens_local');
originalLensFile = thisR.get('lensfile');
piWrite(thisR);

testCase.verifyTrue(isfile(lensCopy));
testCase.verifySubstring(fileread(thisR.get('output file')), ...
    '"string lensfile" "lens/dgauss.22deg.3.0mm.json"');
testCase.verifyEqual(thisR.get('lensfile'), originalLensFile);

end

function testRemoteWriteCopiesLensFile(testCase)
%% Test a remote render uploads the lens file the PBRT scene file refers to.

localSaveISETDockerPrefs(testCase);
setpref('ISETDocker','remoteHost','orange.stanford.edu');
setpref('ISETDocker','workDir','/home/wandell/ISETRemoteRender');

[thisR, lensCopy] = localLensRecipe(testCase, 'test_lens_remote');
piWrite(thisR);

testCase.verifyTrue(isfile(lensCopy));
testCase.verifySubstring(fileread(thisR.get('output file')), ...
    '"string lensfile" "lens/dgauss.22deg.3.0mm.json"');

end

function testLensOutsideMatlabPathIsCopied(testCase)
%% Test a lens file that is not on the MATLAB path, as in a microlens build.

localSaveISETDockerPrefs(testCase);
setpref('ISETDocker','remoteHost','');

[thisR, ~] = localLensRecipe(testCase, 'test_lens_outside');

sourceDir = tempname;
mkdir(sourceDir);
testCase.addTeardown(@() localRemoveDir(sourceDir));
sourceLens = fullfile(sourceDir, 'custom.lens.json');
copyfile(thisR.get('lensfile'), sourceLens);
thisR.camera = piCameraCreate('omni','lens file',sourceLens);

piWrite(thisR);

testCase.verifyTrue(isfile(fullfile(thisR.get('output dir'),'lens','custom.lens.json')));
testCase.verifySubstring(fileread(thisR.get('output file')), ...
    '"string lensfile" "lens/custom.lens.json"');
testCase.verifyEqual(thisR.get('lensfile'), sourceLens);

end

function testNewerLensReplacesCopy(testCase)
%% Test piWrite refreshes a lens copy that is older than its source.

localSaveISETDockerPrefs(testCase);
setpref('ISETDocker','remoteHost','');

[thisR, lensCopy] = localLensRecipe(testCase, 'test_lens_newer');
original = fileread(thisR.get('lensfile'));

localWriteText(lensCopy, 'stale');
java.io.File(lensCopy).setLastModified(0);
piWrite(thisR);

testCase.verifyEqual(fileread(lensCopy), original);

end

function testOverwriteLensFileReplacesCopy(testCase)
%% Test piWrite keeps a copy newer than its source unless asked to replace it.

localSaveISETDockerPrefs(testCase);
setpref('ISETDocker','remoteHost','');

[thisR, lensCopy] = localLensRecipe(testCase, 'test_lens_overwrite');
original = fileread(thisR.get('lensfile'));

localWriteText(lensCopy, 'edited');
piWrite(thisR);
testCase.verifyEqual(fileread(lensCopy), 'edited');

piWrite(thisR, 'overwrite lens file', true);
testCase.verifyEqual(fileread(lensCopy), original);

end

function testPiWRSForwardsOverwriteLensFile(testCase)
%% Test piWRS passes the lens overwrite flag to piWrite.
%
% piRender rejects a docker that is not an isetdocker before it starts
% anything, so this reaches piWrite without needing Docker.

localSaveISETDockerPrefs(testCase);
setpref('ISETDocker','remoteHost','');

[thisR, lensCopy] = localLensRecipe(testCase, 'test_lens_piwrs');
original = fileread(thisR.get('lensfile'));

localWriteText(lensCopy, 'stale');
testCase.verifyError(@() piWRS(thisR, 'docker', struct('verbosity', 0), ...
    'overwrite lens file', true, 'show', false), ?MException);
testCase.verifyEqual(fileread(lensCopy), original);

end

function testRadianceEXRPreservesSingletonRow(testCase)
%% Test spectral EXR reads preserve a one-row image shape.

testCase.assumeTrue(exist('exrwrite','file') > 0, ...
    'MATLAB exrwrite is required for this test.');

tempDir = fullfile(tempdir, 'iset3d_exr_singleton_row');
if ~isfolder(tempDir), mkdir(tempDir); end
testCase.addTeardown(@() localRemoveDir(tempDir));

exrFile = fullfile(tempDir, 'radiance_row.exr');
localWriteRadianceEXR(exrFile, 1, 17);

data = piReadEXR(exrFile, 'data type', 'radiance');
testCase.verifyEqual(size(data), [1 17 31]);

end

function testRadianceEXRPreservesSingletonColumn(testCase)
%% Test spectral EXR reads preserve a one-column image shape.

testCase.assumeTrue(exist('exrwrite','file') > 0, ...
    'MATLAB exrwrite is required for this test.');

tempDir = fullfile(tempdir, 'iset3d_exr_singleton_column');
if ~isfolder(tempDir), mkdir(tempDir); end
testCase.addTeardown(@() localRemoveDir(tempDir));

exrFile = fullfile(tempDir, 'radiance_column.exr');
localWriteRadianceEXR(exrFile, 19, 1);

data = piReadEXR(exrFile, 'data type', 'radiance');
testCase.verifyEqual(size(data), [19 1 31]);

end

function localSaveISETDockerPrefs(testCase)
%% Restore ISETDocker preferences after tests that intentionally mutate them.

hadPrefs = ispref('ISETDocker');
if hadPrefs
    oldPrefs = getpref('ISETDocker');
else
    oldPrefs = struct();
end
testCase.addTeardown(@() localRestoreISETDockerPrefs(hadPrefs,oldPrefs));

end

function localRestoreISETDockerPrefs(hadPrefs,oldPrefs)
if ispref('ISETDocker')
    rmpref('ISETDocker');
end
if hadPrefs
    names = fieldnames(oldPrefs);
    for ii = 1:numel(names)
        setpref('ISETDocker',names{ii},oldPrefs.(names{ii}));
    end
end

end

function [thisR, lensCopy] = localLensRecipe(testCase, dirName)
%% A lens camera recipe, with a clean output folder removed after the test.

tempDir = fullfile(piRootPath, 'local', dirName);
localRemoveDir(tempDir);
mkdir(tempDir);
testCase.addTeardown(@() localRemoveDir(tempDir));

thisR = piRecipeDefault('scene name', 'SimpleScene');
thisR.camera = piCameraCreate('omni','lens file','dgauss.22deg.3.0mm.json');
thisR.outputFile = fullfile(tempDir, [dirName '.pbrt']);

lensCopy = fullfile(tempDir, 'lens', 'dgauss.22deg.3.0mm.json');
if ~isfolder(fileparts(lensCopy)), mkdir(fileparts(lensCopy)); end

end

function localWriteText(fileName, str)
fid = fopen(fileName, 'w');
fprintf(fid, '%s', str);
fclose(fid);
end

function localRemoveDir(dirName)
if exist(dirName, 'dir')
    rmdir(dirName, 's');
end

end

function localWriteRadianceEXR(exrFile, nRows, nCols)
channels = strings(1,31);
channelData = cell(1,31);
for ii = 1:31
    channels(ii) = sprintf('Radiance.C%02d',ii);
    channelData{ii} = single(ii + reshape(1:(nRows*nCols), nRows, nCols));
end

exrwrite(channelData, exrFile, Channels = channels, OutputType = "single");

end
