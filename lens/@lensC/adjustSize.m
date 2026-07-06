function height = adjustSize(thisLens,lenssize,varargin)
% Scale the lens surfaces size by a factor
%
% Syntax
%    height = lensC.adjustSize(lensSize,varargin)
%
% Brief description
%  Change all of the spatial dimensions of the lens surfaces and aperture
%  so that the diameter of the front of the lens has a specific size (in
%  mm). Often used to rescale microlens.
%  
% Inputs
%    thisLens - lensC object
%    thisSize - desired size in mm
%
% Optional key/value inputs
%   'all'       - Scale all of radius, center and aperture (default)
%   'radius'    - Scale sRadius
%   'center'    - Scale sCenter
%   'aperture'  - Scale apertureD
% 
% Outputs
%    height     - scaled lens height in millimeters
%
% Description
%  This routine calls the lensC.scale function to adjust all of the
%  surfaces and apertures in the lens to obtain a specific size of the
%  front aperture of the lens.  If you would like to scale only a
%  particular component, call the lensC.scale method.
%
% See also
%   s_lensRescale, lensC.scale

% Examples:
%{
 thisLens = lensC('filename','microlens.json');
 fprintf('height: %f\nfocal length %f\n',thisLens.get('lens height'),lensFocus(thisLens,1e6));

 thisLens.adjustSize(0.001);
 fprintf('height: %f\nfocal length %f\n',thisLens.get('lens height'),lensFocus(thisLens,1e6));
%}

%% Parse inputs
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('thisLens',@(x)(isa(x,'lensC')));
p.addRequired('lenssize',@isscalar);  % Size is in mm

p.parse(thisLens,lenssize,varargin{:});

desiredDiameter = p.Results.lenssize;

%% We will call lensC.scale to adjust to the size

currentDiameter = thisLens.get('diameter');   % mm
thisLens.scale(desiredDiameter/currentDiameter);

%% The new lens needs a black-box model and has a new focal length and middle aperture diameter
thisLens.bbmCreate();
thisLens.focalLength = lensFocus(thisLens,1e6);
thisLens.apertureMiddleD = thisLens.get('middle aperture d');

if nargout > 0, height = thisLens.get('lens height'); end

end

