%% Diffraction-enabled lens basics
%
% Create a small diffraction-enabled spherical lens and trace an on-axis
% point source.  This is a shortened tutorial derived from the former
% ISETLens diffraction material.
%
% See also
%   lensC, psfCameraC.estimatePSF

%% Initialize
ieInit;

%% Create a simple diffraction-enabled lens
point = psCreate(0,0,-1e5);

lens = lensC('aperture sample',[15 15], ...
    'aperture middle d',1.0, ...
    'diffraction enabled',true);
lens.name = 'diffraction-tutorial';
lens.focalLength = 6;
lens.elementsSet([0; 0.18; 0.03], [8.04; 0; -1000], [3; 3; 3], [1.65; 1; 1]);
wave = lens.get('wave');

film = filmC('position',[0 0 5], ...
    'resolution',[61 61], ...
    'size',[0.1 0.1], ...
    'wave',wave);

%% Focus and estimate the PSF
camera = psfCameraC('lens',lens,'film',film,'point source',point);
camera.autofocus(550,'nm');
camera.estimatePSF('n lines',0, ...
    'jitter flag',false, ...
    'diffraction method','HURB', ...
    'rt type','ideal');

assert(sum(camera.film.image(:)) > 0);
oi = camera.oiCreate;
oiPlot(oi,'illuminance hline',round([1 oiGet(oi,'cols')/2]),'no figure');

%% END
