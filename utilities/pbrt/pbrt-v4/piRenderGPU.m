function [ieObject, result] = piRenderGPU(thisR,varargin)
% Read a PBRT scene file, run the docker cmd locally, return the ieObject.
%
% Syntax:
%  [oi or scene or metadata] = piRender(thisR,varargin)
%
% REQUIRED input
%  thisR - A recipe, whose outputFile specifies the file, OR a string that
%          is a full path to a scene pbrt file.
%
% OPTIONAL input parameter/val
%  oi/scene   - You can use parameters from oiSet or sceneSet that
%               will be applied to the rendered ieObject prior to return.
%
%  mean luminance -  If a scene, this mean luminance. If set to a negative
%                    value values returned by the renderer are used.
%                    (default 100 cd/m2)
%  mean illuminance per mm2 - default is 5 lux
%  scalePupilArea
%             - if true, scale the mean illuminance by the pupil
%               diameter in piDat2ISET (default is true)
%  reuse      - Boolean. Indicate whether to use an existing file if one of
%               the correct size exists (default is false)
%
%  verbose    - Level of desired output:
%               0 Silent
%               1 Minimal
%               2 Legacy -- for compatibility
%               3 Verbose -- includes pbrt output, at least on Windows
%
% RETURN
%   ieObject - an ISET scene, oi, or a metadata image
%   result   - PBRT output from the terminal.  This can be vital for
%              debugging! The result contains useful parameters about
%              the optics, too, including the distance from the back
%              of the lens to film and the in-focus distance given the
%              lens-film distance.
%
% Zhenyi, 2021
%
% See also
%   s_piReadRender*.m, piRenderResult

% Examples
%{
   % Renders both radiance and depth
   pbrtFile = fullfile(piRootPath,'data','V4','teapot','teapot-area-light.pbrt');
   scene = piRender(pbrtFile);
   sceneWindow(scene); sceneSet(scene,'gamma',0.5);
%}
%{
   % Render radiance and depth separately
   pbrtFile = fullfile(piRootPath,'data','V4','teapot','teapot-area-light.pbrt');
   scene = piRender(pbrtFile,'render type','radiance');
   ieAddObject(scene); sceneWindow; sceneSet(scene,'gamma',0.5);
   dmap = piRender(pbrtFile,'render type','depth');
   scene = sceneSet(scene,'depth map',dmap);
   sceneWindow(scene); sceneSet(scene,'gamma',0.5);
%}
%{
  % Separately calculate the illuminant and the radiance
  thisR = piRecipeDefault; piWrite(thisR);
  [scene, result]      = piRender(thisR);
  [illPhotons, result] = piRender(thisR);
  scene = sceneSet(scene,'illuminant photons',illPhotons);
  sceneWindow(scene);
%}
%{
  % Calculate the (x,y,z) coordinates of every surface point in the
  % scene.  If there is no surface a zero is returned.  This should
  % probably either a Inf or a NaN when there is no surface.  We might
  % replace those with a black color or something.
  thisR = piRecipeDefault; piWrite(thisR);
  [coords, result] = piRender(thisR, 'render type','coordinates');
  ieNewGraphWin; imagesc(coords(:,:,1));
  ieNewGraphWin; imagesc(coords(:,:,2));
  ieNewGraphWin; imagesc(coords(:,:,3));
%}
% cuda version:11.2.1
% Nvidia driver version: 460.32.03


%%  Name of the pbrt scene file and whether we use a pinhole or lens model

p = inputParser;
p.KeepUnmatched = true;

% p.addRequired('pbrtFile',@(x)(exist(x,'file')));
p.addRequired('recipe',@(x)(isequal(class(x),'recipe') || ischar(x)));

