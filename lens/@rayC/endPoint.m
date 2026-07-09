function endPoint = endPoint(obj,D)
% Given a distance, direction and origin, calculate the end
% point of the ray.
%
% Input
%   D:   This appears to be the intersectT variable calculated in
%        rtThroughLens. I am not sure what it represents.  The code here
%        suggests it is the distance from the current ray origin to the
%        next surface.  Hence, it should always be a real number.  But it
%        is not.
%
% See also
%   lensC.rtThroughLens

repD = repmat(D, [1 3]);
endPoint = obj.origin + repD .* obj.direction;

end
