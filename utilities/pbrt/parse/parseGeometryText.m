function [trees, parsedUntil] = parseGeometryText(thisR, txt, name, beBlock)
% function [trees, parsedUntil] = parseGeometryText(thisR, txt, name, beBlock)
% Parse the text from a Geometry file, returning an asset subtree
%
% Synopsis
%   [trees, parsedUntil] = parseGeometryText(thisR, txt, name, beBlock)
%
% Brief:
%   We parse the geometry text file to build up the asset tree in the
%   recipe.  We succeed for some, but not all, PBRT files.  We continue to
%   add special cases.  Called by parseObjectInstanceText
%
% Inputs:
%   thisR       - a scene recipe
%   txt         - text of the PBRT geometry information that we parse
%   name        - Use this object name
%
% Optional
%   beBlock     - True if called from within a AttributeBegin/End block
%   (default: false)
%
% Outputs:
%   trees       - A tree class that describes the assets and their geometry
%   parsedUntil - line number where the parsing ends
%
% Description:
%   The lines of text in 'txt' are a cell array that has been formatted so
%   that each main object or material or light is on a single line.  We
%   parse the lines to create a tree structure of assets, which includes
%   objects and lights. We also learn about named materials. The naming of
%   these assets has been a constant struggle, and I attempt to clarify
%   here.
%
%   This parseGeometryText method creates the asset tree. It reads the
%   geometry text in the PBRT scene file (and the includes) line by
%   line. It tries to find the materials and shapes to create the
%   assets.  It also tries to find the transforms for the branch node
%   above the object node.
%
%   There are two types of parsing that this routine handles.

%   AttributeBegin/End
%    Each such block and creates an asset.  Because these can be
%    nested (i.e., we have AttributeBegin/End within such a block), this
%    routine is recursive (calls itself).
%
%   NamedMaterial-Shapes
%    Some scenes do not have a Begin/End, just a series of
%    NamedMaterial followed by shapes.
%
%   This routine fails on some 'wild' type PBRT scenes. In those
%   casses we try setting thisR.exporter = 'Copy'.
%
%   A limitation si that we do not have an overview of the whole
%   'world' text at the beginning. Maybe we should do a quick first
%   pass?  To see whether everything is between an AttributeBegin/End
%   grouping, or to determine the Material-Shapes sequences?
%
% More details
%
%   For the AttributeBegin/End case
%
%       a) 'AttributeBegin': this is the beginning of a block. We will
%       keep looking for node/object/light information until we reach
%       the 'AttributeEnd'.  Remember, though, this is recursive.  So
%       we might have multiple Begin/End pairs within a Begin/End
%       pair.
%
%       b) Node/object/light information: The text within a
%       AttributeBegin/End section may contain multiple types of
%       information.  For example, about the object rotation, position,
%       scaling, shape, material properties, light spectrum information. We
%       do our best to parse this information, and then the parameters are
%       stored in the appropriate location within the asset tree in the
%       recipe.
%
%       c) 'AttributeEnd': When we reach this line, we close up this node
%       and add it to the array of what we call 'subnodes'. We know whether
%       it is a branch node by whether it  has children.  'Object' and
%       'Light' nodes are the leaves of the tree and have no children.
%       Instance nodes are copies of Objects and thus also are leaves.
%
%  If we do not have AttributeBegin/End blocks, for example in the
%  kitchen.pbrt scene, we may have lines like
%
%     NamedMaterial
%     Shape
%     Shape
%     NamedMaterial
%     Shape
%     NamedMaterial
%
%  In that case we create a new object for each shape line, and we
%  assign it the material listed above the shape.
%
% See also
%   parseObjectInstanceText, See helper routines below

% This routine processes the text and returns a cell array of trees that
% will be part of the whole asset tree. In many cases the returned tree
% will be the whole asset tree for the recipe.
subtrees = {};

