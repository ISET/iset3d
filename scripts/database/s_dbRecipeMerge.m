%%
ieInit; 
clear ISETdb;
piDockerConfig;

%%
thisDocker = isetdocker();
%% Local cornell box + local bunny
parentRecipe = piRecipeDefault('scene name','cornell_box');
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
    'type','distant');
recipeSet(parentRecipe,'lights', ourLight,'add');
% load a local bunny
assetName = which('bunny.mat');
ourAsset  = piAssetLoad(assetName);

thisID = ourAsset.thisR.get('objects');   % Object id
sz = ourAsset.thisR.get('asset',thisID(1),'size');
ourAsset.thisR.set('asset',thisID(1),'scale',[0.1 0.1 0.1] ./ sz);

% Merge it with the Cornell Box
combinedR = piRecipeMerge(parentRecipe, ourAsset.thisR);
% piAssetGeometry(combinedR);

combinedR.show('textures');

% Render it
result = piWRS(combinedR,'name','local cornell and local bunny');

%% Local cornell box + database bunny
parentRecipe = piRecipeDefault('scene name','cornell_box');
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
    'type','distant');
recipeSet(parentRecipe,'lights', ourLight,'add');
% Add a database bunny
pbrtDB = isetdb;
db_bunny = pbrtDB.contentFind('PBRTResources', 'name','bunny', 'show',true);

bunnyR = piRead(db_bunny,'docker',thisDocker);
thisID = bunnyR.get('objects');   % Object id
bunnyR.set('asset',4,'scale',[2 2 2]);

bunnyR.set('asset',4,'scale',[0.1 0.1 0.1] ./ sz);
bunnyR.set('asset',4,'translation',[0 0 0.5000]);
combinedR_2 = piRecipeMerge(parentRecipe, bunnyR);
result = piWRS(combinedR_2,'name','local cornell and database bunny');
%% Database cornell box + database bunny
db_cbox = pbrtDB.contentFind('PBRTResources', 'name','cornell_box', 'show',true);
parentRecipe = piRead(db_cbox,'docker',thisDocker);
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
    'type','distant');
recipeSet(parentRecipe,'lights', ourLight,'add');
% Add a database bunny
pbrtDB = isetdb;
db_bunny = pbrtDB.contentFind('PBRTResources', 'name','bunny', 'show',true);

bunnyR = piRead(db_bunny,'docker',thisDocker);
thisID = bunnyR.get('objects');   % Object id
bunnyR.set('asset',4,'scale',[2 2 2]);

bunnyR.set('asset',4,'scale',[0.1 0.1 0.1] ./ sz);
bunnyR.set('asset',4,'translation',[0 0 0.5000]);
combinedR_3 = piRecipeMerge(parentRecipe, bunnyR);
result = piWRS(combinedR_3,'name','database cornell and database bunny');