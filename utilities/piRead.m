function thisR = piRead(fname,varargin)
% Read an parse a PBRT scene file, returning a rendering recipe
%
% Syntax
%    thisR = piRead(fname, varargin)
%
% Description
%  Parses a pbrt scene file and returns the full set of rendering
%  information in the slots of the "recipe" object. The recipe object
%  contains all the information needed by PBRT to render the scene.
%
%  We extract blocks with these names from the text prior to
%  WorldBegin block.  We call these the pbrtOptions
%
%    Camera, Sampler, Film, PixelFilter, SurfaceIntegrator (V2, or
%    Integrator in V3), Renderer, LookAt, Transform, ConcatTransform,
%    Scale
%
%  We then read and parse the World block, which is the text following
%  WorldBegin.  This returns the asset tree that is part of the
%  recipe.
%
%  After reading the PBRT files and building the recipe, we typically
%  modify the recipe object programmatically. When we are finished, we
%  use piWrite to write the modified recipe into an updated version of
%  the PBRT scene files for rendering. These are written in the
%  directory local/ inside of the ISET3d root.
%
%  The updated PBRT files in local/ are rendered using piRender, which
%  executes the PBRT docker image and return an ISETCam (scene or oi
%  format).  The rendering is typically done remotely on a machine
%  with GPUs and with the Resource files.  The rendering returns an
%  ISET scene or oi, which we then show.
%
%  Because we commonly execute write, render and show, we also have a
%  single function (piWRS) that performs all three of these functions
%  in a single call.
%
% Required inputs
%   fname - full path to a pbrt scene file.  The geometry, materials
%           and other needed files should be in relative path to the
%           main scene file.
%
% Optional key/value pairs
%
%   'read materials' - When PBRT scene file is exported by cinema4d,
%        the exporterflag is set and we read the materials file.  If
%        you do not want to read that file, set this to false.
%
%   exporter - The exporter determines ... (MORE HERE).
%              One of 'PARSE','Copy'.  Default is PARSE.
%
% Output
%   recipe - A @recipe object with the parameters needed to write a
%            new pbrt scene file for rendering.  Normally, we write
%            out the new files in (piRootPath)/local/scenename
%
% Assumptions:
%
%  piRead assumes that
%
%     * There is a block of text before WorldBegin 
%     * After WorldBegin the assets are defined by PBRT commands, such
%       as Shape and NamedMaterials. 
%     * Most comments (indicated by '#' in the first character) and
%       blank lines are ignored.  But some special comment lines are
%       interpreted
%     * When an AttributeBegin block is encountered, the text lines
%       that follow beginning with a '"' are included in the block. 
%
%  piRead will not work with PBRT files that do not meet these criteria.
%
%  Text starting at WorldBegin to the end of the file (not just WorldEnd)
%  is stored in recipe.world.
%
% Authors: TL, ZLy, BW, Zhenyi
%
% See also
%   piWRS, piWrite, piRender, piBlockExtract

% Examples:
%{
 thisR = piRecipeCreate('MacBethChecker');
 thisR.set('skymap','room.exr');
 % thisR = piRecipeDefault('scene name','SimpleScene');
 % thisR = piRecipeDefault('scene name','teapot');
 piWRS(thisR);
%}

%% Parse the inputs

varargin =ieParamFormat(varargin);
p = inputParser;

p.addRequired('fname', @(x)(exist(fname,'file')));
validExporters = {'Copy','PARSE'};
p.addParameter('exporter', 'PARSE', @(x)(ismember(x,validExporters)));

% We use meters in PBRT, assimp uses centimeter as base unit
% Blender scene has a scale factor equals to 100.
% Not sure whether other type of FBX file has this problem.
% p.addParameter('convertunit',false,@islogical);

% We will use the output in local with this name.
%    local/outputdirname/outdirname.pbrt
p.parse(fname,varargin{:});
[~, outputdirname, input_ext] = fileparts(fname);

thisR = recipe;
thisR.version = 4;

%% If input is a FBX file, we convert it into PBRT file
% I am starting to experiment with using this even on V4 files to get
% a standard format.  Tried on Cornell box, and a complete bust.
if strcmpi(input_ext, '.fbx')
    disp('Converting FBX file into PBRT file...')
    pbrtFile = piFBX2PBRT(fname);

    disp('Formating PBRT file...')
    infile = piPBRTReformat(pbrtFile);
