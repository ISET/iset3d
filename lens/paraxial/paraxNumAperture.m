%% COMPUTE THE NUMERICAL APERTURE for a given ExP diameter and distance from image point
% or the EnP diameter and distance from the object point


function [NA,varargout]=paraxNumAperture(Pupil_diam,GaussPoint_dist,refr_index)

%INPUT
% Pupil_diam : ExP or EnP diameter [scalar o column vector for wavelength
% dependent]
% GaussPoint_dist: distance from the pupil to the gaussian point [scalar o column vector for wavelength
% dependent]
%refr_index: refractive index of the medium between the pupil and the gaussian point[scalar o column vector for wavelength
% dependent]

%OUTPUT
%NA: numerical aperture
%varargout {1}:effective numerical aperture

%%

alfa=atan((Pupil_diam/2)./GaussPoint_dist); %angle of half F-numer

NA=refr_index.*sin(alfa); %numerical aperture

if nargout>1
    effFnum=GaussPoint_dist./Pupil_diam; %effective F-number (or Focal ratio)
    varargout{1}=effFnum;
end


