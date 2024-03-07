%%
ieInit; clear ISETdb;
piDockerConfig;
% set up connection to the database, it's 49153 if we are in Stanford
% Network. 
% Question: 
%   1. How to figure out the port number if we are not.
%   2. What if the data is not on acorn?

%%
% docker for rendering scenes 
thisDocker = isetdocker();

setpref('db','port',49153);
ourDB = isetdb;

% if ~isopen(ourDB.connection),error('No connection to database.');end
collectionName = 'PBRTResources'; % ourDB.collectionCreate(colName);

%% Render local scene with remote PBRT
% Make sure you have configured your computer according to this:
%       https://github.com/ISET/iset3d/wiki/Remote-Rendering-with-PBRT-v4
% See /iset3d/tutorials/remote/s_remoteSet.m for remote server
% configuration

% getpref('ISETDocker') % set up by isetdocker.setUserPrefs()

localFolder = '/Users/zhenyi/git_repo/dev/iset3d/data/scenes/slantedEdge';
% localFolder = '/Users/wandell/Documents/MATLAB/iset3d-v4/data/scenes/materialball';

pbrtFile = fullfile(localFolder, 'slantedEdge.pbrt');
thisR = piRead(pbrtFile);
thisR.set('spatial resolution',[100,100]);
piWrite(thisR);

scene = piRender(thisR,'docker',thisDocker);
sceneWindow(scene);

%% Add a scene to the database, and render it remotely

% Use the database.  We need a thisR.set('use db',true);
%
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

% upload files to the remote server
thisDocker.upload(localFolder,remoteDBDir);
% remove the mat file from local folder
delete(recipeMATFile);

%% Render a scene from data base

% Find it
thisScene = ourDB.contentFind('PBRTResources', 'name',sceneName, 'show',true);

% Get recipe mat
recipeDB = piRead(thisScene,'docker',thisDocker);
% 
recipeDB.set('spatial resolution',[127,127]);
%
piWrite(recipeDB);
%
scene = piRender(recipeDB,'docker',thisDocker);
sceneWindow(scene);


%% change the skymap to a skymap in the database
remoteSkymaps = ourDB.contentFind('PBRTResources','type','skymap', 'show',true);

% need a function to remove skymap using type rather than name.
recipeDB.set('light','all','delete');

recipeDB.set('skymap',remoteSkymaps(1));

scene = piWRS(recipeDB);

%% Use a texture in the database


%% END



