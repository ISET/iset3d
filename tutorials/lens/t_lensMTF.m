% Lens MTF validation renders remotely and is too expensive for the routine
% tutorial smoke test.
% SkipFile
% Remote-rendering MTF workflow; run manually when Docker/PBRT is available.

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create a camera. 

% This can be omni or ray transfer.
lensFile = 'dgauss.22deg.3.0mm.json';
camera = piCameraCreate('omni','lensfile',lensFile);

% Focus distance (play with this by setting it to 1, 5 or 10 (see chart distances))
camera.focusdistance.value = 1;  % As measured from film in meters

% Optionally force desired film  distance
%{
camera = rmfield(camera,'focusdistance')
camera.filmdistance.type='float'
camera.filmdistance.value=filmdistance/1000;   % millimeters to Meters
%}

%% Chart distance as measured from the camera film

chartDistancesFromFilm_mm = 500;        % 1 meter, in mm

%{
% We could loop over chart distances in some cases.
 chartDistancesFromFilm_mm = [0.1 0.5 1 5]*1000; % Compare multiple distances.
%}

%% Calculate MTF for each chart distance

filmwidth_mm = 0.5;
[mtfData, oiList] = piCalculateSlantedEdgeMTF('camera',camera,...
    'filmwidth',filmwidth_mm, ...
    'distances',chartDistancesFromFilm_mm,...
    'resolution',1024, ...
    'rays',256, ...
    'plot',false);

%% Compare ESF, LSF, and MTF

ieFigure([],'wide');
tiledlayout(1,3);

nexttile;
plot(mtfData.lsfx*1e3,mtfData.esf)
title('ESF'), xlabel('Position (microns)'), grid on

nexttile;
plot(mtfData.lsfx*1e3,mtfData.lsf);
title('LSF'); xlabel('Position (microns)');
grid on

nexttile;
plot(mtfData.freq,mtfData.mtf); 
title('MTF'); xlabel('Cycles/mm on sensor'); ylim([0 1]);
grid on

oiWindow(oiList{1});

%%
