%% s_dbResources
% 
% List database resources
%
% There are different resource types
%
%
% See also
%

%%
ieInit; 
clear ISETdb;
piDockerConfig;

%% Create the isetdb object

ourDB = isetdb;

% For ISET3d-tiny we use this collection
collectionName = 'PBRTResources'; % ourDB.collectionCreate(colName);

% Everything
remoteAll  = ourDB.contentFind(collectionName);
fprintf('Found %d remote All.\n',numel(remoteAll));

% We can find scenes this way
remoteScenes  = ourDB.contentFind(collectionName,'type','scene', 'show',true);

% Displays only the first 20.  
remoteAssets  = ourDB.contentFind(collectionName,'type','asset', 'show',true);
fprintf('Found %d remote assets.\n',numel(remoteAssets));

% Assets this way
assets        = ourDB.contentFind(collectionName,'type','asset','category','bus', 'show',true);

% Skymaps
remoteSkymaps = ourDB.contentFind(collectionName,'type','skymap', 'show',true);

% A particular scene
thisScene = ourDB.contentFind(collectionName, 'name',remoteScenes(1).name, 'show',true);


%%