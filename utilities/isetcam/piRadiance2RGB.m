function [ip,sensor] = piRadiance2RGB(radiance,varargin)
% Convert scene or OI to an IP, carrying along the metadata
%
% Syntax
%    [ip,sensor] = piRadiance2RGB(radiance,varargin)
%
%
% Description
%   After we simulate the scene we have both the radiance and the pixel level
%   metadata.  This function converts the radiance and metadata all the way to
%   the IP level. Accepts either scene or OI.
%
% Input
%   scene radiance - This scene should generally have metadata attached to it.
%
% Optional key/value pairs
%   sensor        - File name containing the sensor (default sensorCreate)
%   pixel size    - Size in microns (e.g. 2)
%   film diagonal - In millimeters, default is 5 mm
%   etime         - exposure time
%
% Output
%   ip
%   sensor
%
% See also
%   piMetadataSetSize

%%
varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('radiance',@isstruct);
% p.addRequired('st',@(x)(isa(x,'scitran')));

p.addParameter('sensor','',@ischar);   % A file name
p.addParameter('pixelsize',[],@isscalar); % um
p.addParameter('filmdiagonal',5,@isscalar); % [mm]
p.addParameter('etime',1/100,@isscalar); % 
p.addParameter('noiseflag',2,@isscalar);
p.addParameter('analoggain',1);

p.parse(radiance,varargin{:});
radiance     = p.Results.radiance;
sensorName   = p.Results.sensor;
pixelSize    = p.Results.pixelsize;
filmDiagonal = p.Results.filmdiagonal;
eTime        = p.Results.etime;
noiseFlag    = p.Results.noiseflag;
analoggain   = p.Results.analoggain;
%% scene to optical image

if strcmp(radiance.type,'scene')
    oi = piOICreate(radiance.data.photons);
elseif ~strcmp(radiance.type,'opticalimage')
    error('Input should be a scene or optical image');
else
    oi = radiance;
end
if isempty(pixelSize)
    pixelSize = oiGet(oi,'width spatial resolution','microns');
end

%% oi to sensor
if isempty(sensorName)
    sensor = sensorCreate;
else
%     sensor = sensorCreate('monochrome');
    load(sensorName,'sensor');
end

% Not sure why these aren't settable.  I think they are here to conform
% with the ISETAuto generalization paper
readnoise   = 0.2e-3;
darkvoltage = 0.2e-3;
[electrons,~] = iePixelWellCapacity(pixelSize);  % Microns
converGain = 1/electrons;         % voltage swing/electrons
% 
sensor = sensorSet(sensor,'pixel read noise volts',readnoise);
sensor = sensorSet(sensor,'pixel voltage swing',1);
sensor = sensorSet(sensor,'pixel dark voltage',darkvoltage);
sensor = sensorSet(sensor,'pixel conversion gain',converGain);
sensor = sensorSet(sensor, 'quantization method','12bit');

sensor = sensorSet(sensor,'analog gain', analoggain);
if ~isempty(pixelSize)
    % Pixel size in meters needed here.
    sensor = sensorSet(sensor,'pixel size same fill factor',pixelSize*1e-6);
end


oiSize = oiGet(oi,'size');
samplesapce_oi = oiGet(oi,'width spatial resolution','microns');
if pixelSize == samplesapce_oi
    sensor = sensorSet(sensor, 'size', oiSize);
else
    sensor = sensorSet(sensor, 'size', oiSize*(samplesapce_oi/pixelSize));
end
% sensor = sensorSetSizeToFOV(sensor, oi.wAngular, oi);

%% Compute

% eTime  = autoExposure(oi,sensor,0.90,'weighted','center rect',rect);
sensor = sensorSet(sensor,'exp time',eTime);
sensor = sensorSet(sensor,'noise flag',noiseFlag); % see sensorSet for more detail

sensor = sensorCompute(sensor,oi);
fprintf('eT: %f ms \n',eTime*1e3);

% sensorWindow(sensor);

%% Copy metadata
% if isfield(oi,'metadata')
%     if ~isempty(oi.metadata)
%      sensor.metadata          = oi.metadata;
%      sensor.metadata.depthMap = oi.depthMap;
%      sensor                   = piMetadataSetSize(oi,sensor);
%     end
% end

% annotate the sensor?
% sensor = piBatchSceneAnnotation(sensor);

%% Sensor to IP
CFAs = sensor.color.filterNames;
if numel(CFAs)>3
    ip = [];
    return
end
ip = ipCreate;

% Choose the likely set of signals the sensor will encounter
ip = ipSet(ip,'conversion method sensor','MCC Optimized');
ip = ipSet(ip,'illuminant correction method','gray world');

% demosaics = [{'Adaptive Laplacian'},{'Bilinear'}];
ip = ipSet(ip,'demosaic method','Adaptive Laplacian'); 
% ip = ipSet(ip, 'demosaic method','analog rccc');
ip = ipCompute(ip,sensor);

% ipWindow(ip);

if isfield(sensor,'metadata')
    ip.metadata = sensor.metadata;
    ip.metadata.eT = eTime;
end

end