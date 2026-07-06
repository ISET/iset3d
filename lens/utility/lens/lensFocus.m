function [filmDistance, lens] = lensFocus(lensDescription, objDistance, varargin)
% Compute film distance (mm) to focus at object distance (mm)
%
% Syntax
%   [filmDistance, lens] = lensFocus(lensDescription, objDistance, varargin)
%
% Description
%   Uses the camera autofocus method to determine the film distance that
%   will bring a point at object distance into best focus.  When the object
%   distance is huge, the film distance is the focal length.
%
% Inputs:
%   lensDescription - A lens file (dat or json) or a lensC object
%   objDistance     - Vector of object distances (millimeters)
%
% Optional
%   wavelength  - Which wavelength for the point
%
% Returns
%   filmDistance - Film distance for best focus (millimeters)
%   lens         - lens object created from the name
%
% See also
%   s_lensFocusTable

% Examples:
%{
  lensFileName = '2ElLens.json';
  objDistance = 100;
  [filmDistJ, lensJ] = lensFocus(lensFileName,objDistance);
%}
%{
  lensFileName = '2ElLens.json';
  objDistance = [100:25:200];
  filmDistJ = lensFocus(lensFileName,objDistance);
%}
%{
  lensFileName = '2ElLens.dat';
  objDistance = 100;
  [filmDistD, lensD] = lensFocus(lensFileName,objDistance);
%}
%{
  lens = lensC('file name','2ElLens.json');
  objDistance = 1000;
  filmDistance = lensFocus(lens,objDistance,'wavelength',600);
%}

%% Set up the key parameters
p = inputParser;
p.addRequired('lensDescription',@(x)(ischar(x) || isa(x,'lensC')));
p.addRequired('objDistance',@isnumeric);
p.addParameter('wavelength',550,@isnumeric);

p.parse(lensDescription,objDistance,varargin{:});

wavelength = p.Results.wavelength;

% Read it or this is the lens
if ischar(lensDescription), lens = lensC('fileName',lensDescription);
else,                       lens = lensDescription;
end

%%  Initialize a point, film, and a camera with this lens

filmDistance = zeros(size(objDistance));

for ii = 1:numel(objDistance)
    
    point{1} = [0 0 -objDistance(ii)];
    
    film = filmC;
    
    camera = psfCameraC('lens',lens,'film',film,'pointsource',point);
    
    %%  Find the film focal length (mm) for this wavelength
    
    % Call autofocus, setting the indices of refraction of air and water
    camera.autofocus(wavelength,'nm',1,1);
    
    % Return the position for focus given the lens and a point at this distance
    filmDistance(ii) = camera.film.position(3);
    
end

%% Warn the user
badFocus = (filmDistance < 0);
if sum(badFocus) > 0
    warning('Negative means object distances can not be focused');
end


end

