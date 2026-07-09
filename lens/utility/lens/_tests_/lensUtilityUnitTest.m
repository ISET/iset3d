function results = lensUtilityUnitTest(mode)
% LENSUTILITYUNITTEST - Run lens utility tests in this _tests_ directory.

if nargin < 1 || isempty(mode), mode = 'core'; end
mode = lower(char(mode));

[testDir,~,~] = fileparts(mfilename('fullpath'));
localAddDependencies(testDir);

import matlab.unittest.TestSuite;
import matlab.unittest.TestRunner;

existingFigures = findall(groot,'Type','figure');
cleanupFigures = onCleanup(@() localCloseTestFigures(existingFigures));
if exist('ieUnitTestSetup','file')
    cleanupPrefs = ieUnitTestSetup(); %#ok<NASGU>
end

suite = TestSuite.fromFolder(testDir);
suite = localSelectMode(suite,mode);
runner = TestRunner.withTextOutput;
results = runner.run(suite);
if exist('ieTestReport','file'), ieTestReport(results,'lensUtilityUnitTest'); end
end

function suite = localSelectMode(suite,mode)
switch mode
    case {'core','fast','quantitative'}
        names = {suite.Name};
        suite = suite(~contains(names,'FullOnly') & ~contains(names,'_remote'));
    case {'full','all'}
    otherwise
        error('Unknown lensUtilityUnitTest mode %s. Use ''core'' or ''full''.',mode);
end
end

function localAddDependencies(testDir)
rootPath = fileparts(fileparts(fileparts(testDir)));
repoParent = fileparts(rootPath);
addpath(genpath(rootPath));
for name = {'isetcam','iset3d'}
    dependencyRoot = fullfile(repoParent,name{1});
    if isfolder(dependencyRoot), addpath(genpath(dependencyRoot)); end
end
end

function localCloseTestFigures(existingFigures)
allFigures = findall(groot,'Type','figure');
testFigures = setdiff(allFigures,existingFigures);
testFigures = testFigures(ishghandle(testFigures));
if ~isempty(testFigures), close(testFigures); end
end
