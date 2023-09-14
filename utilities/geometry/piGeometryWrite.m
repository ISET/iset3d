function  piGeometryWrite(thisR,varargin)
% Write out a geometry file that matches the format and labeling objects
%
% Synopsis
%   piGeometryWrite(thisR,varargin)
%
% Input:
%   thisR: a render recipe
%   obj:   Returned by piGeometryRead, contains information about objects.
%
% Optional key/value pairs
%
% Output:
%   None
%
% Description
%   We need a better description of objects and groups here.  Definitions
%   of 'assets'.
%
% Zhenyi, 2018
%
% See also
%   piGeometryRead
%

%% Main logic is in this routine.

%  The routine relies on multiple helpers, below.
p = inputParser;

varargin = ieParamFormat(varargin);

p.addRequired('thisR',@(x)isequal(class(x),'recipe'));
p.addParameter('remoteresources', getpref('docker','remoteResources',false));
p.parse(thisR,varargin{:});

remoteResources = p.Results.remoteresources;

%% Create the default file name

% Get the fullname of the geometry file to write
[Filepath,scene_fname] = fileparts(thisR.outputFile);
fname = fullfile(Filepath,sprintf('%s_geometry.pbrt',scene_fname));[~,n,e]=fileparts(fname);

% Get the assets from the recipe
obj = thisR.assets;

%% Write the geometry file...

fname_obj = fullfile(Filepath,sprintf('%s%s',n,e));

% Open the file and write out the assets
fid_obj = fopen(fname_obj,'W');
% fprintf(fid_obj,'# Exported by piGeometryWrite on %i/%i/%i %i:%i:%f \n  \n',clock);
fprintf(fid_obj,'# Exported by piGeometryWrite %s \n  \n',string(datetime));

% Traverse the asset tree beginning at the root
rootID = 1;

% TODO:  We shouldn't need thisR and thisR.outputFile and Filepath in
% the arguments to recursiveWriteXXXX
%

% Write object and light definitions in the main geometry
% and any needed child geometry files
if ~isempty(obj)

    % This code seems to do nothing unless we are processing
    % instances. If there are no instances, nothing gets written.  If
    % there are instances, we seem to write out some information about
    % the branch defining the geometry for this instance.
    recursiveWriteNode(fid_obj, obj, rootID, Filepath, thisR.outputFile, thisR);

    % Write the geometry from the tree structure in the geometry file
    % for all of the assets, including objects and lights.
    lvl = 0;
    writeGeometryFlag = 0;
    recursiveWriteAttributes(fid_obj, obj, rootID, lvl, thisR.outputFile, writeGeometryFlag, thisR, 'remoteresources', remoteResources);
else
    % if the tree object is empty, copy the world slot into the geometry
    % file.
    for ii = numel(thisR.world)
        fprintf(fid_obj, thisR.world{ii});
    end
end

% Close it up and leave.
fclose(fid_obj);

end

%% ---------  Geometry file writing helpers

%% Recursively write nodes
function recursiveWriteNode(fid, obj, nodeID, rootPath, outFilePath, thisR)
% Manages the special case of instances.
%
% The main work writing out the geometry file is done by
% recursiveWriteAttributes (below).  This one is specialized for
% writing out nodes that are instances of a main node written out by
% recursiveWriteAttributes.
%
% fid - Open file pointer for the geometry file
% obj - A tree structure that contains the scene information,
%       including objects and lights and the geometry branches for
%       those assets
% nodeID   - The node in the tree (an integer)
% rootPath - 
% outFilePath - Shouldn't this be irrelevant given that we have the
%               fid?
% thisR  - The recipe for rendering the scene
%
% Define each object in geometry.pbrt file. This section writes out
% (1) Material for every object
% (2) path to each child geometry file
%     which store the shape and other geometry info.
%
% The process is:
%   (1) Get the children of the current node
%   (2) For each child, check if it is an 'object' or 'light' node.
%       If it is, write it out.
%   (3) If the child is a 'branch' node, put it in a list which will be
%       recursively checked in the next level of our traverse.

%% Get children of the current Node (thisNode)
children = obj.getchildren(nodeID);

%% Loop through all children of our current node (thisNode)
% If 'object' node, write out. If 'branch' node, put in the list

