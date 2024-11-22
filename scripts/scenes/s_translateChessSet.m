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

% Now render a bunch of versions while translating the camera
numsteps = 64;
totaltravel = .1;

stepsize = totaltravel/numsteps;
lookAt = recipeGet(thisR,'lookAt');
lookAt.from(1) = lookAt.from(1) - totaltravel/2;
lookAt.to(1) = lookAt.to(1) - totaltravel/2;
% scene(numsteps) = ;
for ii=1:numsteps
    recipeSet(thisR,'lookAt',lookAt);
    scene(ii) = piWRS(thisR,'render flag','hdr');
    lookAt.from(1) = lookAt.from(1) + stepsize;
    lookAt.to(1) = lookAt.to(1) + stepsize;
end
