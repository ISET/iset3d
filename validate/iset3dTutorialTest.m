function run = iset3dTutorialTest(varargin)
% Run ISET3d tutorials through the shared ISETCam test engine.
%
% Syntax:
%   run = iset3dTutorialTest
%   run = iset3dTutorialTest('selection', scriptName)
%   run = iset3dTutorialTest('start', scriptName)
%
% With no arguments, all tutorials run. 'selection' runs only scriptName;
% 'start' runs scriptName and every tutorial after it.
%

[selector,start] = localParseSelection(varargin{:});

repoRoot = iset3dRootPath;
localEnsureISETCam(repoRoot);

config = struct();
config.repositoryName = 'ISET3d';
config.repositoryRoot = repoRoot;
config.suiteKind = 'tutorials';
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
    error('iset3dTutorialTest:InvalidInput', ...
        'Use no arguments or one name-value pair: selection or start.');
end

option = lower(char(varargin{1}));
switch option
    case 'selection'
        selector = varargin{2};
    case 'start'
        start = varargin{2};
    otherwise
        error('iset3dTutorialTest:InvalidOption', ...
            'Unknown option "%s". Use selection or start.', option);
end

end

function localEnsureISETCam(repoRoot)
%% Add the sibling ISETCam dependency when the shared engine is unavailable.

if ~isempty(which('ieRunTutorialExampleTests')), return; end
dependencyRoot = fullfile(fileparts(repoRoot), 'isetcam');
if ~isfolder(dependencyRoot)
    error('iset3dTutorialTest:MissingISETCam', ...
        'ISETCam dependency not found: %s', dependencyRoot);
end
addpath(genpath(dependencyRoot));

end