% Create a list for next level recursion
nodeList = [];

% Build up the nodeList.  We pass that in to the loop below calling
% recursiveWriteNode
for ii = 1:numel(children)

    % set our current node to each of the child nodes
    thisNode = obj.get(children(ii));

    % The nodes can be a branch, object, light, marker, or instance
    %
    
    if isequal(thisNode.type, 'branch')
        % If a branch, put id in the nodeList

        % It would be much better to pre-allocate if possible.  For speed
        % with scenes and many assets. Ask Zhenyi Liu how he wants to
        % handle this (BW)
        nodeList = [nodeList children(ii)]; %#ok<AGROW> 

        % do not write object instance repeatedly
        if isfield(thisNode,'isObjectInstance')
            % Typically, this field does not exist.  So we do not
            % execute the code below.  But some branches refer to an
            % instance and we specifically write out the transforms
            % separately for this instance.            
            if thisNode.isObjectInstance == 1
                indentSpacing = '    ';
                fprintf(fid, 'ObjectBegin "%s"\n', thisNode.name(10:end-2));
                if ~isempty(thisNode.motion)
                    fprintf(fid, strcat(spacing, indentSpacing,...
                        'ActiveTransform StartTime \n'));
                end

                spacing = ''; % faster if not a string
                piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing);

                % Write out motion
                if ~isempty(thisNode.motion)
                    for jj = 1:size(thisNode.translation, 2)
                        fprintf(fid, strcat(spacing, indentSpacing,...
                            'ActiveTransform EndTime \n'));

                        % First write out the same translation and rotation
                        piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing);

                        if isfield(thisNode.motion, 'translation')
                            if isempty(thisNode.motion.translation(jj, :))
                                fprintf(fid, strcat(spacing, indentSpacing,...
                                    'Translate 0 0 0\n'));
                            else
                                pos = thisNode.motion.translation(jj,:);
                                fprintf(fid, strcat(spacing, indentSpacing,...
                                    sprintf('Translate %f %f %f', pos(1),...
                                    pos(2),...
                                    pos(3)), '\n'));
                            end
                        end

                        if isfield(thisNode.motion, 'rotation') &&...
                                ~isempty(thisNode.motion.rotation)
                            rot = thisNode.motion.rotation;
                            % Write out rotation
                            fprintf(fid, strcat(spacing, indentSpacing,...
                                sprintf('Rotate %f %f %f %f',rot(:,jj*3-2)), '\n')); % Z
                            fprintf(fid, strcat(spacing, indentSpacing,...
                                sprintf('Rotate %f %f %f %f',rot(:,jj*3-1)),'\n')); % Y
                            fprintf(fid, strcat(spacing, indentSpacing,...
                                sprintf('Rotate %f %f %f %f',rot(:,jj*3)), '\n'));   % X
                        end
                    end
                end
                lvl = 1;
                writeGeometryFlag = 1;
                recursiveWriteAttributes(fid, obj, children(ii), lvl, outFilePath, writeGeometryFlag, thisR);
                fprintf(fid, 'ObjectEnd\n\n');
                % nodeID == 1 is rootID.
                if nodeID ~=1, return; end
            end
        end

        % Define object node
    elseif isequal(thisNode.type, 'object')
        % Deal with object node properties in recursiveWriteAttributes;
    elseif isequal(thisNode.type, 'light') || isequal(thisNode.type, 'marker') || isequal(thisNode.type, 'instance')
        % That's okay but do nothing.
    else
        % Something must be wrong if we get here.
        warning('Unknown node type: %s', thisNode.type)
    end
end

% We've built up a list of branch nodes. Loop through them.
for ii = 1:numel(nodeList)
    recursiveWriteNode(fid, obj, nodeList(ii), rootPath, outFilePath);
end

end

%% Recursive write for attributes?
function recursiveWriteAttributes(fid, obj, thisNode, lvl, outFilePath, writeGeometryFlag, thisR, varargin)
% Print out information in the geometry file about the nodes
%
% Information for branches, objects, and lights are managed
% separately.
%
% Inputs
%  fid - File pointer to the geometry file for writing
%  obj - The tree of nodes representing the scene
%  thisNode - The node we are working on
%  lvl - Level of the tree hierarchy.  We use this to set the indentation 
%  outFilePath - Can be determined from thisR, so not necessary
%  writeGeometryFlag - Sometimes, it seems, we get here but do not want
%                     to write.  Not sure why.
%  thisR - The recipe
% 
% Optional key/val
%  remoteresources
%
% Outputs
%   N/A
%
% This runs recursively.
%
%   1) Get the children of the current node
%   2) For each child, write out information accordingly
%
% See also
%   recursiveWriteNodes
%

