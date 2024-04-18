function result = dockercmd(obj,cmd,varargin)
% Gateway to run docker commands on the remote machine
%
% Synopsis
%    result = isetdocker.dockercmd(cmd,varargin)
%
% Inputs
%   cmd
%      ps
%      MORE TO COME
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

%%
switch cmd
    case 'ps'
        % Find the docker containers including the string
        cFlag = sprintf('--context %s ',obj.renderContext);        
        [~, result] = system(sprintf("docker %s ps | grep %s", cFlag, p.Results.string));    
    otherwise
end

