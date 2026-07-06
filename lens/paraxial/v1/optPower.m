function [opw]=optPower(n1,n2,R)

%% Computer the optical power of a refractive surface
%% INPUT
%n1:  matrix [P x M+1 elements],refr. index pre-refraction at P different %wavelengths
%n2: matrix [P x M+1 elements],refr. index post-refraction at P different wavelengths
%R:  vector[M elements],radius of curvature  , its [unit] affects the optical power ones ,
%e.g. R [m,meters]->opw [D, diopter]

%% OUTPUT
%Optical power

%% COMPUTE THE OPTICAL POWER
if size(n1,1)>1
    R=repmat(R,size(n1,1),1);
end

opw=(n2-n1)./R;