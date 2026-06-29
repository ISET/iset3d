%% s_bistro
%
% Worked with cardinal download on July 11, 2022
%
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%

resolution = [640 640]*0.5;

thisR = piRecipeDefault('scene name','bistro');
% Equivalent:  thisR = piRecipeDefault('scene name','bistro,'file','bistro_vespa');
thisR.set('rays per pixel',256);
thisR.set('film resolution',resolution);

scene = piWRS(thisR,'resources remote',false);
ieReplaceObject(piAIdenoise(scene)); sceneWindow;

%%
thisR = piRecipeDefault('scene name','bistro','file','bistro_boulangerie.pbrt');
thisR.set('rays per pixel',256);
thisR.set('film resolution',resolution);

scene = piWRS(thisR,'resources remote',false);
ieReplaceObject(piAIdenoise(scene)); sceneWindow;

%%
thisR = piRecipeDefault('scene name','bistro','file','bistro_cafe.pbrt');
thisR.set('rays per pixel',256);
thisR.set('film resolution',resolution);

scene = piWRS(thisR);
ieReplaceObject(piAIdenoise(scene)); sceneWindow;

%%  You can see the depth from the depth map.
% scenePlot(scene,'depth map');

%% Another double Gauss

% lensList
lensfile  = 'dgauss.22deg.3.0mm.json';    % 30 38 18 10
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

thisR.set('film resolution',resolution);
thisR.set('film diagonal',5);  %% 33 mm is small
thisR.set('object distance',10);  % Move closer. 
piWRS(thisR,'name','DG');

%% Fisheye

lensfile = 'fisheye.87deg.3.0mm.json';
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

thisR.set('film resolution',resolution);
thisR.set('film diagonal',5);  %% 33 mm is small
thisR.set('object distance',10);  % Move closer. 
oi = piWRS(thisR,'name','fisheye 10m');

%%

