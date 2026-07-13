%% s_bmwm6
%
%  The BMW renders nicely, but piLabel does not run on this scene.
%
%  DEBUG in the future
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%
thisR = piRecipeDefault('scene name','bmw-m6');
thisR.set('skymap','room.exr');
scene = piWRS(thisR);

%% Denoise is OK.
ieReplaceObject(piAIdenoise(scene));

%% The piLabel command is not working correctly for this scene.
[idMap, oList] = piLabel(thisR);

%%
ieFigure;image(idMap);  
colormap("prism"); axis image;

%% END