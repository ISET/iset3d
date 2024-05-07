function [ip,sensor] = piRadiance2RGB(radiance,varargin)
% Convert scene or OI to an IP, carrying along the metadata
%
% Syntax
%    [ip,sensor] = piRadiance2RGB(radiance,varargin)
%
%
% Description
%   After we simulate a scene with ISET3d, we have the radiance
%   (scene) or irradiance data (oi). This function creates a sensor
%   and ip, and converts the data and metadata all the way to the IP
%   level.
%
% Input
%   scene or oi - This generally has metadata attached to it.
%
% Optional key/value pairs
%   sensor        - File name containing the sensor, or a sensor.
%                   Default conforms with the ISETAuto generalization paper
%   pixel size    - Size in microns (e.g. 2)
%   film diagonal - In millimeters, default is 5 mm
%   etime         - exposure time
%
% Output
%   ip  - Computed ip
%   sensor - sensor used for the computation.  Can be reused.
%
% See also
%   piMetadataSetSize, piOI2IP

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
p.addParameter('quantization','12 bit',@ischar);  % 12bit, 10bit, 8bit, analog

p.parse(radiance,varargin{:});
radiance     = p.Results.radiance;
sensorName   = p.Results.sensor;
pixelSize    = p.Results.pixelsize;
eTime        = p.Results.etime;
noiseFlag    = p.Results.noiseflag;
analoggain   = p.Results.analoggain;

% filmDiagonal = p.Results.filmdiagonal;

%% scene to optical image

if strcmp(radiance.type,'scene')
    % What oi parameters are in here?
    oi = piOICreate(radiance.data.photons);
elseif ~strcmp(radiance.type,'opticalimage')
    error('Input should be a scene or optical image');
else
    % The usual compute path is through here
    oi = radiance;
end

% Below, we set the pixel size for a 1-1 match to the oi spatial
% sampling resolution.
if isempty(pixelSize)
    pixelSize = oiGet(oi,'width spatial resolution','microns');
end

%% oi to sensor
if isempty(sensorName), sensor = sensorCreate;

    % The default conforms with the ISETAuto generalization paper
    readnoise   = 2e-3;
    darkvoltage = 2e-3;
    [electrons,~] = iePixelWellCapacity(pixelSize);  % Microns
    converGain = 1/electrons;         % voltage swing/electrons
    %
    sensor = sensorSet(sensor,'pixel read noise volts',readnoise);
    sensor = sensorSet(sensor,'pixel voltage swing',1);
    sensor = sensorSet(sensor,'pixel dark voltage',darkvoltage);
    sensor = sensorSet(sensor,'pixel conversion gain',converGain);
    sensor = sensorSet(sensor,'quantization method','12bit');

    sensor = sensorSet(sensor,'analog gain', analoggain);
    if ~isempty(pixelSize)
        % Pixel size in meters needed here.
        sensor = sensorSet(sensor,'pixel size same fill factor',pixelSize*1e-6);
    end
elseif ischar(sensorName), load(sensorName,'sensor');
elseif isfield(sensorName,'type') && isequal(sensorName.type,'sensor')
    sensor = sensorName;
end

% This sensorSet replaces the code below.
sensor = sensorSet(sensor,'match oi',oi);

%{
% Match sensor and oi spatial sampling.
oiSize = oiGet(oi,'size');
samplespace_oi = oiGet(oi,'width spatial resolution','microns');
if pixelSize == samplespace_oi
    sensor = sensorSet(sensor, 'size', oiSize);
else
    sensor = sensorSet(sensor, 'size', oiSize*(samplespace_oi/pixelSize));
end
% sensor = sensorSetSizeToFOV(sensor, oi.wAngular, oi);
%}

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