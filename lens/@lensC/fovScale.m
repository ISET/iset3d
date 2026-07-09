function [scaleFactor, newFL] = fovScale(thisLens, newFOV, filmSz, varargin)
% Calculate how to scale a lens to achieve a field of view.
%
% Syntax
%   [scaleFactor, newFL] = lensC.fovScale(newFOV, filmSz);
%
% Brief description
%   Given a lens and a film size, we find the scale factor that can be
%   applied to the lens to achieve a specific field of view. 
%   Useful link: https://www.dxomark.com/google-pixel-4a-camera-review-excellent-single-camera-smartphone/
%
% Inputs
%   thisLens - lensC object
%   newFOV   - desired field of view (FOV) in the units of degrees
%   filmSz   - target film size in the units of mm
%
% Returns
%   scaleFactor - scaling factor to be applied to the lens
%   newFL       - new effective focal length after scaling
%
% Description:
%   
%   The relationship between the focal length, FOV and film size is:
%       FOV = 2 * atand(filmSz/2/FL);
%   Solving for the focal length:
%       FL = filmSz/2/tand(FOV/2);
%   Scaling factor is then the ratio of the focal lengths:
%       scaleFactor = newFL / curFL;
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

filmSz = 2; % mm
newFOV = 50; % degrees
[sf, newFL] = thisLens.fovScale(newFOV, filmSz);
thisLens.scale(sf);
scaledFOV = thisLens.get('fov', filmSz);
thisLens.draw
%}
%%
p = inputParser;
p.addRequired('thisLens',@(x)(isa(x,'lensC')));
p.addRequired('newFOV', @isnumeric);
p.addRequired('filmSz', @isnumeric);

p.parse(thisLens, newFOV, filmSz);
thisLens = p.Results.thisLens;
newFOV = p.Results.newFOV;
filmSz = p.Results.filmSz;

%%
newFL = filmSz/2/tand(newFOV/2);

% Get current focal length
curFL = thisLens.get('bbm', 'effective focal length');

scaleFactor = newFL / mean(curFL);
end