% TODO:  We are not sure why we have the varargin here.
% The remote resources does not seem to be used in here
%

%% Get children of this node
children = obj.getchildren(thisNode);

%% Loop through children at this level

% Generate spacing to make the tree structure more beautiful
spacing = blanks(lvl * 4);

% indent spacing
indentSpacing = '    ';

for ii = 1:numel(children)
    thisNode = obj.get(children(ii));

    if isfield(thisNode, 'isObjectInstance')
        if thisNode.isObjectInstance ==1 && ~writeGeometryFlag
            % This node is an object instance node, skip;
            continue;
        end
    end

    referenceObjectExist = [];
    if isfield(thisNode,'referenceObject') && ~isempty(thisNode.referenceObject)
        referenceObjectExist = piAssetFind(obj,'name',strcat(thisNode.referenceObject,'_B'));
    end

    fprintf(fid, [spacing, 'AttributeBegin\n']);
    
    if isequal(thisNode.type, 'branch')
        % Get the name after stripping ID for this Node
        while numel(thisNode.name) >= 10 &&...
                isequal(thisNode.name(7:8), 'ID')
            thisNode.name = thisNode.name(10:end);
        end
        
        % Write the object's dimensions
        fprintf(fid, [spacing, indentSpacing,...
            sprintf('#MeshName: "%s" #Dimension:[%.4f %.4f %.4f]',thisNode.name,...
            thisNode.size.l,...
            thisNode.size.w,...
            thisNode.size.h), '\n']);

        % Needs neatening.  At least get the CoordSys thing after the
        % attributeBegin.
        thisNodeChildId = obj.getchildren(children(ii));
        if ~isempty(thisNodeChildId)
            % If there are children, it's a branch.
            thisNodeChild = obj.get(thisNodeChildId);

            % If it is a branch with a light below it, check about the
            % coordinate system.
            if strcmp(thisNodeChild.type, 'light') && ...
                    strcmp(thisNodeChild.lght{1}.type,'area')
                % This is nuts and should go away
            elseif strcmp(thisNodeChild.type, 'light') && ...
                    isfield(thisNodeChild.lght{1},'cameracoordinate') && ...
                    thisNodeChild.lght{1}.cameracoordinate
                fprintf(fid, [spacing, indentSpacing, 'CoordSysTransform "camera" \n']);
            end
        end

        % If a motion exists in the current object, prepare to write it out by
        % having an additional line below.  For now, this is not
        % functional.
        if ~isempty(thisNode.motion)
            fprintf(fid, strcat(spacing, indentSpacing,...
                'ActiveTransform StartTime \n'));
            % thisR.hasActiveTransform = true;
        end

        % Transformation section
        
        % If this branch has a single child that is a light, then we
        % should figure out if the light has cameracoordinate true.
        % If it does, we should write that into the file prior to to
        % the concat transform in 
        %s
        if ~isempty(thisNode.rotation)
            % Zheng: I think it is always this case, but maybe it is rarely
            % the case below. Have no clue.
            % If this way, we would write the translation, rotation and
            % scale line by line based on the order of
            % thisNode.transorder.
            piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing);
        else
            % We think we never get here
            warning('Surprised to be here.');
            thisNode.concattransform(13:15) = thisNode.translation(:);
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('ConcatTransform [%.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f]', thisNode.concattransform(:)), '\n'));
            % Scale
            fprintf(fid, strcat(spacing, indentSpacing,...
                sprintf('Scale %.10f %.10f %.10f', thisNode.scale), '\n'));
        end

        % Motion section
        if ~isempty(thisNode.motion)
            fprintf(fid, strcat(spacing, indentSpacing,...
                'ActiveTransform EndTime \n'));
            for jj = 1:size(thisNode.translation, 2)


                % First write out the same translation and rotation
                piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing);

                if isfield(thisNode.motion, 'translation')
                    if isempty(thisNode.motion.translation(jj, :))
                        fprintf(fid, strcat(spacing, indentSpacing,...
                            'Translate 0 0 0\n'));
                    else
                        pos = thisNode.motion.translation(jj,:);
                        fprintf(fid, strcat(spacing, indentSpacing,...
                            sprintf('Translate %f %f %f', pos(1),...
                            pos(2),...
                            pos(3)), '\n'));
                    end
                end

                if isfield(thisNode.motion, 'rotation') &&...
                        ~isempty(thisNode.motion.rotation)
                    rot = thisNode.motion.rotation;
                    % Write out rotation
                    fprintf(fid, strcat(spacing, indentSpacing,...
                        sprintf('Rotate %f %f %f %f',rot(:,3-2)), '\n')); % Z
                    fprintf(fid, strcat(spacing, indentSpacing,...
                        sprintf('Rotate %f %f %f %f',rot(:,3-1)),'\n')); % Y
                    fprintf(fid, strcat(spacing, indentSpacing,...
                        sprintf('Rotate %f %f %f %f',rot(:,3)), '\n'));   % X
                end
            end
        end

        % Reference object section (also if an instance (object copy))
        if ~isempty(referenceObjectExist) && isfield(thisNode,'referenceObject')
            fprintf(fid, strcat(spacing, indentSpacing, ...
                sprintf('ObjectInstance "%s"', thisNode.referenceObject), '\n'));
        end

        % (fid, obj, thisNode, lvl, outFilePath, writeGeometryFlag, thisR)
        recursiveWriteAttributes(fid, obj, children(ii), lvl + 1, ...
            outFilePath, writeGeometryFlag, thisR);

    elseif isequal(thisNode.type, 'object') || isequal(thisNode.type, 'instance')
        while numel(thisNode.name) >= 10 &&...
                isequal(thisNode.name(7:8), 'ID')

            % remove instance suffix
            endIndex = strfind(thisNode.name, '_I_');
            if ~isempty(endIndex),    endIndex =endIndex-1;
            else,                     endIndex = numel(thisNode.name);
            end
            thisNode.name = thisNode.name(10:endIndex);
        end

        % if this is an arealight or object without a reference object
        if writeGeometryFlag || isempty(referenceObjectExist)
            [rootPath,~] = fileparts(outFilePath);

            % We have a cross-platform problem here?
            %[p,n,e ] = fileparts(thisNode.shape{1}.filename);
            %thisNode.shape{1}.filename = fullfile(p, [n e]);
            ObjectWrite(fid, thisNode, rootPath, spacing, indentSpacing, thisR);
            fprintf(fid,'\n');
        else
            % use reference object
            fprintf(fid, strcat(spacing, indentSpacing, ...
                sprintf('ObjectInstance "%s"', thisNode.name), '\n'));
        end

    elseif isequal(thisNode.type, 'light')
        % Create a tmp recipe
        tmpR = recipe;
        tmpR.outputFile = outFilePath;
        tmpR.lights = thisNode.lght;

        % The cameracoordinate should not be here.  It should be in
        % the branch node just above the light.
        lightText = piLightWrite(tmpR, 'writefile', false);

        for jj = 1:numel(lightText)
            for kk = 1:numel(lightText{jj}.line)
                fprintf(fid,sprintf('%s%s%s\n',spacing, indentSpacing,...
                    sprintf('%s',lightText{jj}.line{kk})));
            end
        end
    else
        % Hopefully we never get here.
        warning('Unknown node type %s\n',thisNode.type);
    end

    fprintf(fid, [spacing, 'AttributeEnd\n']);
