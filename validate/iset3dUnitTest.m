function results = iset3dUnitTest(mode)
% ISET3DUNITTEST - Master runner for all ISET3d unit tests
%
% This script automatically discovers all `_tests_` directories
% within the ISET3d workspace, agglomerates them into a master
% test suite, and runs them.
%
% Usage:
%   results = iset3dUnitTest;
%   results = iset3dUnitTest('full');
%
% Returns:
%   results - A matlab.unittest.TestResult array containing the outcome.
%

if nargin < 1 || isempty(mode), mode = 'core'; end
mode = lower(char(mode));

% Get the root path of the project
rootPath = iset3dRootPath();

% Find all directories named '_tests_' recursively
fprintf('Searching for test directories in ISET3d...\n');
testDirs = dir(fullfile(rootPath, '**', '_tests_'));

import matlab.unittest.TestSuite;
import matlab.unittest.TestRunner;

existingFigures = findall(groot,'Type','figure');
cleanupFigures = onCleanup(@() localCloseTestFigures(existingFigures));

masterSuite = [];

for ii = 1:length(testDirs)
    if testDirs(ii).isdir
        folderPath = fullfile(testDirs(ii).folder, testDirs(ii).name);
        % Create test suite from each folder and append to master
        folderSuite = TestSuite.fromFolder(folderPath);
        masterSuite = [masterSuite, folderSuite]; %#ok<AGROW>
    end
end

% Filter based on the selected mode
masterSuite = localSelectMode(masterSuite, mode);

if isempty(masterSuite)
    fprintf('No ISET3d tests found for mode ''%s''.\n', mode);
    results = [];
    return;
end

fprintf('Found %d test files across %d directories.\n', length(masterSuite), length(testDirs));
fprintf('Starting master test runner for mode ''%s''...\n\n', mode);

% Create runner with standard text output
runner = TestRunner.withTextOutput;

% Run the suite
results = runner.run(masterSuite);

% Generate the test report
ieTestReport(results, 'iset3dUnitTest');

end

function suite = localSelectMode(suite, mode)
%% Select core or full tests using the full-only filename convention.

switch mode
    case {'core', 'fast', 'quantitative'}
        names = {suite.Name};
        % Exclude tests containing 'FullOnly'
        suite = suite(~contains(names, 'FullOnly'));
    case {'full', 'all'}
        % Keep the complete suite.
    otherwise
        error('Unknown iset3dUnitTest mode %s. Use ''core'' or ''full''.', mode);
end

end

function localCloseTestFigures(existingFigures)
%% Close figures opened by tests while preserving pre-existing figures.

allFigures = findall(groot,'Type','figure');
testFigures = setdiff(allFigures,existingFigures);
testFigures = testFigures(ishghandle(testFigures));
if ~isempty(testFigures), close(testFigures); end

end