% We sometimes have multiple objects inside one Begin/End group that have
% the same name.  We add an index in this routine to distinguish them.  See
% below.
% Removed when we changed to making the object names unique in piRead.
% objectIndex = 0;
if ~exist('beBlock','var'), beBlock = false; end

% Multiple material and shapes can be used for one object.
nMaterial   = 0;
nShape      = 0;

% Strip WorldBegin
if isequal(txt{1},'WorldBegin'),  txt = txt(2:end); end

% This code is initially designed to work only with the
% AttributeBegin/End format.  Perhaps we should look for
% AttributeBegin, and if there are none in the txt, we should parse
% with the other style (BW).
% Counts which line we are on.  At the end we return how many lines we
% have counted (parsedUntil)
% if isempty(txt{1}), warning('Empty text line.'); end
cnt = 1;

while cnt <= length(txt)

    % For debugging, I removed the semicolon
    currentLine = txt{cnt};

    if strcmp(currentLine,'AttributeBegin')
        % Entering an AttributeBegin/End block

        % Parse the next lines for materials, shapes, lights. If
        % we run into another AttributeBegin, we recursively come back
        % here.  Typically, we return here with the subnodes from the
        % AttributeBegin/End block.
        [subnodes, retLine] = parseGeometryText(thisR, txt(cnt+1:end), name, true);
        
        % We now have the collection of subnodes from this
        % AttributeBegin/End block.  Also we know the returned line number
        % (retLine) where we will continue.
        
        % Group the subnodes from this Begin/End block with the others that
        % have collected into the variable subtrees.
        subtrees = cat(1, subtrees, subnodes);

        % Update where we start from
        cnt =  cnt + retLine;

    elseif contains(currentLine,...
            {'#ObjectName','#object name','#CollectionName','#Instance','#MeshName', '# Name'}) && ...
            strcmp(currentLine(1),'#')
        % # Name in contemporary bathroom at the end of the
        % AttBegin/End.  I am not sure that the names in that file are
        % all the useful, though.
        
        [name, sz] = piParseObjectName(currentLine);

    elseif contains(currentLine, 'ObjectInstance') && ...
            ~strcmp(currentLine(1),'#')
        % The object instance name will be assigned to a branch node 
        % This happens after the AttributeEnd.
        InstanceName = erase(currentLine(length('ObjectInstance ')+1:end),'"');    

    elseif strncmp(currentLine,'Transform ',10) ||...
            piContains(currentLine,'ConcatTransform')
        % Transformation information
        [translation, rot, scale] = parseTransform(currentLine);

    elseif piContains(currentLine,'MediumInterface') && ...
            ~strcmp(currentLine(1),'#')
        % MediumInterface could be water or other scattering media.
        medium = currentLine;

    elseif piContains(currentLine,'NamedMaterial') && ~strcmp(currentLine(1),'#')
        % We can have multiple materials, but I don't see how this
        % could work.  Here we should only have one namedMaterial at a
        % time (BW).
        nMaterial = nMaterial+1;
        mat{nMaterial} = piParseGeometryMaterial(currentLine); %#ok<AGROW>

    elseif strncmp(currentLine,'Material',8) && ~strcmp(currentLine(1),'#')
        % Material.  But the materials shouldn't be here.  They are
        % parsed and written out separately.
        mat = parseBlockMaterial(currentLine);

    elseif piContains(currentLine,'AreaLightSource') && ~strcmp(currentLine(1),'#')
        % The area light is created below, after the AttributeEnd
        areaLight = currentLine;

    elseif piContains(currentLine,'LightSource') ...
            && ~strcmp(currentLine(1),'#')
        % If this is a light source, it is created below, after the
        % AttributeEnd.
        % 
        % We have a case in contemporary-bathroom where there is a
        % Rotate without a LightSource.  I don't think we are handling
        % that correctly.  Perhaps this elseif clause should be split
        % into separate LightSource, Rotate, and Scale?
        if ~exist('lght','var')
            lght{1} = currentLine;
        else
            lght{end+1} = currentLine; %#ok<AGROW>
        end

        % We need to deal with these separately.  They were grouped with
        % LightSource.
        %
    elseif piContains(currentLine, 'Rotate')
        fprintf('Ignoring Rotate: %s\n',currentLine);

    elseif piContains(currentLine, 'Scale')
        fprintf('Ignoring Scale: %s\n',currentLine);
        
    elseif  piContains(currentLine,'ReverseOrientation')
        fprintf('Ignoring ReverseOrientation: %s\n', currentLine);

    elseif piContains(currentLine,'Shape') && ~strcmp(currentLine(1),'#')
        % Shape - Created below.  Why do we allow a cell array of
        % multiple shapes? 
        nShape = nShape+1;
        shape{nShape} = piParseShape(currentLine);
        if nShape > 1, fprintf('shape %d\n',nShape); end
        
        % We need a way to decide whether we are in an ABLoop
        if ~beBlock
            % If not in an begin/end block, we create the shape and add it
            % to the subtrees here            

            % disp('Shape but no AttributeBegin block.')

            % Build parms and update the trees with a branch node,
            % object node, or both
            if exist('areaLight','var'), parms.areaLight = areaLight; end
            if exist('lght','var'),      parms.lght = lght; end
            if exist('shape','var'),     parms.shape = shape; end
            if exist('rot','var'),       parms.rot = rot; end
            if exist('translation','var'), parms.translation = translation; end
            if exist('mediumInterface','var'), parms.mediumInterface = medium; end
            if exist('mat','var'), parms.mat = mat; end
            if exist('InstanceName','var'), parms.InstanceName = InstanceName; end

            [resCurrent, subtrees] = parseGeometryAttEnd(thisR, subtrees, parms);

            % If not the identity, we add the resCurrent branch above
            % the nodes in this subtree. The subtrees are below this
            % branch with its transformation.
            if piBranchIdentity(resCurrent)
                % disp('Identity branch.  The subtrees added later.');
            else
                trees = tree(resCurrent);
                for ii = 1:numel(subtrees)
                    trees = trees.graft(1, subtrees(ii));
                end
            end
            %             trees = tree(resCurrent);
            %             for ii = 1:numel(subtrees)
            %                 trees = trees.graft(1, subtrees(ii));
            %             end
            nShape = 0;
            nMaterial = 0;                        
        end
    elseif strcmp(currentLine,'AttributeEnd')
        % Exiting a Begin/End block
        % beBlock = false;

        % We accumulate the parameters we read into a node.  The type of
        % node will depend on the parameters we found since the
        % AttributeBegin line.
        %
        % At this point we know what kind of node we have, so we create a
        % node of the right type.
        
        % Set this to false because we are now ending the loop.
        % ABLoop = false;
        % disp('AttributeEnd block.')

        if exist('areaLight','var') ...
                || exist('lght','var') ...
                || exist('shape','var') ...
                || exist('rot','var')  ...
                || exist('translation','var') ...
                || exist('mediumInterface','var') ...
                || exist('mat','var')
            

            % Build parms and update the trees with a branch node,
            % object node, or both
            if exist('name','var'),      parms.name = name; end
            if exist('areaLight','var'), parms.areaLight = areaLight; end
            if exist('lght','var'),      parms.lght = lght; end
            if exist('shape','var'),     parms.shape = shape; end
            if exist('rot','var'),       parms.rot = rot; end
            if exist('scale','var'),     parms.scale = scale; end
            if exist('sz','var'),        parms.sz = sz; end
            if exist('translation','var'),  parms.translation = translation; end
            if exist('mediumInterface','var'), parms.mediumInterface = mediumInterface; end
            if exist('mat','var'),          parms.mat = mat; end
            if exist('InstanceName','var'), parms.InstanceName = InstanceName; end

            [resCurrent, subtrees] = parseGeometryAttEnd(thisR, subtrees, parms);

            trees = tree(resCurrent);
            for ii = 1:numel(subtrees)
                trees = trees.graft(1, subtrees(ii));
            end
            %{
            if piBranchIdentity(resCurrent) && ~isempty(subtrees)
                % If the branch transform is the identity, and there are
                % subtrees, we add them.
                trees = subtrees;
            else
                % If the transform is not the identity, we add it
                % (resCurrent) above the light and object nodes in this
                % subtree.
                trees = tree(resCurrent);
                for ii = 1:numel(subtrees)
                    trees = trees.graft(1, subtrees(ii));
                end
            end
            %}

        elseif exist('name','var')  && ~isempty(name)
            % We have a name, but not a shape, lght or arealight.
            %
            % Zheng remembers that we used this for the Cinema4D case when
            % we hung a camera under a marker position.  It is possible
            % that we should stop doing that.  We should try to get rid of
            % this condition.
            %
            % disp('Name only branch.')
            resCurrent = piAssetCreate('type', 'branch');

            if length(name) < 3 || ~isequal(name(end-1:end),'_B')            
                resCurrent.name = sprintf('%s_B', name); 
            else  % Already ends with '_B'
                resCurrent.name = name;
            end
            
            trees = tree(resCurrent);
            for ii = 1:numel(subtrees)
                trees = trees.graft(1, subtrees(ii));
            end
        else
            % No name, shape, light or arealight.  This is probably an
            % empty block 
            %
            %   AttributeBegin
            %   AttributeEnd
            %
            % We just return subtrees as the trees.
            % disp('No name, no object or light.')
            trees = subtrees;

        end  % AttributeEnd

        % Return, indicating how far we have gotten in the txt within
        % this block
        parsedUntil = cnt;

        % Returned from the AttributeBegin/End block
        % Because this is recursive, the value is just the block
        % count.
        return;

    end % AttributeBegin

    % We get here if we are starting the next Block. 
    % fprintf('Next AttributeBegin block starts at %d\n',cnt);
    cnt = cnt+1;

