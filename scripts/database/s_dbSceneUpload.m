%% Upload a local scene into the Mongo database 
%
%

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
remoteServer = sftp('orange.stanford.edu','wandell');
remoteDir = '/acorn/data/iset/PBRTResources';

% Find the folders on the remote machine.  These are folders for
% skymap, textures, and so forth (Resources)
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

filesSyncRemote(remoteServer, localSceneFolder, remoteDir);

%% add metadata about the scene to the database
% The method will 
[thisID, contentStruct] = ourDB.contentCreate('collection Name',collectionName, ...
    'type','scene', ...
    'filepath',remoteDir,...
    'name','low-poly-taxi',...
    'category','iset3d',...
    'mainfile','low-poly-taxi.pbrt',...
    'source','blender',...
    'tags','test',...
    'sizeInMB',piDirSizeGet(sceneFolder,remoteServer)/1024^2,... % MB
    'format','pbrt'); 

queryStruct.hash = thisID;

thisScene = ourDB.contentFind(collectionName, queryStruct);