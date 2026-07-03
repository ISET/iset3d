%% Experiment with microlens offsets
%
% We are introducing piMicrolensWrite() so we control the microlens.
% It works with the omni branch and the GPU code on MUX.  We are
% writing Matlab code to control the offsets.
%
% The logic of the ray trace using the offsets needs some explanation.
%
% PBRT traces rays from each film sample point (pixel.  This code
% places a 2x2 grid below each microlens.  So if we create a microlens
% array with 256 x 256 microlenses, and we set the film resolution to
% 512 x 512, we will have 4 pixels under each microlens.
%
% The tracing starts with a pixel and then traces through the
% microlens at the corresponding position.  Each pixel is always
% (implicitly) assigned one microlens from the list of 256 x 256.  How
% does it choose its microlens?  
%
% Once it has its microlens, it looks up the microlens surface and
% offset properties to trace into the imaging lens and then to the
% scene.
%
% REQUIRES ISETLens on your path.
%
% See also
%  s_sensorDPAF (ISETCam)

%% Initialize a scene and oi
ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Get the chess set scene

thisR = piRecipeDefault('scene name','chessSet');
%thisR = piRecipeCreate('flatSurface');

%% Set up the combined imaging and microlens array

uLensName = fullfile(piDirGet('lens'),'microlens.json');
iLensName = fullfile(piDirGet('lens'),'dgauss.22deg.3.0mm.json');

%% Create the combined lens file and camera

% Read the microlens and scale it to a diameter of 2.8 microns.
uLensDiameterUM = 2.8;    % Microns
uLensDiameterM = uLensDiameterUM*1e-6;
uLens = lensC('file name',uLensName);
d = uLens.get('lens diameter','microns');
uLens.scale(uLensDiameterUM/d);
fprintf('Microlens diameter (um):  %.2f\n',uLens.get('lens diameter','microns'));

iLens = lensC('file name',iLensName);

% Determines film size.  Samples will be 2x because of subpixels
% We think this (x,y)
% nMicrolens = [384 1];

% For this lens, a 1/5 of the microlens is OK for 256.
% So at 512, 2/5 of the microlens is the max, and so forth.
% nMicrolens = [256 256];  % Chess set.
nMicrolens = [512 512];  % Chess set.

%% Set up the film parameters

% We want the OI to be calculated at 4 positions behind each microlens.
% There will be two positions for each of the pixels.  The pair of up/down
% positions will be summed by the sensor into a single pixel response.  The
% pair of left/right positions will be the two pixels behind the microlens.

pixelsPerMicrolens = 2;
pixelSize  = uLens.get('lens height')/pixelsPerMicrolens;   % mm
filmwidth  = nMicrolens(2)*uLens.get('diameter','mm');       % mm
filmheight = nMicrolens(1)*uLens.get('diameter','mm');       % mm
filmresolution = [filmheight, filmwidth]/pixelSize;

% This is the size of the film/sensor in millimeters
thisR.set('film diagonal',sqrt(filmwidth^2 + filmheight^2));

% Film resolution -
thisR.set('film resolution',filmresolution);

% This is the aperture of the imaging lens of the camera in mm
thisR.set('aperture diameter',10);

% Adjust for quality
thisR.set('rays per pixel',512);

%% Experiments with the mlZ and mlXY

% For some offset, we match the chief ray angle as we extend out. When
% nMicrolens is 2.8 um, this imaging lens, and we have 256
% microlenses, the shift is 1/5th of the diameter of the microlens.
% We found this by experimenting.  We should find a systematic way to
% estimate.
% maxMLXY = uLensDiameterM * ((nMicrolens(1)/256)/5);       % Meters
maxMLXY = 0;

[combinedLensFile, info] = piMicrolensInsert(uLens,iLens,...
    'n microlens',nMicrolens, 'offset method','linear', ...
    'max offset',maxMLXY);
%{
  offsets = info.combinedLens.microlens.offsets;
  X = info.X; Y = info.Y;
  ieNewGraphWin; plot(X(:) + offsets(:,1),Y(:)+offsets(:,2),'.')
        hold on; plot(X(:),Y(:),'b.')
plot(X(:),X(:))
%}
thisR.camera = piCameraCreate('omni','lensFile',combinedLensFile);

% This has to be set after we create the lens file.  Unfortunate.
mlZ = 7e-6;  % Meters
thisR.set('microlens sensor offset',mlZ);   % Specify in meters
thisR.get('microlens sensor offset')

oi = piWRS(thisR);
sz = oiGet(oi,'size');   % Size is row,col - 

% oiPlot specifies x,y 
[uData, hdl] = oiPlot(oi,'illuminance hline',[1 round(sz(1)/2)]);
delete(hdl);

ieNewGraphWin;
plot(uData.pos(1:2:end),uData.data(1:2:end),'bo');
hold on;
plot(uData.pos(2:2:end),uData.data(2:2:end),'ro');
legend({'left','right'});
grid on
set(gca,'ylim',[0 350]);
title(sprintf('m2sensor %0.2f maxOffset %0.2f (um)',thisR.get('microlens sensor offset','um'),maxMLXY*1e6));

%{
rgb = oiGet(oi,'rgb');
imtool(rgb);
%}
%% Make a dual pixel sensor that has rectangular pixels

sensor = sensorCreate('dual pixel',[], oi, nMicrolens);

%% Compute the sensor data

% Notice that we get the spatial structure of the image right, even though
% the pixels are rectangular.
sensor = sensorCompute(sensor,oi);
sensor = sensorSet(sensor,'name','DPAF');
sensorWindow(sensor);

%%  Extract the left and right images from the dual pixel array

volts = sensorGet(sensor,'volts');
leftVolts = volts(1:end,1:2:end);
rightVolts = volts(1:end,2:2:end);

%% Create sensors for left and right image
leftSensor = sensorCreate;
leftSensor = sensorSet(leftSensor,'size',size(leftVolts));
leftSensor = sensorSet(leftSensor,'volts',leftVolts);
leftSensor = sensorSet(leftSensor,'name','left');

sensorWindow(leftSensor);
%%
rightSensor = sensorCreate;
rightSensor = sensorSet(rightSensor,'size',size(rightVolts));
rightSensor = sensorSet(rightSensor,'volts',rightVolts);
rightSensor = sensorSet(rightSensor,'name','right');
sensorWindow(rightSensor);

%%
rightSensorData = sensorPlot(rightSensor,'electrons hline',[88 88]);
% sensorPlot(rightSensor,'electrons hline',[89 89]);
c = [1 176 89 89];
[shapeHandle,ax] = ieROIDraw('sensor','shape','line','shape data',c);
leftSensorData = sensorPlot(leftSensor,'electrons hline',[88 88]);
% sensorPlot(leftSensor,'electrons hline',[89 89]);

ieNewGraphWin;
plot(leftSensorData.pos{1},leftSensorData.data{1},'b-',...
    rightSensorData.pos{1},rightSensorData.data{1},'r-');

%%
bothVolts = (leftVolts + rightVolts)/2;
sensorBoth = rightSensor;
sensorBoth = sensorSet(sensorBoth,'volts',bothVolts);
sensorWindow(sensorBoth);
ipBoth = ipCreate;
ipBoth = ipCompute(ipBoth,sensorBoth);
ipWindow(ipBoth);

%%
ip = ipCreate;
ip = ipCompute(ip,sensor);
ipWindow(ip);

leftip = ipCreate;
leftip = ipCompute(leftip,leftSensor);
ipWindow(leftip);
leftuData = ipPlot(leftip,'horizontal line',[89 89]);

rightip = ipCreate;
rightip = ipCompute(rightip,rightSensor);
ipWindow(rightip);
rightuData = ipPlot(rightip,'horizontal line',[89 89]);
%% END

