%%
ieInit; 
clear ISETdb;
piDockerConfig;

%%
thisDocker = isetdocker();
%% Local cornell box
parentRecipe = piRecipeDefault('scene name','cornell_box');
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
    'type','distant');
recipeSet(parentRecipe,'lights', ourLight,'add');
%% Add a local bunny to cornell box
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
result = piWRS(combinedR);

%%
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
result = piWRS(combinedR_2);