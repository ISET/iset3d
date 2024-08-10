%% Showing how to change 
%
% Renders a
% 
% * local scene (slantedBar.pbrt) from the repository, and 
% * database scene (ChessSet.pbrt) on acorn
%
% Shows how to change the skymap using both local and remote skymap
% data.
%
% See also
%

%%
ieInit; 
clear ISETdb;
piDockerConfig;

% set up connection to the database, it's 49153 if we are in Stanford
% Network. 
% Question: 
%   1. How to figure out the port number if we are not.
%   2. What if the data is not on acorn?

%% Create a docker class we will use to render the scenes 

thisDocker = isetdocker();

%% Render local scene with remote PBRT

% Make sure you have configured your computer according to this:
%
%       https://github.com/ISET/iset3d/wiki/Remote-Rendering-with-PBRT-v4
%
% See /iset3d/tutorials/remote/s_remoteSet.m for remote server
% configuration

% getpref('ISETDocker') % set up by isetdocker.setUserPrefs()

% The local folder can can contain any PBRT scene
pbrtFile = which('slantedEdge.pbrt');

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

% We a recipe.mat file in the database.  We do handle the case in
% which there is no recipe file.
sceneName       = 'ChessSet';

% Always this weird number for Stanford and acorn.
% The database is on acorn and accessible via that port.
if isequal(getpref('db','port'),49153)
else, setpref('db','port',49153); end

% Zhenyi uses this mongoDB.  Maybe we will rename to iset3d-tiny or
% iset3d or something.
ourDB = isetdb;
collectionName = 'PBRTResources'; % ourDB.collectionCreate(colName);

% Returns a struct from the database defining properties of the scene.
thisScene = ourDB.contentFind('PBRTResources', 'name',sceneName, 'show',true);

% The scenes in this database have a recipe.mat.  The input file is on
% acorn.  The docker has the information about the host, username, and
% directories to find the recipe.
recipeDB = piRead(thisScene,'docker',thisDocker);

recipeDB.set('spatial resolution',[512,512]);

piWrite(recipeDB);

scene = piRender(recipeDB,'docker',thisDocker);
sceneWindow(scene);

%% Add a database skymap to the scene
%
remoteSkymaps = ourDB.contentFind('PBRTResources','type','skymap', 'show',true);

% need a function to remove skymap using type rather than name.
recipeDB.set('light','all','delete');

recipeDB.set('skymap',remoteSkymaps(1));

piWRS(recipeDB);

%% Add a local skymap to the scene
recipeDB.set('lights','all','delete');

recipeDB.set('skymap','room.exr');

piWRS(recipeDB);

%% Use a texture in the database


%% END



