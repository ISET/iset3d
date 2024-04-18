function workingDir = piWrite(thisR,varargin)
% Write a PBRT scene file based on its renderRecipe
%
% Brief
%   Write the scene PBRT files from the recipe (thisR). By default they are
%   written to the local/sceneName directory.
%
% Syntax
%   workingDir = piWrite(thisR,varargin)
%
% Input
%   thisR: a recipe object describing the rendering parameters.
%
% Optional key/value parameters
%   verbose -- how chatty to be in this routine.
%
% Return
%    workingDir - path to the output directory mounted by the Docker
%                 container.  This return is not necessary.
%                 The direction is set in the recipe:
%        thisR.get('output dir')
%
% Description
%
% In the original implementation, which still runs, the pbrt scene file and
% all the relevant resource files (geometry, materials, spds, others) are
% written out in a working directory. During rendering, these files are
% mounted by the docker container and used by PBRT to create the radiance,
% depth, mesh metadata outputs.
%
% We have now implemented a second approach based on the idea that there is
% a central, shared, rendering machine.  If the user sets the 'remote
% resources' option to true, we assume that the necessary asset files
% (objects, skymaps, others) are present on the remote server. Thus, there
% is little copying. Only, the scene PBRT file and the _geometry and _material
% files are copied over. The remote assets are in the subdirectories that
% are mounted by the remote Docker container.
%
% In addition to saving time by not moving the data this approach saves
% space. This is because multiple PBRT scenes use the same resources files.
% Thus there is no need to have the same bunny, or sphere, present in the
% directory for different scenes.  The asset or skymap is available to all
% the scenes in the remote resource.
%
% Note: In the original, we included multiple options as to whether or not
% to overwrite files that are already present in the output directory.  The
% logic and conditions about these overwrites was quite complex, and we
% have deprecated those options.  At present, we write the files all the
% time.
%
% Note:  There are many helper files in this function
%
% TL Scien Stanford 2017
% DJC - remote resource
%
% See also
%   piRead, piWRS, piRender

% Examples:
%{
 thisR = piRecipeDefault('scene name','teapotset');
 piWRS(thisR,'remote resources',true); 
%}
%{
 % Note the speed-up
 thisR = piRecipeDefault('scene name','ChessSet');
 piWRS(thisR,'remote resources',false);
 piWRS(thisR,'remote resources',true);
%}
%{
% Works with a lens
thisR = piRecipeDefault('scene name','chessSet');
lensfile = 'fisheye.87deg.6.0mm.json';

thisR.camera = piCameraCreate('omni','lensFile',lensfile);
thisR.set('film resolution',round([300 200]));
thisR.set('pixel samples',32);   % Number of rays set the quality.
thisR.set('focus distance',0.45);
thisR.set('film diagonal',10);
thisR.integrator.subtype = 'path';
thisR.sampler.subtype = 'sobol';
thisR.set('aperture diameter',3);
oi = piWRS(thisR,'remote resources',true);
%}
%% Init ISET prefs
piPrefsInit
%% Parse inputs
varargin = ieParamFormat(varargin);
p = inputParser;

p.addRequired('thisR',@(x)isequal(class(x),'recipe'));
p.addParameter('verbose', 0, @isnumeric);
p.addParameter('remoterender', ~isempty(getpref('ISETDocker','remoteHost'))); 
p.addParameter('mainfileonly',false, @islogical);
p.addParameter('overwriteresources', true, @islogical);
p.addParameter('overwritematerials', true, @islogical);
p.addParameter('overwritegeometry', true, @islogical);

% Human eye writes its own, so we do not generally want to overwrite.
p.addParameter('overwritelensfile', false, @islogical);

p.parse(thisR,varargin{:});

overwriteresources  = p.Results.overwriteresources;

remoteRender        = p.Results.remoterender;

% Render on remote machine
if remoteRender
    if ~isempty(getpref('ISETDocker','remoteHost'))
        [~,sceneName]=fileparts(thisR.get('output dir'));
        setpref('ISETDocker','remoteSceneDir', ...
            fullfile(getpref('ISETDocker','workDir'),sceneName));
    else
        isetdocker.setUserPrefs;
    end
end

overwritelensfile   = p.Results.overwritelensfile;
overwritepbrtfile   = true;
overwritemedia      = true;

