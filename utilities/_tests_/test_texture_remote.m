function tests = test_texture_remote()
% TEST_TEXTURE_REMOTE - Remote validation for texture renders with Docker
%
% This test is classified as _remote and is skipped in 'core' mode.
% It requires a running Docker environment and a remote rendering GPU.
%
% See also:
%   piRecipeCreate, piMaterialsInsert, piAssetSearch, piWRS

tests = functiontests(localfunctions);

end

function testTextureRender(testCase)
%% Test creating, inserting, and configuring textures.

ieInit;
if ~piDockerExists
    try
        piDockerConfig;
    catch
        testCase.verifyFail('Docker configuration failed.');
        return;
    end
end

thisR = piRecipeCreate('flatsurfacewhitetexture');
cubeIDX = piAssetSearch(thisR, 'object name', 'Cube');
testCase.assertNotEmpty(cubeIDX);

% 1. Render default texture
try
    piWRS(thisR, 'show', false, 'name', 'random color');
catch exception
    testCase.verifyFail(sprintf('piWRS default flatsurfacewhitetexture failed: %s', exception.message));
end

% 2. Insert and set checkerboard texture
thisR = piMaterialsInsert(thisR, 'names', 'checkerboard');
thisR.set('asset', cubeIDX, 'material name', 'checkerboard');

try
    piWRS(thisR, 'show', false, 'name', 'checks');
catch exception
    testCase.verifyFail(sprintf('piWRS checks failed: %s', exception.message));
end

% 3. Insert and set dots texture
thisR = piMaterialsInsert(thisR, 'names', 'dots');
thisR.set('asset', cubeIDX, 'material name', 'dots');

try
    piWRS(thisR, 'show', false, 'name', 'dots-orig');
catch exception
    testCase.verifyFail(sprintf('piWRS dots-orig failed: %s', exception.message));
end

% 4. Set dot scaling factors and re-render
thisR.set('texture', 'dots', 'vscale', 16);
thisR.set('texture', 'dots', 'uscale', 16);

try
    piWRS(thisR, 'show', false, 'name', 'dots-scale');
catch exception
    testCase.verifyFail(sprintf('piWRS dots-scale failed: %s', exception.message));
end

end
