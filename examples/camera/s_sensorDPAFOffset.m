%% s_sensorDPAFOffset
% 
% Experiment with microlens offsets can be based on this script.
%
% To get here, we implemented the uLens iLens combination directly in
% matlab, rather than using the lenstool method in the PBRT docker.
%
% Then we experimented with the offset of the microlens from the
% sensor.  This logic needs some explanation.
%
% PBRT traces rays from each film sample point (pixel.  This code
% places a 2x2 grid below each microlens.  So if we create a microlens
% array with 256 x 256 microlenses, and we set the film resolution to
% 512 x 512, we will have 4 pixels under each microlens.
%
% The tracing starts with a pixel and then traces through the
% microlens at the corresponding position.  Each pixel is always
% (implicitly) assigned one microlens from the list of 256 x 256.
%
% Once it has its microlens, it looks up the microlens surface and
% offset properties to trace into the imaging lens and then to the
% scene.
%
% REQUIRES ISETLens on your path.
%
% See also
%  s_sensorDPAFMicrolen, t_cameraDPAF, t_cameraLightField

%% Initialize a scene and oi
ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Get the chess set scene

thisR = piRecipeDefault('scene name','chessSet');

% piWRS(thisR);

%% Set up the combined imaging and microlens array

uLensName = fullfile(piDirGet('lens'),'microlens.json');
iLensName = fullfile(piDirGet('lens'),'dgauss.22deg.3.0mm.json');
nMicrolens = [64 64]*4;     % Did a lot of work at 40,40 * 8

%% Create the combined lens file and camera

% Read the microlens and scale its diameter
uLensDiameter = 2.8;        % Microns
uLensDiameterM = 2.8*1e-6;  % Meters

uLens = lensC('file name',uLensName);
d = uLens.get('lens diameter','microns');
uLens.scale(uLensDiameter/d);
fprintf('Microlens diameter (um):  %.2f\n',uLens.get('lens diameter','microns'));

iLens = lensC('file name',iLensName);

% Zero offset of the microlens by default.  To introduce a linear
% scaling of the offset, set maxOffset to non-zero.
% maxOffset = 0;
maxOffset = uLensDiameterM/4;

% Linearly scaled offset of the microlens array
 [combinedLensFile, info] = piMicrolensInsert(uLens,iLens,'n microlens',nMicrolens,...
     'offset method','linear','max offset',uLensDiameterM/4);

thisR.set('film size',info.filmSize);

thisR.camera = piCameraCreate('omni','lensFile',combinedLensFile);

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
thisR.set('rays per pixel',256);

% The default:
% thisR.set('render type',{'radiance','depth'});

%% Render

% As described in the header:
%
%   The microlens offset for small amounts makes sense.  The rays are
% traced from the pixel to the microlens, and only those get through.
% When the offset is small, many angles are traced.  When the offset
% is large, however, the only rays from the pixel to the microlens are
% along the very narrow on-axis path.  It's kind of a weird model
% because each pixel only traces through its own microlens.
thisR.set('microlens sensor offset',5e-6);
oi = piWRS(thisR);

%{
% To look at the image up close
 rgb = oiGet(oi,'rgb'); imtool(rgb);
%}

%% Make a dual pixel sensor that has rectangular pixels

% The empty slot is for 'pixel'
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

%% Create the combined image, using both pixels

% We make a virtual sensor that combines the left and right into a
% single pixel
bothVolts = (leftVolts + rightVolts)/2;
sensorBoth = rightSensor;
sensorBoth = sensorSet(sensorBoth,'volts',bothVolts);
sensorWindow(sensorBoth);

% Then we use the usual image processing method
ipBoth = ipCreate;
ipBoth = ipCompute(ipBoth,sensorBoth);
ipWindow(ipBoth);

%% Create the image processed images that might be used for depth est.

% This creates the double wide image, just showing that we have it.
ip = ipCreate;
ip = ipCompute(ip,sensor);
ipWindow(ip);

% Now, we pull out the left and right images separately
leftip = ipCreate;
leftip = ipCompute(leftip,leftSensor);
ipWindow(leftip);
leftuData = ipPlot(leftip,'horizontal line',[89 89]);

rightip = ipCreate;
rightip = ipCompute(rightip,rightSensor);
ipWindow(rightip);
rightuData = ipPlot(rightip,'horizontal line',[89 89]);

%% END

