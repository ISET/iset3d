function piRelativeIlluminance(options)
%% Obtain the relative illumination for a specific lens

% Created by Thomas Goossens, Stanford University, 2022
% Adapted for iset3d-v4, D.Cardinal
arguments
    options.lensfile = 'dgauss.22deg.50.0mm.json';
    options.figure = figure(1);
    options.sensorSize = 36;
    options.focalDistance = 3;
    options.pixelSamples = 600; % adjust to reduce noise if desired
end

if isa(options.figure,'double')
    % User sent in a 3-vector describing the subplot dimensions and panel
    assert(numel(options.figure) == 3);
    subplot(options.figure(1), options.figure(2), options.figure(3));
    useSubplot = true;
else
    % Create our own figure
    ourFigure = options.figure;
    useSubplot = false;
end

%% Define receipe with white surface
thisR = piRecipeDefault('scene','flatSurface');

% Set illuminant: make sure it is infinite, so it does not depend on the size of the target
% This is especially important for wide angle lenses
lightName = 'ourinfinite';
ourLight = piLightCreate(lightName,...
    'type','infinite');
recipeSet(thisR,'lights', ourLight,'add');

%% Define a Camera
camera = piCameraCreate('omni','lensfile',options.lensfile);
thisR.set('camera',camera);
thisR.set('focal distance', options.focalDistance); % DO this or adjust film distance

% You don't need much resolution because relative illumination is relatively slow in variation
filmresolution = [300 1];
sensordiagonal_mm = options.sensorSize;

thisR.set('pixel samples',options.pixelSamples);
thisR.set('film diagonal',sensordiagonal_mm,'mm');
thisR.set('film resolution',filmresolution);

%% Render scene
piWrite(thisR);
[oiTemp,result] = piRender(thisR);

%% Make Relative illumination plot
if useSubplot == false
    is ~isempty(ourFigure) ourFigure;
    clf;
end
hold on;

% Read horizontal line and normalize by maximum value
maxnorm = @(x)x/max(x);
relativeIllumPBRT = maxnorm(oiTemp.data.photons(1,:,1));

% Construct x axis [-filmwidth/2 .. filmwidth/2] for given film resolution
resolution = thisR.get('film resolution'); resolution=resolution(1);
xaxis = 0.5 * thisR.get('filmwidth') * linspace(-1,1,resolution);

% Plot the relative illumination
hpbrt = plot(xaxis,relativeIllumPBRT,'color',[0.83 0 0 ],'linewidth',2);

ylim([0 1]); % show on full scale for comparison with other lenses
xlim([0 inf]); % Only show positive x values because of symmetry
xlabel('Image height  on film (mm)');
