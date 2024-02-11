function thisR = piCreateSlantedBarScene(varargin)
% DEPRECATED - Create a recipe for a slanted bar scene. 
%
% This seemed to rely on V3.  Use the V4 instead
%
%    thisR = piRecipeCreate('slanted edge'); 
%    scene = piWRS(thisR);
%
% Inputs
%   N/A
%
% OPTIONAL input parameter/val
%   illumination - illumination of the scene (infinite light) as as SPD
%                filename.
%   planeDepth - distance from camera to both black and white sides. If
%                set, this will override the blackDepth/whiteDepth
%                parameters. (in meters)
%  NYI -
%   blackDepth - distance from the camera to the black side of the slanted
%                bar (in meters)
%   whiteDepth - distance from the camera to the white side of the slanted
%                bar (in meters)
%
% RETURN
%   recipe - recipe for this created scene
%
% See also
%

% Examples:
%{
  thisR = piCreateSlantedBarScene('planeDepth',0.5);
%}

%% Parse inputs
error('Deprecated.  Use thisR = piRecipeCreate(''slanted edge'')');

varargin = ieParamFormat(varargin);
parser = inputParser();
parser.addParameter('planedepth',1, @isnumeric);
parser.addParameter('eccentricity',0, @isnumeric);
parser.addParameter('illumination', 'EqualEnergy.spd', @ischar);
parser.addParameter('whitedepth',0, @isnumeric);
parser.addParameter('blackdepth',0, @isnumeric);

parser.parse(varargin{:});

planeDepth   = parser.Results.planedepth;
eccentricity = parser.Results.eccentricity;
illumination = parser.Results.illumination;

%% Read in base scene
scenePath = fullfile(piRootPath,'data','V3','slantedBar');
sceneName = 'slantedBar.pbrt';
thisR = piRead(fullfile(scenePath,sceneName));

%% Make adjustments to the plane

% Calculate x position given eccentricity
% Note: Where should this position be calculated from?
x = tand(eccentricity)*planeDepth;

%% Set the two planes to the specified distance

T = [x,0,planeDepth];

thisGroup= piAssetNames(thisR,'group find','WhitePlane');
thisR.assets(thisGroup(1)).groupobjs(thisGroup(2)).position(3) = T(3);

thisGroup= piAssetNames(thisR,'group find','BlackPlane');
thisR.assets(thisGroup(1)).groupobjs(thisGroup(2)).position(3) = T(3);

%{
[gnames,cnames] = piAssetNames(thisR);
gnames{thisGroup(1)}{thisGroup(2)}
%}

%% Make adjustments to the light

% Check illumination file
[~,n,e] = fileparts(illumination);
illumName = [n e];

if(~exist(fullfile(scenePath,illumName),'file'))
    Warning(['%s SPD file does not exist in the scene folder. You will'...
        'need to copy it manually into your working folder!'],illumName)
end

thisR = piWorldFindAndReplace(thisR,'EqualEnergy.spd',illumName);


end

