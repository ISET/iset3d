function tests = test_materials_remote()
% TEST_MATERIALS_REMOTE - Remote validation for material preset renders with Docker
%
% This test is classified as _remote and is skipped in 'core' mode.
% It requires a running Docker environment and a remote rendering GPU.
%
% See also:
%   piRecipeDefault, piMaterialsInsert, piWRS, sceneGet

tests = functiontests(localfunctions);

end

function testBunnyMaterialsRender(testCase)
%% Test rendering the Bunny scene with various materials.

ieInit;
if ~piDockerExists
    try
        piDockerConfig;
    catch
        testCase.verifyFail('Docker configuration failed.');
        return;
    end
end

% 1. Load the bunny recipe and scale the bunny asset
thisR = piRecipeDefault('scene name', 'bunny');
thisR.set('skymap', 'room.exr');

bunnyIDX = piAssetSearch(thisR, 'object name', 'Bunny');
thisR.set('asset', bunnyIDX, 'scale', 4);
thisR.set('nbounces', 3);

% 2. Insert and set glossy-red material
thisR = piMaterialsInsert(thisR, 'names', 'glossy-red');
thisR.set('asset', bunnyIDX, 'material name', 'glossy-red');

try
    scene = piWRS(thisR, 'show', false, 'speed', 4);
catch exception
    testCase.verifyFail(sprintf('piWRS glossy-red failed: %s', exception.message));
    return;
end

% 3. Check photon sum
p = sceneGet(scene, 'photons');
testCase.verifyLessThan(abs(sum(p(:)) / 7.0357e+20 - 1), 0.05);

% 4. Test setting other materials (glossy-black, mirror, glass) without failing
thisR = piMaterialsInsert(thisR, 'names', {'glossy-black', 'mirror', 'glass'});

% Glossy-black
thisR.set('asset', bunnyIDX, 'material name', 'glossy-black');
try
    piWRS(thisR, 'show', false, 'speed', 4);
catch exception
    testCase.verifyFail(sprintf('piWRS glossy-black failed: %s', exception.message));
end

% Mirror
thisR.set('asset', bunnyIDX, 'material name', 'mirror');
try
    piWRS(thisR, 'show', false, 'speed', 4);
catch exception
    testCase.verifyFail(sprintf('piWRS mirror failed: %s', exception.message));
end

% Glass
thisR.set('asset', bunnyIDX, 'material name', 'glass');
try
    piWRS(thisR, 'show', false, 'speed', 4);
catch exception
    testCase.verifyFail(sprintf('piWRS glass failed: %s', exception.message));
end

end
