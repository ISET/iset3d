function  [x,y,zOUT]=coordPolar2Cart3D(rho,theta,z)
%Convert point coordinate from  polar to Cartesian, leaving z unchanged
%
%  x = rho*cos(theta)
%  y = rho*sin(theta)
%  z = z
%
% This is not quite the same as pol2cart() in Matlab.  This function 
%
% INPUT:
%   rho   = height eccentricity  (your units)
%   theta = angular eccentricity in radians
%   z = distance along optical axis (your units)
%
% OUTPUT:
%  x, y, z
%
% Examples:
%    rho = 10; theta = pi/4; z = 1;
%    [x,y,z] = coordPolar2Cart3D(rho,theta,z)
%    rho = 1;
%    [x,y,z] = coordPolar2Cart3D(rho,theta,z)
%
% MP Vistasoft Copyright 2014

%% This projects the (x,y) but leaves z unchanged.

% The Matlab function does a cylindrical coordinate transform, which is a
% bit different.
x    = rho.*cos(theta);
y    = rho.*sin(theta);
zOUT = z;

end