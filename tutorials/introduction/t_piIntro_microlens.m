%% Render using a lens plus a microlens
%
% Dependencies:
%    ISET3d, ISETCam, JSONio
%
% Check that you have the updated docker image by running
%
%    docker pull vistalab/pbrt-v3-spectral
%
% ZL, BW SCIEN 2018
%
% See also
%   t_piIntro_*
%   isetLens repository

% Generally
% https://www.pbrt.org/fileformat-v3.html#overview
% 
% And specifically
% https://www.pbrt.org/fileformat-v3.html#cameras
%

%% Initialize ISET and Docker

ieInit;
if ~piDockerExists, piDockerConfig; end
if isempty(which('RdtClient'))
    error('You must have the remote data toolbox on your path'); 
end
%% Read the pbrt files

% sceneName = 'kitchen'; sceneFileName = 'scene.pbrt';
% sceneName = 'living-room'; sceneFileName = 'scene.pbrt';
sceneName = 'ChessSet'; sceneFileName = 'ChessSet.pbrt';

% The output directory will be written here to inFolder/sceneName
inFolder = fullfile(piRootPath,'local','scenes');
dest = piPBRTFetch(sceneName,'pbrtversion',3,...
    'destinationFolder',inFolder,...
    'delete zip',true);

% This is the PBRT scene file inside the output directory
inFile = fullfile(inFolder,sceneName,sceneFileName);
thisR  = piRead(inFile);

% We will output the calculations to a temp directory.  
outFolder = fullfile(tempdir,sceneName);
outFile   = fullfile(outFolder,[sceneName,'.pbrt']);
thisR.set('outputFile',outFile);
%% Set render quality

% Set resolution for speed or quality.
thisR.set('film resolution',round([600 400]*0.5));  % 1.5 is pretty high res
thisR.set('pixel samples',64);                      % 4 is Lots of rays .

%% Set output file

oiName = sceneName;
outFile = fullfile(piRootPath,'local',oiName,sprintf('%s.pbrt',oiName));
thisR.set('outputFile',outFile);
outputDir = fileparts(outFile);

%% Add camera with lens

% For both of the dgauss lenses 22deg is the half width of the field
% of view 

%{
lensfile = 'dgauss.22deg.3.0mm.json';
filmwidth = 1;
filmheight = filmwidth;
%}

% {
lensfile = 'dgauss.22deg.50.0mm.json';
filmwidth  = 11;
filmheight = 11;
%}
fprintf('Using lens: %s\n',lensfile);
combinedlens = lensfile;

% In millimeters.  Used to set diagonal and to set
% piCameraInsertMicrolens, somehow.  ASK MM.

% {
% microlensfile = 'microlens.2um.Example.json';
microlensfile = '2ElLens.json';
fprintf('Using microlens: %s\n',microlensfile);
% mLens = lensC('file name',microlensfile);
% mLens.draw;
%
% edit(microlensfile)

combinedlens = 'dgaussMicrolens.json';

combinedlens = piCameraInsertMicrolens(microlensfile,lensfile, ...
    'output name',combinedlens, ...
    'xdim',64,'ydim',64);
%     'film width',filmwidth,'film height',filmheight, ...
% thisLens = jsonread(combinedlens);
%


% Checking whether we might be able to add metadata to the lens file
% during this operation
% thisLens.metadata.test = 'test';
% jsonwrite(combinedlens,thisLens);
%
% Seems OK. So maybe we should pull that information out somehow and
% put it in the .json files, rather than using
% piRecipeFindOpticsParams?
%
%
% edit(combinedlens)
%}

%%
%{
 combinedlens = 'dgauss.22deg.50.0mm.json';
%}

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
% map, but it is close.
thisR.set('focus distance',0.6);

% The FOV is not used for the 'realistic' camera.
% The FOV is determined by the lens. 

% This is the size of the film/sensor in millimeters 
thisR.set('film diagonal',sqrt(filmwidth^2 + filmheight^2));

% Pick out a bit of the image to look at.  Middle dimension is up.
% Third dimension is z.  I picked a from/to that put the ruler in the
% middle.  The in focus is about the pawn or rook.
thisR.set('from',[0 0.14 -0.7]);     % Get higher and back away than default
thisR.set('to',  [0.05 -0.07 0.5]);  % Look down default compared to default

% We can use bdpt if you are using the docker with the "test" tag (see
% header). Otherwise you must use 'path'
thisR.integrator.subtype = 'path';  
thisR.sampler.subtype    = 'sobol';

% This value determines the number of ray bounces.  If the scene has
% glass or mirrors, we need to have at least 2 or more.
% thisR.set('nbounces',4); 

%% Render and display

% Change this for depth of field effects.
thisR.set('aperture diameter',6);   % thisR.summarize('all');
piWrite(thisR,'creatematerials',true);

[oi, result] = piRender(thisR,'render type','both');
oi = oiSet(oi,'name',sprintf('%s-%d',oiName,thisR.camera.aperturediameter.value));
oiWindow(oi);

%% The depth is not right any more

%{
 depth = piRender(thisR,'render type','depth');
 ieNewGraphWin;
 imagesc(depth);
%}


%% END