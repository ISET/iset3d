%% t_piLightSpectrum
%
% Create a spotlight and assign a few built-in spectral descriptions.
% The tutorial renders only the final setting to keep the smoke test light.
%
% See also
%   t_piIntro_light

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the file and set low-cost render parameters

thisR = piRecipeDefault('scene name','checkerboard');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',2);
piCameraTranslate(thisR,'z shift',2);

%% Add one equal-energy spotlight

thisR.set('light','all','delete');
spotLight = piLightCreate('spot1',...
    'type','spot',...
    'spd','equalEnergy',...
    'specscale float',1,...
    'coneangle',20,...
    'cameracoordinate',true);
thisR.set('light',spotLight,'add');

thisR.get('light print');

%% Change the spectrum without rendering each intermediate state

spdNames = {'tungsten','D50'};
for ii = 1:numel(spdNames)
    thisR.set('lights','spot1_L','spd',spdNames{ii});
    fprintf('Updated spot1_L spectrum to %s\n',spdNames{ii});
end

thisR.set('lights','spot1_L','spd',3000);
fprintf('Updated spot1_L spectrum to 3000 K blackbody\n');

%% Render once

scene = piWRS(thisR,'name','3K spot','render flag','hdr');
fprintf('Mean luminance: %.3f cd/m2\n',mean(sceneGet(scene,'luminance'),'all'));

%% END
