function offsets = offsetCompute(obj)
% Computes offsets from the object's z positions

%get the radii
nEls = obj.get('nsurfaces');
zPos = zeros(1, nEls);
offsets = zeros(1,nEls);
sArray = obj.get('surfaceArray');

for i = 1:nEls
    zPos(i) = sArray(i).get('zpos');
    if (i > 1)
        offsets(i-1) = zPos(i) - zPos(i-1);
    else
        offsets(i) = 0;
    end
end
end