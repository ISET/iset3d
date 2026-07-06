%% Single ray through a lens
%
% Trace one deterministic ray through a double Gauss lens.  This tutorial is
% adapted from the former ISETLens `t_singleRay.m`.
%
% See also
%   rayC, lensC.rtThroughLens

%% Initialize
ieInit;

%% Create a lens and a ray
lensFileName = fullfile(piDirGet('lens'),'dgauss.22deg.3.0mm.json');
thisLens = lensC('filename',lensFileName,'aperture sample',[9 9]);
wave = thisLens.get('wave');

origin = [0 0.6 -20];
direction = [0 sind(-2) cosd(-2)];
ray = rayC('origin',origin, ...
    'direction',direction, ...
    'wave index',4, ...
    'wave',wave);

%% Trace without drawing a ray fan
thisLens.rtThroughLens(ray,0);

finalOrigin = ray.get('origin');
finalDirection = ray.get('direction');

assert(all(isfinite(finalOrigin(:))));
assert(all(isfinite(finalDirection(:))));
fprintf('Final ray z position: %.4f mm\n',finalOrigin(end,3));

%% END
