%% s_landscape
%
% This one is really big, and it must be read as Copy, not PARSE, for
% now.
%
% Read 269 materials and 861 textures.
%
% Several views ran right out of the box.   Not View-3, though.
% Needs much higher spatial resolution to
% look nice.  And lots of rays.
%
% TODO:  This could be put up on cardinal.stanford.edu

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Read, denoise, render

% There are a number of view
% view-3 did not load
thisR = piRecipeDefault('scene name','landscape','file','view-2.pbrt');
thisR.set('rays per pixel',512);
thisR.set('film resolution',[512 512]);
tic
scene = piWRS(thisR);
ieReplaceObject(piAIdenoise(scene)); sceneWindow;
toc

%%