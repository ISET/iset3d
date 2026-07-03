function contextFlag = dockerContextFlag(obj)
% dockerContextFlag Return a validated Docker --context flag.
%
% Synopsis
%   contextFlag = obj.dockerContextFlag()
%
% Description
%   ISETDocker stores the Docker context name, not a complete Docker command.
%   This helper normalizes a few historical/pasted forms and returns the
%   shell-safe flag used by docker commands.

if isempty(obj.remoteHost) && isempty(obj.renderContext)
    contextName = piDockerCurrentContext;
else
    contextName = obj.renderContext;
end

contextName = localNormalizeContextName(contextName);
contextFlag = sprintf(' --context %s ', contextName);

end

function contextName = localNormalizeContextName(contextName)
contextName = strtrim(char(string(contextName)));

if startsWith(contextName, '--context ')
    parts = strsplit(contextName);
    contextName = parts{2};
elseif startsWith(contextName, 'docker --context ')
    parts = strsplit(contextName);
    contextName = parts{3};
elseif startsWith(contextName, 'docker ')
    parts = strsplit(contextName);
    contextName = parts{end};
end

if isempty(regexp(contextName, '^[A-Za-z0-9_.@:-]+$', 'once'))
    error('ISETDocker:InvalidDockerContextName', ...
        'Docker context name contains unsafe characters: "%s"', contextName);
end

end
