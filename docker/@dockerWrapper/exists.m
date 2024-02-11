function [dockerExists, status, result] = exists()
% Check whether we can find and use Docker.
%
%   [dockerExists, status, result] = piDockerExists()
%
% Returns true if Docker can be found on the host system, and if the
% current user has permission to invoke Docker commands.
%
% See also
%   piDockerExists

%% Did this Docker command run?
[status, result] = system('docker ps');

dockerExists = (0 == status);

end
