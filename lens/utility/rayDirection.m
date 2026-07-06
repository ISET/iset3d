function d = rayDirection(oPoints,ePoints)
% Compute direction vector between origin and end points of a ray
%
%   d = rayDirection(origin,endpoints)
%
% See also: lensC
%
% AL/BW (c) Vistasoft Team, 2014

% We could check for the case in which oPoints is just a single point.  In
% that case we could do the repmat here, subtract, and return.
d = ePoints - oPoints;
d = normvec(d,'dim',2);

end