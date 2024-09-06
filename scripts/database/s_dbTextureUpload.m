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
pbrtDB = isetdb();
collectionName = 'PBRTResources';

remoteTextures = pbrtDB.contentFind(collectionName,'type','texture');
for ii=1:numel(remoteTextures)
    fprintf('%d: %s\n',ii,remoteTextures(ii).name);
end

% There is contentRemove
thisD = isetdocker;
%% Put the folder on the location machine

% This opens an sftp connection.  filesSyncRemote closes it by
% default.
remoteServer = sftp(thisD.remoteHost,thisD.remoteUser);
remoteDir = '/acorn/data/iset/PBRTResources/';
remoteTextureDir = '/acorn/data/iset/PBRTResources/texture';
% Find the folders on the remote machine.  These are folders for
% skymap, textures, and so forth (Resources).  
folders = dir(remoteServer, remoteDir);
for ii=1:numel(folders)
    fprintf('%d: %s\n',ii,folders(ii).name);
end
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

