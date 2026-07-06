function intersectPosition = sphereIntersect(obj,center,radius)
% Compute intersection (x,y,z) positions of rays with a sphere
%
% The rays are stored in liveRays
% The sphere is specified by its center and radius
%
% intersectionPosition is the (x,y,z) position of the rays on the sphere
% defined by center/radius
%
% AL Vistasoft 2015

nRays = size(obj.origin,1);

% Make a vector of the center and radius
repCenter = repmat(center, [nRays 1]);
repRadius = repmat(radius, [nRays 1]);

% Radicand from vector form of Snell's Law
radicand = dot(obj.direction, obj.origin - repCenter, 2).^2 - ...
    ( dot(obj.origin - repCenter, obj.origin -repCenter, 2)) + repRadius.^2;

% Calculate something about the ray angle with respect
% to the current surface.  AL to figure this one out
% and put in a book reference.
if (radius < 0)
    intersectT = (-dot(obj.direction, obj.origin - repCenter, 2) + sqrt(radicand));
else
    intersectT = (-dot(obj.direction, obj.origin - repCenter, 2) - sqrt(radicand));
end

%make sure that intersectT is > 0   This does not apply for this
%case, because sometimes a curved sensor is in front of the flat
%sensor plane
%         if (min(intersectT(:)) < 0)
%             fprintf('intersectT less than 0 for lens %i');
%         end

repIntersectT = repmat(intersectT, [1 3]);
intersectPosition = obj.origin + repIntersectT .* obj.direction;
end
