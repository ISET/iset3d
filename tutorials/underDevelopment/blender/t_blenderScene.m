%% Illustrates rendering a scene exported from blender using blender2pbrt exporter
%
% Zhenyi, 2021
%%
ieInit;
if ~piDockerExists, piDockerConfig; end
%%
fileName = '/Users/zhenyi/Desktop/chart_blender/esfr/esfr.pbrt';
thisR = piRead(fileName);

thisR.set('film resolution',thisR.get('film resolution')/4);
thisR.set('rays per pixel',8);
%% set render type
thisR.set('film render type',{'radiance','depth'})

%% write the data out

scene = piWRS(thisR);
 %{
tic
piWrite(thisR);
scene = piRender(thisR);
sceneWindow(scene);
toc
%}