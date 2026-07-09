%% Diffraction-enabled lens comparison
%
% Compare line profiles for two aperture diameters using a small
% diffraction-enabled spherical lens.  This example is adapted from the
% former ISETLens `s_lensDiffraction.m`.
%
% See also
%   lensC, psfCameraC, oiPlot

%% Initialize
ieInit;

%% Set up point, lens, and film
point = psCreate(0,0,-1e5);

lens = lensC('aperture sample',[15 15], ...
    'aperture middle d',2, ...
    'diffraction enabled',true);
lens.name = 'diffraction-example';
lens.focalLength = 6;
lens.elementsSet([0; 0.18; 0.03], [8.04; 0; -1000], [3; 3; 3], [1.65; 1; 1]);
wave = lens.get('wave');

film = filmC('position',[0 0 5], ...
    'resolution',[81 81], ...
    'size',[0.1 0.1], ...
    'wave',wave);

%% Trace two apertures
apertures = [2 0.75];
profiles = cell(size(apertures));
positionUM = linspace(-film.size(1)/2,film.size(1)/2,film.resolution(1))*1e3;

for ii = 1:numel(apertures)
    lens.set('middle aperture diameter',apertures(ii));
    lens.set('aperture sample',[15 15]);

    camera = psfCameraC('lens',lens,'film',film,'point source',point);
    camera.autofocus(550,'nm');
    camera.estimatePSF('n lines',0, ...
        'jitter flag',false, ...
        'diffraction method','HURB', ...
        'rt type','ideal');

    image = camera.film.image;
    profiles{ii} = squeeze(sum(sum(image,3),1));
    assert(max(profiles{ii}) > 0);
end

%% Plot normalized profiles
maxnorm = @(x)(x/max(x));
ieFigure;
for ii = 1:numel(apertures)
    plot(positionUM,maxnorm(profiles{ii}),'LineWidth',1.5);
    hold on;
end
grid on;
xlabel('Position (um)');
ylabel('Relative ray count');
legend(compose('Aperture %.2f mm',apertures),'Location','best');

%% END
