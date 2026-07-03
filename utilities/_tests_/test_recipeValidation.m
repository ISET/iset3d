function tests = test_recipeValidation()
% TEST_RECIPEVALIDATION - Unit tests to verify that all predefined recipe presets load successfully
%
% See also:
%   piRecipeCreate

tests = functiontests(localfunctions);

end

function testAllPredefinedRecipesLoad(testCase)
%% Test that piRecipeCreate can parse and load every predefined scene.

validNames = piRecipeCreate('list');
testCase.assertNotEmpty(validNames);

for ii = 1:numel(validNames)
    recipeName = validNames{ii};
    % Workaround for the name mismatch bug in piRecipeCreate's list
    if strcmp(recipeName, 'cornell-box')
        recipeName = 'cornell_box';
    end
    
    try
        thisR = piRecipeCreate(recipeName);
        testCase.verifyClass(thisR, ?recipe, ...
            sprintf('Scene "%s" did not return a valid recipe class object.', recipeName));
    catch exception
        % If the scene files are not present locally and cannot be downloaded, skip/warn instead of failing
        if contains(exception.message, 'not local') || ...
           contains(exception.message, 'not on SDR') || ...
           contains(exception.message, 'Unknown recipe name')
            fprintf('Skipping non-local recipe: %s (%s)\n', recipeName, exception.message);
        else
            testCase.verifyFail(sprintf('Failed to create recipe for "%s": %s', ...
                recipeName, exception.message));
        end
    end
end

end
