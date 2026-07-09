function obj = addDistance(obj, D)
% D is the distance in the current ray segment
%
% This is added to the current path, stored in .distance
%
% I believe this distance is tracked for when we do diffraction
% calculations accounting for the phase of the wavefront
%
%

obj.distance = obj.distance + D;

end
