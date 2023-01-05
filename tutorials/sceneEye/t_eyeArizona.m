%% t_eyeArizona
%
% Run the Arizona eye model
%
% The script runs the Arizona eye model to show it runs.  But it contains
% comments to show how to turn on chromatic aberration, narrow the FOV, and
% look at the spread in more detail.
%
% See also
%   t_eyeNavarro, t_eyeLeGrand

%%
ieInit
if piCamBio
    error('Use ISETBio, not ISETCam');
end
if ~piDockerExists, piDockerConfig; end

%% Here are the World positions of the letters in the scene

% The units are in meters
toA = [-0.0486     0.0100     0.5556];
toB = [  0         0.0100     0.8333];
toC = [ 0.1458     0.0100     1.6667];

%% Show the scene

% This is rendered using a pinhole so the rendering is fast.  It has
% infinite depth of field (no focal distance).
thisSE = sceneEye('letters at depth','eye model','arizona');

% Position the eye off to the side so we can see the 3D easily
from = [0.25,0.3,-0.2];
thisSE.set('from',from);

% Look at the position with the 'B'.  The values for each of the letters
% are included above.
thisSE.set('to',toB);

% Have a quick check with the pinhole
thisSE.set('use pinhole',true);

% Given the distance from the scene, this FOV captures everything we want
thisSE.set('fov',30);             % Degrees

thisSE.recipe.set('render type', {'radiance','depth'});

%%  Render

% Render the scene with the GPU
thisDockerGPU = dockerWrapper;
thisSE.piWRS('docker wrapper',thisDockerGPU);
thisSE.summary;

%% Now use the optics model with chromatic aberration

% Turn off the pinhole.  The model eye (by default) is the Navarro model.
thisSE.set('use optics',true);

% True by default anyway
thisSE.set('mmUnits', false);

% We turn on chromatic aberration.  That slows down the calculation, but
% makes it more accurate and interesting.  We often use only 8 spectral
% bands for speed and to get a rought sense. You can use up to 31.  It is
% slow, but that's what we do here because we are only rendering once. When
% the GPU work is completed, this will be fast!

%{
% Needs to work with spectral path integrator.
% Zhenyi will make that work in V4.
nSpectralBands = 8;
thisSE.set('chromatic aberration',nSpectralBands);
%}

% Distance in meters to objects to govern accommodation.
thisSE.set('to',toA); distA = thisSE.get('object distance');
thisSE.set('to',toB); distB = thisSE.get('object distance');
thisSE.set('to',toC); distC = thisSE.get('object distance');
thisSE.set('to',toB);

% This is the distance we set our accommodation to that. Try distC + 0.5
% and then distA.  At a resolution of 512, I can see the difference.  I
% don't really understand the units here, though.  (BW).
%
% thisSE.set('accommodation',1/(distC + 0.5));  

thisSE.set('object distance',distC);  

% We can reduce the rendering noise by using more rays. This takes a while.
thisSE.set('rays per pixel',256);      

% Increase the spatial resolution by adding more spatial samples.
thisSE.set('spatial samples',256);     

% Ray bounces
thisSE.set('n bounces',3);

%% Have a at the letters. Lots of things you can plot in this window.

% dockerWrapper.reset();
% thisDocker = dockerWrapper;
% thisDocker.remoteCPUImage = 'digitalprodev/pbrt-v4-cpu';
% thisDocker.gpuRendering = 0;
% thisSE.recipe.set('render type', {'radiance','depth'});

thisSE.piWRS;

% Runs on the CPU on mux for humaneye case.
% oi = thisSE.render('docker wrapper',thisDocker);

% oiWindow(oi);

% Summarize
thisSE.summary;

%% Make an oi of the chess set scene using the LeGrand eye model

% thisSE = sceneEye('chess set scaled','human eye','arizona');
thisSE = sceneEye('chessset','eye model','arizona');

thisSE.set('rays per pixel',256);  % Pretty quick, but not high quality

thisSE.set('render type',{'radiance','depth'});

oi = thisSE.piWRS('show',false,'name','Arizona');

% oi = thisSE.render('docker wrapper',thisDocker);  % Render and show
% oi = oiSet(oi,'name','Arizona');

oi = piAIdenoise(oi);
oiWindow(oi);

%% Have a look with the slanted bar scene

% Commented out because it takes a while to run.  But in a way, seeing the
% chromatic aberration is the point.  So, I put it in here.  The slanted
% bar is at the focal distance.
thisSE = sceneEye('slantedEdge','eye model','arizona');
thisSE.set('to',[0 0 0]);

thisLight = piLightCreate('spot light 1', 'type','spot','rgb spd',[1 1 1]);
thisSE.set('light',thisLight, 'add');
thisSE.set('light',thisLight.name,'specscale',0.5);
thisSE.set('light',thisLight.name,'spd',[0.5 0.4 0.2]);
thisSE.set('fov',2);

% Debug something about reading the light.
% piAssetGeometry(thisSE.recipe);

thisSE.set('render type',{'radiance','depth'});
thisSE.set('rays per pixel',64);  % Pretty quick, but not high quality

thisSE.set('use pinhole',true);
thisSE.piWRS('docker wrapper',thisDockerGPU);  % Render and show
% scene = thisSE.render('docker wrapper',thisDockerGPU);  % Render and show
% sceneWindow(scene);

%%
% CA not working in V4 yet.
% thisSE.set('chromatic aberration',8);

thisSE.set('use pinhole',false);
thisSE.set('object distance',20);

oi = thisSE.piWRS('name','SB Arizona','show',false);
oi = piAIdenoise(oi); 
oiWindow(oi);

% oi = thisSE.render('docker wrapper',thisDWrapper);  % Render and show
% oi = oiSet(oi,'name','SB Arizona','show',false);

thisSE.summary;

%% END

