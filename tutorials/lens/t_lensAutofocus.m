%% Autofocus a PSF camera
%
% Use `psfCameraC.autofocus` to place the film for a point source and
% compare the result with `lensFocus`.  This tutorial is adapted from the
% former ISETLens `t_autofocus.m`.
%
% See also
%   psfCameraC.autofocus, lensFocus

%% Initialize
ieInit;

%% Create the camera
point = {[0 0 -1000]};
lensFileName = fullfile(piDirGet('lens'),'dgauss.22deg.3.0mm.json');
lens = lensC('filename',lensFileName,'aperture sample',[9 9]);
film = filmC('size',[0.25 0.25], ...
    'resolution',[41 41], ...
    'wave',lens.get('wave'));

camera = psfCameraC('lens',lens,'film',film,'point source',point);

%% Autofocus at 550 nm
filmDistance = camera.autofocus(550,'nm',1,1);
expectedDistance = lensFocus(lens,1e3,'wavelength',550);

fprintf('Autofocus film distance: %.6f mm\n',filmDistance);
assert(abs(filmDistance-expectedDistance) < 1e-9);
assert(abs(camera.get('film distance')-filmDistance) < 1e-12);

%% Estimate a small deterministic PSF at the focused film position
camera.estimatePSF('n lines',0,'jitter flag',false);
assert(sum(camera.film.image(:)) > 0);

%% END
