function ppsfReturn = traceToEntrance(obj,nLines, jitterFlag, depthTriangles)
% Calculate the origin and direction of the exiting rays
%
%    ppsfReturn = traceToEntrance(obj,nLines, jitterFlag)
%
% nLines is the number of lines to draw on the diagram.
% For no diagram set nLines to 0 (false).  This is the default.  
% This function does the same thing as estimatePPSF, except it only traces
% the rays til the entrance pupil, and expands the wavelengths.  Does NOT
% trace rays through the lens.  This is useful for using LF linear
% transforms to perform the ray-tracing through the lens.
%
% Example:
%    ppsfCamera.tracetoEntrance(nLines)
%
% AL, Vistasoft Copyright 2014

if ieNotDefined('nLines'), nLines = false; end
if ieNotDefined('jitterFlag'), jitterFlag = false; end
if ieNotDefined('depthTriangles'), depthTriangles = []; end
    
%disp('-----trace source to lens-----');
ppsfObjectFlag = true;
obj.ppsfRays = obj.lens.rtSourceToEntrance(obj.pointSource, ppsfObjectFlag, jitterFlag, [],[], depthTriangles);

%*********
%**project occlude: we need to remove rays that have collided here
%********

%duplicate the existing rays, and creates one for each
%wavelength
%disp('-----expand wavelenghts-----');
obj.ppsfRays.expandWavelengths(obj.lens.wave);


%project rays onto the z = 0 plane for a proper light field
%obj.ppsfRays.projectOnPlane(0);

obj.ppsfRays.pointSourceLocation = obj.pointSource;
ppsfReturn = obj.ppsfRays;

end