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

[status, result] = system('which docker');

% This approach brings up the docker desktop window, starting in 2022.  So,
% I replaced it (BW).
%
% [status, result] = system('docker ps');

dockerExists = (0 == status);

end
