%% Upload a local scene into the Mongo database 
%
%
thisDocker = isetdocker;
pbrtDB = isetdb();

remoteScenes = pbrtDB.contentFind('PBRTResources','type','scene');
for ii=1:numel(remoteScenes)
    fprintf('%d: %s\n',ii,remoteScenes(ii).name);
end

% There is contentRemove

%% Let's add lte-orb

% Confirm it is not there
if ~isempty(pbrtDB.contentFind('PBRTResources','name','lte-orb'))
    disp("Already there")
end

%% Put the folder on the location machine

remoteHost = 'orange.stanford.edu';
remoteUser = 'wandell';

% This opens an sftp connection.  filesSyncRemote closes it by
% default.
remoteServer = sftp('orange.stanford.edu','wandell');
remoteDir = '/acorn/data/iset/PBRTResources/';
remoteSceneDir = '/acorn/data/iset/PBRTResources/scene/lte-orb';

% Find the folders on the remote machine.  These are folders for
% skymap, textures, and so forth (Resources).  
folders = dir(remoteServer, remoteDir);
for ii=1:numel(folders)
    fprintf('%d: %s\n',ii,folders(ii).name);
end

%% Check that the scene is not there
if ~isempty(pbrtDB.contentFind('PBRTResources','name','lte-orb'))
    disp("Already there")
end

%% Copies the files up to acorn inside of the mongodb directory
localSceneFolder = '/Users/wandell/Documents/MATLAB/iset3d-tiny/data/scenes/web/lte-orb';

pbrtFile = fullfile(localSceneFolder, 'lte-orb-silver.pbrt');
thisR = piRead(pbrtFile);
piWrite(thisR);  
scene = piRender(thisR,'docker',thisDocker);

sceneWindow(scene);

%% Edit the recipe so it is set for remote

thisR.useDB = 1;
remoteSceneFile = fullfile(remoteSceneDir,'lte-orb-silver.pbrt');
recipeMATFile   = fullfile(localSceneFolder,'lte-orb-silver.mat');
sceneName       = 'lte-orb-silver';
save(recipeMATFile,'thisR');


% We just copied the directory by hand.
thisDocker.upload(localSceneFolder,remoteSceneDir);
% remove the mat file from local folder
% delete(recipeMATFile);


%% add metadata about the scene to the database

% This scene has multiple different main files that render a bit
% differently.  We add them all to the database
[thisID, contentStruct] = ourDB.contentCreate('collection Name',collectionName, ...
    'type','scene', ...
    'filepath',remoteSceneDir,...
    'name','lte-orb-silver',...
    'category','iset3d',...
    'mainfile','lte-orb-silver.pbrt',...
    'source','pbrtv4',...
    'tags','material testing',...
    'sizeInMB',piDirSizeGet(remoteSceneDir,remoteServer)/1024^2,... % MB
    'format','pbrt'); 

%% Check that we can render it

thisScene = pbrtDB.contentFind(collectionName, 'name','lte-orb-silver');

% The scenes in this database have a recipe.mat.  The input file is on
% acorn.  The docker has the information about the host, username, and
% directories to find the recipe.
thisR = piRead(thisScene,'docker',thisDocker);

thisR.set('spatial resolution',[512,512]);

scene = piWRS(thisR,'docker',thisDocker);


%% Here is a second one

% differently.  We add them all to the database
sceneFolder = 'lte-orb';
[thisID, contentStruct] = ourDB.contentCreate('collection Name',collectionName, ...
    'type','scene', ...
    'filepath',remoteSceneDir,...
    'name','low-poly-taxi',...
    'category','iset3d',...
    'mainfile','lte-orb-silver.pbrt',...
    'source','pbrtv4',...
    'tags','material testing',...
    'sizeInMB',piDirSizeGet(sceneFolder,remoteServer)/1024^2,... % MB
    'format','pbrt'); 

queryStruct.hash = thisID;

thisScene = ourDB.contentFind(collectionName, queryStruct);