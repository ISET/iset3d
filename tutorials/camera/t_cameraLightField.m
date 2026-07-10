%% Simulate a light field camera based on a microlens array 
% We explain the idea of a light field camera built by placing a microlens array 
% in front of the image sensor. In that case, the pixels behind each microlens 
% code the rays that arrive from different locations within the lens.
% 
% ZL, BW SCIEN 2018
% 
% *Dependencies*: ISET3d, ISETCam, ISETLens
% 
% *See also:* 
% 
% t_piIntro_*, tls_camera*, s_sensorDPAF (ISETCam)
%% Initialize ISETCam, Docker and ISETLens, ISET3d

ieInit;
if ~piDockerExists, piDockerConfig; end

% Some scratch files are written, so we change to local to keep them
% out of the repository
chdir(fullfile(piRootPath,'local'));
%% Read the pbrt files
% Read the default chess set scene.  Later we are going to focus at a plane 
% about 0.6 m from the camera

thisR = piRecipeDefault('scene name','chessset');
thisR.set('rays per pixel',16);
% The preview render is useful interactively, but the final microlens render
% below is the tutorial's real visual checkpoint.
% scene = piWRS(thisR);
%% Choose the imaging lens
% This double gauss lenses has a 22 deg field of view.  It works well with the 
% chess set scene.  The focal length is a little shorter than expressed in the 
% file name.

imagingLens     = lensC('filename','dgauss.22deg.12.5mm.json');
imagingLens.draw;
fprintf('Focal length =  %.3f (mm)\nHeight = %.3f\n',...
    imagingLens.focalLength,imagingLens.get('lens height'));
%% Read in the microlens and set its size
% We will array up the microlenses.  They are positioned to be adjacent to one 
% another.  We set the size of each microlens so handle the number of pixels we 
% will have behind the lens.  In this case, we make the microlens size to be 12 
% microns.

mlensFile = fullfile(piDirGet('lens'), 'microlens.json');
microlens = lensC('filename',mlensFile);
microlens.draw;
mLensSize = 0.012;                       % mm
microlens.adjustSize(mLensSize);
fprintf('Focal length =  %.3f (mm)\nHeight = %.3f (mm)F-number %.3f\n',...
    microlens.focalLength,microlens.get('lens height'), microlens.focalLength/microlens.get('lens height'));
%% Set up the microlens array and film size
% The number of microlenses (nMicrolens) is the number of image samples in the 
% reconstructed images. We always choose an even number microlensese, which assures 
% that the sensor and ip data have the right integer relationships in the subsequent 
% calculation. 
% 
% The sensor size (film size) should be big enough to support all of the microlenses.
% 
% There are a lot of pixels (photosites), but fewer microlenses.  The number 
% of microlenses determines the effective spatial resolution.

% Keep the smoke-test render small.  Increase this to [40 40]*4 for the
% denser interactive example used in the original tutorial.
nMicrolens = [40 40];   % Appears to work for rectangular case, too
filmheight = nMicrolens(1)*microlens.get('lens height');
filmwidth  = nMicrolens(2)*microlens.get('lens height');

% The pixel size a is determined by the other factors
pixelsPerMicrolens = 5;  % The 2D array of pixels is this number squared
pixelSize  = microlens.get('lens height')/pixelsPerMicrolens;   % mm

% The number of photosites on the sensor (film)
filmresolution = [filmheight, filmwidth]/pixelSize;
%% Building the lens file 
% The optics includes the imaging lens and the microlens array.  This is specified 
% by  a big json file that is assembled using a special tool that is part of the 
% PBRT Docker container.

[~,imagingLensName,~] = fileparts(imagingLens.name);
[~,microLensName,e]   = fileparts(microlens.name);
combinedName = sprintf('%s+%s',imagingLensName,microLensName);
lensdir = fullfile(thisR.get('output dir'),'lens');
lensFile = fullfile(lensdir,combinedName);
if ~exist(lensdir,'dir'),mkdir(lensdir);end
lensFile = [lensFile,'.json'];

[combinedlens, info] = piMicrolensInsert(microlens,imagingLens,...
    'n microlens',nMicrolens,'output name',lensFile);
%% 
% This is the geometric arrangement

LFMicrolensGeometry(pixelSize,mLensSize);

%% Create the camera with the combined imaging lens and microlens
% In this part of the code we start to use the ISET3d rendering methods.

fprintf('Using lens: %s\n',combinedlens);
thisR.camera = piCameraCreate('omni','lensFile',combinedlens);

