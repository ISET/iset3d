%% Render using a lightfield camera - lens and microlens array
%
%   Set up to work with the Chess Set scene.
%
% Dependencies:
%    ISET3d-v4, ISETCam, isetlens
%
% This script uses the docker container in two ways.  Once to build the
% lens file and a second way to render radiance and depth. 
%
% ZL, BW SCIEN 2018
%
% See also
%   t_piIntro_*, tls_cameraLightField.mlx

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end

chdir(fullfile(piRootPath,'local'))
if isempty(which('lensC')) 
    error('You must add the isetlens repository to your path'); 
end

%% Read the pbrt files
thisR = piRecipeCreate('Chess Set');

% This will run if you want.
% piWRS(thisR);

%% Read in the microlens and set its size

% This is a simple microlens file.
% We are making it big. 12 microns 
microlens     = lensC('filename','microlens.json');
desiredHeight = 0.012;                       % mm
microlens.adjustSize(desiredHeight);
microlens.draw;

%% Choose the imaging lens 

% For the double gauss lenses 22deg is the half width of the field of view.
% This focal length produces a decent part of the central scene.
imagingLens     = lensC('filename','dgauss.22deg.12.5mm.json');
imagingLens.draw;


%% Set up the microlens array and film size

% The nMicrolens is the number of image samples in the reconstructed
% images. 

% Always choose an even number for nMicrolens.  This assures that the
% sensor and ip data have the right integer relationships. 
nMicrolens = [40 40]*8;   % Appears to work for rectangular case, too

% The sensor size (film size) should be big enough to support all of the
% microlenses
filmheight = nMicrolens(1)*microlens.get('lens height');
filmwidth  = nMicrolens(2)*microlens.get('lens height');

% Set the number of pixels behind each microlens.  This determines the size
% of the pixel.
pixelsPerMicrolens = 7;  % The 2D array of pixels is this number squared
pixelSize  = microlens.get('lens height')/pixelsPerMicrolens;   % mm
filmresolution = [filmheight, filmwidth]/pixelSize;

%% Build the combined lens file
[combinedlens, info] = piMicrolensInsert(microlens,imagingLens,...
    'n microlens',nMicrolens);

%% Create the camera with the lens+microlens

thisR.camera = piCameraCreate('omni','lensFile',combinedlens);

%{
% You might adjust the focus for different scenes.  Use piRender with
% the 'depth map' option to see how far away the scene objects are.
% There appears to be some difference between the depth map and the
% true focus.
  dMap = piRender(thisR,'render type','depth');
  ieNewGraphWin; imagesc(dMap); colormap(flipud(gray)); colorbar;
%}

% PBRT estimates the distance.  It is not perfectly aligned to the depth
% map, but it is close.  For the Chess Set we use about 0.6 meters as the
% plane that will be in focus for this imaging lens.  With the lightfield
% camera we can reset the focus, of course.s
thisR.set('focus distance',0.6);

% The FOV is not used for the 'omni' camera.
% The FOV is determined by the lens. 

% This is the size of the film/sensor in millimeters 
thisR.set('film diagonal',sqrt(filmwidth^2 + filmheight^2));

% Film resolution -
thisR.set('film resolution',filmresolution);

% We can use bdpt if you are using the docker with the "test" tag (see
% header). Otherwise you must use 'path'
thisR.integrator.subtype = 'path';  

% This is the aperture of the imaging lens of the camera in mm
thisR.set('aperture diameter',6);   % In millimeters

thisR.summarize('all');

%% Render and display

oiName = sprintf('%s-%d',thisR.get('input basename'),thisR.get('aperture diameter'));
oi = piWRS(thisR,'name',oiName);

%% Lightfield manipulations

% These are based on
% Pull out the oi samples
rgb = oiGet(oi,'rgb');

% Convert these to the lightfield format used by the LF library.
LF = LFImage2buffer(rgb,nMicrolens(2),nMicrolens(1));

% Pull out the corresponding samples from the samples behind the pixel and
% show them as separate images
[imgArray, imgCorners] = LFbuffer2SubApertureViews(LF);

% Notice how the pixelsPerMicrolens x pixelsPerMicrolens images are looking
% through the imaging lens from slightly different points of view.  Also,
% notice how we lose photons at the corner samples.
ieNewGraphWin; imagesc(imgArray); axis image;  

%% Convert the OI through a matched sensor 

% We create a sensor that has each pixel equal to one sample in the OI 
sensor = sensorCreate('light field',oi);
sensor = sensorCompute(sensor,oi);
sensorWindow(sensor);

%% Image process ... should really use the whiteScene here

ip = ipCreate;
ip = ipCompute(ip,sensor);
ipWindow(ip);

%%  Convert the image processed data into a light field representation

% The lightfield variable has the dimensions
%
%  pixelsPerMicrolens x pixelsPerMicrolens x nMicrolens x nMicrolens x 3
%
lightfield = ip2lightfield(ip,'pinholes',nMicrolens,'colorspace','srgb');

% Click on window and press Escape to close
%
% LFDispVidCirc(lightfield.^(1/2.2));

%% Mouse around 

% You can use your mouse to visualize this way
%  LFDispMousePan(lightfield.^(1/2.2))

% This shows up as a movie that cycles through the different images
%
% Click on window to select and then press Escape to close the window
%
LFDispVidCirc(lightfield.^(1/2.2));
%% Focus on a region

%{
outputImage = LFAutofocus(lightfield);
ieNewGraphWin;
imagescRGB(outputImage);
%}


%% END