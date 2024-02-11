%% Example of rendering one of the pbrt V4 scenes
%
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% The contemporary bathroom took about 4 minutes to run on the muxreconrt.

% Read the original
thisR = piRead('/Users/wandell/Documents/MATLAB/iset3d-v4/data/V4/web/contemporary_bathroom/contemporary_bathroom.pbrt','exporter','Copy');

% Make sure the exporter is set to 'Copy' so all the files are copied
% thisR.set('exporter','Copy');
thisR.set('film resolution',[1920 1080]/4);  %?? x,y so (col, row)

scene = piWRS(thisR);
sceneSet(scene,'gamma',0.6);

%% The BMW

% Read the original
thisR = piRead('/Users/wandell/Documents/MATLAB/iset3d-v4/data/V4/web/bmw_m6/bmw_m6.pbrt','exporter','Copy');

% Make sure the exporter is set to 'Copy' so all the files are copied
% thisR.set('exporter','Copy');
thisR.set('film resolution',[1920 1080]/4);  %?? x,y so (col, row)

scene = piWRS(thisR);
sceneSet(scene,'gamma',0.6);


%% The BMW

% Read the original
thisR = piRead('/Users/wandell/Documents/MATLAB/iset3d-v4/data/V4/web/head/head.pbrt','exporter','Copy');

% Make sure the exporter is set to 'Copy' so all the files are copied
% thisR.set('exporter','Copy');
thisR.set('film resolution',[1920 1080]/4);  %?? x,y so (col, row)

scene = piWRS(thisR);
sceneSet(scene,'gamma',0.6);


%%  The bistro cafe took about 4 minutes just to sync 

% Read the original
thisR = piRead('/Users/wandell/Documents/MATLAB/iset3d-v4/data/V4/web/bistro_boulangerie/bistro_boulangerie.pbrt');

% Make sure the exporter is set to 'Copy' so all the files are copied
thisR.set('exporter','Copy');
thisR.set('camera position',[8 5.9 -35]);
thisR.set('film resolution',[1920 1080]/8);  %?? x,y so (col, row)
to = [9.6000    3.9000  -25.0000];
from = [8.0000    3.9000  -35.0000];
thisR.set('from',from + [0 -2 0]);
% thisR.set('to',to + [0 2 0]);
thisR.set('object distance',12);

scene = piWRS(thisR);
sceneSet(scene,'gamma',0.7);


%% Maybe we can set the exporter in piWRS call?

% The contemporary bathroom took about 4 minutes to run on the muxreconrt.

% Read the original
thisR = piRead('/Volumes/Wandell/PBRT-V4/pbrt-v4-scenes/head/head.pbrt');

% Make sure the exporter is set to 'Copy' so all the files are copied
thisR.set('exporter','Copy');

% Write it in local
piWrite(thisR);

% Render it on muxreconrt
scene = piRender(thisR);

% Show it.  Looks right with HDR rendering.  OK with gamma 0.6.
sceneWindow(scene);
sceneSet(scene,'gamma',0.6);

%% END

