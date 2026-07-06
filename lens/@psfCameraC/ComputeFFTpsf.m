function [PSF, x_im, y_im] = ComputeFFTpsf(obj, nSample, ntime, unit)
% Compute the PSF using the Fourier Optics method: PSF=|PupilFunction|^2
%
%   psfCamera.ComputeFFTpsf(nSample, ntime, unit)
%
% For efficiency, set nSample to a power of 2 (for Fast Fourier Trasform
% computation)
%
% This calculation assumes uniform pupil illumination (apodization) is
% uniform 
%
% The psf camera object includes a point source, lens, and film.
%
% INPUT
%  nSample: number of sample of pupil function  [128x128 by default]
%  ntime:   width of the window to sampling the pupil function  (normalized
%           to exit pupil (ExP) radius) [frhom 1 to N] [2times by default] 
%  unit:    ['mm' by default]
%
% OUTPUT
%  PSF:   (nSample x nSample x num_wavelength)
%  x_im:  x-coord (image space)  [Vector beacuse used equal sampling in both coordinate axis]
%  y_im:  y-coord (image space) [Vector beacuse used equal  sampling in both coordinate axis]
%
%Examples
%   ComputeFFTpsf(256,4,'mm')
%   ComputeFFTpsf(256,4)
%   ComputeFFTpsf(256)
%   ComputeFFTpsf()
%
% PrhoGRAMMING TODO:
%   The units of x and y are not clear to me.  I think they are in samples
%   over the exit plane.  If so, then we need to be able to get the size of
%   the exit plane and the units using a call like
%
%      obj.get('spatial sampling','units')
% 
% We should include a varargin{} to select type of apodization (or compute 
% illumination in real scene, i.e. partial occlusion of the PSF.
%
% MP Vistasoft Team, Copyright 2014


%% GET wavelength vector
wave=obj.get('wave'); % in nm
% nW=size(wave(:),1);  % number of sample
% unit='mm';

% The input wavelength should always be in nanometers.  This converts to
% millimeters.
wave_mm = wave*1e-6; % in mm
%% GET INPUT

% These are the default number of samples in one dimension of the pupil
% aperture. 
%
% def_ntim is the window is 2x the size of pupil.
% It seems that unit is no longer used here because the input is
% nanometers.
% More comments to follow (MP)
if ~exist('nSample','var') || isempty(nSample), nSample = 128; end
if ~exist('ntime','var')   || isempty(ntime),   nSample = 2; end
if ~exist('unit','var')    || isempty(unit),    unit = 'mm'; end


%% GET Coeffs for Pupils Function Polinomial
CoeffDef = obj.get('bbm','defocus'); %for defocus
CoeffPA  = obj.get('bbm','primaryaberration'); %for primary aberration

% dZ_def=obj.get('bbm','defocusshift');
% NA=obj.get('bbm','numerical aperture');
% spot_rad_norm=dZ_def.*tan(NA); % radius for defocus


% Coeff1=0.5.*(NA./n_im).^2.*dZ; %Unique coeff

%% BUILD PUPIL FUNCTIONs
% debugF = 'no-debug'; % flag for debugging

% I) Sampling space.  Not sure what the units are here, but if the pupil
% range is in mm, then the samples are in mm.  The pupil range will be
% millimeters if ntime is in millimeters.  It's a bit of a mess right now.
% (BW).
range_pupil = 2*ntime ; % al range od pupil function in normalized coordinate
d_pupil     = range_pupil/nSample; %sampli
xn          = [-nSample/2:nSample/2-1]*d_pupil;
yn          = [-nSample/2:nSample/2-1]*d_pupil;
[Xn,Yn]     = meshgrid(xn,yn);

% Mask=circMask(sqrt(Xn.*Xn+Yn.*Yn)); 

%PUPIL NORMALIZED COORDINATE
% Vector
rho_v   = sqrt(xn.*xn+yn.*yn);
theta_v = atan2(yn,xn);

%Matrix 
rho   = sqrt(Xn.*Xn+Yn.*Yn); % radial coordinate [normalized to the Exit Pupil radius]
theta = atan2(Yn,Xn); % theta  

% II) Apodization (assumed uniform for all the wavelength)
typeApod = 'uniform';
[ApodW]  = psfGetApodFun(typeApod,rho,theta,0);
% ieFigure; imagesc(ApodW)

% III) Phase Function = Seidel Aberration + Defocus
% Wavelength dependence (included in the function)
W_def = psfGetPhaseFun(CoeffDef,'defocus',rho,theta);
W_pa  = psfGetPhaseFun(CoeffPA,'primary aberration',rho,theta);

% FOR DEBUG:
% W_def=psfGetPhaseFun(CoeffDef,'defocus',rho,theta,'debug',1);
% W_pa=psfGetPhaseFun(CoeffPA,'primary aberration',rho,theta,'debug',1);
% %how many wavelength of aberration
% CoeffDef_wave=paUnit2NumWave(CoeffDef);
% CoeffPA_wave=paUnit2NumWave(CoeffPA);

% IV) PUPIL FUNCTION= APODIZATION * EXP (-i*k*PHASE_FUNCTION)
% Wavelength dependence (included in the function)
[PupilFun] = psfGetPupilFun(ApodW,W_pa,W_def,wave_mm);
% ieFigure; imagesc(abs(PupilFun(:,:,1)))

%% COMPUTE POINT SPREAD FUNCTION (PSF)
light_type = 'incoherent';
[PSF] = psfPupil2PSF(PupilFun,light_type);

%% Get GRID sampling for Image Space
% Get ImagSyst
% ImagSyst=obj.get('imagingsystem');
% % Get point Source
% pSource=obj.get('pointsource');
% % Create a dummy object to compute the Numerical Apertuee
% Obj.z=pSource(3)+paraxGet(ImagSyst,'lastVertex'); 
% Obj.y=sqrt(pSource(1).^+pSource(2).^2); % eccentricity (height)
% % Numerical Aperture
% [NA]=paraxEstimateNumAperture(ImagSyst,Obj);
NA = obj.get('bbm','numerical aperture');

% Sampling GRID for image Space
coordType = 'normalized polar';

% These coordinates should have units.  Do they?  What is normalized polar?
% Can we convert that to millimeters on the film?
[x_im,y_im] = psfEstimateImageCoord(coordType, rho_v, theta_v, wave_mm, NA);


%% SET OUTPUT

obj.set('fft psf modulus',PSF);
coord.x = x_im;
coord.y = y_im;
obj.set('fft psf coordinate',coord);


end
