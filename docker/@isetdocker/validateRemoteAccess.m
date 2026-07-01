function report = validateRemoteAccess(obj)
% validateRemoteAccess Validate SSH access to the configured remote host.
%
% Synopsis
%   report = obj.validateRemoteAccess()
%
% Description
%   Runs a short non-interactive SSH command against the configured remote
%   user and host.  This method reports the problem without changing prefs
%   or Docker context configuration.

prefs = obj.prefStruct();
report = isetdocker.validatePrefStruct(prefs);
if ~report.ok || isempty(stringValue(prefs.remoteHost))
    return;
end

remoteUser = char(stringValue(prefs.remoteUser));
remoteHost = char(stringValue(prefs.remoteHost));

if isempty(remoteUser) || isempty(remoteHost)
    report = addError(report, 'ISETDocker.remoteUser and remoteHost are required for SSH validation.');
    return;
end

if ~safeShellToken(remoteUser) || ~safeShellToken(remoteHost)
    report = addError(report, 'Remote user or host contains characters that are unsafe for shell validation.');
    return;
end

cmd = sprintf('ssh -o BatchMode=yes -o ConnectTimeout=10 %s@%s hostname', ...
    remoteUser, remoteHost);
[status, result] = system(cmd);
if status ~= 0
    report = addError(report, sprintf( ...
        'SSH validation failed for %s@%s: %s', ...
        remoteUser, remoteHost, strtrim(result)));
end

end

function value = stringValue(value)
if ischar(value)
    value = string(value);
elseif isnumeric(value) && isscalar(value)
    value = string(value);
elseif ismissing(value)
    value = "";
end
value = strtrim(value);
end

function tf = safeShellToken(value)
tf = ~isempty(regexp(value, '^[A-Za-z0-9_.@:-]+$', 'once'));
end

function report = addError(report, message)
report.errors(end+1,1) = string(message);
report.ok = false;
end
