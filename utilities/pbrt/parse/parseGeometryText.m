function [trees, parsedUntil] = parseGeometryText(thisR, txt, name)
% Parse the text from a Geometry file, returning an asset subtree
%
% Synopsis
%   [trees, parsedUntil] = parseGeometryText(thisR, txt, name)
%
% Brief:
%   We parse the geometry text file here to build up the asset tree in the
%   recipe.  We succeed for some, but not all, PBRT files.  We
%   continue to add special cases.  Called by parseObjectInstanceText
%
% Inputs:
%   thisR       - a scene recipe
%   txt         - text of the PBRT geometry information that we parse
%   name        - current object name
%
% Outputs:
%   trees       - A tree class that describes the assets and their geometry
%   parsedUntil - line number where the parsing ends
%
% Description:
%
%   We parse the lines of text in 'txt' cell array and recrursively create
%   a tree structure of geometric objects.  The naming logic has been a
%   constant struggle, and I attempt to clarify here.
%
%   This parseGeometryText method works recursively, parsing the geometry
%   text line by line. We do not have an overview of the whole situation at
%   the beginning.  The limits how clever we can be. This might be our
%   original sin.
% 
%   If the current text line is
%
%       a) 'AttributeBegin': this is the beginning of a section. We will
%       keep looking for node/object/light information until we reach the
%       'AttributeEnd'.  Remember, though, this is recursive.  So we might
%       have multiple Begin/End pairs within a Begin/End pair.  
%
%       b) Node/object/light information: The text within a Begin/End
%       section may contain multiple types of information.  For example,
%       about the object rotation, position, scaling, shape, material
%       properties, light spectrum information. We do our best to parse
%       this information, and then the parameters are stored in the
%       appropriate location within the recipe. (When things go well).
%
%       c) 'AttributeEnd': We close up this node and add it to the tree. A
%       branch' node will always have children.  'Object' and 'Light' notes
%       are the leafs of the tree and have no children. Instance nodes are
%       copies of Objects and thus also at the leaf.
%
% See also
%   parseObjectInstanceText

% res = [];
% groupobjs = [];
% children = [];

% This routine processes the text and returns a cell array of trees that
% will be part of the whole asset tree
subtrees = {};

% We sometimes have multiple objects inside one Begin/End group that have
% the same name.  We add an index in this routine to distinguish them.  See
% below.
objectIndex = 0;

% Multiple material and shapes can be used for one object.
nMaterial   = 0;  
nShape      = 0; 

