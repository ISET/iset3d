%% Rescale a lens
%
% Re-scale a lens to a new focal length and write temporary lens files.
% This example is adapted from the former ISETLens `s_lensRescale.m`.
%
% See also
%   lensC.scale, lensC.fileWrite, s_lensRescaleJSON

%% Initialize
ieInit;

%% Read a reference lens and scale it to a shorter focal length
referenceFocalLength = 100;  % mm
desiredFocalLength = 12.5;   % mm
baseLensName = 'petzval.12deg';

lensFileName = fullfile(piDirGet('lens'), ...
    sprintf('%s.%.1fmm.json',baseLensName,referenceFocalLength));

baseLens = lensC('filename',lensFileName,'aperture sample',[9 9]);
baseLens.bbmCreate();

baseFocalLength = median(baseLens.get('bbm','effective focal length'));
scaleFactor = desiredFocalLength/baseFocalLength;

scaledLens = lensC('filename',lensFileName,'aperture sample',[9 9]);
scaledLens.scale(scaleFactor);
scaledLens.name = sprintf('%s.%.1fmm',baseLensName,desiredFocalLength);

scaledFocalLength = median(scaledLens.get('bbm','effective focal length'));
fprintf('Base focal length:   %.4f mm\n',baseFocalLength);
fprintf('Scaled focal length: %.4f mm\n',scaledFocalLength);

assert(abs(scaledFocalLength-desiredFocalLength) < 1e-8);

%% Write temporary lens files
tempDat = [tempname,'.dat'];
tempJson = [tempname,'.json'];

scaledLens.fileWrite(tempDat);
scaledLens.fileWrite(tempJson);

assert(exist(tempDat,'file') == 2);
assert(exist(tempJson,'file') == 2);

delete(tempDat);
delete(tempJson);

%% Ray trace a deterministic on-axis point through the scaled lens
film = filmC('position',[0 0 lensFocus(scaledLens,1e6)], ...
    'size',[1 1], ...
    'resolution',[41 41], ...
    'wave',scaledLens.get('wave'));

camera = psfCameraC('lens',scaledLens, ...
    'film',film, ...
    'point source',{[0 0 -10000]});

camera.estimatePSF('jitter flag',false,'n lines',0);

assert(sum(camera.film.image(:)) > 0);

%% END
