%% s_bmwm6
%
% This one PARSED up without any editing from us, I think.
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

%% This fails.
[idMap, oList] = piLabel(thisR);

%%
ieNewGraphWin;image(idMap);  
colormap("prism"); axis image;

%% END