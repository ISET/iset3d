%% Cameras
% We render the chess set scene through a camera with a lens . The output is 
% the spectral irradiance at the sensor surface (the optical image).
% 
% This script  illustrates how to set the focal distance, and it reveals the 
% depth of field for this double Gauss lens.
%% 
% 
%% Set up ISETCam
% Also, make sure we have docker running.

ieInit;
if ~piDockerExists, piDockerConfig; end
if isempty(which('lensC'))
    error('You must add the isetlens repository to your path');
end
%% Read the PBRT scene

% thisR = piRecipeDefault('scene name','chessset');
thisDB = isetdb;
sceneName = 'ChessSet';
thisScene = thisDB.contentFind('PBRTResources', 'name',sceneName);
thisR = piRead(thisScene,'docker',isetdocker);

% thisR = piRecipeDefault('scene name','ChessSet');
thisR.set('spatial resolution',512);
%% Create a camera with a double Gauss lens

lensname    = 'dgauss.22deg.12.5mm.json';
doubleGauss = piCameraCreate('omni','lens file',lensname);

thisR.set('camera',doubleGauss);
%% 
% The distance that will be in focus

thisR.set('focus distance',0.8);
%% Change the camera position
% Set the camera position a little higher than default.  That makes it easier 
% to see the ruler on the chess board.

thisR.set('from',[0,0.18,-0.5]);
%% 
% Rotate the camera down a bit.  The (x,y) axes for this scene surpise me.

piCameraRotate(thisR, 'x rot',-10);
%% 
% Summarize the recipe information.  There is a lot for this scene.  But you 
% can handle it.

thisR.summarize;
%% Write and render

oi = piWRS(thisR,'render type','radiance','show',false);
oi = piAIdenoise(oi);
oiWindow(oi)
%% Change the focus distance to 0.4m

thisR.set('focus distance',0.4);
oi = piWRS(thisR,'render type','radiance','show',false); 
oi = piAIdenoise(oi);
oiWindow(oi)
%%