overwritematerials  = p.Results.overwritematerials;
overwritegeometry   = p.Results.overwritegeometry;

if p.Results.mainfileonly
    overwriteresources = false;
    overwritematerials = false;
    overwritegeometry  = false;
end

verbosity           = p.Results.verbose;

exporter = thisR.get('exporter');

%% Check the input and output directories

% Input should exist.  Even if it doesn't, we can still render just
% from the recipe alone.  Unless we need to copy something.
inputDir   = thisR.get('input dir');

if ~exist(inputDir,'dir') && isempty(getpref('ISETDocker','remoteHost'))
    warning('Could not find local inputDir: %s\n',inputDir);
end

% Make working dir if it does not already exist
workingDir = thisR.get('output dir');
if ~exist(workingDir,'dir')
    mkdir(workingDir);
end
% Make a geometry directory
geometryDir = thisR.get('geometry dir');
if ~exist(geometryDir, 'dir'), mkdir(geometryDir); end

renderDir = thisR.get('rendered dir');
if ~exist(renderDir,'dir'), mkdir(renderDir); end


if isempty(thisR.metadata) || isempty(thisR.metadata.rendertype)
    preRender = thisR.get('rendertype');
    preRender{end+1} = 'radiance';
    thisR.set('rendertype', preRender);
end
if max(ismember(thisR.metadata.rendertype,'radiance')) && min(~ismember(thisR.metadata.rendertype,'depth'))
    preRender = thisR.get('rendertype');
    preRender{end+1} = 'depth';
    thisR.set('rendertype', preRender);
end


%% Selectively copy data from the input to the output directory.
piWriteCopy(thisR,overwriteresources,overwritepbrtfile, verbosity)

%% If the optics type is lens, copy the lens file to a lens sub-directory

if isequal(thisR.get('optics type'),'lens')
    % realisticEye has a lens file slot but it is empty. So we check
    % whether there is a lens file or not.

    lensFile = thisR.get('lensfile');
    if ~isempty(lensFile)
        % We have a nominal lens file.  Check that it exists, or that we
        % have insisted on overwriting it.
        if ~exist(lensFile,'file') || overwritelensfile
            piWriteLens(thisR);
        end

        if exist(lensFile,'file') && ~isempty(getpref('ISETDocker','remoteHost'))
            % if we render the scene remotely, we need to rewrite the lens
            % path from absolute to relative.
            [~,lensName,ext] = fileparts(lensFile);
            thisR.set('lensfile',fullfile('lens',[lensName, ext]));
            % also copy the file over to local/thisScene/lens
            lensDir = fullfile(thisR.get('output dir'),'lens');
            if ~exist(lensDir,'dir'), mkdir(lensDir);end
            if ~exist(fullfile(lensDir,[lensName, ext]),'file')
                copyfile(lensFile,fullfile(lensDir,[lensName, ext]));
            end
        end

    end
end

% This should only run for the human eye case for now.  Someday more
% general. (TG/BW).
if ~isempty(thisR.get('film shape file'))
    piWriteFilmshape(thisR);
end

%% Open up the main PBRT scene file.

outFile = thisR.get('output file');
[fileID, errmsg] = fopen(outFile,'W');
if fileID == -1
    error("Unable to open PBRT file: %s\n",errmsg);
end
%% Write header
piWriteHeader(thisR,fileID)

%% Write media
% Media can interact with the camera
% and can be defined before WorldBegin
if ~isempty(thisR.media.list)
    piWriteMedia(thisR, overwritemedia);
end

%% Write Scale and LookAt commands first
piWriteLookAtScale(thisR,fileID);

%% Write transform start and end time
piWriteTransformTimes(thisR, fileID);

%% Write all other blocks that we have field names for
piWriteBlocks(thisR,fileID);

%% Add 'Include' lines for materials, geometry and lights into the scene PBRT file
piIncludeLines(thisR,fileID);

%% Close the main PBRT scene file
fclose(fileID);

%% Write scene_materials.pbrt

% Even if this is the copy type scene, we parse the materials and
% texture maps and make sure the files are copied to 'local/'.
if ~isempty(thisR.materials.list) && overwritematerials
    % Write critical files.
    piWriteMaterials(thisR);
end

%% Write the scene_geometry.pbrt
if ~isequal(exporter,'Copy') && overwritegeometry && ~isempty(thisR.assets)
    piGeometryWrite(thisR);
