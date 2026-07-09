function clear(obj)
% Zeros the film image, which is a spectral image
%
% The film size is set to match the film resolution and have a wavelength
% dimension
%
% Wandell, CISET Team, 2016

obj.image = zeros([obj.resolution,length(obj.wave)]);

end


