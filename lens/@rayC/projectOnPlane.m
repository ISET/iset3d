function obj = projectOnPlane(obj, planeLocation)
% ray.projectOnPlane(planeLocation)
%
% planeLocation: the z coordinate of a plane that is parallel to the
%                x-y plane.
% nLines: number of lines to draw for the illustration
% intersects the rays with a plane at a specified location.
% This is meant to make it easier to analyze the lightfield function.

%remove dead rays

liveIndices = ~isnan(obj.waveIndex);

intersectZ = repmat(planeLocation, [size(obj.waveIndex(liveIndices, 1), 1) 1]);
intersectT = (intersectZ - obj.origin(liveIndices, 3))./obj.direction(liveIndices, 3);
intersectPosition = obj.origin(liveIndices, :) + obj.direction(liveIndices, :) .* repmat(intersectT, [1 3]);

obj.origin(liveIndices, :) = intersectPosition;
end
