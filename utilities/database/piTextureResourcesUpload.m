function uploadReport = piTextureResourcesUpload(varargin)
% Upload local material textures to the PBRTResources texture collection.
%
% Syntax
%   report = piTextureResourcesUpload()
%   report = piTextureResourcesUpload('dry run', false)
%
% Description
%   Syncs image files from piDirGet('textures') to the shared acorn
%   PBRTResources texture directory and creates missing isetdb records in the
%   PBRTResources collection.  By default the function runs as a dry run so
%   that the file and database actions can be reviewed before anything remote
%   is changed.
%
% Inputs
%   Key/value pairs:
%     'dry run'          - true by default.  When true, no remote files or
%                          database records are changed.
%     'sync files'       - upload changed/missing texture image files.  The
%                          default is the inverse of dry run.
%     'create db records'- create missing PBRTResources records.  The
%                          default is the inverse of dry run.
%     'local dir'        - local texture folder.  Default: piDirGet('textures').
%     'remote dir'       - remote texture folder.  Default:
%                          <ISETDocker.PBRTResources>/texture, falling back to
%                          /acorn/data/iset/PBRTResources/texture.
%     'remote host'      - SFTP host.  Default: ISETDocker.remoteHost, falling
%                          back to orange.stanford.edu.
%     'remote user'      - SFTP user.  Default: ISETDocker.remoteUser, falling
%                          back to getenv('USER').
%     'collection name'  - Mongo collection.  Default: PBRTResources.
%     'db server'        - Optional Mongo server override, such as
%                          localhost:49154 when using an SSH tunnel.
%     'db name'          - Mongo database name.  Default: iset.
%     'db username'      - Optional Mongo username override.
%     'db password'      - Optional Mongo password override.
%     'extensions'       - image extensions to publish.
%     'verbose'          - print a summary table.  Default: true.
%
% Returns
%   uploadReport - struct array with one element per local texture image.
%
% See also
%   isetdb, filesSyncRemote, s_dbTextureUpload

varargin = ieParamFormat(varargin);
p = inputParser;
p.addParameter('dryrun', true, @islogical);
p.addParameter('syncfiles', [], @(x)(isempty(x) || islogical(x)));
p.addParameter('createdbrecords', [], @(x)(isempty(x) || islogical(x)));
p.addParameter('localdir', piDirGet('textures'), @(x)(ischar(x) || isstring(x)));
p.addParameter('remotedir', localDefaultRemoteTextureDir(), @(x)(ischar(x) || isstring(x)));
p.addParameter('remotehost', localPrefValue('ISETDocker', 'remoteHost', 'orange.stanford.edu'), @(x)(ischar(x) || isstring(x)));
p.addParameter('remoteuser', localPrefValue('ISETDocker', 'remoteUser', getenv('USER')), @(x)(ischar(x) || isstring(x)));
p.addParameter('collectionname', 'PBRTResources', @(x)(ischar(x) || isstring(x)));
p.addParameter('dbserver', '', @(x)(ischar(x) || isstring(x)));
p.addParameter('dbname', 'iset', @(x)(ischar(x) || isstring(x)));
p.addParameter('dbusername', '', @(x)(ischar(x) || isstring(x)));
p.addParameter('dbpassword', '', @(x)(ischar(x) || isstring(x)));
p.addParameter('extensions', {'.png', '.exr', '.jpg', '.jpeg', '.tif', '.tiff'}, @(x)(iscell(x) || isstring(x)));
p.addParameter('category', 'iset3d', @(x)(ischar(x) || isstring(x)));
p.addParameter('source', 'iset3d', @(x)(ischar(x) || isstring(x)));
p.addParameter('tags', 'material texture', @(x)(ischar(x) || isstring(x)));
p.addParameter('verbose', true, @islogical);
p.parse(varargin{:});

