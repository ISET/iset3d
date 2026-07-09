%% Ray trace a point spread function
%
% Build a small `psfCameraC` from a lens, film, and point source, then trace
% rays to form a deterministic point spread.  This tutorial is adapted from
% the former ISETLens `t_lensRayTrace.m`.
%
% See also
%   psfCameraC, filmC, lensC, oiPlot

%% Initialize
ieInit;

%% Create a lens, film, and point source
lensFileName = fullfile(piDirGet('lens'),'dgauss.22deg.3.0mm.json');
thisLens = lensC('filename',lensFileName,'aperture sample',[9 9]);
wave = thisLens.get('wave');

filmDistance = lensFocus(thisLens,1e3);
film = filmC('position',[0 0 filmDistance], ...
    'size',[0.25 0.25], ...
    'resolution',[41 41], ...
    'wave',wave);

point = {[0.05 0 -1000]};
camera = psfCameraC('lens',thisLens,'film',film,'point source',point);

%% Estimate the PSF
camera.estimatePSF('n lines',0,'jitter flag',false);

assert(sum(camera.film.image(:)) > 0);
centroid = camera.get('image centroid');
fprintf('PSF centroid: %.5f, %.5f mm\n',centroid.X,centroid.Y);

%% Convert the result to an optical image
oi = camera.oiCreate;
assert(all(oiGet(oi,'size') > 0));
oiPlot(oi,'irradiance image wave',[],550,15);

%% END
