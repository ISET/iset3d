clear; close all
%% Difference distances of chart as measured from the camera film

chartDistancesFromFilm_mm=[1 5 10]*1000; % meter to mm

%% Create a camera , this can be omni or RTF
camera= piCameraCreate('omni','lensfile',['dgauss.22deg.3.0mm.json']);

% Focus distance (play with this by setting it to 1, 5 or 10 (see chart distances))
camera.focusdistance.value =1;  % As measured from film in meters

% Optionally force desired film  distance
%camera = rmfield(camera,'focusdistance')
%camera.filmdistance.type='float'
%camera.filmdistance.value=filmdistance/1000;% milimeters to Meters

%% Calculate MTF's for all chart distances


    filmwidth_mm=0.01;
 [MTF,LSF,ESF] = piCalculateMTF('camera',camera,'filmwidth',filmwidth_mm,'distances',chartDistancesFromFilm_mm,...
    'resolution',2000,'rays',1000);


%% Comparison off all three quantities: ESF, LSF, MTF

figure(1);
subplot(131)
colororder([1 0 0 ; 0  1 0 ;  0 0 1])

plot(ESF.pixelsMicron,ESF.ESF)
title('ESF')
xlabel('Micron')
subplot(132)
% LSF is a derivative of ESF  and can hence be very noise depending on
% rendering noise level
% In the MTF this high frequency noise is not a huge issue
plot(LSF.pixelsMicron,LSF.LSF)
colororder([1 0 0 ; 0  1 0 ;  0 0 1])

xlim(0.5*[-1 1])
title('LSF')
xlabel('Micron')
subplot(133)
plot(MTF.cyclespermilimeter,MTF.MTF)
xlabel('cy/mm')
ylim([0 1])
xlim([0 1000])
title('MTF')



