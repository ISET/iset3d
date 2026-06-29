%% s_opticsPinhole
% 
% Illustrate rendering as the pinhole aperture size increases
%
% PBRT sets the pinhole radius of the perspective
%
% I suspect that the units of the pinhole diameter are not correct
% here.  The blurring is too great for the 20 micron pinhole. This is
% a question of the units in PBRT.
%
% This script is amplified in fise_01Pinhole.mlx (psych221).
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Load the chess scene

thisR = piRecipeDefault('scene name','chessset');

%%  Increasing pinhole size 
radius = [0,logspace(-3,-2,3)];
img = cell(4,1);
for ii=1:numel(radius)
    thisR.set('lens radius',radius(ii));
    scene = piWRS(thisR,'name',sprintf('Radius %.3f mm',radius(ii)));
    scene = piAIdenoise(scene);
    img{ii} = sceneGet(scene,'srgb');
    ieReplaceObject(scene);
end

%%
ieNewGraphWin; montage(img);
%% End

