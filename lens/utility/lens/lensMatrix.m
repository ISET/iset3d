function d = lensMatrix(lens)
% Convert the surface array data to the PBRT matrix format
%
% Syntax:
%   d = lensMatrix(lens)
%
% Inputs
%  lens - Lens class
%
% Outputs
%  d  - Matrix description of lens useful for PBRT methods
%
% Descripton:
%   In the lens class, we don't use offsets. Instead, we store the
%   sphere centers (sCenters) and radii (units of mm).  So here we go
%   through the surfaceArray and produce the radius and offset needed
%   for the PBRT matrix from the surfaceArray object sCenters and
%   radius.
%
% Lin, Lian, Wandell and others
%
% See also
%   fileWrite, t_gullstrandEyeTraceAccomodation

nSurfaces = lens.get('n surfaces');

% The PBRT data matrix
d = zeros(nSurfaces,4);
offsets = lens.get('offsets');
nArray = lens.get('index of refraction');
nArray = nArray(round((size(nArray,1) + 1)/2), :);
for ii=1:nSurfaces
    d(ii,1) = lens.get('s radius',ii);
    d(ii,2) = offsets(ii);
    
    % Pbrt does not yet support custom specified index of refractions.
    % Thus, we will take the middle one
    d(ii,3) = nArray(ii);
    d(ii,4) = lens.get('sdiameter', ii);
end