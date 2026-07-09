function newPrefs = modernizeDbUserPrefs(varargin)
%MODERNIZEDBUSERPREFS Convert legacy isetdb prefs to current names.
%
% Syntax
%   prefs = isetdb.modernizeDbUserPrefs()
%   prefs = isetdb.modernizeDbUserPrefs('remove legacy', false)
%
% Description
%   Older ISET3D database preferences used:
%
%     db.server, db.port, db.username, db.password
%
%   The current isetdb object expects:
%
%     db.dbServer, db.dbName, db.dbImage, db.dbUsername, db.dbPassword
%
%   This helper writes the current preference names using either existing
%   modern values, legacy values, or isetdb defaults.  Legacy keys are removed
%   by default after the current names are written.
%
% See also
%   isetdb, isetdb.setDbUserPrefs

varargin = ieParamFormat(varargin);
p = inputParser;
p.addParameter('removelegacy', true, @islogical);
p.addParameter('dryrun', false, @islogical);
p.parse(varargin{:});

defaultDB = isetdb(noconnect=true, noprefs=true);

newPrefs.dbServer = char(localCurrentOrLegacyValue( ...
    'dbServer', @() localLegacyServer(defaultDB.dbServer), defaultDB.dbServer));
newPrefs.dbName = char(localCurrentValue('dbName', defaultDB.dbName));
newPrefs.dbImage = char(localCurrentValue('dbImage', defaultDB.dbImage));
newPrefs.dbUsername = char(localCurrentOrLegacyValue( ...
    'dbUsername', @() localLegacyValue('username', defaultDB.dbUsername), defaultDB.dbUsername));
newPrefs.dbPassword = char(localCurrentOrLegacyValue( ...
    'dbPassword', @() localLegacyValue('password', defaultDB.dbPassword), defaultDB.dbPassword));

if ~p.Results.dryrun
    prefNames = fieldnames(newPrefs);
    for ii = 1:numel(prefNames)
        setpref('db', prefNames{ii}, newPrefs.(prefNames{ii}));
    end

    if p.Results.removelegacy
        legacyNames = {'server', 'port', 'username', 'password'};
        for ii = 1:numel(legacyNames)
            if ispref('db', legacyNames{ii})
                rmpref('db', legacyNames{ii});
            end
        end
    end
end

fprintf('Current isetdb preferences:\n');
fprintf('  dbServer:   %s\n', newPrefs.dbServer);
fprintf('  dbName:     %s\n', newPrefs.dbName);
fprintf('  dbImage:    %s\n', newPrefs.dbImage);
fprintf('  dbUsername: %s\n', newPrefs.dbUsername);
if strlength(string(newPrefs.dbPassword)) == 0
    fprintf('  dbPassword: <empty>\n');
else
    fprintf('  dbPassword: <set>\n');
end

end

function value = localCurrentValue(currentName, defaultValue)
%% Current preference value, falling back to the supplied default.

if ispref('db', currentName)
    value = getpref('db', currentName);
else
    value = defaultValue;
end

end

function value = localCurrentOrLegacyValue(currentName, legacyFcn, defaultValue)
%% Current preference, or legacy preference, or default.

if ispref('db', currentName)
    value = getpref('db', currentName);
elseif ispref('db')
    value = legacyFcn();
else
    value = defaultValue;
end

end

function serverName = localLegacyServer(defaultValue)
%% Build current dbServer value from legacy server and port prefs.

serverName = localLegacyValue('server', defaultValue);
serverName = string(serverName);

if ispref('db', 'port') && ~contains(serverName, ":")
    serverName = sprintf('%s:%d', serverName, getpref('db', 'port'));
end

end

function value = localLegacyValue(legacyName, defaultValue)
%% Legacy preference value, falling back to the supplied default.

if ispref('db', legacyName)
    value = getpref('db', legacyName);
else
    value = defaultValue;
end

end
