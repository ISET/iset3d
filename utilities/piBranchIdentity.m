function bool = piBranchIdentity(node)
% Test whether a branch node is just the identity
%
%  bool = piBranchIdentity(node)
% 
% See also
%  piRead

bool = false;

if ~isequal(node.type,'branch'), warning('Not a branch node.'); return; end

if isequal(node.scale{1},[1 1 1]) && ...
        isequal(node.rotation{1},[0 0 0; 0 0 1; 0 1 0; 1 0 0]) && ...
        isequal(node.translation{1}, [ 0 0 0])
    bool = true;
end

end
