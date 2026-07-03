function tests = test_worldCoordinates()
% TEST_WORLDCOORDINATES - Unit tests for asset world position and rotation changes
%
% See also:
%   piRecipeDefault, recipeGet, recipeSet

tests = functiontests(localfunctions);

end

function testAssetTranslation(testCase)
%% Test translating an asset and verifying world position update.

thisR = piRecipeDefault('scene name', 'simple scene');
names = thisR.assets.names;
testCase.assertNotEmpty(names);

% Select an asset (e.g. index 10 or the last one if fewer)
targetIdx = min(10, numel(names));
targetName = names{targetIdx};

% Get initial world position
pos1 = thisR.get('asset', targetName, 'world position');
testCase.verifyEqual(numel(pos1), 3);

% Translate the asset
thisR.set('asset', targetName, 'translation', [1.5, -2.0, 0.5]);

% Get new world position
pos2 = thisR.get('asset', targetName, 'world position');

% Check that the translation was correctly applied
testCase.verifyEqual(pos2(1), pos1(1) + 1.5, 'AbsTol', 1e-4);
testCase.verifyEqual(pos2(2), pos1(2) - 2.0, 'AbsTol', 1e-4);
testCase.verifyEqual(pos2(3), pos1(3) + 0.5, 'AbsTol', 1e-4);

end

function testAssetRotation(testCase)
%% Test rotating an asset and verifying rotation changes.

thisR = piRecipeDefault('scene name', 'simple scene');
names = thisR.assets.names;
testCase.assertNotEmpty(names);

% Select an asset
targetIdx = min(15, numel(names));
targetName = names{targetIdx};

% Rotate the asset
thisR.set('asset', targetName, 'rotation', [0, 0, 45]);

% Get rotation
rot = thisR.get('asset', targetName, 'world rotation');
testCase.verifyEqual(numel(rot), 3);

end
