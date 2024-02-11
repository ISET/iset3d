%% pbrt v4 introduction
% CPU only
%%
ieInit;
%% support FBX to PBRT

fbxFile   = fullfile(piRootPath,'data','V4','planet','planet.fbx');
% convert fbx to pbrt
pbrtFile = piFBX2PBRT(fbxFile);
% format this file
infile = piPBRTReformat(pbrtFile);

%%
thisR  = piRead(infile);
%%
thisR.set('film resolution',[1920 1080]/2.5);
thisR.set('rays per pixel',64)
thisR.set('fov',35);
%% convert plane to arealight
ids = thisR.get('objects');
namelist = '';jj = 1;
for ii=1:numel(ids)
    if strcmp(thisR.assets.Node{ids(ii)}.material.namedmaterial,'light')
        % create an area light
        lightName = 'light';
        thisAsset = thisR.get('asset parent id',thisR.assets.Node{ids(ii)}.name);
        newLight = piLightCreate(lightName,...
            'type','area',...
            'spd',[0.8 0.7 0.358],...
            'translation', thisR.assets.Node{thisAsset}.translation, ...
            'rotation', thisR.assets.Node{thisAsset}.rotation,...
            'scale',thisR.assets.Node{thisAsset}.scale);
        
        newLight.ReverseOrientation.value = true;
        newLight.shape.value = thisR.assets.Node{ids(ii)}.shape;
        
        thisR.set('light', 'add', newLight);
        
        namelist{jj} = thisR.assets.Node{ids(ii)}.name;jj=jj+1;
        
    elseif strcmp(thisR.assets.Node{ids(ii)}.material.namedmaterial,'light.001')
        lightName = 'light.001';
        thisAsset = thisR.get('asset parent id',thisR.assets.Node{ids(ii)}.name);
        newLight = piLightCreate(lightName,...
            'type','area',...
            'spd',[0 0.1 0.8],...
            'translation', thisR.assets.Node{thisAsset}.translation, ...
            'rotation', thisR.assets.Node{thisAsset}.rotation,...
            'scale',thisR.assets.Node{thisAsset}.scale);
        
        newLight.shape.value = thisR.assets.Node{ids(ii)}.shape;
        
        thisR.set('light', 'add', newLight);
        % delete this asset
        namelist{jj} = thisR.assets.Node{ids(ii)}.name;jj=jj+1;
        
    elseif strcmp(thisR.assets.Node{ids(ii)}.material.namedmaterial,'light moon')
        lightName = 'light moon';
        thisAsset = thisR.get('asset parent id',thisR.assets.Node{ids(ii)}.name);
        newLight = piLightCreate(lightName,...
            'type','area',...
            'spd',[0 0.3 1],...
            'translation', thisR.assets.Node{thisAsset}.translation, ...
            'rotation', thisR.assets.Node{thisAsset}.rotation,...
            'scale',thisR.assets.Node{thisAsset}.scale);
        
        newLight.shape.value = thisR.assets.Node{ids(ii)}.shape;
        
        thisR.set('light', 'add', newLight);
        namelist{jj} = thisR.assets.Node{ids(ii)}.name;jj=jj+1;
        
    elseif strcmp(thisR.assets.Node{ids(ii)}.material.namedmaterial,'light moon.001')
        lightName = 'light moon.001';
        thisAsset = thisR.get('asset parent id',thisR.assets.Node{ids(ii)}.name);
        newLight = piLightCreate(lightName,...
            'type','area',...
            'spd',[0.8 0.6 0.07],...
            'translation', thisR.assets.Node{thisAsset}.translation, ...
            'rotation', thisR.assets.Node{thisAsset}.rotation,...
            'scale',thisR.assets.Node{thisAsset}.scale);
        
        newLight.shape.value = thisR.assets.Node{ids(ii)}.shape;
        
        thisR.set('light', 'add', newLight);
        namelist{jj} = thisR.assets.Node{ids(ii)}.name;jj=jj+1;
        
    end
end
% Remove plane objects because they are lights now.
for jj = 1:numel(namelist)
    thisR.set('asset',namelist{jj}(10:end),'delete');
end
%% set material
thisR.set('material','listva',      'reflectance value', [0.4 0.6 0.1]);
thisR.set('material','tree',        'reflectance value', [0.2 0.07 0.04]);
thisR.set('material','ice',         'reflectance value', [0.8 0.8 0.8]);
thisR.set('material','flag',        'reflectance value', [0.8 0.01 0.01]);
thisR.set('material','Material.002','reflectance value', [0.04 0.17 0.24]);
thisR.set('material','Material.003','reflectance value', [0.1 0.1 0.1]);
thisR.set('material','Material.004','reflectance value', [0.6 0.6 0.6]);
thisR.set('material','grass',       'reflectance value', [0.38 0.52 0.08]);
thisR.set('material','hills',        'reflectance value', [0.38 0.52 0.08]);
thisR.set('material','low hills',   'reflectance value', [0.6 0.9 0.25]);
thisR.set('material','dark grass',  'reflectance value', [0.14 0.267 0.04]);
thisR.set('material','river',       'reflectance value', [0.28 0.41 0.8]);
thisR.set('material','riverside',   'reflectance value', [0.8 0.67 0.3]);
thisR.set('material','asphalt',     'reflectance value', [0.5 0.2 0.1]);
thisR.set('material','moon',        'reflectance value', [0.09 0.1 0.1]);
%% set render type
% radiance
% rTypes = {'radiance','depth','both','all','coordinates','material','instance', 'illuminant','illuminantonly'};
thisR.set('film render type',{'radiance','depth'})

%% set blackbody to 1000
thisR.lights = thisR.lights(2:end);
%% write the data out
piWrite(thisR);

%% render the scene

[scene,result] = piRender(thisR);
sceneWindow(scene);

%{
scene = piRenderCloud(thisR,'update',true);
sceneWindow(scene);
toc
%}
%% Assign random measured bsdfs
bsdfsDir = fullfile(piRootPath, 'data/bsdf');
bsdfList = dir([bsdfsDir, '/*.bsdf']);
% random pick bsdf file

materialKeys = keys(thisR.materials.list);
idxList  = randi(numel(bsdfList),numel(materialKeys),1);
for ii = 1:numel(materialKeys)
    thisbsdfs = fullfile('bsdf', bsdfList(idxList(ii)).name);
    newMat = piMaterialCreate(materialKeys{ii}, ...
        'type','measured',...
        'filename',thisbsdfs);
    thisR.set('material','replace', materialKeys{ii}, newMat);
end
outputDir = thisR.get('output dir');
copyfile(bsdfsDir, [outputDir,'/bsdf']);
%% write the data out
piWrite(thisR);

%% render the scene

% [scene,result] = piRender(thisR);
% sceneWindow(scene);

scene = piRenderCloud(thisR,'update',true);
sceneWindow(scene);

