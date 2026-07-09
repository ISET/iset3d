function [newN]=checkNandWave(N,wavelength)
%The function checks the size of N and wavelength and corrects if possible
%
% [newN]=checkNandWave(N,wavelength)
%
%  We verify that the wavelength is a column vector  and that the index of
%  refraction length matches.  If N is only a scalar, we replicate it to
%  the length of wavelength.
%
%INPUT
%  N: scalar or column vector
%  wavelength: scalar or column vector
%
%OUTPUT
%  newN: corrected refractive index vector
%
% MP Vistasoft 2014


if size(N,1)==size(wavelength,1)
    newN=N;
else
    if (size(wavelength,1)>1) && (size(N,1)==1) && (size(N,2)==1) %case of no dispersive material
        newN=repmat(N,size(wavelength,1),1);
    else
        warning('Refractive index and sampling wavelength do not match!! The surface struc misses this information')
        newN=[];
    end
end