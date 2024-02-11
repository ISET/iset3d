%% Create a sensor for dual pixel autofocus experiments (DPAF).
%
% This is more recently updated in t_cameraDPAF and extended in
% t_cameraLightField.
%
% Questions to answer:  
% 
%   * Why does the image look square in the sensorWindow?  What function
%   did I write (BW)?
%   * Should we eliminate this and only use the t_camera tutorials
%   below?
%
% See also
%  t_cameraDPAF, t_cameraLightField

%% Initialize a scene and oi
ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Get the chess set scene

thisR = piRecipeDefault('scene name','chessSet');

% piWRS(thisR);

%% Set up the combined imaging and microlens array

uLensName = 'microlens.json';
iLensName = 'dgauss.22deg.3.0mm.json';
uLensHeight = 0.0028;        % 2.8 um - each covers two pixels
nMicrolens = [64 64]*4;     % Did a lot of work at 40,40 * 8

[combinedLensFile, info] = piMicrolensInsert(uLens,iLens,'n microlens',nMicrolens);
% [combinedLensFile, uLens, iLens] = lensCombine(uLensName,iLensName,uLensHeight,nMicrolens);

thisR.camera = piCameraCreate('omni','lensFile',combinedLensFile);

% piWRS(thisR);

%% Set up the film parameters
%
% We want the OI to be calculated at 4 positions behind each microlens.
% There will be two positions for each of the pixels.  The pair of up/down
% positions will be summed by the sensor into a single pixel response.  The
% pair of left/right positions will be the two pixels behind the microlens.
%

pixelsPerMicrolens = 2;

pixelSize  = uLens.get('lens height')/pixelsPerMicrolens;   % mm
filmwidth  = nMicrolens(2)*uLens.get('diameter','mm');       % mm
filmheight = nMicrolens(1)*uLens.get('diameter','mm');       % mm
filmresolution = [filmheight, filmwidth]/pixelSize;

thisR.set('focus distance',0.6);

% This is the size of the film/sensor in millimeters
thisR.set('film diagonal',sqrt(filmwidth^2 + filmheight^2));

% Film resolution -
thisR.set('film resolution',filmresolution);

% This is the aperture of the imaging lens of the camera in mm
thisR.set('aperture diameter',10);

% Adjust for quality
thisR.set('rays per pixel',32);

% oi = piWRS(thisR);

%% Make a dual pixel sensor that has rectangular pixels
%
sensor = sensorCreate('dual pixel',[], oi, nMicrolens);

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

