function tests = test_piMaterials()
% TEST_PIMATERIALS - Unit tests for material creation, preset insertion, and properties
%
% See also:
%   piMaterialCreate, piMaterialsInsert, piMaterialGet, piMaterialSet

tests = functiontests(localfunctions);

end

function testMaterialCreateDiffuse(testCase)
%% Test creating a custom diffuse material.

mat = piMaterialCreate('CustomDiffuse', 'type', 'diffuse');

testCase.verifyEqual(mat.name, 'CustomDiffuse');
testCase.verifyEqual(mat.type, 'diffuse');

end

function testRecipeMaterialAdd(testCase)
%% Test adding a custom material to a recipe.

thisR = recipe();
testCase.verifyEmpty(thisR.materials.list);

% Create and add a custom material
mat = piMaterialCreate('MyDiffuse', 'type', 'diffuse');
thisR.set('material', 'add', mat);

% Verify the material names in the recipe
names = thisR.get('material', 'names');
testCase.verifyEqual(numel(names), 1);
testCase.verifyEqual(names{1}, 'MyDiffuse');

end

function testMaterialsInsertPreset(testCase)
%% Test inserting predefined preset materials into a recipe.

thisR = recipe();

% Insert preset materials
thisR = piMaterialsInsert(thisR, 'names', {'glass-bk7', 'glossy-red'});

names = thisR.get('material', 'names');

% Verify that both preset materials were added
testCase.verifyTrue(ismember('glass-bk7', names));
testCase.verifyTrue(ismember('glossy-red', names));

end
