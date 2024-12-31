% This script demonstrates how to estimate medium absorption from simulated
% measurements. The key idea is to calculate scene radiance with and
% without the medium, and estimate the absorption from the ratio of the
% signals
%
% Henryk Blasinski, 2023

close all;
clear all;
clc;
%%
ieInit
piDockerConfig();

cameraDistance = 5;
targetThickness = 1;
waterThickness = 4;
resolution = [320 240];


testChart = piCreateUniformChart('cameraDistance', cameraDistance, ...
    'depth',targetThickness, ...
    'resolution', resolution,...
    'width',0.1,'height',0.1);
testChart.set('pixel samples', 1024);


% Define rendering parameters
dw = isetdocker('device','cpu', ...
    'deviceID', -1, ...
    'dockerImage','vistalab/pbrt-v4-cpu-arm', ...
    'remoteHost','', ...
    'remoteUser','', ...
    'WorkDir',[piRootPath '/local'], ...
    'renderContext', 'default', ...
    'verbosity', 1 ...
    );

referenceScene = piWRS(testChart, 'ourDocker', dw, 'meanluminance', -1);

% Extract the 'in air' radiance for a particular patch.
delta = 5;
roi = [resolution(1)/2 - delta resolution(2)/2 - delta 2*delta 2*delta];

wave = sceneGet(referenceScene, 'wave');
inAirPhotons = sceneGet(referenceScene,'roi mean energy', roi);

% Create a water medium with absorption properties only. Scattering is
% disabled.
[water, waterProp] = piWaterMediumCreate('seawater', 'cPlankton', 10,  'waterSct', false);

underwaterTestChart = piSceneSubmerge(testChart, water, 'sizeX', 0.1, 'sizeY', 0.1, 'sizeZ', waterThickness);
underwaterTestChart.set('outputfile',fullfile(piRootPath,'local','UnderwaterUniform','UnderwaterUniform.pbrt'));
underwaterTestChart = sceneSet(underwaterTestChart,'name', 'Underwater');

underwaterScene = piWRS(underwaterTestChart, 'ourDocker', dw, 'meanluminance', -1);

% Extract the 'in water radiance for a particular patch
inWaterPhotons = sceneGet(underwaterScene,'roi mean energy', roi);


% Plot the radiance
figure;
hold on; grid on; box on;
plot(wave, inAirPhotons);
plot(wave, inWaterPhotons);
xlabel('Wavelength, nm');
ylabel('Radiance, photons');
legend('Air','Water');

absorptionTrue = interp1(waterProp.wave, waterProp.absorption, wave);

waterDistance = (min(cameraDistance, waterThickness/2) - targetThickness / 2) * 2;
absorptionEst = log(inWaterPhotons ./ inAirPhotons) / -waterDistance;


figure;
hold on; grid on; box on;
plot(wave, absorptionEst, 'x');
plot(wave, absorptionTrue);
xlabel('Wavelength, nm');
ylabel('Absorption');
legend('Estimated','True');



function [targetRecipe] = piCreateUniformChart(varargin)

p = inputParser;
p.addOptional('width',1);
p.addOptional('height',1);
p.addOptional('depth',1);
p.addOptional('cameraDistance',10);
p.addOptional('lightIntensity',1,@isnumeric);
p.addOptional('resolution',[320 240]);
p.parse(varargin{:});
inputs = p.Results;


targetRecipe = recipe();

camera = piCameraCreate('pinhole');
targetRecipe.recipeSet('camera',camera);
targetRecipe.set('fov',0.1);

targetRecipe.film.type = 'Film';
targetRecipe.film.subtype = 'gbuffer';
targetRecipe.set('film resolution',inputs.resolution);

cameraFrom = [0 0 inputs.cameraDistance];
cameraTo = [0 0 0];

targetRecipe.set('from',cameraFrom);
targetRecipe.set('to',cameraTo);
targetRecipe.set('up',[0 1 0]);

targetRecipe.set('samplersubtype','halton');
targetRecipe.set('pixel samples',16);

targetRecipe.set('integrator','volpath');

targetRecipe.exporter = 'PARSE';

%% Create a cube
dx = inputs.width/2;
dy = inputs.height/2;
dz = inputs.depth/2;

% Vertices of a cube
P = [ dx -dy  dz;
    dx -dy -dz;
    dx  dy -dz;
    dx  dy  dz;
    -dx -dy  dz;
    -dx -dy -dz;
    -dx  dy -dz;
    -dx  dy  dz;]';

% Faces of a cube
indices = [4 0 3
    4 3 7
    0 1 2
    0 2 3
    1 5 6
    1 6 2
    5 4 7
    5 7 6
    7 3 2
    7 2 6
    0 5 1
    0 4 5]';

cubeShape = piAssetCreate('type','trianglemesh');
cubeShape.integerindices = indices(:)';
cubeShape.point3p = P(:);

macbethChart = piAssetCreate('type','branch');
macbethChart.name = 'UniformTarget';
macbethChart.size.l = inputs.width;
macbethChart.size.h = inputs.height;
macbethChart.size.w = inputs.depth;
macbethChart.size.pmin = [-dx; -dy; -dz];
macbethChart.size.pmax = [dx; dy; dz];

rootNodeID = piAssetAdd(targetRecipe, 0, macbethChart);

wave = 300:5:800;
spd = ones(numel(wave),1);

cubeBranch = piAssetCreate('type','branch');
cubeBranch.name = 'Cube_B';
cubeBranch.size.l = inputs.width;
cubeBranch.size.h = inputs.height;
cubeBranch.size.w = inputs.depth;
cubeBranch.size.pmin = [-dx; -dy; -dz];
cubeBranch.size.pmax = [dx; dy; dz];
cubeBranch.translation = {[0; 0; 0]};
cubeNodeID = piAssetAdd(targetRecipe, rootNodeID, cubeBranch);

cube = piAssetCreate('type','object');
cube.name = 'Cube';
cube.type = 'object';
cube.material{1}.namedmaterial = 'Cube_material';
cube.shape{1} = cubeShape;
cube.mediumInterface = [];
piAssetAdd(targetRecipe, cubeNodeID, cube);

currentMaterial = piMaterialCreate('Cube_material',...
    'type','diffuse','reflectance',piSPDCreate(wave, spd));

targetRecipe.set('material','add',currentMaterial);


val.value = piSPDCreate(wave, spd);
val.type  = 'spectrum';

light = piLightCreate('light','type','point');
light = piLightSet(light,'from',cameraFrom);
light = piLightSet(light,'spd',val);
light = piLightSet(light,'cameracoordinate',0);
light = piLightSet(light,'specscale',inputs.lightIntensity);
targetRecipe.set('light',light,'add');


outputName = 'UniformChart';

targetRecipe.set('outputfile',fullfile(piRootPath,'local','UniformChart',sprintf('%s.pbrt',outputName)));
targetRecipe.world = {'WorldBegin'};


end