end


% set workDir back to the default
rmpref('ISETDocker','remoteSceneDir');
end   % End of piWrite

%% ---------  Helper functions
%
%  piWriteCopy
%  piWriteHeader
%  piWriteLens
%  piWriteFilmshape
%  piWriteLookAtScale
%  piWriteTransformTimes
%  piWriteBlocks
%  piIncludeLines
%  piWriteMaterials
%  piGeometryWrite
%

%% Copy the input resources to the output directory
function piWriteCopy(thisR,overwriteresources,overwritepbrtfile, verbosity)
% Copy files from the input to output dir
%
% In some cases we are looping over many renderings.  In that case we may
% turn off the repeated copies by setting overwriteresources to false.

inputDir   = thisR.get('input dir');
outputDir  = thisR.get('output dir');

% We check for the overwrite here and we make sure there is also an input
% directory to copy from.
if ~isempty(inputDir) && ~strcmpi(inputDir,outputDir)
    sources = dir(inputDir);
    status  = true;
    for i = 1:length(sources)
        if startsWith(sources(i).name(1),'.')
            % Skip dot-files
            continue;
            % We always copy certain resource files to local, although
            % some aren't used if remoteRender is being used
        elseif sources(i).isdir && strcmpi(sources(i).name,'instanced')
            % Copy the spds and textures directory files.
            status = status && copyfile(fullfile(sources(i).folder, sources(i).name), fullfile(outputDir,sources(i).name));
        elseif overwriteresources
            if sources(i).isdir && (strcmpi(sources(i).name,'spds') || strcmpi(sources(i).name,'textures') || strcmpi(sources(i).name,'instanced'))
                % Copy the spds and textures directory files.
                status = status && copyfile(fullfile(sources(i).folder, sources(i).name), fullfile(outputDir,sources(i).name));
            else
                % Selectively copy the files in the scene root folder
                [~, ~, extension] = fileparts(sources(i).name);
                % ChessSet needs input geometry because we can not parse it
                % yet. --zhenyi
                if ~(piContains(extension,'zip') || piContains(extension,'json'))
                    thisFile = fullfile(sources(i).folder, sources(i).name);
                    if verbosity > 1
                        fprintf('Copying %s\n',thisFile)
                    end
                    status = status && copyfile(thisFile, fullfile(outputDir,sources(i).name));
                    %status = status && system(sprintf('cp -r %s %s \n',thisFile, fullfile(outputDir,sources(i).name)));
                end
            end
        end
    end
    if(~status)
        error('Failed to copy input directory to docker working directory.');
    else
        if verbosity > 1
            fprintf('Copied resources from:\n');
            fprintf('%s \n',inputDir);
            fprintf('to \n');
            fprintf('%s \n \n',outputDir);
        end
    end
end

% Potentially overwrite the scene PBRT file
outFile = thisR.get('output file');

% Check if the outFile exists. If it does, decide what to do.
if(isfile(outFile))
    if overwritepbrtfile
        % A pbrt scene file exists.  We delete here and write later.
        delete(outFile);
    else
        % Do not overwrite is set, and yet it exists. We don't like this
        % condition, so we throw an error.
        error('PBRT file %s exists.',outFile);
    end
end

end

%% Put the header into the scene PBRT file

function piWriteHeader(thisR,fileID)
% Write the header

fprintf(fileID,'# PBRT file created with piWrite on %i/%i/%i %i:%i:%0.2f \n',clock);
fprintf(fileID,'# PBRT version = %i \n',thisR.version);
fprintf(fileID,'\n');

% If a crop window exists, write out a warning
if(isfield(thisR.film,'cropwindow'))
    fprintf(fileID,'# Warning: Crop window exists! \n');
end

end

%% Write lens information
function piWriteLens(thisR,overwritelensfile)
% Write out the lens file.  Manage cases of overwrite or not
%
% We also manage special human eye model cases Some of these require
% auxiliary files like Index of Refraction files that are specified using
% Include statements in the World block.
%
% See also
%   navarroWrite, navarroLensCreate, setNavarroAccommodation

if notDefined('overwritelensfile'),overwritelensfile = false; end

% Make sure the we have the full path to the input lens file
inputLensFile = thisR.get('lens file');

