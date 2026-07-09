function oi = oiCreate(camera,varargin)
% Create an ISET optical image from the psfCamera object
%
% Syntax:
%  oi = camera.oiCreate(varargin);
%
% Inputs:
%  camera - psfCameraC 
%
% Optional Key/value pairs
%   mean illuminance  - Returned oi is set to this mean illuminance.
%                       Default is 10 lux
%
% Outputs
%   oi - ISET Optical image structure
%
% Description:
%   We create an ISET optical image from the film image in a psfCameraC.
%   We have used this with isetlens, mainly, to have a look at lenses and
%   understand their pointspread function or in general the ray trace
%   through the lens.
%
%   This routine abuses the OI specification of the focal length.  It makes
%   the focal length equal to the film distance, not the true focal length
%   of the lens.  That is necessary for the size geometry to work out
%   correctly.
%
% AL/BW Vistasoft Team, Copyright 2014
%
% See also:
%   s_isetauto.m, t_autofocus.m, lensFocus

%% Parse inputs
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('camera',@(x)(isa(x,'psfCameraC')));
p.addParameter('meanilluminance',10,@isscalar);

p.parse(camera,varargin{:});

%% Create an optical image from the camera (film) image data.

oi = oiCreate;
oi = initDefaultSpectrum(oi);
oi = oiSet(oi,'wave', camera.film.wave);

% The shift-invariant model does not require a focal length or an
% f-number.
oi = oiSet(oi,'optics model','shift invariant');

%% Normalize the  scale here

oi = oiSet(oi,'photons',camera.film.image);

%% Estimate the horizontal field of view

% ** Use the distance to the film/sensor from the back of the lens to
% compute the size of the oi image and the geometry. **
filmDistance = camera.get('film distance');
hfov = rad2deg(2*atan2(camera.film.size(1)/2,filmDistance));

% ** N.B. The film  distance is not always at the focal length.  But we set
% the focal length to the film distance so that the geometry will work out
% correctly with field of view and other calculations. **
oi = oiSet(oi,'optics focal length',filmDistance*1e-3);
oi = oiSet(oi,'hfov', hfov);

% Set the name based on the distance of the film (sensor) from the
% final lens surface.  This may not be the focal length of the lens.
oi = oiSet(oi, 'name', ['filmDistance: ' num2str(filmDistance)]);

% Scale the photons in the film image so that the mean illuminance is
% reasonable.  As set by the user or a default of 10 lux.
oi = oiSet(oi,'mean illuminance',p.Results.meanilluminance);

end
