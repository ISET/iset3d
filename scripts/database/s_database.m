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

% Always this weird number for Stanford and acorn.
% The database is on acorn and accessible via that port.
setpref('db','port',49153);
ourDB = isetdb;

% if ~isopen(ourDB.connection),error('No connection to database.');end

% Zhenyi uses this one.  Maybe we will rename to iset3d-tiny or iset3d
% or something.
collectionName = 'PBRTResources'; % ourDB.collectionCreate(colName);

%% Render local scene with remote PBRT

% Make sure you have configured your computer according to this:
%
%       https://github.com/ISET/iset3d/wiki/Remote-Rendering-with-PBRT-v4
%
% See /iset3d/tutorials/remote/s_remoteSet.m for remote server
% configuration

% getpref('ISETDocker') % set up by isetdocker.setUserPrefs()

% The local folder can can contain any PBRT scene
localFolder = '/Users/zhenyi/git_repo/dev/iset3d/data/scenes/slantedEdge';
% localFolder = '/Users/wandell/Documents/MATLAB/iset3d-v4/data/scenes/slantedEdge';

pbrtFile = fullfile(localFolder, 'slantedEdge.pbrt');
thisR = piRead(pbrtFile);

% Edit for a while.
thisR.set('spatial resolution',[100,100]);

% This must exist on your path.  It will be copied locally and then
% sync'd to the remote machine.
thisR.set('skymap','room.exr');

% This writes to iset3d-tiny/local
piWrite(thisR);  
scene = piRender(thisR,'docker',thisDocker);

sceneWindow(scene);

%% Render a scene from data base

% We expect people to include a recipe.mat file in the database.  We
% do handle the case in which there is no recipe file.
sceneName       = 'ChessSet';

% Returns a struct from the database defining properties of the scene.
thisScene = ourDB.contentFind('PBRTResources', 'name',sceneName, 'show',true);

% The scenes in this database have a recipe.mat.  The input file is on
% acorn.  The docker has the information about the host, username, and
% directories to find the recipe.
recipeDB = piRead(thisScene,'docker',thisDocker);

recipeDB.set('spatial resolution',[512,512]);
recipeDB.set('lights','all','delete');

% A local skymap, which will be uploaded to the user's remote
% directory.  (The path needs to be fixed).
recipeDB.set('skymap','room.exr');

% This writes the recipe.  We need to understand why the textures are
% being written locally when we are using remote rendering.  Shouldn't
% happen.
piWrite(recipeDB);

%
scene = piRender(recipeDB,'docker',thisDocker);
sceneWindow(scene);


%% Change the skymap to a skymap in the database

%
remoteSkymaps = ourDB.contentFind('PBRTResources','type','skymap', 'show',true);

% need a function to remove skymap using type rather than name.
recipeDB.set('light','all','delete');

recipeDB.set('skymap',remoteSkymaps(1));

scene = piWRS(recipeDB);

%% Use a texture in the database


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

%% END



