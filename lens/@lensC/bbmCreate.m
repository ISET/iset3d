function [varargout] = bbmCreate(obj,varargin)
% Create the black box model of the lens 
%
% Various problems with the logic here, and we should re-write before long
% (BW).  See below.
%
%INPUT
%   obj:      lens object (lensC)
%   varargin {1}: n_ob refractive index in object space
%   varargin {2}: n_im refractive index in image space
%   
%OUTPUT
%   varargout{1}= Black Box Model or psfCamera (if varargin{1}='all')
%
% The black box model is a summary of the optical system that we use
% for thick lens approximations.  These apply to paraxial data (first
% order, near the center of the lens).
%
% In this format, it creates the BBM with n_ob and n_im = 1
%  thisLens = lensC;
%
%  BBM = lens.bbmCreate()
%  BBM = lens.bbmCreate (n_ob,n_im)
%
% MP Vistasoft 2014

%% CHECK INPUT PARAMETERS and BUILD OPTICAL SYSTEM

if nargin>1, n_ob=varargin{1}; n_im=varargin{2};
else, n_ob=1; n_im=1;
end

% This 'get' does the work.  This get does not account for the lens
% wavelength correctly.
OptSyst = obj.get('optical system',n_ob,n_im);

%% Append Optical System field to the Black Box Model of the lens
obj.set('black box model',OptSyst);  

% If you want, you can get the Black Box Model as Output
if nargout > 0 , varargout{1} =obj.get('bbm','all'); end

end