end

% We made it in through the whole file
parsedUntil = cnt;  

%% We build the tree that is returned from any of the defined subtrees

% Finished with all the AttributeBegin/End blocks
fprintf('Identified %d assets; parsed up to line %d\n',numel(subtrees),parsedUntil);

% We create the root node here, placing it as the root of all of the
% subtree branches.
if ~isempty(subtrees)
    rootAsset = piAssetCreate('type', 'branch');
    rootAsset.name = 'root_B';
    trees = tree(rootAsset);

    % Graft each of the subtrees to the root node
    for ii = 1:numel(subtrees)
        trees = trees.graft(1, subtrees(ii));
    end
else
    % Hmm. There were no subtrees.  So no root.  Send the whole thing back
    % as empty. I used to print a warning, but nothing bad has
    % happened, so I deleted the wearning.
    %
    % warning('Empty tree.')
    trees=[];
end

% if ~exist('trees','var'), warning('trees not defined'); end

end

%% ------------- Helper functions
% parseGeometryAttEnd
% parseGeometryBranch
% parseGeometryObject
% parseGeometryAreaLight
% parseGeometryLight
% parseGeometryLightName

function [resCurrent, subtrees] = parseGeometryAttEnd(thisR, subtrees, parms)
% We reached an attributeEnd.  Process and add to the trees.