outputDir      = thisR.get('output dir');
outputLensFile = thisR.get('lens file output');
outputLensDir  = fullfile(outputDir,'lens');
if ~exist(outputLensDir,'dir'), mkdir(outputLensDir); end

if isequal(thisR.get('human eye model'),'navarro')
    % Write lens file and the ior files into the output directory.
    navarroWrite(thisR);
elseif isequal(thisR.get('human eye model'),'legrand')
    % Write lens file and the ior files into the output directory.
    legrandWrite(thisR);
elseif isequal(thisR.get('human eye model'),'arizona')
    % Write lens file into the output directory.
    % Still tracking down why no IOR files are associated with this model.
    accommodation = thisR.get('accommodation');
    arizonaWrite(thisR, accommodation);
else
    % If the working copy doesn't exist, copy it.
    % If it exists but there is a force overwrite, delete and copy.
    %
    % We need to check that this will work for the RTF json file as well.
    % I think so. (BW).

    if ~exist(outputLensFile,'file')
        copyfile(inputLensFile,outputLensFile);
    elseif isequal(inputLensFile,outputLensFile)
        warning('input and output lens files are the same (%s).',inputLensFile);
    elseif overwritelensfile
        % It must exist.  So if we are supposed overwrite
        delete(outputLensFile);
        copyfile(inputLensFile,outputLensFile);
    end
end

end

%% Write Film information
function piWriteFilmshape(thisR)
% Write JSON file that specifies the film shape.  Used for retina
% shape now.  Could be used for OMNI in the future.
%
% See also
%   navarroWrite, navarroLensCreate, setNavarroAccommodation

% Make sure the we have the full path to the input lens file
inputFilmshapeFile = thisR.get('film shape file');

outputDir      = thisR.get('output dir');
outputFilmshapeDir  = fullfile(outputDir,'filmshape');
if ~exist(outputFilmshapeDir,'dir'), mkdir(outputFilmshapeDir); end
outputFilmshapeFile = thisR.get('film shape output');

% Always overwite.
if isequal(inputFilmshapeFile,outputFilmshapeFile)
    warning('input and output film shape files are the same (%s).',inputFilmshapeFile);
else
    % It must exist.  So if we are supposed overwrite
    delete(outputFilmshapeFile);
    copyfile(inputFilmshapeFile,outputFilmshapeFile);
end

end

%% Write LookAt and Scale fields
function piWriteLookAtScale(thisR,fileID)

% Optional Scale

% This was here for a long time.  But I don't think it matters unless it is
% inside the 'WorldBegin' loop.  So I deleted it and started writing the
% Scale inside the WorldBegin' write section
%
%
theScale = thisR.get('scale');
if(~isempty(theScale))
    fprintf(fileID,'Scale %0.2f %0.2f %0.2f \n', [theScale(1) theScale(2) theScale(3)]);
    fprintf(fileID,'\n');
end
%

% Optional Motion Blur
% default StartTime and EndTime is 0 to 1;
if isfield(thisR.camera,'motion')

    motionTranslate = thisR.get('camera motion translate');
    motionStart     = thisR.get('camera motion rotation start');
    motionEnd       = thisR.get('camera motion rotation end');

    fprintf(fileID,'ActiveTransform StartTime \n');
    fprintf(fileID,'Translate 0 0 0 \n');
    fprintf(fileID,'Rotate %f %f %f %f \n',motionStart(:,1)); % Z
    fprintf(fileID,'Rotate %f %f %f %f \n',motionStart(:,2)); % Y
    fprintf(fileID,'Rotate %f %f %f %f \n',motionStart(:,3));  % X
    fprintf(fileID,'ActiveTransform EndTime \n');
    fprintf(fileID,'Translate %0.2f %0.2f %0.2f \n',...
        [motionTranslate(1),...
        motionTranslate(2),...
        motionTranslate(3)]);
    fprintf(fileID,'Rotate %f %f %f %f \n',motionEnd(:,1)); % Z
    fprintf(fileID,'Rotate %f %f %f %f \n',motionEnd(:,2)); % Y
    fprintf(fileID,'Rotate %f %f %f %f \n',motionEnd(:,3));  % X
    fprintf(fileID,'ActiveTransform All \n');
end

