function obj = append(obj, ID, othertree)
%% APPEND   Append another tree at the specified node of this tree.

    
    nNodes = numel(obj.Parent);

    otParents = othertree.Parent;
    % Shift other parent indices
    otParents = otParents + nNodes;
    % Make the other root a child of the target node
    otParents(1) = ID;
    
    % Concatenate
    newParents = [ obj.Parent ; otParents ];
%     newNodes   = vertcat( obj.Node, othertree.Node );
    
    % Edit
    for ii = 1:numel(othertree.Node)
        obj.Node{end+1,:} = othertree.Node{ii};
    end
    obj.Parent = newParents;
    

end