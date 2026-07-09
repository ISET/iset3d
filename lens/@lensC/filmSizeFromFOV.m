function filmSz = filmSizeFromFOV(thisLens, fov, varargin)
% Calculate film size given certain fov
%
% Synopsis:
%   filmSz = filmSizeFromFOV(thisLens, fov, varargin)
%
% Brief description:
%   Given a lens fov, calculate the film size
%
% Inputs:
%   thisLens - lensC object
%   fov      - desired field of view (FOV) in the units of degrees
%
% Returns:
%   filmSz   - target film size in the units of mm
%
% Description:
%   The relationship between the focal length, FOV and film size is:
%       FOV = 2 * atand(filmSz/2/FL);
%   Solving for film size:
%       filmSz = 2 * FL * tand(FOV/2);
%
% ZLY, 2020
%
% See also
%

% Examples:
%{
thisWave = 450;
thisLens = lensC('filename', 'dgauss.22deg.3.0mm.json');
fl = thisLens.get('focal length', thisWave);
curFOV = thisLens.get('fov');

newFL = 4.38; % mm
scaleFactor = newFL / fl;
thisLens.scale(scaleFactor);
targetFOV = 77;
filmSz = thisLens.filmSizeFromFOV(targetFOV);
fovCheck = thisLens.get('fov', filmSz);
%}

%%
p = inputParser;
p.addRequired('thisLens',@(x)(isa(x,'lensC')));
p.addRequired('fov', @isnumeric);

p.parse(thisLens, fov, varargin{:});
%%
fl = thisLens.get('bbm', 'effective focal length');
filmSz = 2 * fl * tand(fov / 2);
end