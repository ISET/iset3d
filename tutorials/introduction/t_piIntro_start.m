%% The first in a series of scripts introducing iset3d calculations
%
% Brief description:
%
%  This introduction renders the sphere scene in the data directory of the
%  ISET3d repository. This introduction sets up a very simple recipe, runs
%  the docker command, and loads the result into an ISET scene structure.
% 
% Dependencies:
%    ISET3d, (ISETCam or ISETBio), JSONio
%
%  Check that you have the updated docker image by running
%
%    docker pull vistalab/pbrt-v3-spectral
%
% TL, BW, ZL SCIEN 2017
%
% See also
%   t_piIntro_*

%% Initialize ISET and Docker

% We start up ISET and check that the user is configured for docker
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file

thisR = piRecipeDefault('scene name','sphere');

%% Add a point light
thisR = piLightAdd(thisR, 'type', 'point', 'camera coordinate', true);

%% Set up the render quality

% There are many different parameters that can be set.
thisR.set('film resolution',[192 192]);
thisR.set('pixel samples',128);
thisR.set('max depth',1); % Number of bounces

%% Render
piWrite(thisR);

%% This is a pinhole case. So we are rendering a scene.

[scene, result] = piRender(thisR);
sceneWindow(scene);

%% Notice that we also computed the depth map
scenePlot(scene,'depth map');

%%