else
    % Typical
    infile = fname;
end

%% Exist checks on the whole path.
if exist(infile,'file')
    % Force the string to be a full path
    thisR.inputFile = which(infile);
else
    error('Can not find %s on the path.\n',infile);
end

% Copy?  Or some other method?
exporter = p.Results.exporter;
thisR.exporter = exporter;

%% Set the output directory in local that piWrite will use

outFilepath      = fullfile(piRootPath,'local',outputdirname);
outputFile       = fullfile(outFilepath,[outputdirname,'.pbrt']);
thisR.set('outputFile',outputFile);

%% Read PBRT options and world text.

% The text includes just the main PBRT scene file, with the 'Includes'
txtLines = piReadText(thisR.inputFile);

%% Split the text into the options and world

% The pbrt options means the camera, film, sampler and other
% properties that are present prior to WorldBegin
%
% The recipe.world slot is filled with the world text on return.
pbrtOptions = piReadWorldText(thisR, txtLines);

%% Read options information

% Act on the pbrtOptions, setting the recipe slots (i.e., thisR).
piReadOptions(thisR,pbrtOptions);

%% Insert the text from the Include files

% These are usually _geometry.pbrt and _materials.pbrt.  At this
% point, we can have shapes that have no names.  These are defined in
% thisR.world just by their points and normals.
piReadWorldInclude(thisR);

%% Read Materials and Textures

% Read material and texture
[materialLists, textureList, newWorld, matNameList, texNameList] = parseMaterialTexture(thisR);
thisR.world = newWorld;

thisR.materials.list = materialLists;
thisR.materials.order = matNameList;

% Add the material lib
thisR.materials.lib = piMateriallib;

thisR.textures.list = textureList;
thisR.textures.order = texNameList;

% Convert texture file format to PNG
thisR = piTextureFileFormat(thisR);

fprintf('Read %d materials and %d textures.\n', materialLists.Count, textureList.Count);

%% Decide whether to Copy or Parse to get the asset tree filled up

if strcmpi(exporter, 'Copy')
    % On Copy we copy the assets, we do not parse them.
    % It would be best if we could always parse the objects.
else
    % Try to parse the assets
    % Build the asset tree of objects and lights
    [trees, newWorld] = parseObjectInstanceText(thisR, thisR.world);
    thisR.world = newWorld;

    if exist('trees','var') && ~isempty(trees)
        thisR.assets = trees.uniqueNames;

        %  Additional information for instanced objects
        %
        % PBRT does not allow instance lights, however in the cases that
        % we would like to instance an object with some lights on it, we will
        % need to save that additional information to it, and then repeatedly
        % write the attributes when the objectInstance is used in attribute
        % pairs. --Zhenyi
        for ii  = 1:numel(thisR.assets.Node)
            thisNode = thisR.assets.Node{ii};
            if isfield(thisNode, 'isObjectInstance') && isfield(thisNode, 'referenceObject')
                if isempty(thisNode.referenceObject) || thisNode.isObjectInstance == 1
                    continue
                end

                [ParentId, ParentNode] = piAssetFind(thisR, 'name', [thisNode.referenceObject,'_B']);

                if isempty(ParentNode), continue;end

                ParentNode = ParentNode{1};
                ParentNode.extraNode = thisR.get('asset', ii, 'subtree','true');
                ParentNode.camera = thisR.lookAt;
                thisR.assets = thisR.assets.set(ParentId, ParentNode);
            end
        end
    else
        % needs to add function to read structure like this:
        % transform [...] / Translate/ rotate/ scale/
        % material ... / NamedMaterial
        % shape ...
        disp('*** No tree returned by parseObjectInstanceText. recipe.assets is empty');
    end
end

%% Fixing up the object names

% If we have assets, including objects, make the object names unique.
% This is important when there is a global object name (colorChecker) and
% each components is assigned the global name, but given a different shape.
% It happens for the Macbeth case. Ugh.
if ~isempty(thisR.assets)
    oNames = thisR.get('object names no id');

    % Make unique names
    if numel(oNames) ~= numel(unique(oNames))
        idx = thisR.get('objects');

        % Strip the _O.  Maybe this should be a recipeGet method.
        for ii=1:numel(oNames), oNames{ii} = oNames{ii}(1:end-2); end

        % make them unique here
        oNames = matlab.lang.makeUniqueStrings(oNames);
        for ii=1:length(idx)
            thisR.set('asset',idx(ii),'name',sprintf('%s_O',oNames{ii}));
        end
        thisR.assets.uniqueNames;
    end
