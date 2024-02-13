%%
ieInit; clear ISETdb
% set up connection to the database, it's 49153 if we are in Stanford
% Network. 
% Question: 
%   1. How to figure out the port number if we are not.
%   2. What if the data is not on acorn?
% 
setpref('db','port',49153);
ourDB = idb.ISETdb();
remoteHost = 'orange.stanford.edu';
remoteUser = 'zhenyiliu';
remoteServer = sftp('orange.stanford.edu','zhenyiliu');
if ~isopen(ourDB.connection),error('No connection to database.');end
collectionName = 'PBRTResources'; % ourDB.collectionCreate(colName);

% docker for rendering scenes 
isetDocker = idocker();
%% Render local scene with remote PBRT
% Make sure you have configured your computer according to this:
%       https://github.com/ISET/iset3d/wiki/Remote-Rendering-with-PBRT-v4
% See /iset3d/tutorials/remote/s_remoteSet.m for remote server
% configuration

% getpref('ISETDockerPrefs')

localFolder = '/Users/zhenyi/git_repo/dev/iset3d/data/V4/low-poly-taxi';

pbrtFile = fullfile(sceneFolder, 'low-poly-taxi.pbrt');

% list the data in a collection
% thisCollection = ourDB.docList(collectionName);

% Add the scene to the database
% if we need to add a local scene to the database, a directory is
% needed.

remoteDir = '/acorn/data/iset/PBRTResources/scenes/low-poly-taxi';
% or some local directory 
% dstDir = 'your/local/path/to/scenes'

% remove the document with hash query



%% Render remote scene with remote PBRT




%% Render local scene with local PBRT




