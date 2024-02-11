%% general script for rendering a pbrt v4 scene

ieInit;
piDockerConfig;
%%
% fbxFile   = fullfile(piRootPath,'data','V4','testplane','testplane.fbx');
% fbxFile = '/Users/zhenyi/Desktop/ford-scene/deer.fbx';
% convert fbx to pbrt
pbrtFile = piFBX2PBRT(fbxFile);
% format this file 
infile = piPBRTReformat(pbrtFile);

thisR = piRead(infile);

LightRotation = piRotationMatrix('z',180);
piLightDelete(thisR, 'all'); 
newDistant = piLightCreate('new envlight',...
                           'type', 'infinite',...
                           'filename','room.exr',...
                           'rotation', LightRotation);
thisR.set('light', 'add', newDistant);

thisR.set('material','Ground','roughness value',0.5);
thisR.set('material','Deer','roughness value',0.5);

bunnyAsset = piAssetLoad('bunny.mat');
piRecipeMerge(thisR, bunnyAsset.thisR, 'node name', bunnyAsset.mergeNode);
%%
thisR.set('film resolution',[500,300]*2);
thisR.set('pixel samples',32);
thisR.set('fov',30);
thisR.integrator.subtype = 'path';  
thisR.set('film render type',{'radiance'});
%%
piWrite(thisR);
scene = piRender(thisR);
sceneWindow(scene);

%%
% piAssetGeometry(thisR);
