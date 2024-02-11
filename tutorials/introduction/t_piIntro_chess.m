%% Introducing iset3d calculations with the Chess Set
%
% Brief description:
%  This script renders the chess set scene.  
% 
%  This script:
%
%    * Initializes the recipe
%    * Sets the film (sensor) resolution parameters
%    * Calls the renderer that invokes PBRT via docker
%    * Loads the returned radiance and depth map into an ISET Scene structure.
%    * Adds a point light
%
% Dependencies:
%    ISET3d and either ISETCam or ISETBio
%
% See also
%   t_piIntro_*, piRecipeDefault, @recipe
%

%% Initialize ISET and Docker

% Start up ISET and check that docker is configured 
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the recipe

thisR = piRecipeDefault('scene name','chessset');
    
%% Set the render quality

% There are many rendering parameters.  This is an introductory
% script, so we set a minimal number of parameters.  Much of what is
% described in other scripts expands on this section.

thisR.set('film resolution',[256 256]);
thisR.set('rays per pixel',64);
thisR.set('n bounces',4); % Number of bounces traced for each ray

thisR.set('render type',{'radiance','depth'});

% The main way we write, render and show the recipe.  The render flag
% is optional, and there are several other optional piWRS flags.
scene = piWRS(thisR,'render flag','hdr');

%% By default, we have also computed the depth map, so we can render it

scenePlot(scene,'depth map');

%% Add a bright point light near the front where the camera is

thisR.show('lights');
thisR.set('light','all','delete');

% First create the light
pointLight = piLightCreate('point',...
    'type','point',...
    'cameracoordinate', true);

% Then add it to our scene
thisR.set('light',pointLight,'add');

piWRS(thisR,'name','Point light');

%% Add a skymap

[~, skyMap] = thisR.set('skymap','room.exr');

thisR.show('lights');

piWRS(thisR, 'name', 'Point light and skymap');

%% Rotate the skymap

thisR.set('light',skyMap.name,'rotate',[30 0 0]);

piWRS(thisR, 'name','Rotated skymap');

%% World orientation
thisR.set('light', skyMap.name, 'world orientation', [30 0 30]);
thisR.get('light', skyMap.name, 'world orientation')

piWRS(thisR, 'name','No rotation skymap');

%% END
