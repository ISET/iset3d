function fullPathfname = piShapeWrite(fname,pointsXYZ_meters,varargin)
% Write out a JSON file for specifying the film shape
%
% Synopsis
%   fullPathfname = piShapeWrite(fname,pointsXYZ_meters,varargin)
%
% Description
%  The film shape is described as a collection of XYZ sample points. This
%  function converts the points into the relatively arcane lookup format
%  needed by PBRT.  Its main purpose is to hide the complexity from the
%  user. 
%
% Inputs
%  fname - File name (JSON file)
%  pointCloud - Film surface locations (Nx3) specified in meters
%  
% Key/val
%   N/A
%
% Outputs
%   fullPathfname - Full path to the file written out.
%
% See also
%   piShapeLookuptable

%% Generate Lookup table JSON 

lookuptable = piShapeLookuptable(pointsXYZ_meters);

jsonwrite(fname,lookuptable);

fullPathfname = which(fname);

end


