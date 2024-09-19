%% Upload a local texture into the Mongo database 
%
% There is a directory called texture with the main ones we have used
% recently.  THere is a parallel diretory called texture-archives that
% has many others we might use.  These are from PBRT scenes.  They
% could be useful.
%
% To add a texture, put it in the iset/PBRTResources on acorn.
% Then do this.
%
% (characters has not yet been added.  it could go with the assets).
%

%%
thisDocker = isetdocker;
pbrtDB = isetdb();

%
remoteTextures = pbrtDB.contentFind('PBRTResources','type','texture','show',true);

% There is contentRemove

%% Put the folder on the location machine

remoteHost = 'orange.stanford.edu';
remoteUser = 'wandell';

% This opens an sftp connection.  filesSyncRemote closes it by
% default.
remoteServer = sftp('orange.stanford.edu','wandell');
remoteDir = '/acorn/data/iset/PBRTResources/';
remoteTextureDir = '/acorn/data/iset/PBRTResources/texture';

% Find the folders on the remote machine.  These are folders for
% skymap, textures, and so forth (Resources).  
folders = dir(remoteServer, remoteDir);
for ii=1:numel(folders)
    fprintf('%d: %s\n',ii,folders(ii).name);
end

%% Check that the scene is not there
% if ~isempty(pbrtDB.contentFind('PBRTResources','name','lte-orb'))
%     disp("Already there")
% end
%{
flatScene = pbrtDB.contentFind('PBRTResources','name','flatSurfaceWhiteTexture');
thisR = piRead(flatScene,'docker',thisDocker);
scene = piWRS(thisR);

thisR.show('objects')

idx = piAssetSearch(thisR,'object name','Cube_O');

piMaterialsInsert(thisR,'groups','wood');
thisR.get('print materials');
thisR.set('asset',idx,'material name','wood-medium-knots');

piWRS(thisR);


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

%}
%% add metadata about the scene to the database

% This scene has multiple different main files that render a bit
% differently.  We add them all to the database
remoteTextureFile = fullfile(remoteTextureDir,'macbeth_001.png');
[thisHash, contentStruct] = pbrtDB.contentCreate('collection Name',collectionName, ...
    'type','texture', ...
    'filepath',remoteTextureDir,...
    'name','macbeth',...
    'category','iset3d',...
    'mainfile','macbeth_001.png',...
    'source','unknown',...
    'tags','material',...
    'description','Classic Macbeth Chart',...
    'sizeInMB',piDirSizeGet(remoteTextureFile,remoteServer)/1024^2,... % MB
    'format','png'); 


thisTexture = pbrtDB.contentFind(collectionName, 'name','macbeth');

thisTexture(1)

% When I changed the file name and had to delete a database entry, I
% used this
%
%  nRemoved = pbrtDB.contentRemove(collectionName, thisTexture(1));
%

%%


%%
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