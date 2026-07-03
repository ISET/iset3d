function results = dockerUnitTest(mode)
% DOCKERUNITTEST Run Docker helper tests in this _tests_ directory.
%
% Usage:
%   results = dockerUnitTest;
%   results = dockerUnitTest('full');

if nargin < 1 || isempty(mode), mode = 'core'; end
mode = lower(char(mode));

[testDir, ~, ~] = fileparts(mfilename('fullpath'));
repoRoot = fileparts(fileparts(testDir));
localEnsureISETCam(repoRoot);

import matlab.unittest.TestSuite;
import matlab.unittest.TestRunner;

existingFigures = findall(groot,'Type','figure');
cleanupFigures = onCleanup(@() localCloseTestFigures(existingFigures));
cleanupPrefs = ieUnitTestSetup(); %#ok<NASGU>

suite = TestSuite.fromFolder(testDir);

switch mode
    case {'core','fast','quantitative'}
        names = {suite.Name};
        suite = suite(~contains(names, 'FullOnly') & ~contains(names, '_remote'));
    case {'full','all'}
        % Keep the full suite.
    otherwise
        error('Unknown dockerUnitTest mode %s. Use ''core'' or ''full''.', mode);
end

runner = TestRunner.withTextOutput;
results = runner.run(suite);
ieTestReport(results,'dockerUnitTest');

end

function localCloseTestFigures(existingFigures)
%% Close figures opened by tests while preserving pre-existing figures.

allFigures = findall(groot,'Type','figure');
testFigures = setdiff(allFigures,existingFigures);
testFigures = testFigures(ishghandle(testFigures));
if ~isempty(testFigures), close(testFigures); end

end

function localEnsureISETCam(repoRoot)
%% Add the sibling ISETCam dependency when test reporting is unavailable.

if exist('ieTestReport', 'file'), return; end

dependencyRoot = fullfile(fileparts(repoRoot), 'isetcam');
if ~exist(dependencyRoot, 'dir')
    error('dockerUnitTest:MissingISETCam', ...
        'ISETCam dependency not found: %s', dependencyRoot);
end

addpath(genpath(dependencyRoot));

end
