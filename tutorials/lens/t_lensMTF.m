% Lens MTF validation renders remotely and is too expensive for the routine
% tutorial smoke test.
% SkipFile
% Remote-rendering MTF workflow; run manually when Docker/PBRT is available.

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Chart distance as measured from the camera film

chartDistancesFromFilm_mm = 1000;        % 1 meter, in mm
% chartDistancesFromFilm_mm = [1 5 10]*1000; % Compare multiple distances.

%% Create a camera. This can be omni or ray transfer.
camera = piCameraCreate('omni','lensfile','dgauss.22deg.3.0mm.json');

% Focus distance (play with this by setting it to 1, 5 or 10 (see chart distances))
camera.focusdistance.value =1;  % As measured from film in meters

% Optionally force desired film  distance
%camera = rmfield(camera,'focusdistance')
%camera.filmdistance.type='float'
%camera.filmdistance.value=filmdistance/1000;% milimeters to Meters

%% Calculate MTF for each chart distance

filmwidth_mm = 0.5;
[mtfData, oiList] = piCalculateSlantedEdgeMTF('camera',camera,...
    'filmwidth',filmwidth_mm, ...
    'distances',chartDistancesFromFilm_mm,...
    'resolution',1024, ...
    'rays',64, ...
    'plot',false);

%% Compare ESF, LSF, and MTF

figure(1);
subplot(1,3,1)
plot(mtfData.lsfx*1e3,mtfData.esf)
title('ESF')
xlabel('Position (microns)')
grid on

subplot(1,3,2)
plot(mtfData.lsfx*1e3,mtfData.lsf)
title('LSF')
xlabel('Position (microns)')
grid on

subplot(1,3,3)
plot(mtfData.freq,mtfData.mtf)
xlabel('Cycles/mm on sensor')
ylim([0 1])
title('MTF')
grid on

oiWindow(oiList{1});

%%