% In this case, we detected a light of some type.
if isfield(parms,'areaLight')
    % Adds the area light asset to the collection of subtrees
    % that we are building.
    areaLight = parms.areaLight;
    if isfield(parms,'name'),  name = parms.name; else, name = ''; end
    if isfield(parms,'shape'), shape = parms.shape; else, shape = []; end

    % if ~exist('name','var'), name = '';   end
    resLight = parseGeometryAreaLight(thisR,areaLight,name,shape);
    subtrees = cat(1, subtrees, tree(resLight));

elseif isfield(parms,'lght') 
    lght = parms.lght;

    if isfield(parms,'name'),  name = parms.name; else, name = ''; end
    resLight = parseGeometryLight(thisR,lght,name);
    subtrees = cat(1, subtrees, tree(resLight));

    % ------- A shape.  Create an object node
elseif isfield(parms,'shape')
    shape = parms.shape;

    % Shouldn't we be looping over numel(shape)?
    if iscell(shape), shape = shape{1}; end
    if ~isfield(parms,'name')
        % The name might have been passed in
        name = piShapeNameCreate(shape,true,thisR.get('input basename'));
    else, name = parms.name;
    end

    % We create object (assets) here.
    if isfield(parms,'mat'), oMAT = parms.mat;   else, oMAT = []; end
    if isfield(parms,'medium'), oMEDIUM = parms.medium; else, oMEDIUM = []; end
    resObject = parseGeometryObject(shape,name,oMAT,oMEDIUM);

    % Makes a tree of this object and adds that into the
    % collection of subtrees we are building.
    subtrees = cat(1, subtrees, tree(resObject));