i = 1;          
while i <= length(txt)

    currentLine = txt{i};

    % Strip trailing spaces from the current line.  That has hurt us
    % multiple times in the parsing.
    idx = find(currentLine ~=' ',1,'last');
    currentLine = currentLine(1:idx);

    % ObjectInstances are treated specially.  I do not yet understand this
    % (BW).
    if piContains(currentLine, 'ObjectInstance') && ~strcmp(currentLine(1),'#')
        InstanceName = erase(currentLine(16:end),'"');
    end

    % Return if we've reached the end of current attribute

    if strcmp(currentLine,'AttributeBegin')
        % We reached a line with an AttributeBegin. So we start to process.
        % There may be additional Begin/Ends on the next line. So, we
        % dig our way down to the lowest level by recursively calling
        [subnodes, retLine] = parseGeometryText(thisR, txt(i+1:end), name);
        
        % We processed the next line (through this same routine!) and it
        % returned to us a section of a tree.  The 'subnodes'.  It also
        % told us which line to start continuing our analysis from
        % (retLine).
        %
        % We have a lot things to check, and that is what the long series
        % of if/else choices accomplishes.  The logic of each of those
        % choices is described through the if/else sequence.  This code
        % remains a work in progress.
        %
        % For piLabel to work, we need to have this be >=2.
        % But in that case, the labels can get pretty ugly, with recursive
        % objectIndex values. It would be much better if the labels were
        % based on the == 2 condition, not this >= 2 case.
        if numel(subnodes.Node) >= 2 && strcmp(subnodes.Node{end}.type, 'object')
            % The last node is an object.  When we only process for == 2,
            % piLabel fails.
            lastNode = subnodes.Node{end};
            if strcmp(lastNode.type,'object')
                % Why do we add the objectIndex at all?
                %
                % In some cases (e.g., the Macbeth color checker) there is
                % one ObjectName in the comment, but multiple components to
                % the object (the patches). We need to distinguish the
                % components. We use the objectIndex to distinguish them.                
                %
                % But when we allow processing when there are >2 nodes, we
                % repeatedly add an objectIndex to the node name.  That's
                % ugly, but runs.
                objectIndex = objectIndex+1;
                lastNode.name = sprintf('%03d_%s',objectIndex, lastNode.name);
                subnodes = subnodes.set(numel(subnodes.Node),lastNode);

                % This is the base name, with the _O part removed.  It has
                % the object index in it.
                baseName = lastNode.name(1:end-2);
                %                 if contains(lastNode.name,'008')
                %                     pause;
                %                 end

                % Label the other subnodes with the same name but _B, if
                % they are previously unlabeled.
                for ii=(numel(subnodes.Node)-1):-1:1
                    thisNode = subnodes.Node{ii};
                    if isequal(thisNode.name,'_B')
                        % An empty name.  So let's chanage it and put it
                        % in place.
                        thisNode.name = sprintf('%s_B',baseName);
                        subnodes = subnodes.set(ii,thisNode);
                    end
                end
            end
        end

        subtrees = cat(1, subtrees, subnodes);
        i =  i + retLine;

    elseif contains(currentLine,{'#ObjectName','#object name','#CollectionName','#Instance','#MeshName'}) && ...
            strcmp(currentLine(1),'#')

        % Name
        [name, sz] = piParseObjectName(currentLine);

    elseif strncmp(currentLine,'Transform ',10) ||...
            piContains(currentLine,'ConcatTransform')
        
        % Translation
        [translation, rot, scale] = parseTransform(currentLine);

    elseif piContains(currentLine,'MediumInterface') && ~strcmp(currentLine(1),'#')
        % MediumInterface could be water or other scattering media.
        medium = currentLine;

    elseif piContains(currentLine,'NamedMaterial') && ~strcmp(currentLine(1),'#')
        nMaterial = nMaterial+1;
        mat{nMaterial} = piParseGeometryMaterial(currentLine); %#ok<AGROW> 

    elseif strncmp(currentLine,'Material',8) && ~strcmp(currentLine(1),'#')

        mat = parseBlockMaterial(currentLine);

    elseif piContains(currentLine,'AreaLightSource') && ~strcmp(currentLine(1),'#')

        areaLight = currentLine;

    elseif piContains(currentLine,'LightSource') ||...
            piContains(currentLine, 'Rotate') ||...
            piContains(currentLine, 'Scale') && ~strcmp(currentLine(1),'#')
        
        % Usually light source contains only one line. Exception is there
        % are rotations or scalings
        if ~exist('lght','var')
            lght{1} = currentLine;
        else
            lght{end+1} = currentLine; %#ok<AGROW>
        end

    elseif piContains(currentLine,'Shape') && ~strcmp(currentLine(1),'#')
        
        % Shape
        nShape = nShape+1;
        shape{nShape} = piParseShape(currentLine);

    elseif strcmp(currentLine,'AttributeEnd')
        % At this point we know what kind of node we have, so we create a
        % node of the right type.
        %
        % Another if/else sequence.
        %
        %   * If certain properties are defined, we process this node
        %   further. 
        %   * The properties depend on the node type (light or asset)

        % Fill in light node type properties
        if exist('areaLight','var') || exist('lght','var') ...
                || exist('rot','var') || exist('translation','var') || ...
                exist('shape','var') || ...
                exist('mediumInterface','var') || exist('mat','var')

            % These variables mean it is a 'light' node
            if exist('areaLight','var') || exist('lght','var')
                resLight = piAssetCreate('type', 'light');
                if exist('lght','var')
                    % Wrap the light text into attribute section
                    lghtWrap = [{'AttributeBegin'}, lght(:)', {'AttributeEnd'}];
                    resLight.lght = piLightGetFromText(lghtWrap, 'print', false);
                end
                if exist('areaLight','var')
                    resLight.lght = piLightGetFromText({areaLight}, 'print', false);
                    if exist('shape', 'var')
                        resLight.lght{1}.shape = shape;
                    end
                end

                if exist('name', 'var')
                    resLight.name = sprintf('%s_L', name);
                    resLight.lght{1}.name = resLight.name;
                end

                subtrees = cat(1, subtrees, tree(resLight));
                % trees = subtrees;


            % Fill in object node properties
            elseif exist('shape','var') || exist('mediumInterface','var') || exist('mat','var') 
                % We create object (assets) here.  If the shape is
                % empty for an asset, we will have a problem later.
                % So check how that can happen.
                resObject = piAssetCreate('type', 'object');
                if exist('name','var')
                    resObject.name = sprintf('%s_O', name);

                    % This was prepared for empty object name case.

                    % If we parse a valid name already, do this.
                    if ~isempty(name)
                        % Assign a name, but add _O to denote that
                        % this is an object. 
                        resObject.name = sprintf('%s_O', name);
                        % Maybe we need to add the shape here.  I see
                        % that if isempty(name), we add the shape
                        % below.  Could this be why we have objects
                        % with missing shapes?

                    % Otherwise we set the role of assigning object name in
                    % with priority:
                    %   (1) Check if ply file exists
                    %   (2) Check if named material exists
                    %   (3) (Worst case) Only material type exists
                    elseif exist('shape','var')
                        if iscell(shape)
                            shape = shape{1};  % tmp fix
                        end
                        if ~isempty(shape.filename)
                            [~, n, ~] = fileparts(shape.filename);

                            % If there was a '_mat0' added to the object
                            % name, remove it.
                            if contains(n,'_mat0')
                                n = erase(n,'_mat0');
                            end

                            resObject.name = sprintf('%s_O', n);
                        elseif ~isempty(mat)
                            % We need a way to assign a name to this
                            % object.  We want them unique.  So for
                            % now, we just pick a random number.  Some
                            % chance of a duplicate, but not much.
                            mat = mat{1}; % tmp fix
                            resObject.name = sprintf('%s-%d_O',mat.namedmaterial,randi(1e6,1));
                        end
                    end
                end

                % Maybe we check here.  If this is an object, it
                % really needs to have a shape.
                if exist('shape','var')
                    resObject.shape = shape;
                end

                if exist('mat','var')
                    resObject.material = mat;
                end
                if exist('medium','var')
                    resObject.medium = medium;
                end

                subtrees = cat(1, subtrees, tree(resObject));

            end

            % This path if it is a 'branch' node
            resCurrent = piAssetCreate('type', 'branch');
            
            % If present populate fields.
            if exist('name','var'), resCurrent.name = sprintf('%s_B', name); end
            
            if exist('InstanceName','var')
                resCurrent.referenceObject = InstanceName;
            end
            
            if exist('rot','var') || exist('translation','var') || exist('scale', 'var')
                if exist('sz','var'), resCurrent.size = sz; end
                if exist('rot','var'), resCurrent.rotation = {rot}; end
                if exist('translation','var'), resCurrent.translation = {translation}; end
                if exist('scale','var'), resCurrent.scale = {scale}; end
            end
            trees = tree(resCurrent);
            for ii = 1:numel(subtrees)
                % TODO: solve the empty node name problem here
                trees = trees.graft(1, subtrees(ii));
            end

        elseif exist('name','var')
            % We got this far, and all we have is a name.
            % So we create a branch, add it to the main tree.
            resCurrent = piAssetCreate('type', 'branch');
            if exist('name','var'), resCurrent.name = sprintf('%s_B', name); end
            trees = tree(resCurrent);
            for ii = 1:numel(subtrees)
                trees = trees.graft(1, subtrees(ii));
            end
        end

        parsedUntil = i;
        return;
    else
       %  warning('Current line skipped: %s', currentLine);
    end
    i = i+1;
end
parsedUntil = i;

% We build the main tree from any defined subtrees.  Each subtree is an
% asset.
if ~isempty(subtrees)
    % ZLY: modified the root node to a identity transformation branch node.
    % Need more test
    rootAsset = piAssetCreate('type', 'branch');
    rootAsset.name = 'root_B';
    trees = tree(rootAsset);
    % trees = tree('root');
    % Add each of the subtrees to the root
    for ii = 1:numel(subtrees)
        trees = trees.graft(1, subtrees(ii));
    end
else
    trees=[];
end

end
