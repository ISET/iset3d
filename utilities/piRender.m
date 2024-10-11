function [ieObject, result, thisD, outFile] = piRender(thisR, varargin)
% Read a PBRT scene file, run the docker command, return the ieObject.
%
% Synopsis
%   [ieObject, result, thisD] = piRender(thisR,varargin)
%
% Input
%  thisR - An ISET3d recipe
%
% OPTIONAL key/val pairs
%
%  rendertype - Any combination of these strings
%        {'radiance', 'radiancebasis', 'depth', 'material', 'instance', 'illuminance'}
%
%  {oi or scene} params - Parameters from sceneSet or oiSet that will
%                         be applied to the rendered ieObject prior to
%                         return.
%
%  mean luminance -  If a scene, this mean luminance. If set to a negative
%            value values returned by the renderer are used.
%            (default 100 cd/m2)
%
%  mean illuminance per m2 - If an oi, this is mean illuminance
%            (default is 5 lux)
%
%  scalePupilArea
%             - if true, scale the mean illuminance by the pupil
%               diameter in piDat2ISET (default is true)
%
%  reuse      - Boolean. Indicate whether to use an existing file if one of
%               the correct size exists (default is false)
%
%  ourdocker  - Specify the docker wrapper to use.  Default is build
%               from scratch with defaults in the Matlab getprefs('docker')
%
%  verbosity  - How much to print to standard output:
%               0 Silent
%               1 Minimal
%               2 Legacy -- for compatibility
%               3 Verbose -- includes pbrt output, at least on Windows
%
%  denoise    - Apply denoising, default 'none'
%               also: 'exr_radiance', 'exr_albedo', 'exr_all' (includes
%               normal)
%               ** These assume the recipe asks for them and the camera
%               type supports them.
%
%  wave      -   Adjust the wavelength sampling of the returned ieObject
%
% Output:
%   ieObject - an ISET scene, oi, or a metadata image
%   result   - PBRT terminal output. The result is very useful for
%              debugging because it contains Warnings and Errors. The
%              text also contains parameters about the optics,
%              including the distance from the back of the lens to
%              film and the in-focus distance given the lens-film distance.
%   thisD    - the isetdocker used for the rendering.  Useful if
%              you want to use it next as the ourdocker specification.
%
% See also
%   s_piReadRender*.m, piRenderResult, isetdocker

% Examples:
%{
  % Calculate only the radiance.
  thisR = piRecipeDefault('scene name','ChessSet');
  piWRS(thisR);  
%}
%{
  % Calculate the (x,y,z) coordinates of every surface point in the
  % scene.  If there is no surface a zero is returned.  This should
  % probably either a Inf or a NaN when there is no surface.  We might
  % replace those with a black color or something.
  thisR = piRecipeDefault('scene name', 'ChessSet'); 
  piWrite(thisR,'remote resources',true);
  [coords, result] = piRender(thisR, 'render type','coordinates');
  ieNewGraphWin; imagesc(coords(:,:,1));
  ieNewGraphWin; imagesc(coords(:,:,2));
  ieNewGraphWin; imagesc(coords(:,:,3));
%}
%{
% get materials
  thisR = piRecipeDefault('scene name', 'ChessSet'); piWrite(thisR);
  [aScene, metadata] = piRender(thisR, 'render type','material');
%}
%{
% Render locally with your CPU machine
  thisR = piRecipeDefault('scene name', 'ChessSet');
  thisDocker = isetdocker;
  thisDocker.gpuRendering = false;
  thisDocker.localRender = true; 
  thisDocker = isetdocker('localRender',true,'gpuRendering', false,'verbosity',0);
  scene = piWRS(thisR,'our docker',thisDocker);
%}

%% Init ISET prefs.

%  If ISET3d prefs are not already set, this will initialize.
piPrefsInit

%%  Name of the pbrt scene file and whether we use a pinhole or lens model

p = inputParser;
p.KeepUnmatched = true;

p.addRequired('recipe',@(x)(isequal(class(x),'recipe') || ischar(x)));

varargin = ieParamFormat(varargin);
p.addParameter('meanluminance',getpref('ISET3d','meanluminance'),@isnumeric);   % radiance
p.addParameter('meanilluminance',getpref('ISET3d','meanilluminance'),@isnumeric);  % irradiance
p.addParameter('scalepupilarea',true,@islogical);
p.addParameter('reuse',false,@islogical);
p.addParameter('docker',[],@(x)(isa(x,'isetdocker'))); % isetdocker object

