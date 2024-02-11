%% Introducing iset3d calculations with the Chess Set
%
% Brief description:
%  This script renders the chess set scene to illustrate the lighting.  It
%  does so by changing the materials of the chess set to
%  diffuse-white.
% 
%    * Initializes the recipe
%    * Sets the film (sensor) resolution parameters
%    * Calls the renderer that invokes PBRT via docker
%    * Loads the returned radiance and depth map into an ISET Scene structure.
%    * Adds a point light
%    * Adds a skymap
%
% Dependencies:
%    ISET3d and either ISETCam or ISETBio
%
% See also
%   t_piIntro_*, piRecipeDefault, @recipe
%

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the chess set recipe

thisR = piRecipeCreate('chess set');

%% Set the render quality

% There are many rendering parameters.  This is the just an introductory
% script, so we set a minimal number of parameters.  Much of what is
% described in other scripts expands on this section.
thisR.set('film resolution',[256 256]);
thisR.set('rays per pixel',256);
thisR.set('n bounces',4); % Number of bounces traced for each ray

thisR.set('skymap','sky-blue-sun.exr');

piWRS(thisR);

%% Render with just ambient and then three different point sources

% CFL_2471
% CFL_5780
% D50, D65, D75
% halogen_2913
% LED_4613
% Tungsten

thisR.set('light', 'all', 'delete');
whitePoint = piLightCreate('mainLight_L',...
    'type', 'point', ...
    'spd spectrum', 'Tungsten',...
    'specscale float', 1,...
    'cameracoordinate', true);
thisR.set('light',whitePoint,'add');
thisR.set('skymap','sky-blue-sun.exr');
piWRS(thisR);

%%

thisR.set('light', 'all', 'delete');
whitePoint = piLightCreate('mainLight_L',...
    'type', 'point', ...
    'spd spectrum', 'CFL_5780',...
    'specscale float', 1,...
    'cameracoordinate', true);
thisR.set('light',whitePoint,'add');
thisR.set('skymap','sky-blue-sun.exr');
piWRS(thisR);

%%
thisR.set('light', 'all', 'delete');
whitePoint = piLightCreate('mainLight_L',...
    'type', 'point', ...
    'spd spectrum', 'D75',...
    'specscale float', 1,...
    'cameracoordinate', true);
thisR.set('light',whitePoint,'add');
thisR.set('skymap','sky-blue-sun.exr');
piWRS(thisR);

%%
thisR.show('lights');
l = thisR.get('light','mainLight');
l.lght{1}.spd
%{
% The light is an asset with a special slot .lght
% The slot is a cell array (not sure why).
% You can set the entries of struct lght{1}
%
thisR.set('light','mainLight','specscale',5);
thisR.set('light','mainLight','spd',[.3 .5 1]);
thisR.set('skymap','room.exr');
%}

%%  The scene does not have the true illuminant spectrum
%
% We should find a way to update it into the ISET scene from the recipe.
%
% piWRS(thisR);

%%
rgb = cell(4,1);
for ii=1:4
    vcSetSelectedObject('scene',ii);
    scene = ieGetObject('scene');
    scene = piAIdenoise(scene);
    rgb{ii} = sceneGet(scene,'srgb');
end

ieNewGraphWin;
montage(rgb);

%% Look for the linear transform between RGB values

comp = [2,3];
vcSetSelectedObject('scene',comp(1));     
scene = ieGetObject('scene');
scene = piAIdenoise(scene);
srgb1 = sceneGet(scene,'srgb');
lrgb1 = srgb2lrgb(srgb1);

vcSetSelectedObject('scene',comp(2));     
scene = ieGetObject('scene');
scene = piAIdenoise(scene);
srgb2 = sceneGet(scene,'srgb');
lrgb2 = srgb2lrgb(srgb2);

xw1 = RGB2XWFormat(lrgb1);
xw2 = RGB2XWFormat(lrgb2);

% M = pinv(xw1)*xw2;  xw2 = xw1*M;
M = xw1\xw2;  

pred2 = xw1*M;

%% How well did we do with the prediction?

ieNewGraphWin([],'wide');
subplot(1,2,1)
plot(xw2(1:10:end),xw1(1:10:end),'.');
identityLine;
xlabel('lRGB2'); ylabel('lRGB1'); grid on;

subplot(1,2,2)
plot(xw2(1:10:end),pred2(1:10:end),'.');
identityLine;
xlabel('lRGB2'); ylabel('lRGB1'); grid on;

%%
ieNewGraphWin;
rgbPred2 = XW2RGBFormat(pred2,size(srgb2,1),size(srgb2,2));
rgbPred2 = ieClip(rgbPred2,0,1);
srgbPred2 = lrgb2srgb(rgbPred2);

montage({srgb1,srgb2,srgbPred2},'Size',[1 3]);


%% Plot the spectra

wave = 400:2:700;
tungsten = ieReadSpectra('Tungsten',wave);
cfl = ieReadSpectra('CFL_5780',wave);
d75 = ieReadSpectra('D75',wave);
tungsten = ieScale(tungsten,1);
cfl = ieScale(cfl,1);
d75 = ieScale(d75,1);

ieNewGraphWin; 
p = plot(wave,tungsten,'r-',wave,cfl,'k-',wave,d75,'b-');
for ii=1:3
    p(ii).LineWidth = 2;
end
grid on;
xlabel('Wavelength (nm)')
ylabel('Relative radiance');

%% END

