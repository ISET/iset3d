% This tutorial shows how to create a simple scene,
% a medium, and how to render the scene submerged in that medium.
%
% Henryk Blasinski, 2023
close all;
clear all;
clc;
%%
ieInit
piDockerConfig();

%% Create a scene with a Macbeth Chart.
macbeth = piCreateMacbethChart();
macbeth.set('pixel samples', 128);

% Define rendering parameters

%{
dw = dockerWrapper('dockerContainerName','digitalprodev/pbrt-v4-gpu',...
    'localRender',false,...
    'gpuRendering',false,...
    'remoteMachine','mux.stanford.edu',...
    'remoteUser','henryk',...
    'remoteRoot','/home/henryk',...
    'remoteImage','digitalprodev/pbrt-v4-cpu',...
    'relativeScenePath','/iset3d/',...
    'remoteResources',false);
%}

%% Here is the code to set Docker up to run on a local GPU
%  My laptop doesn't have an Nvidia GPU, so I can't completely
%  test it, so let me know if it works!
%{
try
    ourGPU = gpuDevice();
    if str2double(ourGPU.ComputeCapability) >= 5.3 % minimum for PBRT on GPU
        [status,result] = system('docker pull digitalprodev/pbrt-v4-gpu-ampere-mux');    
        dw = dockerWrapper('dockerContainerName','digitalprodev/pbrt-v4-gpu-ampere-mux',...
            'localImage', 'digitalprodev/pbrt-v4-gpu-ampere-mux', ...
            'localRender',true,...
            'gpuRendering',true,...
            'remoteResources',false);
        haveGPU = true;
    else
        fprintf('GPU Compute is: %d\n',ourGPU.computeCapability);
        haveGPU = false;
    end
catch
    haveGPU = false;
end

if ~haveGPU
    [status,result] = system('docker pull digitalprodev/pbrt-v4-cpu');
    dw = dockerWrapper('dockerContainerName','camerasimulation/pbrt-v4-cpu-arm',...
        'localRender',true,...
        'gpuRendering',false,...
        'remoteImage','camerasimulation/pbrt-v4-cpu-arm',...
        'localImageName','camerasimulation/pbrt-v4-cpu-arm',...
        'remoteResources',false);
end
%}

macbethScene = piWRS(macbeth, 'meanluminance', -1);

% Create an optical image
oi = oiCreate;
oi = oiCompute(oi, macbethScene);
ieAddObject(oi);
oiWindow();

% create a camera sensor
sensor = sensorCreate;
sensor = sensorSet(sensor,'integrationTime',8.5774e-04);
sensor = sensorSet(sensor, 'noise flag', -1);
sensor = sensorSet(sensor, 'cols', recipeGet(macbeth,'film x resolution'));
sensor = sensorSet(sensor, 'rows', recipeGet(macbeth,'film y resolution'));
sensor = sensorCompute(sensor, oi);
ieAddObject(sensor);
sensorWindow();

% Sample RGB data from the sensor for each Macbeth patch.
% [cornerPoints, obj, rect] = chartCornerpoints(sensor);
cornerPoints = [1 458;637 458;638 22;4 21];
[rects, mLocs, pSize] = chartRectangles(cornerPoints,4,6);
pixelValuesOrg = chartRectsData(sensor, mLocs, 5, false, 'volts');


% Build a linear image formation model
responseFunction = sensorGet(sensor, 'spectral QE');
reflectance = macbethReadReflectance(sensorGet(sensor,'wave'));
illuminant = ones(size(sensorGet(sensor,'wave')));

% PBRT specifies spectral units in terms of energy, but sensor response is
% proportional to the number of quanta. We care about relative values,
% hence we normalize by the maximum.
illuminant = Energy2Quanta(sceneGet(sensor,'wave'),illuminant);
illuminant = illuminant / max(illuminant(:));

pixelEstimatesOrg = reflectance'*diag(illuminant)*responseFunction;

