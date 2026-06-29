function tests = test_iset3dValidationRunners()
tests = functiontests(localfunctions);
end

function testPublicRunnerLocations(testCase)
%% Public validation entry points live together in validate.

validateDir = fileparts(fileparts(mfilename('fullpath')));
runnerNames = {'iset3dUnitTest','iset3dTutorialTest','iset3dExampleTest'};
for runnerIndex = 1:numel(runnerNames)
    runnerPath = which(runnerNames{runnerIndex});
    verifyEqual(testCase,fileparts(runnerPath),validateDir);
end

end

function testTutorialOptionNames(testCase)
%% Removed option aliases fail before a tutorial run begins.

verifyError(testCase,@() iset3dTutorialTest('select','t_missing'), ...
    'iset3dTutorialTest:InvalidOption');
verifyError(testCase,@() iset3dTutorialTest('t_missing'), ...
    'iset3dTutorialTest:InvalidInput');

end

function testExampleOptionNames(testCase)
%% Removed option aliases fail before an example run begins.

verifyError(testCase,@() iset3dExampleTest('select','s_missing'), ...
    'iset3dExampleTest:InvalidOption');
verifyError(testCase,@() iset3dExampleTest('s_missing'), ...
    'iset3dExampleTest:InvalidInput');

end
