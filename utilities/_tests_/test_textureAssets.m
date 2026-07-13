function tests = test_textureAssets()
% TEST_TEXTUREASSETS - Unit tests for local material texture asset management
%
% These tests catch missing texture-library files before piWrite falls back
% from image maps to constant diffuse materials.
%
% See also:
%   piDirGet, piMaterialPresets, piMaterialsInsert, piTextureText, piWrite

tests = functiontests(localfunctions);

end

function testPatternTextureLibraryFilesExist(testCase)
%% Verify that the texture library used by material/chart presets is present.

textureDir = piDirGet('textures');
testCase.assertTrue(isfolder(textureDir), ...
    sprintf('Texture directory is missing: %s', textureDir));

requiredFiles = { ...
    'slantedbar.png', ...
    'ringsrays.png', ...
    'macbeth.png', ...
    'gridlines.png', ...
    'pointArray_512_64.png', ...
    'pointArray_1024_64.png', ...
    'squarewave_h_01.png', ...
    'squarewave_h_04.png', ...
    'squarewave_h_12.png', ...
    'squarewave_v_01.png', ...
    'squarewave_v_04.png', ...
    'squarewave_v_12.png', ...
    'EIA1956-300dpi.png', ...
    'EIA1956-300dpi-center.png', ...
    'EIA1956-300dpi-corner.png', ...
    'EIA1956-72dpi.png', ...
    'monochromeFace.png'};

for ii = 1:numel(requiredFiles)
    testCase.verifyTrue(isfile(fullfile(textureDir, requiredFiles{ii})), ...
        sprintf('Missing texture file: %s', requiredFiles{ii}));
end

end

function testCheckerboardPresetUsesValidTextureParameters(testCase)
%% Verify checkerboard preset does not pass stale texture parameter names.

lastwarn('');
thisR = piRecipeDefault('scene name', 'flatsurfacewhitetexture');
thisR = piMaterialsInsert(thisR, 'names', 'checkerboard');
[warningText, ~] = lastwarn;

testCase.verifyFalse(contains(warningText, 'spectrumtex1'), ...
    'Checkerboard preset used stale spectrumtex1 texture parameter.');
testCase.verifyFalse(contains(warningText, 'spectrumtex2'), ...
    'Checkerboard preset used stale spectrumtex2 texture parameter.');
testCase.verifyEqual(thisR.get('texture', 'checkerboard', 'tex1'), ...
    [0.05 0.05 0.05], 'AbsTol', 1e-12);
testCase.verifyEqual(thisR.get('texture', 'checkerboard', 'tex2'), ...
    [0.95 0.95 0.95], 'AbsTol', 1e-12);

end

function testSlantedEdgePresetWritesImageMapTexture(testCase)
%% Verify slantededge material writes and stages slantedbar.png.

localSuppressNoLightWarning(testCase);

thisR = localSlantedEdgeCornellRecipe(testCase, 'test_texture_assets');

piWrite(thisR);

localVerifySlantedEdgeOutput(testCase, thisR);

end

function testSlantedEdgePresetStagesTextureForOrdinaryRemoteRender(testCase)
%% Verify remote rendering without DB still stages texture files for rsync.

localSuppressNoLightWarning(testCase);
localSaveISETDockerPrefs(testCase);
localSetRemoteRenderPrefs();

thisR = localSlantedEdgeCornellRecipe(testCase, 'test_texture_assets_remote');
testCase.verifyFalse(logical(thisR.useDB), ...
    'This regression test covers ordinary remote rendering, not DB-backed resources.');

piWrite(thisR);

localVerifySlantedEdgeOutput(testCase, thisR);
testCase.verifyFalse(ispref('ISETDocker', 'remoteSceneDir'), ...
    'piWrite should clear the transient remoteSceneDir preference.');

end

function testResourceTextureStagesForOrdinaryRemoteRender(testCase)
%% Verify piResourceFind textures are staged and rewritten for remote upload.

localSuppressNoLightWarning(testCase);
localSaveISETDockerPrefs(testCase);
localSetRemoteRenderPrefs();

folderName = 'test_texture_assets_resource_remote';
testDir = fullfile(piRootPath, 'local', folderName);
if isfolder(testDir), rmdir(testDir, 's'); end
mkdir(testDir);
testCase.addTeardown(@() localRemoveDir(testDir));

thisR = piRecipeDefault('scene name', 'cornell_box');
thisR.outputFile = fullfile(testDir, sprintf('%s.pbrt', folderName));

textureName = 'slantedbar-resource';
thisM.texture = piTextureCreate(textureName, ...
    'format', 'spectrum', ...
    'type', 'imagemap', ...
    'filename', 'slantedbar.png');
thisM.material = piMaterialCreate(textureName, ...
    'type', 'diffuse', ...
    'reflectance val', textureName);

thisR.set('material', 'add', thisM);
thisR.set('asset', 'large_box_O', 'material name', textureName);

piWrite(thisR);

