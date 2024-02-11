%% Illustrate rendering as the pinhole aperture size increases
%
% PBRT sets the pinhole radius of the perspective

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Load the EIA chart
eia = piAssetLoad('eia');
thisR = eia.thisR;

% Add a light
thisR.set('skymap','sky-sunlight.exr');
% piWRS(thisR);

%%  Increasing pinhole size 
radius = [0,logspace(-3,-1.8,3)];
for ii=1:numel(radius)
    thisR.set('lens radius',radius(ii));
    piWRS(thisR,'name',sprintf('Radius %.3f mm',radius(ii)));
end

%% An image for the slide
imageMultiview('scene',1:4,true);

%% End