varargin = ieParamFormat(varargin);
p.addParameter('meanluminance',100,@isnumeric);
p.addParameter('meanilluminancepermm2',[],@isnumeric);
p.addParameter('scalepupilarea',true,@islogical);
p.addParameter('reuse',false,@islogical);
p.addParameter('reflectancerender', false, @islogical);
p.addParameter('dockerimagename','camerasimulation/pbrt-v4-gpu',@ischar);
p.addParameter('wave', 400:10:700, @isnumeric); % This is the past to piDat2ISET, which is where we do the construction.
p.addParameter('verbose', 2, @isnumeric);

p.parse(thisR,varargin{:});
dockerImageName  = p.Results.dockerimagename;
scalePupilArea = p.Results.scalepupilarea;
meanLuminance    = p.Results.meanluminance;
wave             = p.Results.wave;
verbosity        = p.Results.verbose;

%% We have a radiance recipe and we have written the pbrt radiance file

% Set up the output folder.  This folder will be mounted by the Docker
% image
outputFolder = fileparts(thisR.outputFile);
if(~exist(outputFolder,'dir'))
    error('We need an absolute path for the working folder.');
end
pbrtFile = thisR.outputFile;

%% Call the Docker for rendering

%% Build the docker command
dockerCommand   = 'docker run --gpus 1 -it';

[~,currName,~] = fileparts(pbrtFile);

% Make sure renderings folder exists
if(~exist(fullfile(outputFolder,'renderings'),'dir'))
    mkdir(fullfile(outputFolder,'renderings'));
end

outFile = fullfile(outputFolder,'renderings',[currName,'.exr']);

renderCommand = sprintf('pbrt --gpu --outfile %s %s', outFile, pbrtFile);

if ~isempty(outputFolder)
    if ~exist(outputFolder,'dir'), error('Need full path to %s\n',outputFolder); end
    dockerCommand = sprintf('%s --workdir="%s"', dockerCommand, outputFolder);
end
locallibPath = ['-v /usr/lib/nvidia-470/libnvoptix.so.1:/usr/lib/x86_64-linux-gnu/libnvoptix.so.1 ',...
    '-v /usr/lib/nvidia-470libnvoptix.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvoptix.so.470.57.02 ',...
    '-v /usr/lib/nvidia-470/libnvidia-rtcore.so.470.57.02:/usr/lib/x86_64-linux-gnu/libnvidia-rtcore.so.470.57.02'];
dockerCommand = sprintf('%s --volume="%s":"%s"', dockerCommand, outputFolder, outputFolder);

cmd = sprintf('%s %s %s %s', dockerCommand, locallibPath, dockerImageName, renderCommand);

%% Determine if prefer to use existing files, and if they exist.
tic;
[status, result] = piRunCommand(cmd, 'verbose', verbosity);
elapsedTime = toc;
% disp(result)
%% Check the return

if status
    warning('Docker did not run correctly');            % The status may contain a useful error message that we should
    % look up.  The ones we understand should offer help here.
    fprintf('Status:\n'); disp(status)
    fprintf('Result:\n'); disp(result)
    pause;
end

fprintf('*** Rendering time for %s:  %.1f sec ***\n\n',currName,elapsedTime);

%% Convert the returned data to an ieObject
ieObject = piEXR2ISET(outFile, 'recipe',thisR,'label',{'radiance','depth'});
%% We used to name here, but apparently not needed any more

% Why are we updating the wave?  Is that ever needed?
if isstruct(ieObject)
    switch ieObject.type
        case 'scene'
            % names = strsplit(fileparts(thisR.inputFile),'/');
            % ieObject = sceneSet(ieObject,'name',names{end});
            curWave = sceneGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = sceneSet(ieObject, 'wave', wave);
            end
            
        case 'opticalimage'
            % names = strsplit(fileparts(thisR.inputFile),'/');
            % ieObject = oiSet(ieObject,'name',names{end});
            curWave = oiGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = oiSet(ieObject,'wave',wave);
            end
            
        otherwise
            error('Unknown struct type %s\n',ieObject.type);
    end
end





