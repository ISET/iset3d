% Add a 4th order wavefront coeff term independent from the Gaussian parameters
% of the optical system elements

function [waveCoeff]=paAddWaveCoeffs(waveCoeff,term_type,varargin)

%INPUT
%waveCoeff: structure for  4th order wavefront coefs [are accepted also
% Seidel Coeff or Peak Value Coeff]
%term_type: specify the type of the term to add
%['piston','defocus','tilt']
%varagin: depends to term_type     'piston'  {1}-> const  o column vectore equal to wavelength
 %                                 'defocus'  {1}->shift along z; {2}->effective F-num =[ExP-Focus]/D_ExP; {3}-> refractive index in image space %                               
  %                                 'tilt'    {1}->tilt angle; {2}-> ExP Radius ; {3}-> refractive index in image space

%OUTPUT
%waveCoeff: structure for wavefront coeffs


%THEORY: Chapter 6 -"Sasián, José. "Introduction to Aberration in Optical Imaging System"
% Piston term: piston terms depend on the reference used to measure the wavefront delay or advance
%              One option is tomeasure the piston terms with respect to the entrance and exit pupil
%               on axis points. In this case the second-order piston term is zero because the pupils
%              are conjugated. W000=constant
% Defocus term: expressed in the term W020 as effect of a longitudinal
%               change of the defocus delta_shift. It is related to effective f-number of
%               the system, refractive index of image space.
 %              Defocus (W020)+Astigmastim (W220)= peakValue (W20) 
% Tilt  term: expressed in the term W011 
%               Tilt (W011)+ Distortion (W311)= peakValue (W11)
                  

%Formula to Defocus and Tilt obtained with "Mahajan- Optical Imaging  and Aberrations-Part I- ray Geometrical Optics"
% 3.3 and 3.4

% DEFOCUS  W020=n_im/2*(1/z-1/R)*Radius_ExP^2=-n_im*delta_shift/(8*effFnum^2)
% TILT  W011=n_im*Radius_ExP* tilt_angle

%% CHECK is are available Wavefront 4th Order Coeffs or Seidel
fnames=fieldnames(waveCoeff);
type='w4th'; % Ground Hypothesis
for ci=1:length(fnames)
    switch fnames{ci}
    case {'SI';'SII';'SIII';'SIV';'SV'}
        type='seidel';
    case {'W040';'W131';'W222';'W220';'W311'}
    case {'wave','unit'}
    otherwise
    end
end

if strcmp (type,'seidel')
    waveCoeff=paSeidel2Wave4thOrder(waveCoeff); %Compute 4th order wavefront coeffs
end

%%  CHECK number of wave samples

x=getfield(waveCoeff,fnames{1});
nw=size(x,1);

%% COMPUTE ADDITIONAL TERMs
switch term_type
    case {'Piston';'piston'}  %Constant term
        if nargin>2
            piston=varargin{1};
        else
            piston=0;
        end
        if not(length(piston)==nw)
            piston=repmat(piston,nw,1);
        end
        waveCoeff.W000=piston;
    case {'Defocus';'defocus'}
        if nargin>4
            shiftZ=varargin{1}; %shift along Z
            eff_Fnum=varargin{2}; %effective focal number
            n_im=varargin{3}; %refractive index of the image space
        else
            error (['Not enough Inputs for ',term_type])
        end
        defocus=-n_im.*shiftZ./(8.*eff_Fnum.^2);
        waveCoeff.W020=defocus;
    case {'Tilt';'tilt'}
        if nargin>4
            tilt_angle=varargin{1}; %tilt angle
            ExP_radius=varargin{2}; %ExP Radius
            n_im=varargin{3}; %refractive index of the image space
        else
            error (['Not enough Inputs for ',term_type])
        end
        tilt=n_im.*ExP_radius.*tilt_angle;
        waveCoeff.W011=tilt;
        
    otherwise
        error([term_type, 'cannot be used to modify the wavefront error!!'])
end
        
     