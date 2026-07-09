function tests = test_dbTextureResources()
% TEST_DBTEXTURERESOURCES - Local tests for PBRTResources texture upload tooling

tests = functiontests(localfunctions);

end

function testDryRunFindsRepositoryTextures(testCase)
%% Dry-run manifest should include committed texture images without remote work.

report = piTextureResourcesUpload('dry run', true, 'verbose', false);
mainfiles = {report.mainfile};

testCase.verifyTrue(ismember('slantedbar.png', mainfiles), ...
    'Texture upload manifest did not include slantedbar.png.');
testCase.verifyFalse(ismember('piTextureFiles.m', mainfiles), ...
    'Texture upload manifest should not include generator scripts.');
testCase.verifyTrue(all(strcmp({report.fileStatus}, 'dry-run')), ...
    'Dry-run upload should not sync files.');
testCase.verifyTrue(all(strcmp({report.dbStatus}, 'dry-run')), ...
    'Dry-run upload should not create database records.');

end

function testDryRunFiltersCustomTextureDirectory(testCase)
%% Only image files with approved extensions should appear in the manifest.

localDir = tempname;
mkdir(localDir);
cleanupObj = onCleanup(@() localRemoveFolder(localDir));

localWriteBytes(fullfile(localDir, 'chart.png'));
localWriteBytes(fullfile(localDir, 'surface.exr'));
localWriteBytes(fullfile(localDir, 'notes.txt'));
localWriteBytes(fullfile(localDir, 'piTextureFiles.m'));

report = piTextureResourcesUpload( ...
    'dry run', true, ...
    'local dir', localDir, ...
    'remote dir', '/acorn/data/iset/PBRTResources/texture', ...
    'verbose', false);

mainfiles = sort({report.mainfile});
testCase.verifyEqual(mainfiles, {'chart.png', 'surface.exr'});
testCase.verifyEqual(report(strcmp({report.mainfile}, 'chart.png')).name, 'chart');
testCase.verifyEqual(report(strcmp({report.mainfile}, 'surface.exr')).format, 'exr');
testCase.verifyTrue(endsWith(report(1).remoteFile, ...
    fullfile('PBRTResources', 'texture', report(1).mainfile)), ...
    'Remote texture path was not constructed under the texture resource directory.');

clear cleanupObj;

end

function testIsetdbAcceptsLegacyPreferenceNames(testCase)
%% Legacy db.server/db.port prefs should map to current isetdb properties.

oldPrefs = localPreferenceSnapshot('db');
cleanupObj = onCleanup(@() localRestorePreferenceSnapshot('db', oldPrefs));

if ispref('db')
    rmpref('db');
end
setpref('db', 'server', 'acorn');
setpref('db', 'port', 49153);
setpref('db', 'username', '');
setpref('db', 'password', '');

pbrtDB = isetdb(noconnect=true);
testCase.verifyEqual(char(pbrtDB.dbServer), 'acorn:49153');
testCase.verifyEqual(char(pbrtDB.dbUsername), '');
testCase.verifyEqual(char(pbrtDB.dbPassword), '');

clear cleanupObj;

end

function testModernizeDbUserPrefsDryRun(testCase)
%% Migration helper should infer current pref names from legacy values.

oldPrefs = localPreferenceSnapshot('db');
cleanupObj = onCleanup(@() localRestorePreferenceSnapshot('db', oldPrefs));

if ispref('db')
    rmpref('db');
end
setpref('db', 'server', 'acorn');
setpref('db', 'port', 49153);
setpref('db', 'username', 'dbuser');
setpref('db', 'password', 'dbpass');

newPrefs = isetdb.modernizeDbUserPrefs('dry run', true);

testCase.verifyEqual(newPrefs.dbServer, 'acorn:49153');
testCase.verifyEqual(newPrefs.dbName, 'iset');
testCase.verifyEqual(newPrefs.dbImage, 'mongodb');
testCase.verifyEqual(newPrefs.dbUsername, 'dbuser');
testCase.verifyEqual(newPrefs.dbPassword, 'dbpass');
testCase.verifyFalse(ispref('db', 'dbServer'), ...
    'Dry run should not write modern preferences.');
testCase.verifyTrue(ispref('db', 'server'), ...
    'Dry run should not remove legacy preferences.');

clear cleanupObj;

end

function localWriteBytes(fname)
%% Create a small placeholder file; image validity is irrelevant here.

fid = fopen(fname, 'w');
cleanupObj = onCleanup(@() fclose(fid));
fwrite(fid, uint8([1 2 3 4]), 'uint8');
clear cleanupObj;

end

function localRemoveFolder(folderName)
%% Remove temp test folder if it still exists.

if isfolder(folderName)
    rmdir(folderName, 's');
end

end

function prefs = localPreferenceSnapshot(groupName)
%% Capture a MATLAB preference group for later restoration.

if ispref(groupName)
    prefs = getpref(groupName);
else
    prefs = [];
end

end

function localRestorePreferenceSnapshot(groupName, prefs)
%% Restore a MATLAB preference group captured by localPreferenceSnapshot.

if ispref(groupName)
    rmpref(groupName);
end

if isempty(prefs)
    return;
end

prefNames = fieldnames(prefs);
for ii = 1:numel(prefNames)
    setpref(groupName, prefNames{ii}, prefs.(prefNames{ii}));
end

end
