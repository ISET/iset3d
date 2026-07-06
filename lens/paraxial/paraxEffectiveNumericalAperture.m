%% Compute the effective numerical aperture = n(sin[teta_ComaR]-sin[teta_ChiefR])
% difference of the sine of chief ray and comaRays (upper and lower should be the same)
%in MERIDIONAL PLANE

function [effNA]=paraxEffectiveNumericalAperture(n,teta_chiefR,teta_comaR,type)

%INPUT
%n: refractive index (column vector if wavelength-dependent
%teta_chiefRay: angle of the chief ray
%teta_comaRay: [nx2] 
%type : specific type of computation ('paraxial','non-paraxial')
%
%
%OUTPUT
%effNA: effective numerical aperture [nx2] for upper and lower coma rays

switch type
    
    case{'parax','paraxial','par'}
        effNA=n.*((teta_comaR)-(teta_chiefR)); % upper coma 
        
    otherwise
        effNA=n.*(sin(teta_comaR)-sin(teta_chiefR)); % upper coma 
end