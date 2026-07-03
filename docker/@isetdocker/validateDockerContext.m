function report = validateDockerContext(obj, varargin)
% validateDockerContext Validate Docker context consistency.
%
% Synopsis
%   report = obj.validateDockerContext()
%
% Optional key/value
%   checkVersion - Run "docker --context <context> version" after the
%                  context endpoint is validated. Default false.
%
% Description
%   Validates that the configured Docker context exists and points to the
%   same remote user and host as the ISETDocker preferences.  This method
%   reports exact repair commands but does not modify Docker contexts.

p = inputParser;
p.CaseSensitive = false;
p.addParameter('checkversion', false, @islogical);
p.parse(varargin{:});

prefs = obj.prefStruct();
report = isetdocker.validatePrefStruct(prefs, ...
    'checkDockerContext', true);

if ~report.ok || ~p.Results.checkversion || isempty(stringValue(prefs.remoteHost))
    return;
end

context = char(stringValue(prefs.renderContext));
if isempty(context)
    report = addError(report, 'ISETDocker.renderContext is required for remote Docker rendering.');
    return;
end

cmd = sprintf('docker --context %s version', context);
[status, result] = system(cmd);
if status ~= 0
    report = addError(report, sprintf( ...
        'Docker context "%s" exists but cannot be used: %s', ...
        context, strtrim(result)));
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

function report = addError(report, message)
report.errors(end+1,1) = string(message);
report.ok = false;
end