% 'pixelEstimates' from the linear image formation model should be the same
% (up to a single scale factor) as the 'pixelValues' from camera
% simulation. If this is the case the scatter plot of one vs. the other
% should fall on a line.

figure;
hold on; grid on; box on;
plot(pixelValuesOrg, pixelEstimatesOrg,'.');
xlabel('From Simulation');
ylabel('From linear system');
title('Pixel values');


%%
% HB created a full representation model of scattering that has a number of
% different
%
% Create a seawater medium.
% water is a description of a PBRT object that desribes a homogeneous
% medium.  The waterProp are the parameters that define the seawater
% properties, including absorption, scattering, and so forth.
%
% vsf is volume scattering function. Outer product of the scattering
% function and the phaseFunction.  For pbrt you only specify the scattering
% function and a single scalar that specifies the phaseFunction.
%
% phaseFunction
%
% PBRT allows specification only of the parameters scattering, scattering
[water, waterProp] = piWaterMediumCreate('seawater', 'waterSct', 0);

%{
   uwMacbeth = sceneSet(uwMacbeth,'medium property',val);
   medium = sceneGet(uwMacbeth,'medium');
   medium = mediumSet(medium,'property',val);
   mediumGet()....
%}
% Submerge the scene in the medium.
% The size defines the volume of water.  It is centered at 0,0 and extends
% plus or minus 50/2 away from center in units of meters!  Excellent!
% It returns a modified recipe that has the 'media' slot built in the
% format that piWrite knows what to do with it.
underwaterMacbeth = piSceneSubmerge(macbeth, water, 'sizeX', 50, 'sizeY', 50, 'sizeZ', 50);
underwaterMacbeth.set('outputfile',fullfile(piRootPath,'local','UnderwaterMacbeth','UnderwaterMacbeth.pbrt'));
underwaterMacbeth = sceneSet(underwaterMacbeth,'name', 'baselineWater');

underwaterScene = piWRS(underwaterMacbeth, 'meanluminance', -1);

% Create an optical image
oi = oiCreate;
oi = oiCompute(oi, underwaterScene);
ieAddObject(oi);
oiWindow();

% create a camera sensor
sensor = sensorCreate;
sensor = sensorSet(sensor,'integrationTime',8.5774e-04);
sensor = sensorSet(sensor, 'noise flag', -1);
sensor = sensorSet(sensor, 'cols', recipeGet(macbeth,'film x resolution'));
sensor = sensorSet(sensor, 'rows', recipeGet(macbeth,'film y resolution'));
sensor = sensorCompute(sensor, oi);
ieAddObject(sensor);
sensorWindow();

% Sample RGB data from the sensor for each Macbeth patch.
% [cornerPoints, obj, rect] = chartCornerpoints(sensor);
cornerPoints = [1 458;637 458;638 22;4 21];
[rects, mLocs, pSize] = chartRectangles(cornerPoints,4,6);
pixelValues = chartRectsData(sensor, mLocs, 5, false, 'volts');

% Build a linear image formation model
responseFunction = sensorGet(sensor, 'spectral QE');
reflectance = macbethReadReflectance(sensorGet(sensor,'wave'));
illuminant = ones(size(sensorGet(sensor,'wave')));

% PBRT specifies spectral units in terms of energy, but sensor response is
% proportional to the number of quanta. We care about relative values,
% hence we normalize by the maximum.
illuminant = Energy2Quanta(sceneGet(sensor,'wave'),illuminant);
illuminant = illuminant / max(illuminant(:));

pixelEstimates = reflectance'*diag(illuminant)*responseFunction;

% 'pixelEstimates' from the linear image formation model should be the same
% (up to a single scale factor) as the 'pixelValues' from camera
% simulation. If this is the case the scatter plot of one vs. the other
% should fall on a line.

figure;
hold on; grid on; box on;
plot(pixelValues, pixelEstimates,'.');
xlabel('From Simulation');
ylabel('From linear system');
title('Pixel values');

