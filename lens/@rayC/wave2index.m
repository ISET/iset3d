function idx = wave2index(rays,wave)
% Convert a wavelength (nm) into the wave index for these rays
%
% Inputs
%  rays:   rayC
%  wave:   wavelength in nanometers
%
% Output
%  idx:    Index of the wavelength in rays.wave
%
% Used for selecting out rays according to their index as stored in
% waveIndex.  Very clunky, but I am not ready for a re-write (BW).
%
% See also
%  raysC.get();

%% Parse
p = inputParser;

p.addRequired('rays',@(x)(isa(x,'rayC')));
p.addRequired('wave',@isscalar);

p.parse(rays,wave);

%%
idx = find(rays.wave == wave);

end