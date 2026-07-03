%% ISET3d-tiny testing
% 
% 

ieInit; 
clear ISETdb;
piDockerConfig;

%% This must exist on your path.  
% 
% It will be copied locally and then sync'd to the remote machine.
pbrtFile = which('sphere.pbrt');
thisR = piRead(pbrtFile);

thisR.set('skymap','room.exr');
thisR.set('to', [0 0 0]);
thisR.set('from', [-300 0 -300]);
thisR.set('fov', 60);

piWRS(thisR,'name','diffus','render flag','hdr');

%% Change to a mirror material

mirrorName = 'mirror';
piMaterialsInsert(thisR,'name',mirrorName);

% Assigning mirror to sphere
assetSphere = piAssetSearch(thisR,'object name','Sphere');
thisR.set('asset', assetSphere, 'material name', mirrorName);

piWRS(thisR,'name','mirror','render flag','hdr');


%%

thisR.set('to', [-600 0 -600]);
thisR.set('fov', 140);
piWRS(thisR,'name','flipped mirror','render flag','hdr');

%%

% thisR.set('asset', assetName, 'material name', 'white');
% thisR.set('to', [0 0 -499]);
% thisR.set('from', [0 0 -500]);
% thisR.set('fov', 60);
% 
% % piWRS(thisR);
% scene = piRender(thisR, 'render type', 'radiance','meanluminance', -1);
% scene = sceneSet(scene, 'name', 'reference scene');
% 
% % normalize scene luminance so all the following scenes have normalized
% % luminances
% meanlum = sceneGet(scene, 'meanluminance');
% scale = 100/meanlum;
% scene = sceneSet(scene, 'meanluminance', meanlum*scale);
% sceneWindow(scene);

%% Flip back and make it shiny green coated

thisR.set('to', [0 0 0]);
thisR.set('from', [-300 0 -300]);
thisR.set('fov', 60);

% We'll start by getting the current the kd value
matte_kd_orig = thisR.get('material', 'white', 'reflectance');

% However, white is of type diffuse, which doesn't allow roughness
% so we will create a new material that is coateddiffuse
coatedMaterial = piMaterialCreate('coated', 'type', 'coateddiffuse');
thisR.set('material', 'add', coatedMaterial);

% Change value of kd to reflect a green color using RGB values
thisR.set('material', coatedMaterial, 'reflectance', [0 0.4 0]);

% Set value of roughness to 0, surface will have pure Lambertian reflection
thisR.set('material', coatedMaterial, 'roughness', 0);

assetSphere = piAssetSearch(thisR,'object name','Sphere');
thisR.set('asset', assetSphere, 'material name', 'coated');

piWRS(thisR,'name','matte green','render flag','hdr');

%%