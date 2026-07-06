function estimatePPSF(obj, nLines, jitterFlag)
% Deprecate.
% Calculate the origin and direction of the exiting rays
%
%    ppsfRays = estimatePPSF(obj,nLines,jitterFlag)
%
% Inputs:
%    nLines: The number of lines to draw on the diagram.
%       For no figure set nLines to false (default).
%    jitterFlag:  Jitter ray aperture positions
%
% Example:
%    psfCamera.estimatePPSF(nLines)
%
% AL, Vistasoft Copyright 2014

if ieNotDefined('nLines'),     nLines = false; end
if ieNotDefined('jitterFlag'), jitterFlag = false; end

disp('-----trace source to lens-----');
tic
ppsfObjectFlag = true;
obj.ppsfRays = obj.lens.rtSourceToEntrance(obj.pointSource{1}, jitterFlag);
toc

%duplicate the existing rays, and creates one for each
%wavelength
disp('-----expand wavelenghts-----');
tic
obj.ppsfRays.expandWavelengths(obj.lens.wave);
toc

%lens intersection and raytrace
disp('-----rays trace through lens-----');
tic
obj.lens.rtThroughLens(obj.ppsfRays,nLines);
toc

% This should work with recordOnFilm, like the estimatePSF case.
% This calculates the plenoptic rays onto the z = 0 plane so that the
% recordOnFilm routine will be able to form an image.
obj.ppsfRays.projectOnPlane(0);

% Record these rays on film, I think.
obj.ppsfRays.recordOnFilm(obj.film,'nLines',nLines,'fig',gcf);

% Store some additional information and return.  Not sure why we are
% returning.
obj.ppsfRays.pointSourceLocation = obj.pointSource;

end