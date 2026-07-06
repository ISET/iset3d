function computeRayDist(obj, nLines, jitterFlag, subsection)
% Estimate distances in millimeters of each ray to the exist aperture
%
%   psfCamera.computeRayDist(obj)
%
% The camera has a point source, lens, and film.
%
% THe calculation is done
%
%
% See also: psfCamera.estimatePSF, psfCamera.oiCreate
%
% AL/BW Vistasoft Team, Copyright 2014


if ieNotDefined('nLines'),     nLines = false;     end
if ieNotDefined('jitterFlag'), jitterFlag = false; end

% Trace from the point source to the entrance aperture of the
% multielement lens
ppsfCFlag = false;
obj.rays = obj.lens.rtSourceToEntrance(obj.pointSource, ppsfCFlag, jitterFlag,[], subsection);

% Duplicate the existing rays for each wavelength
% Note that both lens and film have a wave, sigh.
% obj.rays.expandWavelengths(obj.film.wave);
obj.rays.expandWavelengths(obj.lens.wave);

%lens intersection and raytrace
obj.lens.rtThroughLens(obj.rays, nLines);

% Something like this?  Extend the rays to the film plane?
% if nLines > 0; obj.rays.draw(obj.film); end

% intersect with "film" and add to film
%obj.rays.recordOnFilm(obj.film, nLines);

end