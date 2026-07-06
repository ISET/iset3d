function draw(camera,nLines)
% Draw the camera lens and rays to the film plane
%
% Syntax:
%    psfCamera.draw(nLines)
%
% Inputs
%   camera:  psfCameraC object
%   nLines:  Number of rays to draw
%            Default is 20
%
% Description
%   Show the ray trace lines to the film (sensor) plane
%
% AL/BW Vistasoft Team, Copyright 2014
%
% See also:
%   

%% Parameters

if ieNotDefined('nLines'), nLines = 20; end

%% Drawing to film surface

% Set up for yFan picture.  Could be an option
yFan(1) =  0; yFan(3) = 0;
yFan(2) = -1; yFan(4) = 1;

jitterFlag = true;
camera.rays = camera.lens.rtSourceToEntrance(camera.pointSource{1},jitterFlag,'realistic',yFan);

% Duplicate the existing rays for each wavelength
% Note that both lens and film have a wave, sigh.
% obj.rays.expandWavelengths(obj.film.wave);
camera.rays.expandWavelengths(camera.get('wave'));

%lens intersection and raytrace
figHdl = camera.lens.rtThroughLens(camera.rays, nLines);

% intersect with "film" and draw the film
camera.rays.recordOnFilm(camera.film, 'nLines',nLines,'fig',figHdl);
% title('Final surface to film');

% Set the window limits
xFilm     = camera.get('film distance');
lens      = camera.get('lens');
thickness = lens.get('lens thickness');
height    = lens.get('lens height');

% Set the axes so the rays on the left show and we see 1 mm past the film
% plane.  And set twice the height of the lens.
set(gca,'xlim',[-2*thickness xFilm+1]); 
set(gca,'ylim',[-1*height,height])
grid on

end