end

end

%% Helper functions
% piReadText
% piReadOptions
% piReadWorldText
% piReadLookAt
% piParseOptions
% piReadWorldInclude
%

%% Open, read, close excluding comment lines
function txtLines = piReadText(fname)
%
% Synopsis
%    txtLines = piReadText(fname)
%
% Brief description:
%   Read the text lines in a PBRT file. Also 
%
%    * strips any trailing blanks on the line
%    * does some fix for square brackets (some historical thing)
%    * Removes all blank lines
%
%   Comment lines are included because they sometimes contain useful
%   information about object names.
%
% Inputs
%   fname = PBRT scene file name.  
%
% Outputs
%   txtLines - Cell array of each of the text lines in the file.
%
% See also
%   piRead

%% Open the PBRT scene file
fileID = fopen(fname);

tmp = textscan(fileID,'%s','Delimiter','\n');

txtLines = tmp{1};

fclose(fileID);

% Remove empty lines.  Shouldn't this be handled in piReadText?
txtLines = txtLines(~cellfun('isempty',txtLines));

% We remove any trailing blank spaces from the text lines here. (BW).
for ii=1:numel(txtLines)
    idx = find(txtLines{ii} ~=' ',1,'last');
    txtLines{ii} = txtLines{ii}(1:idx);
end

% Replace left and right bracks with double-quote.  ISET3d formatting.
txtLines = strrep(txtLines, '[ "', '"');
txtLines = strrep(txtLines, '" ]', '"');

%{
% In the past we excluded the comment lines.  But then
% we included them, probably so we can get the objectnames.  That made
% this bit of code redundant.  I am removing (BW, March 31, 2023).
%
fileID = fopen(fname);
tmp = textscan(fileID,'%s','Delimiter','\n');
header = tmp{1};
fclose(fileID);
%}

end

%% Step through each of the pbrtOption lines and updated the recipe
function piReadOptions(thisR,pbrtOptions)
%
% Synopsis
%   piReadOptions(thisR,pbrtOptions)
%
% Inputs
%   thisR - PBRT recipe
%   pbrtOptions - Text extracted from PBRT scene file containing the
%     options for Camera, Sample, Filme, TransformTimes, PixelFilter,
%     Integrator, and Scale
%
% Output
%   thisR is updated
%
% See also
%   piRead, piParseOptions


% Extract camera block
thisR.camera = piParseOptions(pbrtOptions, 'Camera');

% Extract sampler block
thisR.sampler = piParseOptions(pbrtOptions,'Sampler');

% Extract film block
thisR.film    = piParseOptions(pbrtOptions,'Film');

% always use 'gbuffer' for multispectral rendering
thisR.film.subtype = 'gbuffer';

% Patch up the filmStruct to match the recipe requirements
if(isfield(thisR.film,'filename'))
    % Remove the filename since it inteferes with the outfile name.
    thisR.film = rmfield(thisR.film,'filename');
end

% Some PBRT files do not specify the film diagonal size.  We set it to
% 1mm here.
try
    thisR.get('film diagonal');
catch
    disp('Setting film diagonal size to 1 mm');
    thisR.set('film diagonal',1);
end

% Extract transform time block
thisR.transformTimes = piParseOptions(pbrtOptions, 'TransformTimes');

% Extract surface pixel filter block
thisR.filter = piParseOptions(pbrtOptions,'PixelFilter');

% Extract (surface) integrator block
thisR.integrator = piParseOptions(pbrtOptions,'Integrator');

% % Extract accelerator
% thisR.accelerator = piParseOptions(options,'Accelerator');

% Set thisR.lookAt and determine if we need to flip the image
flipping = piReadLookAt(thisR,pbrtOptions);

% Sometimes the axis flip is "hidden" in the concatTransform matrix. In
% this case, the flip flag will be true. When the flip flag is true, we
% always output Scale -1 1 1.
if(flipping)
    thisR.scale = [-1 1 1];
end

