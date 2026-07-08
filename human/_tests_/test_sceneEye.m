function tests = test_sceneEye()
% TEST_SCENEEYE - Unit tests for sceneEye human model configurations
%
% See also:
%   sceneEye, eyeGet, eyeSet

tests = functiontests(localfunctions);

end

function testSceneEyeConstructor(testCase)
%% Test creating a sceneEye object and verifying default model properties.

% Create a Navarro eye model on a simple scene
eye = sceneEye('simple scene', 'eye model', 'navarro');

testCase.verifyClass(eye, ?sceneEye);
testCase.verifyEqual(eye.get('model name'), 'navarro');
testCase.verifyEqual(eye.get('use pinhole'), false); % defaults to optics/human eye

end

function testSceneEyeConstructorLegacyHumanEyeAlias(testCase)
%% Test legacy constructor spelling for the human-eye model.

eye = sceneEye('simple scene', 'human eye', 'Navarro');

testCase.verifyClass(eye, ?sceneEye);
testCase.verifyEqual(eye.get('model name'), 'navarro');

end

function testSceneEyeGetSet(testCase)
%% Test getting and setting parameters on a sceneEye object.

eye = sceneEye('simple scene', 'eye model', 'navarro');

% Test horizontal field of view
eye.set('fov', 30);
testCase.verifyGreaterThan(eye.get('retina semidiam'), 0);

% Test lens density
eye.set('lens density', 0.8);
testCase.verifyEqual(eye.get('lens density'), 0.8, 'AbsTol', 1e-4);

% Test toggling pinhole/optics mode
eye.set('use pinhole', true);
testCase.verifyEqual(eye.get('use pinhole'), true);

eye.set('use pinhole', false);
testCase.verifyEqual(eye.get('use pinhole'), false);

end