% PBRT estimates the distance.  It is not perfectly aligned to the depth
% map, but it is close.  For the Chess Set we use about 0.6 meters as the
% plane that will be in focus for this imaging lens.  With the lightfield
% camera we can reset the focus, of course.s
thisR.set('focal distance',0.6);

% This is the size of the film/sensor in millimeters
thisR.set('film diagonal',sqrt(filmwidth^2 + filmheight^2));

% Film resolution -
thisR.set('film resolution',filmresolution);

% We can use bdpt if you are using the docker with the "test" tag (see
% header). Otherwise you must use 'path'
thisR.set('integrator subtype','path');

% This is the aperture of the imaging lens of the camera in mm
thisR.set('aperture diameter',6);   % In millimeters

% Full summaries of the chess-set recipe are verbose in automated runs.
% thisR.summarize('all');
%% Render and then display

oiName = sprintf('%s-%d',thisR.get('input basename'),thisR.get('aperture diameter'));
oi = piWRS(thisR,'name',oiName);
%% Create a lightfield structure
% Next, we use Don Dansereau's  _Light Field toolbox_ routines (LF<tab>) to 
% analyze the data.  Here we work with the optical image data.  Later we will 
% work with the image processed data.
% 
% This routine converts the RGB image to the lightfield format used by the LF 
% library. It does this with knowledge of the number of microlenses. Notice that 
% this library uses x,y rather than row,col.

rgb = oiGet(oi,'rgb');
LF = LFImage2buffer(rgb,nMicrolens(2),nMicrolens(1));
%% Show the sub aperture views
% Once the data are in LF format, we extract corresponding samples from behind 
% each microlens and show the nMicrolens x nMicrolens  samples as separate images.  
% The LF toolbox calls these 'sub aperture' views.  There are pixelsPerMicrolens 
% x pixelsPerMicrolens images, and each is like looking through the imaging lens 
% from slightly different points of view.  Also, notice how we don't get a very 
% good view based on the photons at the corner samples.

[imgArray, imgCorners] = LFbuffer2SubApertureViews(LF);
ieFigure; imagesc(imgArray); axis image;
%% 
% If you want to see just one of the pictures, you can do this.  Maybe we should 
% write a function for this.  Notice that the corners are returned from the LFbuffer2SubApertureViews() 
% above.
%% Convert the OI through a matched sensor
% Next, we go through the image processor.  We create a sensor that has each 
% pixel equal to one sample in the OI.  There is a special _sensorCreate_ method 
% that creates a sensor matched to the light field at the optical image.  Each 
% pixel in the sensor samples each point in the optical image.

sensor = sensorCreate('light field',oi);
sensor = sensorCompute(sensor,oi);
% sensorWindow(sensor);
%% Image process ... should really use the whiteScene here

ip = ipCreate;
ip = ipCompute(ip,sensor);
% ipWindow(ip);
%% Convert the image processed data into a light field representation
% The lightfield variable, _lightfield_, has the dimensions
% 
% pixelsPerMicrolens x pixelsPerMicrolens x nMicrolens x nMicrolens x 3
% 
% We use an ISETCam function to convert the image processed data to the lightfield 
% format.  This is a little different from the LFImage2buffer function we used 
% earlier.

lightfield = ip2lightfield(ip,'pinholes',nMicrolens,'colorspace','srgb');
%% Video of the subaperture views
% You have to copy and past this line into the command prompt.  The video does 
% not play within the LiveScript well.  The command creates a little video that 
% cycles through the different subaperture views. To end the movie, click on the 
% window to select and then press Escape
% 
% Run this code by hand.  It doesn't do well with the LiveScript!

% This crashed Matlab the last time I ran it
%
% LFDispVidCirc(lightfield.^(1/2.2));
%

%% Additional ideas for more analyses
% I  found that Don Dansereau posted a recent (May 2020) GitHub update with 
% new features!  (https://github.com/doda42/LFToolbox).  A good project might 
% be to explore using the simulated data with some of the new functionality in 
% Don's toolbox.  One older example - autofocus - is here.  I never made it work, 
% however.

%{
% There are other LF functions to explore for visualizing the data.
  outputImage = LFAutofocus(lightfield);
  ieFigure;
  imagescRGB(outputImage);
%}
%{
% To adjust the focus for different scenes, use piRender with
% the 'depth map' option.  This lets you see how far away the scene objects
% are.
  dMap = piRender(thisR,'render type','depth');
  ieFigure; 
  imagesc(dMap); colormap(flipud(gray)); colorbar;
%}
%% 
%
