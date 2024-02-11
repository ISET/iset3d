% t_material_properties - Understand Material Properties
%
% This tutorial  explores the properties of 4 commonly used materials:
% matte, glass, plastic, and uber. It uses multiple lights to showcase how
% properties affect the image. 
% 
% This tutorial also demonstrates how spectral properties of materials can
% be changed in 2 ways: 1) Assigning RGB values 2) Assigning Spectral
% Reflectance Values
%
% See also
%   t_materials.m, tls_materials.mlx, t_assets, t_piIntro*,
%   piMaterialCreate.m
%


%% Initialize
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create recipe

thisR = piRecipeCreate('sphere');
thisR.set('skymap','room.exr');

% A low resolution rendering for speed
thisR.set('film resolution',[200 150]);
thisR.set('rays per pixel',48);
thisR.set('nbounces',5); 
thisR.set('fov',45);

%% Understanding the environment light

% To see a list of the preset materials in a window, and printed to the
% command window, you can use 
%
%   piMaterialPresets('help');
%

% To insert one of those materials into the recipe, 
mirrorName = 'mirror';
piMaterialsInsert(thisR,'name',mirrorName);

% Assigning mirror to sphere
assetSphere = piAssetSearch(thisR,'object name','Sphere');
thisR.set('asset', assetSphere, 'material name', mirrorName);

% Change the camera coordinate to better see the environmental light's
% effect
thisR.set('to', [0 0 0]);
thisR.set('from', [-300 0 -300]);
thisR.set('fov', 60);
piWRS(thisR,'name','mirror','render flag','hdr');

%% Flip camera to confirm mirror is reflecting the scene 

thisR.set('to', [-600 0 -600]);
thisR.set('fov', 140);
piWRS(thisR,'name','flipped mirror','render flag','hdr');

%% Return to reference scene to explore properties

% Before we begin exploring properties, we must set up our reference scene

thisR.set('asset', assetName, 'material name', 'white');
thisR.set('to', [0 0 -499]);
thisR.set('from', [0 0 -500]);
thisR.set('fov', 60);

piWRS(thisR);
scene = piRender(thisR, 'render type', 'radiance','meanluminance', -1);
scene = sceneSet(scene, 'name', 'reference scene');

% normalize scene luminance so all the following scenes have normalized
% luminances
meanlum = sceneGet(scene, 'meanluminance');
scale = 100/meanlum;
scene = sceneSet(scene, 'meanluminance', meanlum*scale);
sceneWindow(scene);

%% Matte properties: Setting diffuse reflectance using RGB values
% In pbrt-v4 matte materials are now type diffuse
% The material type 'matte' has two main properties: the diffuse
% reflectivity (reflectance) and the sigma parameter (roughness) of the Oren-Nayar model

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

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance', -1);
meanlum = sceneGet(scene, 'meanluminance');
scene = sceneSet(scene, 'meanluminance',meanlum*scale);
scene = sceneSet(scene, 'name', 'Matte: reflectance = [0 1 0]');
sceneWindow(scene);

% To get the radiance of the sphere, either choose your own rectangles or
% use the saved coordinates below.

% Draw rectangle in scene window and save location first in center and
% second in outer region.
[loc_1,rect_1] = ieROISelect(scene);
centerROI = loc_1;
[loc_2,rect_2] = ieROISelect(scene);
fringeROI = loc_2;

% or use these saved positions
% centerROI = [88 65 25 22];
% fringeROI = [92 25 19 4];


% Plot mean radiance in ROI
radMean_1 = sceneGet(scene, 'roimeanenergy',centerROI);
radMean_2 = sceneGet(scene, 'roimeanenergy',fringeROI);

wave = 400:10:700;
ieNewGraphWin; hold on; grid on;
plot(wave, radMean_1); plot(wave, radMean_2);
xlab = 'Wavelength (nm)';
ylab = 'Radiance (watts/sr/nm/m^2)';
xlabel(xlab); ylabel(ylab);
title('Matte - using RGB values'); 
legend('Center', 'Fringe'); ylim([0 2*10^-3]);
hold off;

%% Matte properties: setting diffuse reflectance using spectral reflectance values

% Change value of kd value to reflect a green color using spectral
% reflectance values
kd_val = zeros(1,length(wave));
kd_val(wave>480 & wave<600)=0.4;
spd = piMaterialCreateSPD(wave, kd_val);
thisR.set('material', 'white', 'reflectance', spd);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance', -1);
meanlum = sceneGet(scene, 'meanluminance');
scene = sceneSet(scene, 'meanluminance',meanlum*scale);
scene = sceneSet(scene, 'name', 'Matte, spectral ref val');
sceneWindow(scene);

% Get the radiance of an inner and outer section
radMean_1 = sceneGet(scene, 'roimeanenergy', centerROI);
radMean_2 = sceneGet(scene, 'roimeanenergy', fringeROI);

ieNewGraphWin; hold on; grid on;
plot(wave, radMean_1); plot(wave, radMean_2);
xlabel(xlab); ylabel(ylab);
title('Matte - using Spectral Reflectance values');
legend('Center', 'Fringe');
hold off;

%% Matte Properties: Sigma value

% Set value of signma to 100, making the surface rougher
thisR.set('material', coatedMaterial, 'roughness', 100);

piWRS(thisR,'name', 'Matte: reflectance=[0 1 0]','meanluminance', -1);

piWrite(thisR);
scene = piRender(thisR, 'render type', 'radiance', 'meanluminance', -1);
meanlum = sceneGet(scene, 'meanluminance');
scene = sceneSet(scene, 'meanluminance',meanlum*scale);
scene = sceneSet(scene, 'name', 'Matte: reflectance=[0 1 0]');
sceneWindow(scene);

% Plot the inner and outer regions
radMean_1 = sceneGet(scene, 'roimeanenergy', centerROI);
radMean_2 = sceneGet(scene, 'roimeanenergy', fringeROI);

ieNewGraphWin; hold on; grid on;
plot(wave, radMean_1); plot(wave, radMean_2);
xlabel(xlab); ylabel(ylab); ylim([0 2*10^-3]);
title('Matte');
legend('Center', 'Fringe');
hold off;

%% END