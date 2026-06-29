% recipe = load('/Volumes/acorn.stanford.edu/data/iset/isetauto/Ford/SceneRecipes/1114041814.mat');
tmp = load('/Volumes/acorn.stanford.edu/Vistalab/data/iset/isetauto/Ford/SceneRecipes/1114041814.mat');
thisR = tmp.thisR;


load(fullfile(piRootPath,'local','autoRecipe.mat'),'thisR');
thisR.media.list = [];

thisR.set('outputFile',fullfile(piRootPath,'local','auto','auto.pbrt'));

lights = thisR.get('lights');
thisR.set('lights','skymap_012_L','delete');

thisR.set('skymap','sky-noon_009.exr');

thisR.set('film resolution',[1920 1080]/2); % Divide by 4 for speed
thisR.set('pixel samples',2048);            % 256 for speed
thisR.set('max depth',5);                  % Number of bounces
thisR.set('sampler subtype','pmj02bn'); 
thisR.set('fov',45); 

scene = piWRS(thisR);
scene = piAIdenoise(scene); ieReplaceObject(scene); sceneWindow;

%% Run it through a sensor and render
%


oi = oiCreate; oi = oiCompute(oi,scene);
oi = piAIdenoise(oi);
oiWindow(oi);

sensor = sensorCreate;
sensor = sensorSet(sensor,'fov',sceneGet(scene,'fov'),oi);
sensor = sensorSet(sensor,'exp time',0.05);
sensor = sensorCompute(sensor,oi);
% sensorWindow(sensor);

ip = ipCreate;
ip = ipCompute(ip,sensor);
ipWindow(ip);