% This passed to piDat2ISET, which is where we do the construction.
p.addParameter('wave', getpref('ISET3d','wave'), @isnumeric);

% Passed to isetdocker
p.addParameter('verbosity', 1, @isnumeric);

p.addParameter('remote',true,@islogical);

% Optional denoising -- OIDN-based for now
p.addParameter('denoise','none',@(x)(ischar(x) || islogical(x)));

% Return render command only
p.addParameter('commandonly',false);

p.KeepUnmatched = true;

p.parse(thisR,varargin{:});
renderDocker     = p.Results.docker;
scalePupilArea   = p.Results.scalepupilarea;    
meanLuminance    = p.Results.meanluminance;     
meanIlluminance  = p.Results.meanilluminance;   
wave             = p.Results.wave;
verbosity        = p.Results.verbosity;

% Deal with denoise string names.
if islogical(p.Results.denoise)
    if    p.Results.denoise,  denoiseFlag = 'exr_radiance';
    else, denoiseFlag = 'none';
    end
else
    denoiseFlag = p.Results.denoise;
end


%% Set up the isetdocker -- add test for have prefs but no object
if ~ispref('ISETDocker') && isempty(renderDocker)
    renderDocker = isetdocker();
else
    if isempty(renderDocker)
        renderDocker = isetdocker();
        if verbosity, disp('[INFO]: Render Locally.'); end
    else
        % renderDocker is fine
    end
end

%% Set up the output folder.  
outputFolder = fileparts(thisR.outputFile);
if(~exist(outputFolder,'dir'))
    % local doesn't always exist for this recipe
    try
        mkdir(outputFolder);
    catch
        error('We need an absolute path for the working folder.');
    end
end
pbrtFile = thisR.outputFile;

%% Build the docker command

[~,currName,~] = fileparts(pbrtFile);

outFile = fullfile(outputFolder,'renderings',[currName,'.exr']);

outF = strcat('renderings/',currName,'.exr');

% renderDocker is a isetdocker object.  The parameters control which
% machine and with what parameters the docker image/containter is invoked.

[status, result] = renderDocker.render(thisR, p.Results.commandonly);
if getpref('ISETDocker','batch'), ieObject =[]; return;end

% Lots of output when verbosity is 2.
% Append the renderCommand and output file
if renderDocker.verbosity > 0
    fprintf('[INFO]: Output file:  %s\n',outF);
    if renderDocker.verbosity > 1
        fprintf('PBRT result info:  %s\n',result);
    end
end


% The user wants the isetdocker.
if nargout > 2, thisD = renderDocker; end

%% Check the returned rendering image.

if status
    warning('Docker did not run correctly');

    % The status may contain a useful error message that we should
    % look up.  The ones we understand should offer help here.
    fprintf('Status:\n'); disp(status);
    fprintf('Result:\n'); disp(result);
    ieObject = [];

    % Did not work, so we might as well return.
    return;
end

%% EXR-based denoising option here
if ~isequal(denoiseFlag, 'none')
    piEXRDenoise(outFile,'channels', denoiseFlag);
end

%% Convert the returned data to an ieObject

% renderType is a cell array, typically with radiance and depth. But
% it can also be instance or material.
ieObject = piEXR2ISET(outFile, 'recipe',thisR,...
    'label',thisR.metadata.rendertype, ...
    'mean luminance',    meanLuminance, ...
    'mean illuminance',  meanIlluminance, ...
    'scale pupil area',  scalePupilArea);

% If it is not a struct, it is metadata (instance, material, ....)
if isstruct(ieObject)
    % It might be helpful to preserve the recipe used
    ieObject.recipeUsed = thisR;

    switch ieObject.type
        case 'scene'
            curWave = sceneGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = sceneSet(ieObject, 'wave', wave);
            end
            dist = thisR.get('object distance','m');
            ieObject = sceneSet(ieObject,'distance',dist);

        case 'opticalimage'
            curWave = oiGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = oiSet(ieObject,'wave',wave);
            end
        case 'metadata'
            % Probably instanceID data
        otherwise
            error('Unknown struct type %s\n',ieObject.type);
    end
end

end