% Read Scale, if it exists
% Because PBRT is a LHS and many object models are exported with a RHS,
% sometimes we stick in a Scale -1 1 1 to flip the x-axis. If this scaling
% is already in the PBRT file, we want to keep it around.
% fprintf('Reading scale\n');
[~, scaleBlock] = piParseOptions(pbrtOptions,'Scale');
if(isempty(scaleBlock))
    thisR.scale = [];
else
    values = textscan(scaleBlock, '%s %f %f %f');
    thisR.scale = [values{2} values{3} values{4}];
end

end

%% Find the text in WorldBegin/End section
function [options, world] = piReadWorldText(thisR,txtLines)
%
% Finds all the text lines beginning with WorldBegin
%
% It puts the original world section into the thisR.world.
% Then it removes the world section from the txtLines
%
% Question: Why doesn't this stop at WorldEnd?  In our experience, we
% see some files that never even have a WorldEnd, just a World Begin.
%
% This function converts the blocks to a single line.  We need this
% format because Zheng's Matlab parser expects the blocks to be in a
% single line. Some files PBRT files come to us with blocks separated
% onto multiple lines.  These are converted from format-X to PBRT by
% the PBRT parser (toply).  (BW)
%
% See also
%  piRead -> piReadWorldText -> piFormatConvert

txtLines = piFormatConvert(txtLines);

% Look for WorldBegin
worldBeginIndex = 0;
for ii = 1:length(txtLines)
    currLine = txtLines{ii};
    if(piContains(currLine,'WorldBegin'))
        worldBeginIndex = ii;
        break;
    end
end

if(worldBeginIndex == 0)
    warning('Cannot find WorldBegin.');
    worldBeginIndex = ii;
end

% Store the text from WorldBegin to the end here
world = txtLines(worldBeginIndex:end);
thisR.world = world;

% Store the text lines from before WorldBegin here
options = txtLines(1:(worldBeginIndex-1));

end

%% Build the lookAt information
function [flipping,thisR] = piReadLookAt(thisR,txtLines)
% Reads multiple blocks to create the lookAt field and flip variable
%
% The lookAt is built up by reading from, to, up field and transform and
% concatTransform.
%
% Interpreting these variables from the text can be more complicated w.r.t.
% formatting.

% A flag for flipping from a RHS to a LHS.
flipping = 0;

% Get the block
% [~, lookAtBlock] = piBlockExtract(txtLines,'blockName','LookAt');
[~, lookAtBlock] = piParseOptions(txtLines,'LookAt');
if(isempty(lookAtBlock))
    % If it is empty, use the default
    thisR.lookAt = struct('from',[0 0 0],'to',[0 1 0],'up',[0 0 1]);
else
    % We have values
    %     values = textscan(lookAtBlock{1}, '%s %f %f %f %f %f %f %f %f %f');
    values = textscan(lookAtBlock, '%s %f %f %f %f %f %f %f %f %f');
    from = [values{2} values{3} values{4}];
    to = [values{5} values{6} values{7}];
    up = [values{8} values{9} values{10}];
end

% If there's a transform, we transform the LookAt. % to change
[~, transformBlock] = piBlockExtract(txtLines,'blockName','Transform');
if(~isempty(transformBlock))
    values = textscan(transformBlock{1}, '%s [%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f]');
    values = cell2mat(values(2:end));
    transform = reshape(values,[4 4]);
    [from,to,up,flipping] = piTransform2LookAt(transform);
end

% If there's a concat transform, we use it to update the current camera
% position. % to change
[~, concatTBlock] = piBlockExtract(txtLines,'blockName','ConcatTransform');
if(~isempty(concatTBlock))
    values = textscan(concatTBlock{1}, '%s [%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f]');
    values = cell2mat(values(2:end));
    concatTransform = reshape(values,[4 4]);

    % Apply transform and update lookAt
    lookAtTransform = piLookat2Transform(from,to,up);
    [from,to,up,flipping] = piTransform2LookAt(lookAtTransform*concatTransform);
end

% Warn the user if nothing was found
if(isempty(transformBlock) && isempty(lookAtBlock))
    warning('Cannot find "LookAt" or "Transform" in PBRT file. Returning default.');
end

thisR.lookAt = struct('from',from,'to',to,'up',up);
thisR.set('film render type',{'radiance'});

end

%% Parse several critical recipe options
function [s, blockLine] = piParseOptions(txtLines, blockName)
% Parse the options for a specific block
%

