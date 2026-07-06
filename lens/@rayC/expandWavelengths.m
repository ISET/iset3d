function obj = expandWavelengths(obj, wave, waveIndex)
% Replicates the (monochromatic) ray bundle to include more wavelengths
%
% The first ray trace step is in free space, from point source to the first
% lens element. This step is performed without knowledge of wavelength - to
% save computation and memory.  
% 
% But once the ray enters the lens,  wavelength information is
% necessary.  This function replicates the bundle of rays and assigns a
% wavelength to each of the replicated bundles.
%
% wave:  List of wavelengths
% waveIndex:  Which wavelengths to replicate (if empty, use all)
% 
% The returned object is in the rayC class.
% AL, Vistasoft Team, 2015

% If not defined, then replicate for all the wavelengths
if notDefined('waveIndex'), waveIndex = 1:length(wave); end

% This is the number of rays in the bundle.
% subLength = size(obj.origin, 1);
nRays = obj.get('nrays');
nWave = length(wave);

% Not sure why we need to repmat the origin and direction and
% distance
obj.origin = repmat(obj.origin, [nWave 1]);
obj.direction = repmat(obj.direction, [nWave 1]);
obj.distance  = repmat(obj.distance,[nWave 1]);
obj.set('wave', wave);

% We need an explanation from Andy about wave and waveIndex
%
% Assign the indices of this wavelength expansion
%  TODO: maybe make this simpler and cleaner somehow ...
tmp = (waveIndex' * ones(1, nRays))';
obj.waveIndex = tmp(:);

end