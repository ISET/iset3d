function [result, dockerCommand] = dockercmd(obj,cmd,varargin)
% Gateway to run docker commands on the remote machine
%
% Synopsis
%    result = isetdocker.dockercmd(cmd,varargin)
%
% Inputs
%   cmd - Execute a command on the remote machine and return the
%   result
%      ps find    - docker ps | grep string
%      nvidia smi (run this remotely)
%
% Optional
%    string - used for ps
%
% Returns
%  result
%
% Description
%   Uses the remote context to invoke the docker command.
%
% See also
%   isetdocker

% Example
%{
   thisD = isetdocker;
   result = thisD.dockercmd('ps','string','wandell');
%}

%%
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('obj');
p.addRequired('cmd',@ischar)

p.addParameter('string','',@ischar);
p.parse(obj,cmd,varargin{:})

%% Set up command parameters

if ispc,     flags = '-i ';
else,        flags = '-it ';
end

% context
dockerContext = sprintf('--context %s ',obj.renderContext);
pbrtcontainer = getpref('ISETDocker','PBRTContainer');

switch ieParamFormat(cmd)
    case 'psfind'
        % Find the docker containers including the string
        dockerCommand = sprintf("docker %s ps | grep %s", dockerContext, p.Results.string);
        [~, result] = system(dockerCommand);
    case 'nvidiasmi'
        % Check the nvidia GPUs on the remote machine
        remoteCommand = "nvidia-smi ";
        dockerCommand = sprintf('docker %s exec %s %s sh -c " %s "',...
            dockerContext, flags, pbrtcontainer, remoteCommand);
        [~, result] = system(dockerCommand);
        disp(result);

    otherwise
        error('Unknown command %s\n',cmd);
end

