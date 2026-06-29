function tests = test_piRecipe()
% TEST_PIRECIPE - Unit tests for ISET3d recipe class and creation functions
%
% Write function-based MATLAB tests in files named test_<subject>.m, starting
% each file with tests = functiontests(localfunctions).
%
% See also:
%   recipe, recipeGet, recipeSet, piRecipeCreate

tests = functiontests(localfunctions);

end

function testRecipeConstructor(testCase)
%% Test that the recipe class constructor initializes default properties.

thisR = recipe();

% Verify it is a recipe object
testCase.verifyClass(thisR, ?recipe);

% Verify default properties
testCase.verifyEqual(thisR.name, 'recipe');
testCase.verifyEqual(thisR.version, 4);
testCase.verifyEqual(thisR.recipeVer, 2);
testCase.verifyEqual(thisR.useDB, 0);

end

function testRecipeGetSet(testCase)
%% Test getting and setting basic properties on a recipe.

thisR = recipe();

% Test setting and getting the name
thisR = recipeSet(thisR, 'name', 'test-recipe-name');
name = recipeGet(thisR, 'name');
testCase.verifyEqual(name, 'test-recipe-name');

% Test setting and getting input/output files
inputFile = '/path/to/input.pbrt';
outputFile = '/path/to/output.pbrt';

thisR = recipeSet(thisR, 'input file', inputFile);
thisR = recipeSet(thisR, 'output file', outputFile);

testCase.verifyEqual(recipeGet(thisR, 'input file'), inputFile);
testCase.verifyEqual(recipeGet(thisR, 'output file'), outputFile);

% Test basename getter derived parameters
testCase.verifyEqual(recipeGet(thisR, 'input basename'), 'input');
testCase.verifyEqual(recipeGet(thisR, 'output basename'), 'output');

end

function testRecipeCopy(testCase)
%% Test that copying a recipe creates a separate and identical instance.

thisR = recipe();
thisR = recipeSet(thisR, 'name', 'original-name');

% Create a copy
copiedR = thisR.copy();

% Verify it is a separate object handle
testCase.verifyNotSameHandle(thisR, copiedR);

% Verify values are identical initially
testCase.verifyEqual(recipeGet(copiedR, 'name'), 'original-name');

% Modify copy and verify original is unchanged
copiedR = recipeSet(copiedR, 'name', 'copied-name');
testCase.verifyEqual(recipeGet(thisR, 'name'), 'original-name');
testCase.verifyEqual(recipeGet(copiedR, 'name'), 'copied-name');

end
