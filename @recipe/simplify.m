function simplify(thisR)
% Remove geometry branch nodes with only an identity transform
%
% Input
%  thisR
%
% Modifies the recipe, eliminating branch nodes (geometry) that only
% represent the identity transformation.
%
%  

%% How many nodes
nNodes = thisR.get('n nodes');

% Set delete list to false to begin
deleteList = false(1,nNodes);

% Work backwards through all the nodes
for ii=nNodes:-1:2
    thisN = thisR.get('node',ii);
    if isequal(thisN.type,'branch')
        [~,deleteList(ii)] = piTransformConcat(thisN);
    end
end

%% Delete them, again working backwards
for ii=nNodes:-1:2
    if deleteList(ii)
        thisR.set('node',ii,'delete');
    end
end

end
