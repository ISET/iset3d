function results = utilitiesUnitTest(mode)
% UTILITIESUNITTEST - Run utilities tests in the _tests_ directory.
%
% Usage:
%   results = utilitiesUnitTest;
%   results = utilitiesUnitTest('full');
%

if nargin < 1 || isempty(mode), mode = 'core'; end
mode = lower(char(mode));

[testDir, ~, ~] = fileparts(mfilename('fullpath'));
import matlab.unittest.TestSuite;
import matlab.unittest.TestRunner;

existingFigures = findall(groot,'Type','figure');
cleanupFigures = onCleanup(@() localCloseTestFigures(existingFigures));
cleanupPrefs = ieUnitTestSetup(); %#ok<NASGU>

suite = TestSuite.fromFolder(testDir);

switch mode
    case {'core','fast','quantitative'}
        names = {suite.Name};
        % Exclude tests containing 'FullOnly' or '_remote'
        suite = suite(~contains(names, 'FullOnly') & ~contains(names, '_remote'));
    case {'full','all'}
        % Keep the full suite
    otherwise
        error('Unknown utilitiesUnitTest mode %s. Use ''core'' or ''full''.', mode);
end

runner = TestRunner.withTextOutput;
results = runner.run(suite);
ieTestReport(results,'utilitiesUnitTest');

end

function localCloseTestFigures(existingFigures)
%% Close figures opened by tests while preserving pre-existing figures.

allFigures = findall(groot,'Type','figure');
testFigures = setdiff(allFigures,existingFigures);
testFigures = testFigures(ishghandle(testFigures));
if ~isempty(testFigures), close(testFigures); end

end