dryRun = p.Results.dryrun;
syncFiles = p.Results.syncfiles;
createDBRecords = p.Results.createdbrecords;
if isempty(syncFiles), syncFiles = ~dryRun; end
if isempty(createDBRecords), createDBRecords = ~dryRun; end

localDir = char(p.Results.localdir);
remoteDir = char(p.Results.remotedir);
collectionName = char(p.Results.collectionname);
extensions = localNormalizeExtensions(p.Results.extensions);

uploadReport = localTextureReport(localDir, remoteDir, extensions);

if syncFiles
    uploadReport = localSyncTextureFiles(uploadReport, ...
        char(p.Results.remotehost), char(p.Results.remoteuser), remoteDir);
elseif dryRun
    [uploadReport.fileStatus] = deal('dry-run');
else
    [uploadReport.fileStatus] = deal('not-requested');
end

if createDBRecords
    uploadReport = localCreateTextureRecords(uploadReport, collectionName, ...
        char(p.Results.category), char(p.Results.source), char(p.Results.tags), ...
        char(p.Results.dbserver), char(p.Results.dbname), ...
        char(p.Results.dbusername), char(p.Results.dbpassword));
elseif dryRun
    [uploadReport.dbStatus] = deal('dry-run');
else
    [uploadReport.dbStatus] = deal('not-requested');
end

if p.Results.verbose
    localPrintReport(uploadReport, dryRun, syncFiles, createDBRecords);
end

end

function report = localTextureReport(localDir, remoteDir, extensions)
%% Create one report entry per local texture image file.

if ~isfolder(localDir)
    error('piTextureResourcesUpload:MissingLocalDir', ...
        'Local texture directory not found: %s', localDir);
end

allFiles = dir(localDir);
isTextureFile = false(size(allFiles));
for ii = 1:numel(allFiles)
    [~, ~, ext] = fileparts(allFiles(ii).name);
    isTextureFile(ii) = ~allFiles(ii).isdir && ...
        ~startsWith(allFiles(ii).name, '.') && ...
        any(strcmpi(ext, extensions));
end
textureFiles = allFiles(isTextureFile);

emptyEntry = struct( ...
    'name', '', ...
    'mainfile', '', ...
    'format', '', ...
    'localFile', '', ...
    'remoteFile', '', ...
    'sizeInMB', 0, ...
    'fileStatus', '', ...
    'dbStatus', '', ...
    'hash', '', ...
    'message', '');
report = repmat(emptyEntry, numel(textureFiles), 1);

for ii = 1:numel(textureFiles)
    [~, baseName, ext] = fileparts(textureFiles(ii).name);
    report(ii).name = baseName;
    report(ii).mainfile = textureFiles(ii).name;
    report(ii).format = lower(erase(ext, '.'));
    report(ii).localFile = fullfile(localDir, textureFiles(ii).name);
    report(ii).remoteFile = fullfile(remoteDir, textureFiles(ii).name);
    report(ii).sizeInMB = textureFiles(ii).bytes/1024^2;
end

end

function report = localSyncTextureFiles(report, remoteHost, remoteUser, remoteDir)
%% Upload missing or changed local image files to the remote texture folder.

if isempty(remoteHost) || isempty(remoteUser)
    error('piTextureResourcesUpload:MissingRemotePrefs', ...
        'Remote host and user are required to sync texture files.');
end

remoteServer = sftp(remoteHost, remoteUser);
cleanupObj = onCleanup(@() close(remoteServer));

try
    mkdir(remoteServer, remoteDir);
catch
end
cd(remoteServer, remoteDir);

remoteFiles = dir(remoteServer, remoteDir);
if isempty(remoteFiles)
    remoteNames = {};
else
    remoteNames = {remoteFiles.name};
end

