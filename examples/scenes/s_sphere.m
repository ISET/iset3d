% s_sphere
%
% Illustrate the sphere rendering
%

%% init
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read and configure the recipe
thisR = piRecipeDefault('scene name','sphere');

thisR.set('fov',50);
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',3);

%% Add an equal-energy distant light
thisR.set('lights','all','delete');

from = thisR.get('from');
to   = thisR.get('to');

distantLight = piLightCreate('distantLight', ...
    'type','distant', ...
    'spd','equalEnergy', ...
    'from',from, ...
    'to',to);
thisR.set('light',distantLight,'add');

%% Render

scene = piWRS(thisR);

%% Optical image
oi = oiCreate;
oi = oiSet(oi,'optics fnumber',4);
oi = oiSet(oi,'optics offaxis method','skip');
oi = oiSet(oi,'optics focal length',3e-3);
oi = oiCompute(oi,scene);

%% Sensor and IP
sensor = sensorCreate('bayer (gbrg)');
sensor = sensorSetSizeToFOV(sensor,oiGet(oi,'fov'),oi);
sensor = sensorSet(sensor,'auto exposure',1);
sensor = sensorSet(sensor,'noise flag',0);
sensor = sensorCompute(sensor,oi);

ip = ipCreate;
ip = ipSet(ip,'gamma',1);
ip = ipCompute(ip,sensor);

%%