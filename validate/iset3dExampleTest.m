function run = iset3dExampleTest(varargin)
% Run ISET3d examples through the shared ISETCam test engine.
%
% Syntax:
%   run = iset3dExampleTest
%   run = iset3dExampleTest('selection', scriptName)
%   run = iset3dExampleTest('start', scriptName)
%
% With no arguments, all examples run. 'selection' runs only scriptName;
% 'start' runs scriptName and every example after it.
%

[selector,start] = localParseSelection(varargin{:});

repoRoot = iset3dRootPath;
localEnsureISETCam(repoRoot);

config = struct();
config.repositoryName = 'ISET3d';
config.repositoryRoot = repoRoot;
config.suiteKind = 'examples';
config.runnerName = mfilename;
config.selector = selector;
config.start = start;
config.skipPathPatterns = { ...
    [filesep 'data' filesep]};

run = ieRunTutorialExampleTests(config);

end

function [selector,start] = localParseSelection(varargin)
%% Parse the public selection options.

selector = '';
start = '';
if isempty(varargin), return; end
if numel(varargin) ~= 2
    error('iset3dExampleTest:InvalidInput', ...
        'Use no arguments or one name-value pair: selection or start.');
end

option = lower(char(varargin{1}));
switch option
    case 'selection'
        selector = varargin{2};
    case 'start'
        start = varargin{2};
    otherwise
        error('iset3dExampleTest:InvalidOption', ...
            'Unknown option "%s". Use selection or start.', option);
end

end

function localEnsureISETCam(repoRoot)
%% Add the sibling ISETCam dependency when the shared engine is unavailable.

if ~isempty(which('ieRunTutorialExampleTests')), return; end
dependencyRoot = fullfile(fileparts(repoRoot), 'isetcam');
if ~isfolder(dependencyRoot)
    error('iset3dExampleTest:MissingISETCam', ...
        'ISETCam dependency not found: %s', dependencyRoot);
end
addpath(genpath(dependencyRoot));

end