textureFile = fullfile(thisR.get('output dir'), 'textures', 'slantedbar.png');
testCase.verifyTrue(isfile(textureFile), ...
    sprintf('piWrite did not stage resource texture file: %s', textureFile));

[~, outputName] = fileparts(thisR.outputFile);
materialFile = fullfile(thisR.get('output dir'), sprintf('%s_materials.pbrt', outputName));
materialText = fileread(materialFile);
testCase.verifyTrue(contains(materialText, sprintf('Texture "%s" "spectrum" "imagemap"', textureName)), ...
    'The resource texture was not written as an imagemap.');
testCase.verifyTrue(contains(materialText, '"string filename" "textures/slantedbar.png"'), ...
    'The resource texture filename was not rewritten to the staged textures directory.');

[~, ~, textureList, missingTextures] = piRenderValidate(thisR);
testCase.verifyNotEmpty(textureList);
testCase.verifyEmpty(missingTextures, ...
    'piRenderValidate reported the resource texture missing after piWrite.');

end

function localSetRemoteRenderPrefs()
%% Set enough remote preferences for piWrite to use the remote render branch.

setpref('ISETDocker', 'remoteHost', 'orange.stanford.edu');
setpref('ISETDocker', 'remoteUser', 'wandell');
setpref('ISETDocker', 'renderContext', 'remote-orange');
setpref('ISETDocker', 'workDir', '/home/wandell/ISETRemoteRender');
setpref('ISETDocker', 'PBRTResources', '/acorn/data/iset/PBRTResources');
setpref('ISETDocker', 'device', 'gpu');
setpref('ISETDocker', 'deviceID', '0');
setpref('ISETDocker', 'dockerImage', 'vistalab/pbrt-v4-gpu');

end

function thisR = localSlantedEdgeCornellRecipe(testCase, folderName)
%% Build a Cornell box recipe with slantededge assigned to large_box_O.

testDir = fullfile(piRootPath, 'local', folderName);
if isfolder(testDir), rmdir(testDir, 's'); end
mkdir(testDir);
testCase.addTeardown(@() localRemoveDir(testDir));

thisR = piRecipeDefault('scene name', 'cornell_box');
thisR.outputFile = fullfile(testDir, sprintf('%s.pbrt', folderName));

assetName = 'large_box_O';
assetID = piAssetSearch(thisR, 'object name', assetName);
testCase.assertNotEmpty(assetID, ...
    sprintf('Expected Cornell box asset not found: %s', assetName));

thisR = piMaterialsInsert(thisR, 'names', 'slantededge');
thisR.set('asset', assetName, 'material name', 'slantededge');

end

function localVerifySlantedEdgeOutput(testCase, thisR)
%% Verify piWrite staged the texture and kept the imagemap material.

textureFile = fullfile(thisR.get('output dir'), 'textures', 'slantedbar.png');
testCase.verifyTrue(isfile(textureFile), ...
    sprintf('piWrite did not stage texture file: %s', textureFile));

[~, outputName] = fileparts(thisR.outputFile);
materialFile = fullfile(thisR.get('output dir'), sprintf('%s_materials.pbrt', outputName));
testCase.assertTrue(isfile(materialFile), ...
    sprintf('Material file was not written: %s', materialFile));

materialText = fileread(materialFile);
testCase.verifyTrue(contains(materialText, 'Texture "slantededge" "spectrum" "imagemap"'), ...
    'slantededge was not written as an imagemap texture.');
testCase.verifyTrue(contains(materialText, '"string filename" "textures/slantedbar.png"'), ...
    'slantededge texture filename was not rewritten to the staged textures directory.');
testCase.verifyFalse(contains(materialText, 'Texture "slantededge" "spectrum" "constant"'), ...
    'slantededge fell back to a constant diffuse texture.');

[~, ~, textureList, missingTextures] = piRenderValidate(thisR);
testCase.verifyNotEmpty(textureList);
testCase.verifyEmpty(missingTextures, ...
    'piRenderValidate reported missing staged textures after piWrite.');

end

function localSaveISETDockerPrefs(testCase)
%% Restore ISETDocker preferences after tests that intentionally mutate them.

hadPrefs = ispref('ISETDocker');
if hadPrefs
    oldPrefs = getpref('ISETDocker');
else
    oldPrefs = struct();
end
testCase.addTeardown(@() localRestoreISETDockerPrefs(hadPrefs, oldPrefs));

end

function localSuppressNoLightWarning(testCase)
%% Keep texture staging tests focused on texture behavior, not scene lighting.

warningState = warning('off','piRecipeDefault:NoLights');
testCase.addTeardown(@() warning(warningState));

end

function localRestoreISETDockerPrefs(hadPrefs, oldPrefs)
if ispref('ISETDocker')
    rmpref('ISETDocker');
end
if hadPrefs
    names = fieldnames(oldPrefs);
    for ii = 1:numel(names)
        setpref('ISETDocker', names{ii}, oldPrefs.(names{ii}));
    end
end

end

function localRemoveDir(dirName)
if isfolder(dirName)
    rmdir(dirName, 's');
end

end
