function [ieObject, result, thisD] = piRender(thisR,varargin)
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
%  verbose    - How much to print to standard output:
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
%   thisD    - the dockerWrapper used for the rendering.  Useful if
%              you want to use it next as the ourdocker specification.
%              
% See also
%   s_piReadRender*.m, piRenderResult, dockerWrapper

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
  thisDocker = dockerWrapper;
  thisDocker.gpuRendering = false;
  thisDocker.localRender = true; 
  thisDocker = dockerWrapper('localRender',true,'gpuRendering', false,'verbosity',0);
  scene = piWRS(thisR,'our docker',thisDocker);
%}

%%  Name of the pbrt scene file and whether we use a pinhole or lens model

p = inputParser;
p.KeepUnmatched = true;

% p.addRequired('pbrtFile',@(x)(exist(x,'file')));
p.addRequired('recipe',@(x)(isequal(class(x),'recipe') || ischar(x)));

varargin = ieParamFormat(varargin);
p.addParameter('meanluminance',100,@isnumeric);    % Cd/m2
p.addParameter('meanilluminance',10,@isnumeric);   % Lux

% p.addParameter('meanilluminanceperm2',[],@isnumeric);
p.addParameter('scalepupilarea',true,@islogical);
p.addParameter('reuse',false,@islogical);

% Only one of these should be sent in.
p.addParameter('ourdocker','',@(x)(isa(x,'dockerWrapper')) || isempty(x));    % to specify a docker image
p.addParameter('dockerwrapper','',@(x)(isa(x,'dockerWrapper')) || isempty(x));    % to specify a docker image

% This passed to piDat2ISET, which is where we do the construction.
p.addParameter('wave', 400:10:700, @isnumeric); 

p.addParameter('verbose', getpref('docker','verbosity',1), @isnumeric);

% If you would to render on your local machine, set this to true.  And
% make sure that 'ourdocker' is set to the container you want to run.
p.addParameter('localrender',false,@islogical);

% Optional denoising -- OIDN-based for now
p.addParameter('do_denoise','none',@ischar);

% Allow passthrough of arguments
p.KeepUnmatched = true;

p.parse(thisR,varargin{:});
ourDocker        = p.Results.ourdocker;
dWrapper    = p.Results.dockerwrapper;
scalePupilArea   = p.Results.scalepupilarea;    % Fix this
meanLuminance    = p.Results.meanluminance;     % And this
meanIlluminance  = p.Results.meanilluminance;   % And this

wave             = p.Results.wave;

%% Set up the dockerWrapper

% If the user has sent in a dockerWrapper or an ourDocker we use it.
% We object if both are sent in.
if ~isempty(ourDocker) && ~isempty(dWrapper)
    error('Bad docker arguments to piRender.  Specify only one.');
elseif ~isempty(ourDocker) && isempty(dWrapper), renderDocker = ourDocker;
elseif ~isempty(dWrapper) && isempty(ourDocker), renderDocker = dWrapper;
else, renderDocker = dockerWrapper();
end

%% We have a radiance recipe and we have written the pbrt radiance file

% Set up the output folder.  This folder will be mounted by the Docker
% image if run locally.  When run remotely, we are using rsync and
% different mount points.
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

if ispc  % Windows
    currFile = pbrtFile; % in v3 we could process several files, not sure about v4

    % Hack to reverse \ to / for _depth files, for compatibility
    % with Linux-based Docker pbrt container
    pFile = fopen(currFile,'rt');
    tFileName = tempname;
    tFile = fopen(tFileName,'Wt');
    while true
        thisline = fgets(pFile);
        if ~ischar(thisline); break; end  %end of file
        % pc definitely needs some path massaging. Not sure about Mac/Linux
        if ispc && (contains(thisline, "C:\") || contains(thisline, "B:\"))
            thisline = strrep(thisline, piRootPath, '');
            % in some cases local has a trailing slash
            thisline = strrep(thisline, ['\local\' currName '\'], '');
            thisline = strrep(thisline, '\local', '');
            thisline = strrep(thisline, '\', '/');
        end
        fprintf(tFile,  '%s', thisline);
    end
    fclose(pFile);
    fclose(tFile);
    copyfile(tFileName, currFile);
    delete(tFileName);

    % With V4 the output is EXR not Dat
    outF = strcat('renderings/',currName,'.exr');
    renderCommand = sprintf('pbrt --outfile %s %s', outF, strcat(currName, '.pbrt'));
        
    if ~isempty(outputFolder)
        if ~exist(outputFolder,'dir'), error('Need full path to %s\n',outputFolder); end
    end

else  % Linux & Mac

    % With V4 the output is EXR not Dat
    outF = strcat('renderings/',currName,'.exr');
    renderCommand = sprintf('pbrt --outfile %s %s', outF, strcat(currName, '.pbrt'));

    if ~isempty(outputFolder)
        if ~exist(outputFolder,'dir'), error('Need full path to %s\n',outputFolder); end
    end
end

% renderDocker is a dockerWrapper object.  The parameters control which
% machine and with what parameters the docker image/containter is invoked.
preRender = tic;
[status, result] = renderDocker.render(renderCommand, outputFolder, varargin{:});

% Lots of output when verbosity is 2.
% Append the renderCommand and output file
if renderDocker.verbosity > 0
    fprintf('Output file:  %s\n',outF);
elseif renderDocker.verbosity > 1
    fprintf('PBRT result info:  %s\n',result);
end

elapsedTime = toc(preRender);
if renderDocker.verbosity > 0
    fprintf('*** Rendering time (%s) was %.1f sec ***\n\n',currName,elapsedTime);
end

% The user wants the dockerWrapper.
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
if ~isequal(p.Results.do_denoise, 'none')
    piEXRDenoise(outFile,'channels', p.Results.do_denoise);
end

%% Convert the returned data to an ieObject

% renderType is a cell array, typically with radiance and depth. But
% it can also be instance or material.  
ieObject = piEXR2ISET(outFile, 'recipe',thisR,...
    'label',thisR.metadata.rendertype, ...
    'mean luminance',    meanLuminance, ...
    'mean illuminance',  meanIlluminance, ...
    'scale pupil area', scalePupilArea);

% If it is not a struct, it is metadata (instance, material, ....)
if isstruct(ieObject)
    % It might be helpful to preserve the recipe used    
    ieObject.recipeUsed = thisR;
    
    switch ieObject.type
        case 'scene'
            % names = strsplit(fileparts(thisR.inputFile),'/');
            % ieObject = sceneSet(ieObject,'name',names{end});
            curWave = sceneGet(ieObject,'wave');
            if ~isequal(curWave(:),wave(:))
                ieObject = sceneSet(ieObject, 'wave', wave);
            end
            dist = thisR.get('object distance','m');
            ieObject = sceneSet(ieObject,'distance',dist);

        case 'opticalimage'
            % names = strsplit(fileparts(thisR.inputFile),'/');
            % ieObject = oiSet(ieObject,'name',names{end});
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