end

end


%% Geometry transforms
function piGeometryTransformWrite(fid, thisNode, spacing, indentSpacing)
% Prints the ConcatTransform matrix into the geometry file.
%
% We never write out scale/translate/rotate.  Only this matrix.
%
% If the transform is simply the identity, we do not bother writing it out.
% I am unsure whether that will create problems somewhere. (BW).

identityTransform = [ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1];

pointerT = 1; pointerR = 1; pointerS = 1;
translation = zeros(3,1);
rotation = piRotationMatrix;
scale = ones(1,3);
for tt = 1:numel(thisNode.transorder)
    switch thisNode.transorder(tt)
        case 'T'
            translation = translation + thisNode.translation{pointerT}(:);
            pointerT = pointerT + 1;
        case 'R'
            rotation = rotation + thisNode.rotation{pointerR};
            pointerR = pointerR + 1;
        case 'S'
            scale = scale .* thisNode.scale{pointerS};
            pointerS = pointerS + 1;
    end
end
tMatrix = piTransformCompose(translation, rotation, scale);
tMatrix = reshape(tMatrix,[1,16]);

% This is not correct.  I left it here because I want to eliminate writing
% out the identity.  But I haven't figured out the correct way. (BW).
% if tMatrix(:) ~= identityTransform(:)

    transformType = 'ConcatTransform';

    % A 4x4 affine transformation used is in graphics to combine rotation and
    % translation.  The identity transform does nothing.  So it is not worth
    % writing out.  BW trying to save time/space this way
    % This takes a lot of time, let's break it up to see why
    printString = sprintf('%s [%.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f %.5f]',...
        transformType, tMatrix(:));
    fullLine = [spacing indentSpacing printString '\n'];
    fprintf(fid, fullLine);
