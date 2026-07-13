% s_flatSurface
%
% No idea what the point of this example might be.
%

%% init
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read and configure the recipe
thisR = piRecipeDefault('scene name','flatSurface');

thisR.set('fov',50);
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',3);

%% Render
scene = piWRS(thisR,'render flag','hdr');

% Adjust the mean luminance to 100 cd/m2.
scene = sceneAdjustLuminance(scene,100);

%% Optical image
oi = oiCreate;
oi = oiSet(oi,'optics fnumber',4);
oi = oiSet(oi,'optics offaxis method','skip');
oi = oiSet(oi,'optics focal length',3e-3);
oi = oiCompute(scene,oi);

%% Sensor and IP
sensor = sensorCreate('bayer (gbrg)');
sensor = sensorSetSizeToFOV(sensor,oiGet(oi,'fov'),oi);
sensor = sensorSet(sensor,'auto exposure',1);
sensor = sensorSet(sensor,'noise flag',0);
sensor = sensorCompute(sensor,oi);

ip = ipCreate;
ip = ipSet(ip,'gamma',1);
ip = ipCompute(ip,sensor);
ipWindow(ip);

%%
