function tests = test_piRender_remote()
% TEST_PIRENDER_REMOTE - Remote validation for rendering SimpleScene with Docker
%
% This test is classified as _remote and is skipped in 'core' mode.
% It requires a running Docker environment and a remote rendering GPU.
%
% See also:
%   piRecipeDefault, piWRS, sceneGet

tests = functiontests(localfunctions);

end

function testSimpleSceneRender(testCase)
%% Test rendering SimpleScene and verifying numeric luminance and depth

% 1. Start up ISET and verify docker config
ieInit;
if ~piDockerExists
    try
        piDockerConfig;
    catch ME
        testCase.assumeFail( ...
            sprintf('Docker not available, skipping: %s', ME.message));
        return;
    end
end

% 2. Read SimpleScene recipe
thisR = piRecipeDefault('scene name', 'SimpleScene');

% 3. Configure rendering quality
thisR.set('film resolution', [128, 96]);
thisR.set('rays per pixel', 32);
thisR.set('n bounces', 2);
thisR.set('render type', {'radiance', 'depth'});

% 4. Render the scene
try
    scene = piWRS(thisR, 'show', false);
catch ME
    testCase.verifyFail(sprintf('piWRS failed: %s', ME.message));
    return;
end

% 5. Assert numeric properties on the rendered scene
testCase.verifyEqual(scene.type, 'scene');
testCase.verifyEqual(sceneGet(scene, 'rows'), 96);
testCase.verifyEqual(sceneGet(scene, 'cols'), 128);
testCase.verifyEqual(sceneGet(scene, 'mean luminance'), 100, 'RelTol', 0.01);
sceneDistance = double(sceneGet(scene, 'distance'));
testCase.verifyGreaterThan(sceneDistance, 0);
testCase.verifyLessThan(sceneDistance, 100);

depthMap = sceneGet(scene, 'depth map');
foregroundDepth = depthMap(depthMap > 0);
testCase.assertNotEmpty(foregroundDepth);
testCase.verifyGreaterThan(min(foregroundDepth), 0);
testCase.verifyLessThan(max(foregroundDepth), 100);

photons = sceneGet(scene, 'photons');
testCase.verifyGreaterThanOrEqual(min(photons(:)), 0);

end
