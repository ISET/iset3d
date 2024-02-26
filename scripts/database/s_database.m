%%
ieInit; 
clear ISETdb;
piDockerConfig;

%%
% set up connection to the database, it's 49153 if we are in Stanford
% Network. 
% Question: 
%   1. How to figure out the port number if we are not.
%   2. What if the data is not on acorn?
% 
setpref('db','port',49153);
ourDB = idb.ISETdb();
%{
remoteHost = 'orange.stanford.edu';
remoteUser = 'zhenyiliu';
remoteServer = sftp('orange.stanford.edu','zhenyiliu');
%}

if ~isopen(ourDB.connection),error('No connection to database.');end
collectionName = 'PBRTResources'; % ourDB.collectionCreate(colName);

% docker for rendering scenes 
isetDocker = idocker();

%% Render local scene with remote PBRT
% Make sure you have configured your computer according to this:
%       https://github.com/ISET/iset3d/wiki/Remote-Rendering-with-PBRT-v4
% See /iset3d/tutorials/remote/s_remoteSet.m for remote server
% configuration

% getpref('ISETDocker') % set up by idocker.setUserPrefs()

localFolder = '/Users/wandell/Documents/MATLAB/iset3d-v4/data/scenes/Sphere';
if ~exist(localFolder,'dir'), error('No folder found. %s',localFolder); end

pbrtFile = fullfile(localFolder, 'Sphere.pbrt');
thisR = piRead(pbrtFile);
thisR.set('spatial resolution',[100,100]);
piWrite(thisR);

scene = piRender(thisR,'docker',isetDocker);
sceneWindow(scene);

thisR.set('spatial resolution',[200,200]);
piWrite(thisR);
scene = piRender(thisR,'docker',isetDocker);
sceneWindow(scene);

%%
piWRS(thisR,'docker',isetDocker);

%% Add a scene to the database, and render it remotely

thisR.useDB = 1;
remoteDBDir     = '/acorn/data/iset/PBRTResources/scene/ChessSet';
remoteSceneFile = fullfile(remoteDBDir,'ChessSet.pbrt');
recipeMATFile   = fullfile(localFolder,'ChessSet.mat');
sceneName       = 'ChessSet';
save(recipeMATFile,'thisR');

% add info to the database.

ourDB.contentCreate('collection Name',collectionName, ...
    'type','scene', ...
    'filepath',remoteDBDir,...
    'name',sceneName,...
    'category','indoor',...
    'mainfile',[sceneName, '.pbrt'],...
    'source','iset3d',...
    'tags','',...
    'size',piDirSizeGet(localFolder)/1024^2,... % MB
    'format','pbrt');

%% upload files to the remote server
isetDocker.upload(localFolder,remoteDBDir);
% remove the mat file from local folder
delete(recipeMATFile);

%% Render the scene from data base

% Find it
sceneName       = 'ChessSet';
thisScene = ourDB.contentFind(collectionName, 'name',sceneName, 'show',true);

% Get recipe mat
recipeDB = piRead(thisScene,'docker',isetDocker);

% 
recipeDB.set('spatial resolution',[100,100]);
%
piWrite(recipeDB);
%
scene = piRender(recipeDB,'docker',isetDocker);
sceneWindow(scene);

%%
recipeDB.set('spatial resolution',[200,200]);
piWRS(recipeDB,'docker',isetDocker);


%% Use a different remote working directory

% docker for rendering scenes 
% isetDocker.workDir = '/home/wandell/isetRemote';
setpref('ISETDocker','workDir','/home/wandell/isetRemote')
isetDocker = idocker();

% We need a reset, like dockerWrapper.reset;

piWRS(recipeDB,'docker',isetDocker);