end

% Create a parent branch node with the transform information for
% the object, light, or arealight.
%
% Sometimes are here with some transform information
% (following an AttributeEnd), and we put in a branch
% node.

% When there is no name, I make up this special case. This
% happens at the end of ChessSet.  There is an
% AttributeBegin/End with only a transform, but no mesh
% name.
if isfield(parms,'name'), bNAME = parms.name;
else, bNAME = 'AttributeEnd';
end

if isfield(parms,'sz'),  oSZ = parms.sz; else, oSZ = []; end
if isfield(parms,'rot'), oROT = parms.rot; else, oROT = []; end
if isfield(parms,'translation'),oTRANS = parms.translation; else, oTRANS = []; end
if isfield(parms,'scale'),oSCALE = parms.scale; else, oSCALE = []; end

resCurrent = parseGeometryBranch(bNAME,oSZ,oROT,oTRANS,oSCALE);

% if piBranchIdentity(resCurrent)
%     disp(resCurrent.name)
%     fprintf('%f\n',oSCALE);
%     fprintf('%f\n',oTRANS);
%     fprintf('%f\n',oROT);
% end
% If we have defined an Instance (ObjectBegin/End) then we
% assign it to a branch node here.
if isfield(parms,'InstanceName')
    resCurrent.referenceObject = parms.InstanceName;
end

%{
% We do this on return now.  Not sure where is better.
%
% Adding this resCurrent branch above the light and object
% nodes in this subtree.  The subtrees are below this branch
% with its transformation.
trees = tree(resCurrent);
for ii = 1:numel(subtrees)
    trees = trees.graft(1, subtrees(ii));
end
%}
end


%% Make a branch node
function resCurrent = parseGeometryBranch(name,sz,rot,translation,scale)
% Create a branch node with the transform information.

% This should be the parent of the light or object,
resCurrent = piAssetCreate('type', 'branch');

% It is a branch.  Adjust the name
if length(name) < 3  
    % Could be a single character name, such as 'A'
    resCurrent.name = sprintf('%s_B', name);
elseif ~isequal(name(end-1:end),'_B')
    % At least 3, but not the right ending.
    switch name(end-1:end)
        case {'_L','_O'}
            % Replace with _B
            name(end-1:end) = '_B';
            resCurrent.name = name;
        otherwise
            % Append _B
            resCurrent.name = sprintf('%s_B', name);
    end
else
    % >= 3 and ends in _B.  Good to go.
    resCurrent.name = name;
end

if ~isempty(sz), resCurrent.size = sz; end
if ~isempty(rot), resCurrent.rotation = {rot}; end
if ~isempty(translation), resCurrent.translation = {translation}; end
if ~isempty(scale), resCurrent.scale = {scale}; end

end

