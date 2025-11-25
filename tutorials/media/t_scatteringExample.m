%% t_scatteringExample
%
% Synopsis
%  This script demonstrates a scattering example in iset3d, simulating how
%  light interacts with a small unit volume of participating medium at
%  various angles between the camera and incident light. It initializes the
%  iset3d environment, sets up rendering configurations (now streamlined to
%  default settings), and defines the scene parameters such as cube size,
%  image resolution, and field of view. 
% 
%  The script 
%    * constructs a test chart scene, 
%    * configures it for scattering studies, and 
%    * runs a series of renderings to compare energy transmission through
%    the medium under different geometric conditions. 
% 
%  Results are collected for each configuration to analyze the effect of
%  scattering and absorption properties, enabling visualization and
%  quantitative assessment of light transport in participating media.
% 
% Henryk Blasinski, 2025
%
% See also
%   t_absorptionExample
%

close all;
clear all;
clc;
%%
ieInit
piDockerConfig();

unitCubeSize = 0.0001;
resolution = [320 240];
fov = 0.001;
nAngles = 18;

delta = 5;
roi = [resolution(1)/2 - delta resolution(2)/2 - delta 2*delta 2*delta];

[water, waterProp] = piWaterMediumCreate('seawater', 'cSmall', 100, 'cLarge', 100,  'waterAbs', false);

water.g.value = 0.75;

allData = [];

angles = linspace(0,180,nAngles);
for angle=angles

    testChart = piCreateUnitMediumVolume(water, angle, ...
                                        'sizeX', unitCubeSize, 'sizeY', unitCubeSize, 'sizeZ',unitCubeSize, ...
                                        'resolution', resolution,...
                                        'fov', fov);

    testChart.set('pixel samples', 1024);

    referenceScene = piWRS(testChart, 'meanluminance', -1);

    data = sceneGet(referenceScene, 'roi mean energy', roi);    
    allData = cat(2, allData, data(:));
end

wave = sceneGet(referenceScene,'wave');
nWaves = numel(wave);

refScattering = waterProp.scattering / max(waterProp.scattering);


% Scattering coefficient
figure;
hold on; grid on; box on;
plot(waterProp.wave, refScattering);

for i=1:nAngles

    meas = allData(:,i) / max(allData(:,i));
    plot(wave, meas, 'x');

end
xlabel('Wavelength, nm');
ylabel('Norm. scattering coefficient');


% Phase function

figure;
hold on; grid on; box on;

hg = HGPhaseFunction(water.g.value, angles);
hg = hg / max(hg);

plot(angles, hg);

for i=1:nWaves

    % corrFactor = cosd(180 - angles);
    
    ph = allData(i,:);
    % ph = ph / corrFactor;
    ph = ph / max(ph);

    plot(angles, ph, 'x');

end
xlabel('angle, deg');
ylabel('Phase function');
yscale('log');



function [targetRecipe] = piCreateUnitMediumVolume(medium, angle, varargin)

p = inputParser;
p.addOptional('sizeX', 1, @isnumeric);
p.addOptional('sizeY', 1, @isnumeric);
p.addOptional('sizeZ', 1, @isnumeric);
p.addOptional('cameraDistance', 10);
p.addOptional('fov', 1, @isnumeric);
p.addOptional('resolution', [320 240]);
p.parse(varargin{:});
inputs = p.Results;


targetRecipe = recipe();

camera = piCameraCreate('pinhole');
targetRecipe.recipeSet('camera',camera);
targetRecipe.set('fov', inputs.fov);

targetRecipe.film.type = 'Film';
targetRecipe.film.subtype = 'gbuffer';
targetRecipe.set('film resolution', inputs.resolution);

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
dx = inputs.sizeX/2;
dy = inputs.sizeY/2;
dz = inputs.sizeZ/2;

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



mediumCubeMesh = piAssetCreate('type','trianglemesh');
mediumCubeMesh.integerindices = indices(:)';
mediumCubeMesh.point3p = P(:);


mediumBranch = piAssetCreate('type','branch');
mediumBranch.name = 'Water';
mediumBranch.size.l = inputs.sizeX;
mediumBranch.size.h = inputs.sizeY;
mediumBranch.size.w = inputs.sizeZ;
mediumBranch.size.pmin = [-dx; -dy; -dz];
mediumBranch.size.pmax = [dx; dy; dz];
mediumBranch.translation = {[0; 0; 0;]};

mediumID = piAssetAdd(targetRecipe, 0, mediumBranch);

mediumMaterial = piMaterialCreate('WaterInterface','type','interface');

% This step loses the container maps
targetRecipe.set('material','add',mediumMaterial);

mediumCube = piAssetCreate('type','object');
mediumCube.name = 'WaterMesh';
mediumCube.mediumInterface.inside = medium.name;
mediumCube.mediumInterface.outside = [];
mediumCube.material.namedmaterial = 'WaterInterface';
mediumCube.shape = mediumCubeMesh;

piAssetAdd(targetRecipe, mediumID, mediumCube);
targetRecipe.set('medium', 'add', medium);

    
% Submerge the camera if needed
xstart = -dx;
xend = dx;

ystart = -dy;
yend = dy;

zstart = -dz;
zend = dz;

camPos = targetRecipe.get('from');

if (xstart <= camPos(1) && camPos(1) <= xend) && ...
        (ystart <= camPos(2) && camPos(2) <= yend) && ...
        (zstart <= camPos(3) && camPos(3) <= zend)

    targetRecipe.camera.medium = medium.name;

end


wave = 395:10:705;
spd = ones(numel(wave),1);

val.value = piSPDCreate(wave, spd);
val.type  = 'spectrum';

xLight = sind(angle) * inputs.cameraDistance;
zLight = cosd(angle) * inputs.cameraDistance;

lightFrom = [xLight, 0, zLight];

light = piLightCreate('light','type','distant');
light = piLightSet(light,'from',lightFrom);
light = piLightSet(light,'to',[0 0 0]);
light = piLightSet(light,'spd',val);
light = piLightSet(light,'cameracoordinate',0);
light = piLightSet(light,'specscale', 1);
targetRecipe.set('light',light,'add');


outputName = 'MediumUnitVolume';

targetRecipe.set('outputfile',fullfile(piRootPath,'local','MediumUnitVolume',sprintf('%s.pbrt',outputName)));
targetRecipe.world = {'WorldBegin'};


end


function val = HGPhaseFunction(g, angle)

num = (1 - g.^2);
denom = 4 * pi * (1 + g^2 + 2 * g * cosd(angle)).^(3/2);

val = num ./ denom;

end



