function report = validatePrefStruct(prefStruct, varargin)
% validatePrefStruct Validate an ISETDocker preference struct.
%
% Synopsis
%   report = isetdocker.validatePrefStruct(prefStruct)
%
% Optional key/value
%   checkDockerContext - Inspect the configured Docker context. Default false.
%   contextInspect     - Precomputed JSON/text from "docker context inspect".
%
% Description
%   This static helper is safe for use from DockerPref and unit tests.  It
%   reports errors, warnings, and suggested repair commands but never changes
%   MATLAB preferences or Docker context configuration.

p = inputParser;
p.CaseSensitive = false;
p.addRequired('prefStruct', @isstruct);
p.addParameter('checkdockercontext', false, @islogical);
p.addParameter('contextinspect', '', @(x) ischar(x) || isstring(x));
p.parse(prefStruct, varargin{:});

report = struct( ...
    'ok', true, ...
    'errors', strings(0,1), ...
    'warnings', strings(0,1), ...
    'repairCommands', strings(0,1), ...
    'prefs', struct());

[prefs, normalizeErrors, normalizeWarnings] = normalizePrefs(prefStruct);
report.prefs = prefs;
report.errors = [report.errors; normalizeErrors];
report.warnings = [report.warnings; normalizeWarnings];

required = ["device", "dockerImage", "workDir"];
for ii = 1:numel(required)
    report = requireNonempty(report, prefs, required(ii));
end

if ~isfield(prefs, 'remoteHost') || strlength(prefs.remoteHost) == 0
    if ~isfield(prefs, 'renderContext') || strlength(prefs.renderContext) == 0
        report.warnings(end+1,1) = "ISETDocker.renderContext is empty; local Docker will use the active Docker context.";
    end
else
    remoteRequired = ["remoteHost", "remoteUser", "renderContext", "PBRTResources"];
    for ii = 1:numel(remoteRequired)
        report = requireNonempty(report, prefs, remoteRequired(ii));
    end
end

if isfield(prefs, 'device')
    device = lower(prefs.device);
    if strlength(device) > 0 && ~ismember(device, ["cpu", "gpu"])
        report.errors(end+1,1) = sprintf( ...
            'ISETDocker.device must be "cpu" or "gpu", not "%s".', prefs.device);
    end
    if device == "gpu"
        report = requireNonempty(report, prefs, "deviceID");
    end
end

if isfield(prefs, 'PBRTContainer') && strlength(prefs.PBRTContainer) > 0
    report.warnings(end+1,1) = sprintf( ...
        'ISETDocker.PBRTContainer is transient and may be stale: "%s".', ...
        prefs.PBRTContainer);
end

tokensAreSafe = safePrefTokens(prefs);
if ~tokensAreSafe
    report.errors(end+1,1) = ...
        "ISETDocker.remoteUser, remoteHost, and renderContext must use shell-safe characters.";
end

if tokensAreSafe && p.Results.checkdockercontext && ...
        isfield(prefs, 'remoteHost') && strlength(prefs.remoteHost) > 0
    report = validateContextEndpoint(report, prefs, p.Results.contextinspect);
end

report.ok = isempty(report.errors);

end

function [prefs, errors, warnings] = normalizePrefs(inputPrefs)
knownFields = ["label", "renderContext", "remoteHost", "device", ...
    "deviceID", "dockerImage", "remoteUser", "workDir", ...
    "PBRTResources", "PBRTContainer", "batch"];

errors = strings(0,1);
warnings = strings(0,1);
prefs = struct();

fields = fieldnames(inputPrefs);
for ii = 1:numel(fields)
    name = string(fields{ii});
    value = inputPrefs.(fields{ii});

    if ~ismember(name, knownFields)
        warnings(end+1,1) = sprintf('Ignoring unknown ISETDocker field "%s".', name);
        continue;
    end

    if isstring(value)
        if ~isscalar(value)
            errors(end+1,1) = sprintf('ISETDocker.%s must be a scalar string or char value.', name);
            value = "";
        end
        value = strtrim(value);
    elseif ischar(value)
        value = strtrim(string(value));
    elseif isnumeric(value) && isscalar(value)
        value = string(value);
    elseif islogical(value) && isscalar(value) && name == "batch"
        value = string(value);
    else
        errors(end+1,1) = sprintf( ...
            'ISETDocker.%s has type %s; expected char, string, or scalar numeric.', ...
            name, class(value));
        value = "";
    end

    prefs.(char(name)) = value;
end

end

function report = requireNonempty(report, prefs, fieldName)
fieldName = char(fieldName);
if ~isfield(prefs, fieldName) || strlength(prefs.(fieldName)) == 0
    report.errors(end+1,1) = sprintf('ISETDocker.%s is required.', fieldName);
end
end

function tf = safePrefTokens(prefs)
tf = true;
fields = ["remoteUser", "remoteHost", "renderContext"];
for ii = 1:numel(fields)
    fieldName = char(fields(ii));
    if isfield(prefs, fieldName) && strlength(prefs.(fieldName)) > 0
        tf = tf && ~isempty(regexp(char(prefs.(fieldName)), '^[A-Za-z0-9_.@:-]+$', 'once'));
    end
end
end

function report = validateContextEndpoint(report, prefs, contextInspect)
context = char(prefs.renderContext);
if strlength(prefs.renderContext) == 0
    return;
end

if strlength(string(contextInspect)) == 0
    cmd = sprintf('docker context inspect %s', context);
    [status, contextInspect] = system(cmd);
    if status ~= 0
        report.errors(end+1,1) = sprintf( ...
            'Docker context "%s" could not be inspected: %s', ...
            context, strtrim(contextInspect));
        report.repairCommands(end+1,1) = sprintf( ...
            'docker context create %s --docker "host=ssh://%s@%s"', ...
            context, prefs.remoteUser, prefs.remoteHost);
        return;
    end
end

try
    decoded = jsondecode(char(contextInspect));
catch ME
    report.errors(end+1,1) = sprintf( ...
        'Docker context "%s" inspect output could not be parsed: %s', ...
        context, ME.message);
    return;
end

if isempty(decoded)
    report.errors(end+1,1) = sprintf('Docker context "%s" inspect output is empty.', context);
    return;
end

if numel(decoded) > 1
    decoded = decoded(1);
end

if ~isfield(decoded, 'Endpoints') || ~isfield(decoded.Endpoints, 'docker') || ...
        ~isfield(decoded.Endpoints.docker, 'Host')
    report.errors(end+1,1) = sprintf( ...
        'Docker context "%s" does not include a Docker endpoint host.', context);
    return;
end

actualHost = string(decoded.Endpoints.docker.Host);
expectedHost = sprintf('ssh://%s@%s', prefs.remoteUser, prefs.remoteHost);

if actualHost ~= expectedHost
    report.errors(end+1,1) = sprintf( ...
        'Docker context %s points to %s, but ISETDocker prefs specify %s@%s.', ...
        prefs.renderContext, actualHost, prefs.remoteUser, prefs.remoteHost);
    report.repairCommands(end+1,1) = sprintf( ...
        'docker context update %s --docker "host=%s"', ...
        prefs.renderContext, expectedHost);
end

end
