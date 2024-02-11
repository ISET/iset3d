%% Explore area light parameters
%
% See also
%   s_arealight

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% 
fileName = fullfile(piRootPath, 'data','scenes','arealight','arealight.pbrt');
thisR    = piRead(fileName);
thisR.set('render type',{'radiance','depth'});
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

scene = piWRS(thisR,'render flag','hdr','mean luminance',-1);

%% Plot the luminance across a line

roiLocs = [1 100];
sz = sceneGet(scene,'size');
scenePlot(scene,'luminance hline',roiLocs);
ieROIDraw(scene,'shape','line','shape data',[1 sz(2) roiLocs(2) roiLocs(2)]);

%%
% t = thisR.get('light','Area_Yellow_L','rotate')

thisR.set('light','Area_Yellow_L','rotate',[-20 -30 -10]);
scene = piWRS(thisR,'render flag','rgb','mean luminance',-1);
thisR.set('asset','Plane_O','delete');
%%
% x and y are reversed between world position and the light position
wp = thisR.get('light','Area_Yellow_L','world position')
thisR.set('light','Area_Yellow_L','translate',[-5 0 0]);
scene = piWRS(thisR,'render flag','hdr','mean luminance',-1);


%% The intensity seems to be scaling with the square of the value
% So to reduce it by a factor of 2, we scale by sqrt(2)
% It may be that this factor depends on the shape of the area light.
% These are roughly square.  If they are linear, maybe the scaling does
% something else? (BW/DJC)

thisR.set('light','Area_Yellow_L','specscale',gScale/sqrt(2));
scene = piWRS(thisR,'render flag','hdr','mean luminance',-1);
uData2 = scenePlot(scene,'luminance hline',roiLocs);

%%
ieNewGraphWin;
plot(uData1.pos,uData1.data./uData2.data);

%% Can we scale it back?

thisR.set('light','Area_Yellow_L','specscale',gScale);
scene = piWRS(thisR,'render flag','hdr','mean luminance',-1);
uData1 = scenePlot(scene,'luminance hline',roiLocs);

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

