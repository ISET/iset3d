%% Rescale a JSON lens
%
% Re-scale a JSON lens, write it, read it back, and run a small ray trace.
% This example is adapted from the former ISETLens `s_lensRescaleJSON.m`.
%
% See also
%   lensC.scale, lensC.fileWrite

%% Initialize
ieInit;

%% Read a JSON lens and create a scaled copy
lensFile = fullfile(piDirGet('lens'),'dgauss.22deg.3.0mm.json');

baseLens = lensC('filename',lensFile,'aperture sample',[9 9]);
baseLens.bbmCreate();

baseFocalLength = median(baseLens.get('bbm','effective focal length'));
desiredFocalLength = 1.5;   % mm
scaleFactor = desiredFocalLength/baseFocalLength;

scaledLens = lensC('filename',lensFile,'aperture sample',[9 9]);
scaledLens.scale(scaleFactor);
scaledLens.name = sprintf('dgauss.22deg.%.1fmm',desiredFocalLength);

scaledFocalLength = median(scaledLens.get('bbm','effective focal length'));
fprintf('Base focal length:   %.4f mm\n',baseFocalLength);
fprintf('Scaled focal length: %.4f mm\n',scaledFocalLength);

assert(abs(scaledFocalLength-desiredFocalLength) < 1e-10);

%% Write and read the scaled lens as JSON
tempJson = [tempname,'.json'];
scaledLens.fileWrite(tempJson);
reloadedLens = lensC('filename',tempJson,'aperture sample',[9 9]);
delete(tempJson);

reloadedLens.bbmCreate();
reloadedFocalLength = median(reloadedLens.get('bbm','effective focal length'));

assert(reloadedLens.get('n surfaces') == scaledLens.get('n surfaces'));
assert(abs(reloadedFocalLength-scaledFocalLength) < 1e-4);

%% Ray trace a deterministic on-axis point through the reloaded lens
film = filmC('position',[0 0 lensFocus(reloadedLens,1e6)], ...
    'size',[0.2 0.2], ...
    'resolution',[41 41], ...
    'wave',reloadedLens.get('wave'));

camera = psfCameraC('lens',reloadedLens, ...
    'film',film, ...
    'point source',{[0 0 -1000]});

camera.estimatePSF('jitter flag',false,'n lines',0);

assert(sum(camera.film.image(:)) > 0);

%% END