% How many lines of text?
nline = numel(txtLines);
s = [];ii=1;

while ii<=nline
    blockLine = txtLines{ii};
    % There is enough stuff to make it worth checking
    if length(blockLine) >= 5 % length('Shape')
        % If the blockLine matches the BlockName, do something
        if strncmp(blockLine, blockName, length(blockName))
            s=[];

            % If it is Transform, do this and then return
            if (strcmp(blockName,'Transform') || ...
                    strcmp(blockName,'LookAt')|| ...
                    strcmp(blockName,'ConcatTransform')|| ...
                    strcmp(blockName,'Scale'))
                return;
            end

            % It was not Transform.  So figure it out.
            thisLine = strrep(blockLine,'[','');  % Get rid of [
            thisLine = strrep(thisLine,']','');   % Get rid of ]
            thisLine = textscan(thisLine,'%q');   % Find individual words into a cell array

            % thisLine is a cell of 1.
            % It contains a cell array with the individual words.
            thisLine = thisLine{1};
            nStrings = length(thisLine);
            blockType = thisLine{1};
            blockSubtype = thisLine{2};
            s = struct('type',blockType,'subtype',blockSubtype);
            dd = 3;

            % Build a struct that will be used for representing this type
            % of Option (Camera, Sampler, Integrator, Film, ...)
            % This builds the struct and assigns the values of the
            % parameters
            while dd <= nStrings
                if piContains(thisLine{dd},' ')
                    C = strsplit(thisLine{dd},' ');
                    valueType = C{1};
                    valueName = C{2};
                end

                % Some parameters have multiple values, most just one.
                % inserted this switch to handle the cropwindow case.
                % Maybe others will come up (e.g., spectrum?) (BW)
                switch valueName
                    case 'cropwindow'
                        value = zeros(1,4);
                        for jj=1:4
                            value(jj) = str2double(thisLine{dd+jj});
                        end
                        dd = dd+5;
                    otherwise
                        value = thisLine{dd+1};
                        dd = dd+2;
                end

                % Convert value depending on type
                if(isempty(valueType))
                    continue;
                elseif(strcmp(valueType,'string')) || strcmp(valueType,'spectrum')
                    % Do nothing.
                elseif strcmp(valueType,'bool')
                    if isequal(value, 'true')
                        value = true;
                    elseif isequal(value, 'false')
                        value = false;
                    end
                elseif(strcmp(valueType,'float') || strcmp(valueType,'integer'))
                    % In cropwindow case, above, value is already converted.
                    if ischar(value)
                        value = str2double(value);
                    end
                else
                    error('Did not recognize value type, %s, when parsing PBRT file!',valueType);
                end

                % Assign the type and value to the recipe
                tempStruct = struct('type',valueType,'value',value);
                s.(valueName) = tempStruct;
            end
            break;
        end
    end
    ii = ii+1;
end

if isequal(blockName,'Integrator') && isempty(s)
    % We did not find an integrator.  So we return a default.
    s.type = 'Integrator';
    s.subtype = 'path';
    s.maxdepth.type = 'integer';
    s.maxdepth.value= 5;
    fprintf('Setting integrator to "path" with 5 bounces.\n')
end

end

%% Include files into world text
function piReadWorldInclude(thisR)
% Insert text from the Include files in the world section
%
% We also change the World txt lines into the single line format
%
% See also
%  piRead, piReadText
%

world = thisR.world;

if any(piContains(world, 'Include'))

    % Find all the lines in world that have an 'Include'
    inputDir = thisR.get('inputdir');
    IncludeIdxList = find(piContains(world, 'Include'));

    % For each of those lines ....
    for IncludeIdx = 1:numel(IncludeIdxList)
        % Find the include file
        IncStrSplit = strsplit(world{IncludeIdxList(IncludeIdx)},' ');
        IncFileName = erase(IncStrSplit{2},'"');
        IncFileNamePath = fullfile(inputDir, IncFileName);

        % Read the text from the include file
        IncLines = piReadText(IncFileNamePath);

        % Erase the include line.
        thisR.world{IncludeIdxList(IncludeIdx)} = [];

        % Add the text to the world section
        thisR.world = {thisR.world, IncLines};
        thisR.world = cat(1, thisR.world{:});
    end
end

%
thisR.world = piFormatConvert(thisR.world);
end

%% END
