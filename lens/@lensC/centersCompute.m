function centers = centersCompute(~, sOffset, sRadius)
% Computes the center position of each spherical lens element
% from the array of element offsets and radii.
%
nSurfaces = length(sOffset);

% The lens file includes the offsets between each surface and
% its previous one (millimeters).  The location of the first
% surface is at negative of the sum of the offsets.
zIntercept    = zeros(nSurfaces,1);
zIntercept(1) = -sum(sOffset);

% Cumulate the offsets to find the intercept of the following
% surface
for ii=2:length(sOffset)
    zIntercept(ii) = zIntercept(ii-1) + sOffset(ii);
end

% Centers of the spherical surfaces are stored in this matrix
% (nSurfaces x 3)
x = zeros(nSurfaces,1); y = x;
z = zIntercept + sRadius;
centers = [x(:), y(:), z(:)];
end