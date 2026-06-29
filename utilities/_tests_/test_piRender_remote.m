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
    catch
        testCase.verifyFail('Docker configuration failed.');
        return;
    end
end

% 2. Read SimpleScene recipe
thisR = piRecipeDefault('scene name', 'SimpleScene');

% 3. Configure rendering quality
thisR.set('film resolution', [256, 256]);
thisR.set('rays per pixel', 64);
thisR.set('n bounces', 2);
thisR.set('render type', {'radiance', 'depth'});

% 4. Render the scene
try
    scene = piWRS(thisR, 'show', false);
catch exception
    testCase.verifyFail(sprintf('piWRS failed: %s', exception.message));
    return;
end

% 5. Assert numeric properties on the rendered scene
testCase.verifyLessThan(abs(sceneGet(scene, 'mean luminance') - 100), 1e-2);
testCase.verifyLessThan(abs(sceneGet(scene, 'distance') / 11.867 - 1.0), 1e-3);

end
