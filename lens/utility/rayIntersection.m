function endPoints = rayIntersection(rays,zPlane,varargin)
% Calculate where rays intersect a planar or spherical position
%
% Inputs:
%  rays:    A ray object, containing ray.origin (3xN)
%  zPlane:  Position of the plane in Z; plane is perpendicular to Z
%  film:    'planar' or 'spherical'
%
% Output:
%  endPoints: Points in the z-plane (3xN)
% 
% BW, CISET team, 2016

%% Parse inputs

p = inputParser;
p.addRequired('rays',@(x)(isa(x,'rayC')));
p.addRequired('zPlane',@isnumeric);
p.addParameter('film','planar',@ischar);

p.parse(rays,zPlane,varargin{:});
filmType = ieParamFormat(p.Results.film);

%% Calculate endpoints

% The ray initial position is rays.origin
switch lower(filmType)
    case 'planar'     
        
        % Extend the rays to the zPlane
        endPoints = repmat(zPlane, [size(rays.origin, 1) 1]);

        %  Distance to reach the zPlane from current origin
        s = (endPoints - rays.origin(:, 3))./rays.direction(:, 3);
        
        % From the rays.origin extend in the direction by the distance
        % needed to reach the zPlane
        endPoints = rays.origin + rays.direction .* repmat(s, [1 3]);
        
    case 'spherical'
        % The rays extend to a point on the sphere with a radius, r, and
        % with x=0, y=0 at zC. We store zC in zPlane.
        %
        % The formula for the point positions on the spherical surface is
        %
        %   r^2 = (x - pos)^2 + (y - pos)^2 + (z - zC)^2
        %
        % The x and y pos are usually 0,0 because the film is centered.
        % 
        % Suppose (x,y,z) = origin + s*direction. Then we have to find the
        % scalar such that the endpoints satisfies this equation 
        % 
        %   r^2 = (ox + s*dx)^2 + (oy + s*dy)^2 + (oz + s*dz - zC))^2
        %
        % Suppose ozz = (oz - zC), then
        %
        %   r^2   = ox^2 + 2*ox*s*dx + (s*dx)^2 + 
        %           oy^2 + 2*oy*s*dy + (s*dy)^2 +
        %           ozz^2 + 2*ozz*s*dz + (s*dz)^2
        %
        %    0    = s^2*(dx^2 + dy^2 + dz^2) + 
        %           s  *(ox*dx + oy*dy + ozz*dz) +
        %               ox^2 + oy^2 + ozz^2 - r^2
        %
        % So the two solutions are
        %
        %    s = (-b +/- sqrt(b^2 - 4ac)) / 2a
        %
        
        % TO BE REPLACED WITH CODE FROM COMMENTSs
        % Extend the rays to the zPlane
        endPoints = repmat(zPlane, [size(rays.origin, 1) 1]);
        
        %  Distance to reach the zPlane from current origin
        s = (endPoints - rays.origin(:, 3))./rays.direction(:, 3);
        
        % From the rays.origin extend in the direction by the distance
        % needed to reach the zPlane
        endPoints = rays.origin + rays.direction .* repmat(s, [1 3]);
        
        
    otherwise
        error('Unknown film type %s\n',filmType);
end

end
