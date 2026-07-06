function height = scale(thisLens,factor,varargin)
% Scale the lens surfaces size by a factor
%
% Syntax
%    height = lensC.scale(factor,varargin)
%
% Brief description
%  Change all of the spatial dimensions of the lens by the specified scale
%  factor. The surface radius of curvature, center position, and aperture
%  are all scaled.  The lens focal length is recalculated and the
%  apertureMiddleD parameter of the lensC object is updated.
%
% Inputs
%    thisLens - lensC object
%    factor   - scale factor
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
% Wandell
%
% See also
%   s_lensRescale

% Examples:
%{
 microLensName   = 'microlens.json';
 thisLens = lensC('filename',microLensName);
 fprintf('height: %f\nfocal length %f\n',thisLens.get('lens height'),lensFocus(thisLens,1e6));

 fprintf('height: %f\n',thisLens.get('lens height'));
 thisLens.scale(4);
 fprintf('height: %f\nfocal length %f\n',thisLens.get('lens height'),lensFocus(thisLens,1e6));

%}

%%
p = inputParser;
p.addRequired('thisLens',@(x)(isa(x,'lensC')));
p.addRequired('factor',@isscalar);
p.addParameter('radius',true,@islogical);
p.addParameter('center',true,@islogical);
p.addParameter('aperture',true,@islogical);

p.parse(thisLens,factor,varargin{:});


%% Scale all the surfaces by the specified scale factor

for ii=1:numel(thisLens.surfaceArray)
    if p.Results.radius
        thisLens.surfaceArray(ii).sRadius = thisLens.surfaceArray(ii).sRadius * factor;
    end
    if p.Results.center
        thisLens.surfaceArray(ii).sCenter = thisLens.surfaceArray(ii).sCenter * factor;
    end
    if p.Results.aperture
        thisLens.surfaceArray(ii).apertureD = thisLens.surfaceArray(ii).apertureD * factor;
    end
end

% Recalculate the focal length and black box model
thisLens.bbmCreate();
thisLens.focalLength = lensFocus(thisLens,1e6);
thisLens.apertureMiddleD = thisLens.get('middle aperture d');

if nargout > 0, height = thisLens.get('lens height'); end

end