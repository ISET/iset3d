%% Render a Cornell box
%
% Zhenyi, SCIEN

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read a Cornell box pbrt file

sceneName = 'cornell_box';
thisR = piRecipeDefault('scene name',sceneName);

thisR.set('rays per pixel',128);
thisR.set('nbounces',5);

%% Add an area light at predefined region

% Should we delete all the lights and start clean?

thisR.set('lights','all','delete');

distantLight = piLightCreate('distantLight', ...
    'type','spot',...
    'cameracoordinate', true);
thisR.set('light',distantLight,'add');

%%  Rendering parameters


% By default, the fov is setted as horizontal and vertical
% fov = [10 10]; 
fov = [25 25]; 
% fov = [30 30];  % Default
% fov = [40 40];
% fov = [50 50];
thisR.set('fov',fov); 

% Increase the spatial resolution a bit
filmRes = [384 256];
thisR.set('film resolution',filmRes);

thisR.integrator.subtype ='directlighting'; 

%% Write and render

piWRS(thisR);

%% Add another point light

% The relative intensity is a problem.
%
% function [idx, light] = piLightFind(thisR,'param',val)
%
% spd = piLightGet(thisR,'idx',1,'param','spd');
%
% thisR = piLightDelete(thisR,2);
distantLight = piLightCreate('pointLight', ...
    'type','point',...
    'specscale', 1e-10, ...
    'from',[-0.25,-0.25,1.68]);
thisR.set('light','add',distantLight);

% thisR = piLightAdd(thisR, 'type', 'point', ...
%     'from',[-0.25,-0.25,1.68], ...
%     'spectrum scale', 1e-10);
% spd = piLightGet(thisR,'idx',2,'param','spd');
% ieNewGraphWin; plot(spd)

piWrite(thisR);
[scene, result] = piRender(thisR, 'rendertype', 'radiance');

sceneWindow(scene);
scene = sceneSet(scene,'mean luminance',100);
sceneSet(scene,'gamma',0.3);

%% Change light to D65

%{
lightsource = piLightGet(thisR);
thisR.set('lights','all','delete');

% When the light sources were all removed, this throws an error.
thisR = piLightAdd(thisR, 'type', 'area', 'lightspectrum', 'D65');
%}
%% END