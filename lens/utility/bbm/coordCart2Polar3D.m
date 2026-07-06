function  [rho,theta,zOUT] = coordCart2Polar3D(x,y,z)
%Convert (x,y,z) to (rho,theta,z) 
%
%  [rho,theta,zOUT] = coordCart2Polar3D(x,y,z)
%
% INPUT:
%   x, y, z
%
% OUTPUT:
%  rho   = height eccentricity  (your units)
%  theta = angular eccentricity (radians)
%  z = z (distance along optical axis, usually; your units)
%
% Examples:
%   x = 1, y = 1, z = 10; [rho,theta,zOUT] = coordCart2Polar3D(x,y,z)
%   x = 0, y = 1, z = 10; [rho,theta,zOUT] = coordCart2Polar3D(x,y,z)
%
%  MP Vistasoft 2014

%% HEIGHT ECCENTRICITY
rho =sqrt(x.^2 + y.^2); %distance of the point source to optical axis

%% ANGULAR ECCENTRICITY

theta = atan2(y,x);

% Used to be this, but BW changed to atan2 after MP left.
% if not(x==0) && not(y==0)
%     theta=atan(y/x); %angle subtended by the point source and the x-axis in the object plane
% else
%     if (y==0),         theta = 0;
%     else               theta = pi/2;
%     end
% end
        
%% DISTANCE along THE OPTICAL AXIS
zOUT = z;

end