% Required LookAt
from = thisR.get('from');
to   = thisR.get('to');
up   = thisR.get('up');
fprintf(fileID,'LookAt %0.6f %0.6f %0.6f %0.6f %0.6f %0.6f %0.6f %0.6f %0.6f \n', ...
    [from(:); to(:); up(:)]);

fprintf(fileID,'\n');

end

%% Write Transform times
function piWriteTransformTimes(thisR, fileID)
% Get transform times
startTime = thisR.get('transform times start');
endTime = thisR.get('transform times end');

if ~isempty(startTime) && ~isempty(endTime)
    fprintf(fileID,'TransformTimes %0.6f %0.6f \n', ...
        startTime, endTime);
end
end

%%
function piWriteBlocks(thisR,fileID)
% Loop through the thisR fields, writing them out as required
%
% The blocks that are written out include
%
%  Camera, lens
%

workingDir = thisR.get('output dir');

% These are the main fields in the recipe.  We call them the outer fields.
% Within each outer field, there will be inner fields.  The outer fields
% include film, filter, camera and such.
outerFields = fieldnames(thisR);

for ofns = outerFields'
    ofn = ofns{1};

    % If empty, we skip this field.
    if(~isfield(thisR.(ofn),'type') || ...
            ~isfield(thisR.(ofn),'subtype'))
        continue;
    end

    % Skip, we don't want to write these out here.  So if any one of these,
    % we skip to the next for-loop step
    if(strcmp(ofn,'world') || ...
            strcmp(ofn,'lookAt') || ...
            strcmp(ofn,'inputFile') || ...
            strcmp(ofn,'outputFile')|| ...
            strcmp(ofn,'version')) || ...
            strcmp(ofn,'materials')|| ...
            strcmp(ofn,'recipeVer')|| ...
            strcmp(ofn,'exporter') || ...
            strcmp(ofn,'metadata') || ...
            strcmp(ofn,'renderedFile') || ...
            strcmp(ofn,'world')
        continue;
    end

    % Write header that identifies which block this is
    fprintf(fileID,'# %s \n',ofn);

    % If the camera is submerged, then the medium needs to be defined.
    if strcmp(ofn,'camera') && isfield(thisR.(ofn),'medium')
        if ~isempty(thisR.(ofn).medium)
            fprintf(fileID,'%s \n',sprintf('Include "%s_media.pbrt" \n', thisR.get('output basename')));
            fprintf(fileID,'MediumInterface "" "%s"\n',thisR.(ofn).medium);
        end
    end


    % Write out the main type and subtypes
    fprintf(fileID,'%s "%s" \n',thisR.(ofn).type,...
        thisR.(ofn).subtype);

    % Find and then loop through inner field names
    innerFields = fieldnames(thisR.(ofn));

    % BW: May, 2023 Special case:  For humaneye, we do not want to write
    % out the field 'focaldistance' or chromaticAberrationEnabled
    if isequal(thisR.(ofn).subtype,'humaneye')
        idx = strcmp(innerFields,'focaldistance');
        if ~isempty(idx), innerFields(idx) = []; end
        idx = strcmp(innerFields,'chromaticAberrationEnabled');
        if ~isempty(idx), innerFields(idx) = []; end
    end

    if(~isempty(innerFields))
        for ifns = innerFields'
            ifn = ifns{1};

            % Skip these since we've written these out earlier.
            if(strcmp(ifn,'type') || ...
                    strcmp(ifn,'subtype') || ...
                    strcmp(ifn,'subpixels_h') || ...
                    strcmp(ifn,'subpixels_w') || ...
                    strcmp(ifn,'motion') || ...
                    strcmp(ifn,'subpixels_w') || ...
                    strcmp(ifn,'medium'))
                continue;
            end

            %{
             Many fields are written out in here.  
             (There is an issue with mmUnits, that I need to discuss
             with Zheng/Zhenyi.  [1m[31mError[0m:
             contemporary-bathroom.pbrt:13:2: "mmUnits": unused parameter.
             Probably a missing implementation V4?  (BW). 
             Some examples are: 
               type, subtype, lensfile retinaDistance
               retinaRadius pupilDiameter retinaSemiDiam ior1 ior2 ior3 ior4
               pixelsamples xresolution yresolution maxdepth
            %}

            currValue = thisR.(ofn).(ifn).value;
            currType  = thisR.(ofn).(ifn).type;

            if (strcmp(currType,'bool'))
                % Deal with bool first. It has a char currValue but is
                % written out without the quotation marks.
                lineFormat = '  "%s %s" %s \n';
            elseif(strcmp(currType,'string') || ischar(currValue))
                % We have a string with some value.  Note that bool is
                % a string so we do not want the quotation marks here.
                lineFormat = '  "%s %s" "%s" \n';

                % The currValue might be a full path to a file with an
                % extension. We find the base file name and copy the file
                % to the working directory. Then, we transform the string
                % to be printed in the pbrt scene file to be its new
                % relative path.  There is a minor exception for the lens
                % file. Perhaps we should have a better test here, say an
                % exist() test. (BW).
                [~,name,ext] = fileparts(currValue);
                % only if the file is in lens folder
                if ~isempty(which(currValue))
                    if(~isempty(ext))
                        % This looks like a file with an extension. If it
                        % is a lens file or an iorX.spd file, indicate that
                        % it is in the lens/ directory. Otherwise, copy the
                        % file to the working directory.

                        fileName = strcat(name,ext);
                        if strcmp(ifn,'specfile') || strcmp(ifn,'lensfile')
                            % It is a lens, so just update the name.  It
                            % was already copied
                            % This should work.
                            % currValue = strcat('lens',[filesep, strcat(name,ext)]);
                            if ispc()
                                currValue = strcat('lens/',strcat(name,ext));
                            else
                                currValue = fullfile('lens',strcat(name,ext));
                            end
                        elseif piContains(ifn,'ior')
                            % The the innerfield name contains the ior string,
                            % then we change it to this
                            currValue = strcat('lens',[filesep, strcat(name,ext)]);
                        else
                            [success,~,id]  = copyfile(currValue,workingDir);
                            if ~success && ~strcmp(id,'MATLAB:COPYFILE:SourceAndDestinationSame')
                                warning('Problem copying %s\n',currValue);
                            end
                            % Update the file for the relative path
                            currValue = fileName;
                        end
                    end
                end

            elseif(strcmp(currType,'spectrum') && ~ischar(currValue))
                % A spectrum of type [wave1 wave2 value1 value2]. TODO:
                % There are probably more variations of this...
                lineFormat = '  "%s %s" [%f %f %f %f] \n';
            elseif(strcmp(currType,'rgb'))
                lineFormat = '  "%s %s" [%f %f %f] \n';
            elseif(strcmp(currType,'float'))
                if(length(currValue) > 1)
                    lineFormat = '  "%s %s" [%f %f %f %f] \n';
                else
                    lineFormat = '  "%s %s" [%f] \n';
                end
            elseif(strcmp(currType,'integer'))
                %if we use %i, we can get exponents which pbrt hates
                lineFormat = '  "%s %s" [%.0f] \n';
            end

            if ~islogical(currValue)
                fprintf(fileID,lineFormat,...
                    currType,ifn,currValue);
            else
                logicalStr = {'false', 'true'};
                fprintf(fileID,lineFormat,...
                    currType,ifn,logicalStr{currValue+1});
            end
        end
    end

    % Blank line.
    fprintf(fileID,'\n');
end

end

%% Include Lines inserted in the scene file

function piIncludeLines(thisR,fileID)
% Insert the 'Include scene_materials.pbrt' and similarly for geometry and
% lights into the main scene file
%
% We must add the materials before the geometry.
% We add the lights at the end.
%

basename = thisR.get('output basename');

% Find the World lines with _geometry, _materials, _lights
% We are being aggressive about the Include files.  We want to name them
% ourselves.  First we see whether we have Includes for these at all
lineMaterials = find(contains(thisR.world, {'_materials.pbrt'}));
lineGeometry  = find(contains(thisR.world, {'_geometry.pbrt'}));
lineLights    = find(contains(thisR.world, {'_lights.pbrt'}));
lineMedia     = find(contains(thisR.world, {'_media.pbrt'}));


% For the Copy case, we just copy the world and Include the lights and materials.
if isequal(thisR.exporter, 'Copy')
    for ii = 1:numel(thisR.world)
        fprintf(fileID,'%s \n',thisR.world{ii});
        % if piContains(thisR.world{ii},'WorldBegin') && ...
        %         isempty(lineMaterials) &&...
        %         ~isempty(thisR.materials)
        %     % Insert the materials file
        %     fprintf(fileID,'%s \n',sprintf('Include "%s_materials.pbrt" \n', basename));
        % end
        if piContains(thisR.world{ii}, 'WorldBegin') &&...
                isempty(lineLights) &&...
                ~isempty(thisR.lights)
            % Insert the lights file.
            fprintf(fileID, sprintf('Include "%s_lights.pbrt" \n', basename));
        end
    end
    return;
end

% If we have  geometry Include, we overwrite it with the name we want.
if ~isempty(lineGeometry)
    thisR.world{lineGeometry} = sprintf('Include "%s_geometry.pbrt"\n', basename);
end

% If we have materials Include, we overwrite it.
% end.
if ~isempty(lineMaterials)
    thisR.world{lineMaterials} = sprintf('Include "%s_materials.pbrt"\n',basename);
end

% We think nobody except us has these lights files.  So this will never get
% executed.
if ~isempty(lineLights)
    thisR.world{lineLights} = sprintf('Include "%s_lights.pbrt"\n', basename);
end

% Write out the World information.
%
% Insert the Include lines as the last three before WorldEnd.
% Also, as of December 2021, placed the 'Scale' line in here.
% Maybe we should not have an overall Scale in the recipe, however.
%
for ii = 1:length(thisR.world)
    currLine = thisR.world{ii};    % ii = 1 is 'WorldBegin'

    if piContains(currLine, 'WorldEnd') && isempty(lineLights)
        % Insert the lights file.
        fprintf(fileID, sprintf('Include "%s_lights.pbrt" \n', basename));
    end

    fprintf(fileID,'%s \n',currLine);

    if piContains(currLine,'WorldBegin')
        % Start with the Scale value from the recipe.  This scales the whole scene,
        % but it might be a bad idea because it does not preserve the geometric
        % relationships between the objects.  They all get bigger.
        %         theScale = thisR.get('scale');
        %         if(~isempty(theScale))
        %             fprintf(fileID,'Scale %0.2f %0.2f %0.2f \n', [theScale(1) theScale(2) theScale(3)]);
        %             fprintf(fileID,'\n');
        %         end
    end

    if piContains(currLine,'WorldBegin') && isempty(lineMaterials) && ~isempty(thisR.materials.list)
        % Insert the materials file
        fprintf(fileID,'%s \n',sprintf('Include "%s_materials.pbrt" \n', basename));
    end

    if piContains(currLine,'WorldBegin') && isempty(lineMedia) && ~isempty(thisR.media.list) && ...
            (~isfield(thisR.camera,'medium') || (isfield(thisR.camera,'medium') && isempty(thisR.camera.medium)))
        % Insert the materials file
        fprintf(fileID,'%s \n',sprintf('Include "%s_media.pbrt" \n', basename));
    end

    if piContains(currLine,'WorldBegin') && isempty(lineGeometry) && ~isempty(thisR.assets.Node)
        % Insert the materials file
        fprintf(fileID,'%s \n',sprintf('Include "%s_geometry.pbrt" \n', basename));
    end
    if piContains(currLine, 'WorldBegin') && isempty(lineLights) && ~isempty(thisR.lights)
        % Insert the lights file.
        fprintf(fileID, sprintf('Include "%s_lights.pbrt" \n', basename));
    end

end

end

%%
function piWriteMaterials(thisR)
% Write both materials and textures files into the output directory

% We create the materials file.  Its name is the same as the output pbrt
% file, but it has an _materials inserted.
outputDir  = thisR.get('output dir');
basename   = thisR.get('output basename');
% [~,n] = fileparts(thisR.inputFile);
fname_materials = sprintf('%s_materials.pbrt',basename);
thisR.set('materials output file',fullfile(outputDir,fname_materials));
piMaterialWrite(thisR);


end

%%

function piWriteMedia(thisR,overwritemedia)
% Write both materials and textures files into the output directory

% We create the materials file.  Its name is the same as the output pbrt
% file, but it has an _materials inserted.
if overwritemedia
    outputDir  = thisR.get('output dir');
    basename   = thisR.get('output basename');
    % [~,n] = fileparts(thisR.inputFile);
    fname_media = sprintf('%s_media.pbrt',basename);
    thisR.set('media output file',fullfile(outputDir,fname_media));
    piMediaWrite(thisR);
end

end

