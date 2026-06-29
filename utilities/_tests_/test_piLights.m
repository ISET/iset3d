function tests = test_piLights()
% TEST_PILIGHTS - Unit tests for light creation and property management
%
% See also:
%   piLightCreate, piLightGet, piLightSet, piLightPrint

tests = functiontests(localfunctions);

end

function testLightCreatePoint(testCase)
%% Test creating a default point light.

lght = piLightCreate('MyPointLight', 'type', 'point');

testCase.verifyEqual(lght.name, 'MyPointLight_L');
testCase.verifyEqual(lght.type, 'point');
testCase.verifyEqual(lght.spd.type, 'rgb');
testCase.verifyEqual(lght.cameracoordinate, true);

end

function testLightGetSet(testCase)
%% Test get and set operations on light structures.

lght = piLightCreate('TestLight', 'type', 'distant');

% Test set / get spd
lght = piLightSet(lght, 'spd val', [1 0.5 0.2]);
spd = piLightGet(lght, 'spd val');
testCase.verifyEqual(spd, [1 0.5 0.2]);

% Test set / get specscale
lght = piLightSet(lght, 'specscale val', 10);
testCase.verifyEqual(piLightGet(lght, 'specscale val'), 10);

% Test set / get from/to
lght = piLightSet(lght, 'from val', [1 2 3]);
lght = piLightSet(lght, 'to val', [0 0 0]);
testCase.verifyEqual(piLightGet(lght, 'from val'), [1 2 3]);
testCase.verifyEqual(piLightGet(lght, 'to val'), [0 0 0]);

end

function testRecipeLightManagement(testCase)
%% Test adding and deleting lights within a recipe.

thisR = piRecipeDefault('scene name', 'simple scene');
initialNum = thisR.get('n lights');

% Create and add a distant light
distLight = piLightCreate('DistantLight', 'type', 'distant');
thisR.set('light', distLight, 'add');

% Verify it was added
testCase.verifyEqual(thisR.get('n lights'), initialNum + 1);
names = thisR.get('light', 'names');
testCase.verifyTrue(ismember('DistantLight_L', names));

% Create and add a second point light
pointLight = piLightCreate('PointLight', 'type', 'point');
thisR.set('light', pointLight, 'add');

% Verify we have two more lights
testCase.verifyEqual(thisR.get('n lights'), initialNum + 2);

% Delete a light
thisR.set('light', 'DistantLight_L', 'delete');

% Verify only one additional light remains
testCase.verifyEqual(thisR.get('n lights'), initialNum + 1);
names = thisR.get('light', 'names');
testCase.verifyFalse(ismember('DistantLight_L', names));
testCase.verifyTrue(ismember('PointLight_L', names));

end
