function [dockerExists, status, result] = piDockerExists()
% Check whether we can find and use Docker.
%
% Synopsis
%   [dockerExists, status, result] = piDockerExists()
%
% Description
%   Returns true if Docker can be found on the host system.
%
%   The location of the docker executable is in result.
%
%

%% Can we use Docker?

% MATLAB launched as a GUI app (Dock, Spotlight, Finder) does not inherit
% the login shell's PATH, so Docker installs in the usual Homebrew
% locations can be invisible to system() even though a Terminal shell
% finds them fine.  Add them here so 'which docker' can succeed.  Mirrors
% the PATH fix in piDockerConfig.m.
if ismac
    initPath = getenv('PATH');
    homebrewPaths = {'/usr/local/bin', '/opt/homebrew/bin'};
    for ii = 1:numel(homebrewPaths)
        if ~piContains(initPath, homebrewPaths{ii})
            initPath = [homebrewPaths{ii}, ':', initPath]; %#ok<AGROW>
        end
    end
    setenv('PATH', initPath);
end

[status, result] = system('which docker');

% This approach brings up the docker desktop window, starting in 2022.  So,
% I replaced it (BW).
%
% [status, result] = system('docker ps');

dockerExists = (0 == status);

end
