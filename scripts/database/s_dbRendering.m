%% Rendering a local and an database scene
%
% Renders
% 
%  * a local scene (slantedBar.pbrt), and 
%  * an acorn database scene (ChessSet.pbrt)
%
% Also shows how to change the skymap using both local and remote skymap
% data.
%
% Make sure you have configured your computer for remote rendering.
% For instructions, see
%
%   doc isetdocker
%
% See also
%

%%
ieInit; 
piDockerConfig;

% set up connection to the database, it's 49153 if we are in Stanford
% Network. 
% Question: 
%   1. How to figure out the port number if we are not.
%   2. What if the data is not on acorn?

%% Create a docker class we will use to render the scenes 

thisDocker = isetdocker();

%% Remotely render a local scene

% Make sure you have configured your computer according to this:
%
%   https://github.com/ISET/iset3d/wiki/Remote-Rendering-with-PBRT-v4
%
% See /iset3d/tutorials/remote/s_remoteSet.m for remote server
% configuration

% getpref('ISETDocker') % set up by isetdocker.setUserPrefs()

% The local folder can can contain any PBRT scene
pbrtFile = which('slantededge.pbrt');
if isempty(pbrtFile)
    localPath = ieWebGet('deposit name','iset3d-scenes','deposit file','slantededge');
    pbrtFile = fullfile(localPath,'slantededge.pbrt');
end

% localFolder = '/Users/zhenyi/git_repo/dev/iset3d/data/scenes/slantedEdge';
% localFolder = '/Users/wandell/Documents/MATLAB/iset3d-v4/data/scenes/slantedEdge';
% pbrtFile = fullfile(localFolder, 'slantedEdge.pbrt');
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

% isetdb opens a connection to the MongoDB on acron.
%
% Zhenyi implemented a mongoDB collection.  We might rename in the
% future.
if ~exist('pbrtDB','var')
    pbrtDB = isetdb;
    collectionName = 'PBRTResources'; % ourDB.collectionCreate(colName);

    % The database is on acorn and accessible via this port.
    % NOTE:  This port is not the same as the one defined in isetdb
    % itself, which is 27017,  Why?
    if isequal(getpref('db','port'),49153)
    else, setpref('db','port',49153); end
end

% All the remote scenes.  Find the one you want.
remoteScenes = pbrtDB.contentFind('PBRTResources','type','scene');
names = {remoteScenes.name};
% ChessSet 1, kitchen is 29, living-room 31
idx = find(strcmp(names,'ChessSet'));  
%{
for ii=1:numel(remoteScenes)
   fprintf('%d:  %s\n',ii,names{ii});
end
%}

% Returns a struct from the database defining properties of the scene.
% thisScene = pbrtDB.contentFind('PBRTResources', 'name',sceneName, 'show',true);
thisScene = pbrtDB.contentFind('PBRTResources', 'name',names{idx}, 'show',true);

% The scenes in this database have a recipe.mat.  The input file is on
% acorn.  The docker has the information about the host, username, and
% directories to find the recipe.
thisR = piRead(thisScene,'docker',thisDocker);

thisR.set('spatial resolution',[512,512]);

scene = piWRS(thisR,'docker',thisDocker);

%% Add a database skymap to the scene

% There are a lot of remote skymaps stored
remoteSkymaps = pbrtDB.contentFind('PBRTResources','type','skymap', 'show',true);

% Need a function to remove skymap using type rather than name.
thisR.set('light','all','delete');

% Use the remote skymap
thisR.set('skymap',remoteSkymaps(5));

piWRS(thisR);

%% Add a local skymap to the scene

thisR.set('lights','all','delete');

% Now use the local skymap
thisR.set('skymap','room.exr');

piWRS(thisR);

%%

thisR.summarize;

%% END



