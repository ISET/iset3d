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

% Now render many images while translating the camera.
% This will produce a 'cube' of luminance images that we can slice through
% to see some surprising structure.  It is also the equivalent of what we
% might measure if we had an array of cameras along a straight line.
numsteps = 128;
totaltravel = .1;
stepsize = totaltravel/numsteps;

% Half the travel to the left and then to the right
lookAt = initialLookAt;
lookAt.from(1) = lookAt.from(1) - totaltravel/2;
lookAt.to(1)   = lookAt.to(1)   - totaltravel/2;

%% Maybe use remote rendering method because it is chess set.

for ii=1:numsteps
    fprintf('Step %d\n',ii);
    recipeSet(thisR,'lookAt',lookAt);
    thisScene = piWRS(thisR,'show',false,'remote resources', true);
    if ii==1
        sz = sceneGet(thisScene,'size');
        lum = zeros(sz(1),sz(2),numsteps);
    end
    lum(:,:,ii) = sceneGet(thisScene,'luminance');
    lookAt.from(1) = lookAt.from(1) + stepsize;
    lookAt.to(1) = lookAt.to(1) + stepsize;
end

%%  Have a look at a cross-section one row at a time

% The motion is right/left.  This reveals the epipolar geometry, but I need
% a better explanation.
tst = permute(lum,[2 3 1]);
hcViewer(tst.^0.5);

%%  Have a look at a cross-section one colun at a time

% Because of the direction of motion, the columns are just a scan of the
% original image
tst = permute(lum,[1 3 2]);
hcViewer(tst.^0.5);

% Fix a column
% for ii=1:size(lum,2)
%     imagesc(squeeze(lum(:,ii,:).^0.5)); axis image
%     title(sprintf('col %d',ii));
%     pause(0.1);
% end

%% Have a look at the luminance images face on

hcViewer(lum.^0.5)

%%
