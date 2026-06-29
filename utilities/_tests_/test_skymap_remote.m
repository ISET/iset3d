function tests = test_skymap_remote()
% TEST_SKYMAP_REMOTE - Remote validation for skymap renders with Docker
%
% This test is classified as _remote and is skipped in 'core' mode.
% It requires a running Docker environment and a remote rendering GPU.
%
% See also:
%   piRecipeDefault, piWRS

tests = functiontests(localfunctions);

end

function testSkymapRender(testCase)
%% Test setting different environment skymaps and rendering.

ieInit;
if ~piDockerExists
    try
        piDockerConfig;
    catch
        testCase.verifyFail('Docker configuration failed.');
        return;
    end
end

% 1. Test room.exr skymap on sphere
thisR = piRecipeDefault('scene name', 'sphere');
thisR.set('skymap', 'room.exr');
try
    piWRS(thisR, 'show', false);
catch exception
    testCase.verifyFail(sprintf('piWRS room.exr failed: %s', exception.message));
end

% 2. Test cathedral_interior.exr
thisR = piRecipeDefault('scene name', 'sphere');
thisR.set('skymap', 'cathedral_interior.exr');
try
    piWRS(thisR, 'show', false);
catch exception
    testCase.verifyFail(sprintf('piWRS cathedral_interior.exr failed: %s', exception.message));
end

% 3. Test equiarea-rainbow.exr
thisR = piRecipeDefault('scene name', 'sphere');
thisR.set('skymap', 'equiarea-rainbow.exr');
try
    piWRS(thisR, 'show', false);
catch exception
    testCase.verifyFail(sprintf('piWRS equiarea-rainbow.exr failed: %s', exception.message));
end

end
