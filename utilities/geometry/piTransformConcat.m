function [tMatrix,identityTest] = piTransformConcat(thisNode)
% Return the concat transform for a geometry node

%%
if ~isequal(thisNode.type,'branch')
    error('Not a branch node.')
elseif isfield(thisNode,'referenceObject') && ~isempty(thisNode.referenceObject)
    % Preserve branch nodes that represent an object instance
    disp('Instance.')
    tMatrix = [];
    identityTest = false;
    return;
end

%%
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

%%
if nargout > 1
    if tMatrix(:) == identityTransform(:)
        identityTest = true;
    else
        identityTest = false;
    end
end

end

