function [iRays, oRays, planes, nanIdx, pupilPos, pupilRadii,lensThickness] = lensRayPairs(lensfile, varargin)
%% Input/output ray pairs
% 
% Synopsis:
%   [iRays, oRays, planes] = lensRayPairs(lensfile, varargin)
%
% Inputs:
%   lensfile - name of the lens json file
%   
% Outputs:
%   iRays - input rays (radius, u, v)
%   oRays - output rays (x, y, u, v)
%   planes - coordinate of input and output planes on z axis
%   nanIdx - failed rays index (useful for determining exit pupil)
%   pupilPos - pupil positions
%   pupilRadii     - pupil radii
%
% Optional key/val pairs:
%   elevationMax - max elevation difference from normal in degrees
%   nRadiusSamp  - number of samples along radius
%   nAzSamp      - number of azumith samples 
%   nElSamp      - number of elevation samples
%   planeOffset  - offset from the front and rear surface of the lens
%   visualize    - whether visualize the ray tracing process
%   waveIndex    - Index in the wavelength vector of the lens.wave
% Examples:
%{
lensName = 'lenses/dgauss.22deg.3.0mm.json';
[iRays, oRays, planes] = lensRayPairs(lensName, 'visualize', true, 'elevation max', 20);
%}

%{
lensName = 'wide.40deg.3.0mm.json';
[iRays, oRays, planes] = lensRayPairs(lensName, 'visualize', true,...
                                    'n radius samp', 10, 'elevation max', 40,...
                                    'reverse', true);
%}
%%
varargin = ieParamFormat(varargin);
p = inputParser;
p.addRequired('lensfile', @(x)(exist(x, 'file')));
p.addParameter('elevationmax', 10, @isnumeric);
p.addParameter('nradiussamp', 10, @isnumeric);
p.addParameter('nazsamp', 10, @isnumeric);
p.addParameter('nelsamp', 10, @isnumeric);
p.addParameter('inputplaneoffset', 0.01, @isnumeric); % mm
p.addParameter('visualize', false, @islogical);
p.addParameter('reverse', true, @islogical);
p.addParameter('maxradius', 0, @isnumeric);
p.addParameter('minradius', 0, @isnumeric);
p.addParameter('waveindex', 1, @isnumeric);
p.addParameter('outputsurface',outputPlane(0.01)); % mm
p.addParameter('diaphragmdiameter',NaN,@isnumeric); % mm


p.parse(lensfile, varargin{:});
%{
arguments
    lensName char {mustBeFile}
    options.thetamax (1, 1) {mustBeNumeric} = 20
    options.nradiussamp (1, 1) {mustBeNumeric} = 10
    options.nazsamp (1, 1) {mustBeNumeric} = 10
    options.nphisamp (1, 1)
end
%}

lensfile = p.Results.lensfile;
elevationMax = p.Results.elevationmax;
nRadiusSamp = p.Results.nradiussamp;
nAzSamp = p.Results.nazsamp;
nElSamp = p.Results.nelsamp;
inputPlaneOffset = p.Results.inputplaneoffset;
visualize = p.Results.visualize;
reverse = p.Results.reverse;
maxradius = p.Results.maxradius;
minradius = p.Results.minradius;
waveindex= p.Results.waveindex;
outputSurface = p.Results.outputsurface;
diaphragm_diameter = p.Results.diaphragmdiameter;
%% Reverse the lens
if reverse
    lensR = lensReverse(lensfile);
else
    lensR = lensC('filename', which(lensfile));
end


%% Set diaphragm diameter is requested

if(~isnan(diaphragm_diameter))
    % Get aperture index
 index = lensR.get('diaphragm');
 lensR.surfaceArray(index).apertureD=diaphragm_diameter;
 lensR.apertureMiddleD=diaphragm_diameter;
end
%% Determine lens thickness
firstEle = lensR.surfaceArray(1); % First lens element surface
lastEle = lensR.surfaceArray(end); % First lens element surface
firstVertex = firstEle.sCenter(3)-firstEle.sRadius;
lastVertex = lastEle.sCenter(3)-lastEle.sRadius;

lensThickness=abs(lastVertex-firstVertex);
%%
 [iRays, oRays, planes] = raytraceLightField(lensR, nRadiusSamp,...
         elevationMax, nElSamp, nAzSamp, inputPlaneOffset, outputSurface, 'visualize', visualize,...
         'max radius', maxradius, 'min radius', minradius,'waveindex',waveindex);

%[iRays, oRays, planes] = raytraceLightFieldPupil(lensR, nRadiusSamp,...
%        nElSamp, nAzSamp, inputPlaneOffset, outputSurface, 'visualize', visualize,...
%        'max radius', maxradius, 'min radius', minradius,'waveindex',waveindex);    
    
%% remove nan 
nanIdx = find(any(isnan(oRays), 2));

% Get rid of w
iRays = iRays(:, 1:3);
%iRays = iRays(:, 1:4);
oRays = oRays(:, :); % ouput Z value can be negative for fisheye lenses so we need to keep this info


% %% Generate entrance pupils
 [pupilPos, pupilRadii] = lensGetEntrancePupils(lensR);
 pupilPos = pupilPos - inputPlaneOffset;
end