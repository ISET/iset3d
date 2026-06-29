%% Chromaticity example
%
% * We render a scene of a sphere that is illuminated by a point source.
% We calculate an RGB image using a typical oi, sensor and ip routines.
%
% Then we look at the chromaticity and luminance components of the
% linear RGB image. 
% 
% The chromaticity calculation removes most of the illumination variation.
%
% Then we run the same analysis on a more complex image (Fruit.mat,
% from the spectral scene database).
%
% See also
%   t_cieChromaticity, t_metricsColor, ieWebGet

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Render a sphere illuminated with a point source

thisR = piRecipeDefault('scene name','sphere');

thisLight = piLightCreate('point','type','point','cameracoordinate', true);
thisR.set('light',thisLight, 'add');
thisR.set('light',thisLight.name,'specscale',0.5);
thisR.set('light',thisLight.name,'spd',[0.5 0.4 0.2]);

thisR.set('film resolution',[192 192]);
thisR.set('rays per pixel',128);
thisR.set('n bounces',1); % Number of bounces
thisR.set('render type', {'radiance', 'depth'});

sceneSphere = piWRS(thisR);

%%  Convert the scene into an image through a sensor
oi = oiCreate;
oi = oiCompute(oi,sceneSphere);
sensor = sensorCreate;
sensor = sensorSet(sensor,'fov',sceneGet(sceneSphere,'fov'),oi);
sensor = sensorCompute(sensor,oi);
ip = ipCreate;
ip = ipCompute(ip,sensor);

ipWindow(ip);

%%  Plot the values through the middle

sz = ipGet(ip,'size');  % Row, col
ipPlot(ip,'horizontal line',[1,round(sz(1)/2)]);  % x,y (sorry about that)

%%  Look at the linear data corrected for the luminance level

% Remember that the sphere has the same reflectance everywhere; the
% variations are due to the lighting

srgb = ipGet(ip,'srgb');
lrgb = srgb2lrgb(srgb);

% Get the luminance level and compute the chromaticity map
% If lum is very small, the chromaticity is unreliable.  So, clean it up
lum = sum(lrgb,3);
dark = lum < 0.01;
chr = zeros(size(lrgb));
for ii=1:3
    thisC = lrgb(:,:,ii)./lum;
    thisC(dark) = 0;
    chr(:,:,ii) = thisC;
end

%% Show the results as an image

ieNewGraphWin;
mimg = montage({lum,chr},'Size',[2 1]); axis image; axis off
sz = size(mimg.CData);
row = round(sz(1)/2);

%% Show the results as a scatter plot in rg space

ieNewGraphWin;
plot(chr(:,1),chr(:,3),'bo');
set(gca,'xlim',[0 1],'ylim',[0 1]);
grid on; xlabel('r'); ylabel('g');

%% Plot a horizontal line through the data
ieNewGraphWin;
plot(lum(row,:),'k-'); hold on;
plot(chr(row,:,1),'r:');
plot(chr(row,:,2),'g:');
grid on; xlabel('Position'); ylabel('Relative intensity');

%% This is not a perfect algorithm.
%
% Here we illustrate the idea with a more complex image that contains
% multiple objects and inter-reflections

%{
 fname = ieWebGet('resource type','spectral','resource name','Fruit');
%}

sceneFruit = sceneFromFile(fname,'spectral');
sceneWindow(sceneFruit);
oi = oiCompute(oi,sceneFruit);
sensor = sensorSet(sensor,'fov',sceneGet(sceneFruit,'fov'),oi);
sensor = sensorCompute(sensor,oi);
ip = ipCompute(ip,sensor);
ipWindow(ip);

%% Now calculate the chromaticity and show, again
srgb = ipGet(ip,'srgb');
lrgb = srgb2lrgb(srgb);

% Get the luminance level and compute the chromaticity map
% If lum is very small, the chromaticity is unreliable.  So, clean it up
lum = sum(lrgb,3);
dark = lum < 0.05;
chr = zeros(size(lrgb));
for ii=1:3
    thisC = lrgb(:,:,ii)./lum;
    thisC(dark) = 0;
    chr(:,:,ii) = thisC;
end

%% Compare the segmentation

ieNewGraphWin;
mimg = montage({lum,chr},'Size',[2 1]); axis image; axis off
sz = size(mimg.CData);
row = round(sz(1)/2);

%% Scatter plot

ieNewGraphWin;
plot(chr(:,1),chr(:,3),'bo');
set(gca,'xlim',[0 1],'ylim',[0 1]);
grid on; xlabel('r'); ylabel('g');

%% END
