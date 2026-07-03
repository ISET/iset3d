%% t_slantedBarMTF.m
%
% We recommend you go through t_rayTracingIntroduction.m before running
% this tutorial.
%
% This tutorial renders a retinal image of "slanted bar." We can then use
% this slanted bar to estimate the modulation transfer function of the
% optical system.
%
% We also show how the color fringing along the edge of the bar due to
% chromatic aberration. 
%
% Depends on: pbrt2ISET, ISETBIO, Docker, ISET
%
% TL ISETBIO Team, 2017

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Render a fast image of the slanted bar first

thisSE = sceneEye('slantedEdge','eye model','arizona');
thisSE.set('to',[0 0 0]);

% Illuminate with a blue light
thisLight = piLightCreate('spot light 1', 'type','spot','rgb spd',[0.5 0.5 1]);
thisSE.set('light',thisLight, 'add');
thisSE.set('light',thisLight.name,'specscale',0.5);
thisSE.set('fov',2);

thisSE.set('rays per pixel',256);   % Pretty quick, but not high quality
thisSE.set('spatial samples',512);  % Number of OI sample points
thisSE.set('object distance',20);   % Units are meters, I think (BW).

thisSE.set('use pinhole',true);
thisSE.summary;

dockerWrapper.reset;
thisDocker = dockerWrapper.humanEyeDocker;
thisSE.piWRS('docker wrapper',thisDocker,'name','slantedBar-pinhole');

%%  Put the object at the 
thisSE.set('use pinhole',false);
thisSE.set('object distance',0.5);   % Units are meters, I think (BW).

% I tried a series of object distances and accommodation values by
% hand. (BW).  Puzzling and in need of more fixing for calibration.
%{

  These were all for the arizona eye model
  We should make a new script and do it again for the navarro eye

  With an object distance of 1, accommodation value of
    1 was a bit blurry
    2 was more blurry
    0.5 was pretty sharp.

  
  With an object distance of 10, accommodation value of
    0.5 was quite blurry
    1 was more blurry
    0.25 was sharper
    0.2  was a bit sharper

  With an object distance of 0.5
    0.2 was weird and blue all of a sudden
    0.5 was sharper and still blue
    1   was sharp
    2   was blurry again
%}
thisSE.set('accommodation',1);     % Units are diopters (1/m)
thisSE.piWRS('docker wrapper',thisDocker,'name','slantedBar-eye');

%% Increase the  number of ray samples to get rid of graphics noise

% Needs work and calibration.  See above.  Also, this is old code.

%{
thisSE.set('rays per pixel',128);
oi = thisSE.render;
oiWindow(oi);

thisSE.set('chromatic aberration',false);
oi = thisSE.render;
oiWindow(oi);

%% Turn on chromatic aberration

% This is a lot slower.  8 bands or 4 bands is faster to just have a look.
nSpectralBands = 4;
thisSE.set('chromatic aberration',nSpectralBands);
oi = thisSE.render;
oiWindow(oi);

%% Focus infront of and behind the plane, which is at 1m

mean(thisSE.get('depth range'))   % Where is the plane?

thisSE.set('focal distance',0.5); % Set the focus off the plane
oi = thisSE.render;               % Render
oiWindow(oi);

thisSE.set('focal distance',5); % Set the focus off the plane
oi = thisSE.render;               % Render
oiWindow(oi);
%}

%%
% The slanted bar scene consists of a square plane (1x1 m) that is
% split in half diagonally. The bottom left half is white while the top
% right half is black. By default the plane is placed at [0 0 1] meters,
% but we can change that by given sceneEye an optional 'planeDistance'
% input.
%{
myScene = sceneEye('slantedBar'); % Create a slanted bar at 0.5 meter
myScene.set('mm units',false);
myScene.set('rays per pixel',64);
myScene.set('film resolution',[256 256]); 
myScene.set('accommodation',2);  % Diopters
myScene.set('pupil diameter',3); % mm
%}

% myScene.set('retina semidiam',1);  % mm
% myScene.set('retina radius',12);  % mm
% myScene.get('retina radius','m');  % mm
% myScene.get('retina semidiam','mm');  % mm


%% Try moving the slanted bar in and out of focus
%{
% A note on chromatic aberration:
% We can render chromatic aberration in the eye by tracing one ray per band
% of wavelength. The parameter, numCABands determines the number of band we
% will sample. We will trace a total of numRay x numCABands rays, meaning
% that the rendering will be ~(numCABands) times slower.
% 
% As we move the plane in and out of focus we can see the color fringes
% change due to longitudinal chromatic aberration.

planeDistance = [0.3 0.5 0.8]; % meters
% planeDistance = 0.8;  % Meters
for ii = 1:length(planeDistance)
    
    % myScene = sceneEye('slantedBar');
    
    myScene = sceneEye('slantedBar','planeDistance',planeDistance(ii)); % Create a slanted bar at 0.5 meter

    myScene.name = sprintf('slantedBar_%0.2fm',planeDistance(ii));
    
    myScene.numRays    = 64;
    myScene.resolution = 128;
    myScene.numCABands = 8;
    
    myScene.accommodation = 1/0.5; % Diopters
    myScene.pupilDiameter = 4;     % mm
    myScene.fov = 3;               % deg

    % Not in debug mode, so we have an OI
    oi = myScene.render;
    
    oiWindow(oi);

end
%}
%% Calculate the MTF 
% We can use the ISO12233 standard to calculate the MTF from a slanted bar.

% First render the slanted bar. You might want to increase the numRays and
% resolution for less noisy results. With numRays = 256 and resolution =
% 256, and numCABands = 16, this takes roughly 3 min to render on an 8 core
% machine.

%{
myScene = sceneEye('slantedBar','planeDistance',1);
myScene.name = 'slantedBarForMTF';
myScene.accommodation = 1;
myScene.fov = 2;
myScene.numCABands = 8;
myScene.numRays = 256;
myScene.resolution = 256;
oi = myScene.render;

oiWindow(oi);
%}

%% If you have isetlens-eye ( https://github.com/ISET/isetlens-eye) on your
% path, you can run the following:
% [freq,mtf] = calculateMTFfromSlantedBar(oi);
% figure();
% plot(freq,mtf);
% xlabel('Spatial Frequency (cycles/deg)');
% ylabel('Contrast Reduction (SFR)');
% grid on;
% axis([0 60 0 1])

%%  Otherwise, you can run this, which is essentially what
% calculateMTFfromSlantedBar does.

%{
% Crop the image so we only have the slanted line visible. The ISO12233
% routine will be confused by the edges of the retinal image if we don't
% first crop it.
cropRadius = myScene.resolution/(2*sqrt(2))-5;
oiCenter = myScene.resolution/2;
barOI = oiCrop(oi,round([oiCenter-cropRadius oiCenter-cropRadius ...
    cropRadius*2 cropRadius*2]));

% Convert to illuminance (resulting in a polychromatic MTF)
barOI = oiSet(barOI,'mean illuminance',1);
barImage = oiGet(barOI,'illuminance');

% Calculate MTF
figure;
deltaX_mm = oiGet(oi,'sample spacing')*10^3; % Get pixel pitch
[results, fitme, esf, h] = ISO12233(barImage, deltaX_mm(1),[1/3 1/3 1/3],'none');

% Convert to cycles per degree
mmPerDeg = 0.2852; % Approximate (assuming a small FOV and an focal length of 16.32 mm)
plot(results.freq*mmPerDeg,results.mtf);
xlabel('Spatial Frequency (cycles/deg)');
ylabel('Contrast Reduction (SFR)');
grid on;
axis([0 60 0 1])
%}

%%