for ii = 1:numel(report)
    remoteIdx = find(strcmp(remoteNames, report(ii).mainfile), 1);
    try
        if isempty(remoteIdx)
            mput(remoteServer, report(ii).localFile);
            report(ii).fileStatus = 'uploaded';
        elseif remoteFiles(remoteIdx).bytes ~= round(report(ii).sizeInMB*1024^2)
            mput(remoteServer, report(ii).localFile);
            report(ii).fileStatus = 'updated';
        else
            report(ii).fileStatus = 'exists';
        end
    catch ex
        report(ii).fileStatus = 'failed';
        report(ii).message = ex.message;
    end
end

clear cleanupObj;

end

function report = localCreateTextureRecords(report, collectionName, category, source, tags, ...
    dbServer, dbName, dbUsername, dbPassword)
%% Add one database record per missing texture mainfile.

if isempty(dbServer)
    pbrtDB = isetdb();
else
    pbrtDB = isetdb(dbServer=string(dbServer), ...
        dbName=string(dbName), ...
        dbUsername=string(dbUsername), ...
        dbPassword=string(dbPassword));
end

for ii = 1:numel(report)
    try
        if strcmp(report(ii).fileStatus, 'failed')
            report(ii).dbStatus = 'skipped-file-failed';
            continue;
        end

        existingRecord = pbrtDB.contentFind(collectionName, ...
            'type', 'texture', ...
            'mainfile', report(ii).mainfile);

        if ~isempty(existingRecord)
            report(ii).dbStatus = 'exists';
            continue;
        end

        [thisHash, ~] = pbrtDB.contentCreate( ...
            'collection name', collectionName, ...
            'type', 'texture', ...
            'filepath', fileparts(report(ii).remoteFile), ...
            'name', report(ii).name, ...
            'category', category, ...
            'mainfile', report(ii).mainfile, ...
            'source', source, ...
            'tags', tags, ...
            'description', sprintf('ISET3D material texture: %s', report(ii).mainfile), ...
            'sizeInMB', report(ii).sizeInMB, ...
            'format', report(ii).format);

        confirmedRecord = pbrtDB.contentFind(collectionName, ...
            'type', 'texture', ...
            'mainfile', report(ii).mainfile);

        if isempty(confirmedRecord)
            report(ii).dbStatus = 'failed';
            report(ii).message = strtrim(sprintf('%s %s', ...
                report(ii).message, 'Database record was not found after contentCreate.'));
        else
            report(ii).hash = thisHash;
            report(ii).dbStatus = 'created';
        end
    catch ex
        report(ii).dbStatus = 'failed';
        report(ii).message = strtrim(sprintf('%s %s', report(ii).message, ex.message));
    end
end

end

function localPrintReport(report, dryRun, syncFiles, createDBRecords)
%% Print a compact summary.

fprintf('\nPBRTResources texture upload plan\n');
fprintf('  dry run: %d, sync files: %d, create DB records: %d\n', ...
    dryRun, syncFiles, createDBRecords);
fprintf('  texture image files: %d\n\n', numel(report));

if isempty(report)
    return;
end

T = struct2table(report);
disp(T(:, {'mainfile', 'sizeInMB', 'fileStatus', 'dbStatus'}));

end

function remoteTextureDir = localDefaultRemoteTextureDir()
%% Default to the mounted PBRTResources texture folder on acorn.

remoteRoot = localPrefValue('ISETDocker', 'PBRTResources', ...
    '/acorn/data/iset/PBRTResources');
remoteTextureDir = fullfile(char(remoteRoot), 'texture');

end

function value = localPrefValue(groupName, prefName, defaultValue)
%% Read a MATLAB preference with an explicit fallback.

if ispref(groupName, prefName)
    value = getpref(groupName, prefName);
else
    value = defaultValue;
end

if isstring(value)
    value = char(value);
end

end

function extensions = localNormalizeExtensions(extensions)
%% Normalize extension list to lower-case strings with leading dots.

if isstring(extensions)
    extensions = cellstr(extensions);
end

for ii = 1:numel(extensions)
    if ~startsWith(extensions{ii}, '.')
        extensions{ii} = ['.', extensions{ii}];
    end
    extensions{ii} = lower(extensions{ii});
end

end
