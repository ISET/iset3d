%% t_eyeNavarro.m
%
% We recommend you go through t_eyeIntro.m before running
% this tutorial.
%
% This tutorial renders the PBRT SCENE "letters at depth" using the Navarro
% eye model.  The script illustrates how to
%
%   * set up a sceneEye with the Navarro model
%   * position the camera to center on a specific scene object
%   * render with chromatic aberration (slow)
%
% Depends on: 
%    ISETBio, ISET3d, Docker
%
% Wandell, 2020
%
% See also
%   t_eyeArizona, t_eyeLeGrand
%

%% Check ISETBIO and initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Here are the World positions of the letters in the scene

% The units are in meters
toA = [-0.0486     0.0100     0.5556];
toB = [  0         0.0100     0.8333];
toC = [ 0.1458     0.0100     1.6667];

%% Show the scene

% This is rendered using a pinhole so the rendering is fast.  It has
% infinite depth of field (no focal distance).
thisSE = sceneEye('letters at depth');

% First render with pinhole
thisSE.set('use pinhole',true);

thisSE.set('render type',{'radiance','depth'});

% Position the eye off to the side so we can see the 3D easily
from = [0.25,0.3,-0.2];
thisSE.set('from',from);

% Look at the position with the 'B'.
thisSE.set('to',toB);

% Set its distance
thisSE.set('object distance',1);  % meters

thisSE.set('to',toA); distA = thisSE.get('object distance');
thisSE.set('to',toB); distB = thisSE.get('object distance');
thisSE.set('to',toC); distC = thisSE.get('object distance');
thisSE.set('to',toB);

% To just see the 'B' at higher resolution use a small FOV
thisSE.set('fov',40);

% Render the scene
thisSE.set('render type', {'radiance','depth'});

%% Render as a scene with the GPU docker wrapper

thisDocker = dockerWrapper;
scene = thisSE.piWRS('docker wrapper',thisDocker,'name','pinhole');

% You can see the depth map if you like
%   scenePlot(scene,'depth map');

%% Now use the optics model with chromatic aberration

% Use the model eye
thisSE.set('use optics',true);

thisSE.set('pupil diameter',3);

% True by default anyway
% thisSE.set('mmUnits', false);

% We turn on chromatic aberration.  That slows down the calculation, but
% makes it more accurate and interesting.  We often use only 8 spectral
% bands for speed and to get a rought sense. You can use up to 31.  It is
% slow, but that's what we do here because we are only rendering once. When
% the GPU work is completed, this will be fast!

% This sets the chromaticAberrationEnabled flag and the integrator to
% spectral path.
% Now works in V4 - May 28, 2023 (ZL)
nSpectralBands = 8;
thisSE.set('chromatic aberration',nSpectralBands);

% We can reduce the rendering noise by using more rays. This takes a while.
thisSE.set('rays per pixel',256);      

% Increase the spatial resolution by adding more spatial samples.
thisSE.set('spatial samples',384);     

% Ray bounces
thisSE.set('n bounces',3);

% We want the scene to be around 5-10 deg so we do not need a lot of
% samples to resolve the blur.  This renders only the region around
% the 'B'.
thisSE.set('fov',7);             % Degrees

thisSE.get('sample spacing')
%% Change the accommodation.  But look at 'B'.

% Focus on the A
thisSE.set('accommodation',1/distA);  

% Summarize
thisSE.summary;

% Runs on the CPU on mux for humaneye case.  Make it explicit in this case.
thisDocker = dockerWrapper.humanEyeDocker;
thisSE.piWRS('docker wrapper',thisDocker,'name','navarro-A');

%{
oi = ieGetObject('oi'); oi = piAIdenoise(oi); 
ieReplaceObject(oi); oiWindow(oi);
%}

%% Change the accommodation.  But look at 'B'.

% Focus on the A
thisSE.set('accommodation',1/distB);  

% Summarize
thisSE.summary;

% Runs on the CPU on mux for humaneye case.  Make it explicit in this case.
thisDocker = dockerWrapper.humanEyeDocker;
thisSE.piWRS('docker wrapper',thisDocker,'name','navarro-A');

%{
oi = ieGetObject('oi'); oi = piAIdenoise(oi); 
ieReplaceObject(oi); oiWindow(oi);
%}


%% Set accommodation to a different distance.

% Focus on the C
thisSE.set('accommodation',1/distC);  

% Default renderer for sceneEye is humanEyeDocker, so try just the
% default.  Should also work.
thisSE.summary;
thisSE.piWRS('docker wrapper',thisDocker,'name','navarro-C');

%{
oi = ieGetObject('oi'); oi = piAIdenoise(oi); 
ieReplaceObject(oi); oiWindow(oi);
%}
%% END
