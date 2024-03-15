function [trees, newWorld] = parseObjectInstanceText(thisR, txt)
% Parse the geometry objects accounting for object instances
%
% Synopsis
%   [trees, newWorld] = parseObjectInstanceText(thisR, txt)
%
% Brief description
%   The txt is the world text from a PBRT file.  It is parsed into
%   objects creating the asset tree.  The assets include objects and
%   lights.
% 
%   This function relies heavily on parseGeometryText, which works on
%   AttributeBegin/End sequences and certain other simple file
%   formats.  The code here handles the case of ObjectBegin/End
%   instances, which are comprised of AttributeBegin/End blocks.
%   These define an object that is reused as an instance.
%
% Inputs
%   thisR - ISET3d recipe
%   txt -  Cell array of text strings, usually from the WorldBegin ...
%
% Outputs
%   trees    -  Assets in a tree format
%   newWorld - Modified world text, after removing unnecessary lines.
%
% See also
%   parseGeometryText

%% Initialize the asset tree root
rootAsset = piAssetCreate('type', 'branch');
rootAsset.name = 'root_B';
trees = tree(rootAsset);

%% Identify the objects
% This section might be placed in parseGeometryText.

% The ObjectBegin/End sections define an object that will be reused as an
% ObjectInstance elsewhere, probably with different position, scale, or
% even materials.  Here are the lines with objects.
objBeginLocs = find(contains(txt,'ObjectBegin'));
objEndLocs   = find(contains(txt,'ObjectEnd'));

% For each objectBegin/End section we process to create a reusable
% asset. The 'trees' variable stores these objects.  The code between
% ObjectBegin/End is parsed in the usual way via parseGeometryText.
% If there are objects, this block reads them and adds them to the
% 'trees' variable.
if ~isempty(objBeginLocs)
    disp('[INFO]: Start Object processing.');
    for objIndex = 1:numel(objBeginLocs)
        

        % Find its name.  Sometimes this is empty.  Hmm.
        objectName = erase(txt{objBeginLocs(objIndex)}(13:end),'"');

        % Parse the text to create the subnodes of the object tree
        thisTxt = txt(objBeginLocs(objIndex)+1:objEndLocs(objIndex)-1);
        if isempty(thisTxt)
            txt(objBeginLocs(objIndex):objEndLocs(objIndex)) = cell(objEndLocs(objIndex)-objBeginLocs(objIndex)+1,1);
            continue; 
        end
        fprintf('Object %d: \n',objIndex);
        [subnodes, ~] = parseGeometryText(thisR, 'txt',thisTxt);

        % If subnodes were returned, they always contain a root (1) and
        % two additional subnodes defining the transform (2) and the
        % object itself (3).  We add the transformation and object to
        % the main tree we are building.
        if ~isempty(subnodes)            
            % To make it easy to set the isObjectInstance, we extract
            % the node from the tree and then set it back.
            subtree = subnodes;    % The tree below the root
            branchNode = subtree.Node{1};     % The branch node
            branchNode.isObjectInstance = 1;  % This is a reference object 
            % Name the branch to match the object name
            if length(objectName) < 3 || ~isequal(objectName(end-1:end),'_B')
                branchNode.name = sprintf('%s_B',objectName);  
            else
                branchNode.name = objectName;
            end

            subtree = subtree.set(1, branchNode); % Get rid 
            trees = trees.graft(1, subtree);
        end

        % Remove the object lines we processed, creating an empty cell
        txt(objBeginLocs(objIndex):objEndLocs(objIndex)) = cell(objEndLocs(objIndex)-objBeginLocs(objIndex)+1,1);
        
    end
    
    % We remove the empty cells which were created as we removed the
    % objects.
    
    disp('[INFO]: Finished Object processing.');
end
txt = txt(~cellfun(@isempty,txt));

% If we have any empty AttributeBegin/End blocks, remove them too.
attBeginLocs = find(contains(txt,'AttributeBegin'));
attEndLocs = find(contains(txt,'AttributeEnd'));

for ii=1:numel(attBeginLocs)
    if attBeginLocs(ii) == attEndLocs(ii) - 1
        % fprintf('[INFO]: Empty AttBegin/End block %d \n',attBeginLocs(ii));
        txt(attBeginLocs(ii):attEndLocs(ii)) = cell(2,1);
    end
end

txt = txt(~cellfun(@isempty,txt));

curIndex = 2;txt_new = txt(1);insideFlag = false;
while curIndex<=numel(txt)
    curLine = txt(curIndex);
    if contains(curLine,'AttributeBegin')
        insideFlag = true;
        txt_new(end+1)=curLine;
    elseif contains(curLine,'AttributeEnd')
        insideFlag = false;
        txt_new(end+1)=curLine;
    elseif insideFlag || ~contains(curLine,{'NamedMaterial','Texture','Material'})
        txt_new(end+1)=curLine;
    end
    curIndex = curIndex+1;
end
%% Build the asset tree apart from the Object instances

% The remaining txt has no ObjectBegin/End cases, those have been
% processed and removed above. It does have AttributeBegin/End
% sequences that we parse here, returning the subnodes of a tree.
newWorld = txt_new(:);
fprintf('[INFO]: Attribute processing: \n');
[subnodes, parsedUntil] = parseGeometryText(thisR, 'txt',newWorld);

%% We assign the returned subnodes to the tree

%fprintf('Grafting subnodes to main tree ...')
if trees.Parent == 0
    % The subnodes return by parseGeometryText. There is a
    % root node and that's all we need.
    trees = subnodes;   
else
    % We graft the returned subnodes onto a root.  I think this
    % happens in the case of ObjectInstances.    
    if ~isempty(subnodes)
        % subtree = subnodes.subtree(2);
        trees = trees.graft(1, subnodes);
    end
end

% We first parsed all of the lines in txt between ObjectBegin/End. We
% then parsed the remaining lines in newWorld.  parsedUntil should
% equal the number of lines in newWorld.

% Old code I didn't understand.  Seemed wrong, but it ran.  But
% replaced with lines below.
% parsedUntil(parsedUntil>numel(newWorld)) = numel(newWorld);

% I have never seen this warning.
% So we can probably just delete these two lines.
if parsedUntil ~= numel(newWorld), warning('Incomplete parsing'); end
parsedUntil = min(parsedUntil,numel(newWorld));

% Remove the parsed lines from newWorld, leaving only WorldBegin
newWorld(2:parsedUntil)=[];

% Maybe this should be optional?
if ~isempty(trees)
    trees = trees.uniqueNames;
end

end