%% Make an object node
function resObject = parseGeometryObject(shape,name,mat,medium)
% Create an object node with the shape and material information

resObject = piAssetCreate('type', 'object');
resObject.shape = shape;
if length(name) < 3 || ~isequal(name(end-1:end),'_O')
    resObject.name = sprintf('%s_O', name);
else
    resObject.name = name;
end


% Hopefully we have a material or medium for this object. If not, then PBRT
% uses coateddiffuse as a default, I think.
if ~isempty(mat),    resObject.material = mat;  end
if ~isempty(medium), resObject.medium = medium; end

end

%% Make an area light struct forthe tree
function resLight = parseGeometryAreaLight(thisR,areaLight,name,shape)

isNode = true;
baseName = thisR.get('input basename');

resLight = piAssetCreate('type', 'light');

resLight.lght = piLightGetFromText({areaLight}, 'print', false);
if ~isempty(shape)
    resLight.lght{1}.shape = shape;
else, warning("Area light with no shape.");
end

% Manage the name with an _L at the end.
if isempty(name)
    resLight.name = parseGeometryLightName(resLight.lght,isNode,baseName);
elseif length(name) < 3 || ~isequal(name(end-1:end),'_L') 
    resLight.name = sprintf('%s_L',name);
end

% We have two names.  One for the node and one for the
% object itself, I guess. (BW).
resLight.lght{1}.name = resLight.name;
end

%% Make a light struct for the tree
function resLight = parseGeometryLight(thisR,lght,name)

isNode = true;
baseName = thisR.get('input basename');

resLight = piAssetCreate('type', 'light');

if exist('lght','var')
    % Wrap the light text into attribute section
    lghtWrap = [{'AttributeBegin'}, lght(:)', {'AttributeEnd'}];
    resLight.lght = piLightGetFromText(lghtWrap, 'print', false);
end

if isempty(name)
    resLight.name = parseGeometryLightName(resLight.lght,isNode,baseName);
elseif length(name) < 3 || ~isequal(name(end-1:end),'_L')
    resLight.name = sprintf('%s_L',name);
end

% We have two names.  One for the node and one for the
% object itself, I guess. (BW).
resLight.lght{1}.name = resLight.name;

end

%% Create a name for a light.  Area or other light. 
function name = parseGeometryLightName(lght,isNode,baseName)
%
% Synopsis
%   name = parseGeometryLightName(lght,[isNode = true],[baseName = 'unlabeledLight'])
%
% Input
%   lght   - A light or arealight built by piRead and parseGeometryText
%   isNode - This is a light node name or a light filename.
%            Default (true, a node)
%   baseName - Scene base name (thisR.get('input basename'));
%
% Output
%    name - The name of the node or file name
%
% Brief description
%   (1) If lght.filename is part of the lght struct, use it.
%   (2) If not, use baseName and ieHash on the final cell entry of the
%       lght. We use the first 8 characters in the hex hash. I think
%       that should be enough (8^16), especially combined with the
%       base scene name. 
%
% See also
%   parseGeometryText, piGeometryWrite

if iscell(lght), lght = lght{1}; end
if ~exist('isNode','var') || isempty(isNode), isNode = true; end
if ~exist('baseName','var') || isempty(baseName)
    if isfield(lght,'filename'), [~,baseName] = fileparts(lght.filename);
    else, baseName = 'unlabeledLight';
    end
end

% Get the name or create a name based on a hash of the data
if isstruct(lght) 
    if isfield(lght,'name'), name = lght.name;
    else, warning('No name for this lght.');
    end
elseif iscell(lght)
    str = ieHash(lght{end});  % Last entry of the cell for the hash
    name = sprintf('%s-%s',baseName,str(1:8));
end

% If this is a node, we make sure the name ends with _L
if isNode && (length(name) < 3 || ~isequal(name(end-1:end),'_L'))
    name = sprintf('%s_L', name);
end

end