% end

end


%%
function ObjectWrite(fid, thisNode, rootPath, spacing, indentSpacing,thisR)
% Write out an object, including its named material and shape
% information.

%% The participating media PBRT line.  More comments needed
if ~isempty(thisNode.mediumInterface)
    fprintf(fid, strcat(spacing, indentSpacing, sprintf("MediumInterface ""%s"" ""%s""\n", thisNode.mediumInterface.inside, thisNode.mediumInterface.outside)));
end

%% Write out material properties
% An object can contain multiple material and shapes
for nMat = 1:numel(thisNode.material)

    if iscell(thisNode.material), material = thisNode.material{nMat};
    else,                         material = thisNode.material;
    end

    try
        str = sprintf('%s%s NamedMaterial "%s" ',spacing,indentSpacing,material.namedmaterial);
        fprintf(fid, '%s\n',str); % strcat(spacing, indentSpacing, "NamedMaterial ", '"', material.namedmaterial, '"', '\n'));
    catch
        % we should never be here
        warning('Material write issue.')
        materialTxt = piMaterialText(material, thisR);
        fprintf(fid, strcat(materialTxt, '\n'));
    end

    % Deal with possibility of a cell array for the shape.  This logic
    % seems off to me (BW, 4/4/2023)
    if ~iscell(thisNode.shape)
        thisShape = thisNode.shape;
    elseif iscell(thisNode.shape) && numel(thisNode.shape)
        % At least one entry in the cell?
        thisShape = thisNode.shape{1};
    else
        thisShape = thisNode.shape{nMat};
    end

    % There is a shape.  We create the text line for the shape and
    % potentially a file that will be included.
    if ~isempty(thisShape)

        % There is a filename that will be included to define the
        % shape
        if ~isempty(thisShape.filename)
            % If the shape has a file specification, we do this

            % The file can be a ply or a pbrt file. 
            % Figure out the extension.
            [~, ~, fileext] = fileparts(thisShape.filename);

            % We seem to be testing these here.
            pbrtName = strrep(thisShape.filename,'.ply','.pbrt');
            if ~isfile(fullfile(rootPath, pbrtName))
                % No PBRT file matching the shape.  Go to line 493.

                plyName = strrep(thisShape.filename,'.pbrt','.ply');
                if ~isfile(fullfile(rootPath, plyName))
                    % No PLY file matching the shape

                    % In the past, we allowed for meshes to be along
                    % our path This is expensive. We are now expecting
                    % meshes to be where they belong, I think
                    % [~, shapeFile, shapeExtension] = fileparts(thisShape.filename);
                    %     if false % which([shapeFile shapeExtension])
                    %         thisShape.filename = plyName;
                    %         thisShape.meshshape = 'plymesh';
                    %         shapeText = piShape2Text(thisShape);
                    %      else
                    %         shapeText = piShape2Text(thisShape);
                    %      end
                    %
                    % We no longer care, as resources can be remote
                    % error('%s not exist',thisShape.filename);
                    % Instead we'll just leave it along to be
                    % passed to the renderer
                    shapeText = piShape2Text(thisShape);                    
                else
                    thisShape.filename = plyName;
                    thisShape.meshshape = 'plymesh';
                    shapeText = piShape2Text(thisShape);
                end
            else
                % There is no filename.
                % We are going to write one out based on the data in shape.  
                if isequal(fileext, '.ply')
                    thisShape.filename = pbrtName;
                    thisShape.meshshape = 'trianglemesh';
                    shapeText = piShape2Text(thisShape);
                    fileext = '.pbrt';
                end
            end

            % Write out the PBRT text line for this shape
            if isequal(fileext, '.ply')
                fprintf(fid, strcat(spacing, indentSpacing, sprintf('%s\n',shapeText)));
            else
                % 4/4/2023 - Removed code and used pbrtName
                %
                %                 if iscell(thisNode.shape)
                %                     fname = thisNode.shape{1}.filename;
                %                 else
                %                     fname = thisNode.shape.filename;
                %                 end
                fprintf(fid, strcat(spacing, indentSpacing, sprintf('Include "%s"', pbrtName)),'\n');
            end
        else
            % There is no shape file name, but there is a shape
            % struct. That means the shapeText has points and nodes
            % that define the shape.  We write those out into a PBRT
            % file inside geometry/ and change the shapeText line to
            % include the file name.
            % 
            % We use an identifier for the file name based on the
            % shape itself. Whenever we have the same points, we have
            % the same name.
            %

            %{
            % Changed April 3rd, 2023
            % In the past, we used the node name for the file.  That
            % was not unique, and changed every time we ran the code.
            name = thisNode.name;  % Maybe we choose a better name.  No ID.
            tmp = split(name,'_');
            name = [tmp{end-2},tmp{end-1},tmp{end}];
            %}

            isNode = false;
            name = piShapeNameCreate(thisShape,isNode, thisR.get('input basename'));
            shapeText = piShape2Text(thisShape);

            % Open the shape specification PBRT file and write the shape data
            geometryFile = fopen(fullfile(rootPath,'geometry',sprintf('%s.pbrt',name)),'w');
            fprintf(geometryFile,'%s',shapeText);
            fclose(geometryFile);

            % Include the file in the scene_geometry.pbrt file
            fprintf(fid, strcat(spacing, indentSpacing, sprintf('Include "geometry/%s.pbrt"', name)),'\n');

        end
        fprintf(fid,'\n');  % Enjoy a carriage return.
    else
        % thisShape is empty. 
        % On 4/4/2023 this worked for ChessSet, SimpleScene, and the
        % fixed up 'kitchen' scene with AttributeBegin/End.  Also with
        % Macbeth Check via piRecipeCreate.  So a decent set of tests.
        % 
        % We get this awkward situation in our Auto @recipes. That might
        % indicate an issue with the recipe creation, but for now we need
        % to let it through in order to render them
        %fprintf('Note: processed empty shape for material %d in %s\n',nMat,thisNode.name);
        
        %{
        % For some Included .pbrt files we don't get a shape
        % since it is in the file. So  we need to write out
        % the include statement instead
        % If it does not have ply file, do this
        % There is a shape slot we also open the geometry file.
        name = thisNode.name;
        % HACK! to test if getting rid of instancing helps-- DJC
        instanceHack = false;
        if instanceHack
            if isequal(regexp(name,'\d\d\d_\d\d\d_\d\d\d_'), 1)
                name = name(13:end);
            end
            if isequal(min(regexp(name,'\d\d\d_\d\d\d_')), 1)
                name = name(9:end);
            end
            if isequal(min(regexp(name,'\d\d\d_')), 1)
                name = name(5:end);
            end
            % interferes with B* assets
            %name = strrep(name,'_B','');

            % Super-weenie HACK!
            % For starters not all materials are 0:!
            % So fails on others
            name = strrep(name,'_O','_mat0');

            fprintf(fid, strcat(spacing, indentSpacing, ...
                sprintf('Shape "plymesh" "string filename" "geometry/%s.ply"', name)),'\n');
        else
            % Currently running code!
            fprintf(fid, strcat(spacing, indentSpacing, sprintf('Include "geometry/%s.pbrt"', name)),'\n');
        end
        fprintf(fid,'\n');
        %}
    end
end

end
