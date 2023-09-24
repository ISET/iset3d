%% Explore light creation with new area light parameters
%
% The area lights were implemented by Zhenyi to help us accurately simulate
% the headlights in night time driving scenes.
%
% The definitions of the shape of the area light are in the
% arealight_geometry.pbrt file.  Looking at the text there should give
% us some ideas about how to create more area lights with different
% properties.
%
% This script should explore setting the SPD of the lights and perhaps
% making different shapes and intensities.
%
% See also
%   s_arealight

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% 
fileName = fullfile(piRootPath, 'data','scenes','arealight','arealight.pbrt');
thisR    = piRead(fileName);
thisR.get('print lights')

% The no number is the blue one
% The 002 light is the green one.
% The 001 is the red one
% the 003 must be the yellow one.

%% This sets the name of the light asset.  
%
% The name must always have a _L if it is a light. There is also a
% name in the 'lght{1}' slot. That should probably be set to align
% with this name.
thisR.set('light','AreaLightRectangle_L','name','Area_Blue_L');
thisR.set('light','AreaLightRectangle.001_L','name','Area_Red_L');
thisR.set('light','AreaLightRectangle.002_L','name','Area_Green_L');
thisR.set('light','AreaLightRectangle.003_L','name','Area_Yellow_L');
thisR.show('lights');

scene = piWRS(thisR,'render flag','hdr');

%% Plot the luminance across a line

roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%% The green light is bright.  Let's reduce its intensity.
gScale = thisR.get('light','Area_Green_L','specscale');

thisR.set('light','Area_Green_L','specscale',gScale/4);
scene = piWRS(thisR,'render flag','hdr');

%%
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%% Set the light adjust the light properties

lNames = thisR.get('light','names');

% The spread of car headlights is about 
for ii=1:numel(lNames)
    thisR.set('light',lNames{ii},'spread val',ii*10);
end

scene = piWRS(thisR,'render flag','hdr');

%% Plot the luminance
roiLocs = [1 74];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

roiRect = [416 124 34 42];
scenePlot(scene,'radiance energy roi',roiRect);
ieROIDraw(scene,'shape','rectangle','shape data',roiRect);%%

% The yellow must be in the plane
thisR.set('asset', 'Area_Yellow_L', 'rotate', [-30, 0, 0]); % -5 degree around y axis

% The red and blue are in the plane
thisR.set('asset', 'Area_Red_L', 'rotate', [0, 0, 30]); % -5 degree around y axis
thisR.set('asset', 'Area_Blue_L', 'rotate', [0, 0, -30]); % -5 degree around y axis

piWRS(thisR,'render flag','hdr');

%% Change the SPD of the lights to halogen

lList = {'LED_3845','LED_4613','halogen_2913','CFL_5780'};

% Setting the name is enough.  At some point we read the light file
% and write out the values in piWRS().
thisR.set('light','Area_Yellow_L','spd',lList{1});
thisR.set('light','Area_Red_L','spd',lList{2});
thisR.set('light','Area_Green_L','spd',lList{3});
thisR.set('light','Area_Blue_L','spd',lList{4});

piWRS(thisR,'render flag','hdr');

%%  Spectrum of an LED light that might be found in a car headlight

ieNewGraphWin; hold on;
for ii=1:numel(lList)
    [ledSPD,wave] = ieReadSpectra(lList{ii});
    if ii==1, plotRadiance(wave,ledSPD);
    else, hold on; plot(wave,ledSPD);
    end
end

for ii=1:numel(lList)
    [ledSPD,wave] = ieReadSpectra(lList{ii});
    XYZ = ieXYZFromEnergy(ledSPD',wave);
    xy  = chromaticity(XYZ);
    if ii == 1
        chromaticityPlot; 
        hold on; plot(xy(1),xy(2),'o');
    else, hold on; plot(xy(1),xy(2),'o');
    end
end

%% END

