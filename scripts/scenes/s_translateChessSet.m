%% Initialize ISET and Docker

% Start up ISET and check that docker is configured 
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the recipe

thisR = piRecipeDefault('scene name','chessset');

initialLookAt = thisR.get('lookat');

%% Set the render quality

% There are many rendering parameters.  This is an introductory
% script, so we set a minimal number of parameters.  Much of what is
% described in other scripts expands on this section.

thisR.set('film resolution',[256 256]);
thisR.set('rays per pixel',64);
thisR.set('n bounces',4); % Number of bounces traced for each ray

thisR.set('render type',{'radiance','depth'});

%% The main way we write, render and show the recipe.  The render flag
% is optional, and there are several other optional piWRS flags.

% Now render a bunch of versions while translating the camera
numsteps = 64;
totaltravel = .1;
stepsize = totaltravel/numsteps;

% Half the travel to the left and then to the right
lookAt = initialLookAt;
lookAt.from(1) = lookAt.from(1) - totaltravel/2;
lookAt.to(1)   = lookAt.to(1)   - totaltravel/2;

%% Maybe use remote method
for ii=1:numsteps
    recipeSet(thisR,'lookAt',lookAt);
    thisScene = piWRS(thisR,'render flag','rgb');
    if ii==1
        sz = sceneGet(thisScene,'size');
        lum = zeros(sz(1),sz(2),numsteps);
    end
    lum(:,:,ii) = sceneGet(thisScene,'luminance');
    lookAt.from(1) = lookAt.from(1) + stepsize;
    lookAt.to(1) = lookAt.to(1) + stepsize;
end


%% Have a look at the luminance images face on

ieNewGraphWin; axis image; colormap(gray);
for ii=1:numsteps
    imagesc(lum(:,:,ii).^0.5); axis image
    pause(0.5);
end

