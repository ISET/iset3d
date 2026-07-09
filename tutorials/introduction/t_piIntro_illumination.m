%% Introducing illumination with the Chess Set
%
% This short tutorial shows how to replace the default lights in a recipe
% with a point light and how to inspect the light spectrum.
%
% See also
%   t_piIntro_*, piLightCreate, recipe/set

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the chess set recipe

thisR = piRecipeCreate('chess set');
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('n bounces',2);

%% Replace the default lighting with one camera-centered point light

thisR.set('light', 'all', 'delete');

mainLight = piLightCreate('mainLight_L',...
    'type', 'point', ...
    'spd spectrum', 'D75',...
    'specscale float', 1,...
    'cameracoordinate', true);
thisR.set('light',mainLight,'add');

thisR.show('lights');
lightStruct = thisR.get('light','mainLight');
fprintf('Light SPD source: %s\n',lightStruct.lght{1}.spd.value);

%% Render once

scene = piWRS(thisR,'render flag','hdr');

% A compact quantitative checkpoint for the tutorial runner and readers.
fprintf('Mean luminance %.3f cd/m2\n',sceneGet(scene,'mean luminance'));

%% Plot spectra for a few common illuminants

wave = 400:10:700;
tungsten = ieScale(ieReadSpectra('Tungsten',wave),1);
cfl = ieScale(ieReadSpectra('CFL_5780',wave),1);
d75 = ieScale(ieReadSpectra('D75',wave),1);

ieNewGraphWin;
plot(wave,tungsten,'r-',wave,cfl,'k-',wave,d75,'b-','LineWidth',2);
grid on;
xlabel('Wavelength (nm)');
ylabel('Relative radiance');
legend({'Tungsten','CFL 5780','D75'},'Location','best');

%% END
