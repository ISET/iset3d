function aGrid = apertureGrid(obj,varargin)
% Specify a sampling grid on the first surface of the multi-element lens
% 
% Brief description
%  Returns the (X,Y) positions inside a region on the front surface.
%  These sample positions are used for the subsequent ray tracing. We
%  should be able to specify a sample on the surface (jittered or
%  regular) as well as just an xFan or yFan on the surface.  Maybe
%  other shapes?
%
% Input
%  obj -   lensC object
%
% Optional key/values
%  randJitter
%  rtType
%  subSection
%
% Output
%   aGrid
%
% HB/BW

%% Parse inputs

varargin = ieParamFormat(varargin);

p = inputParser;

p.addRequired('obj',@(x)(isa(obj,'lensC')));

p.addParameter('randjitter',false,@islogical);  % Jitter the grid positions

vFunc = @(x)(isempty(x) || isvector(x));
p.addParameter('subsection',[],vFunc); % Trace only a portion of the ???
p.addParameter('rttype',[],@ischar);   % Type of ray trace

p.parse(obj,varargin{:});

randJitter = p.Results.randjitter;
subSection = p.Results.subsection;
rtType     = p.Results.rttype;

%%
if isempty(subSection)
    % Realistic or ideal ray trace type (rtType)
    aGrid = fullGrid(obj,randJitter, rtType);
    
    aMask   = apertureMask(obj);
    aGrid.X = aGrid.X(aMask);
    aGrid.Y = aGrid.Y(aMask);
    
else
    % Define the grid on a subsection
    % Perhaps we can implement xFan and yFan this way?
    %
    % For example, for yFan we could set
    %   subSection(1) = 0; subSection(3) = 0
    %   subSection(2) = -Y; subSection(4) = Y;
    %
    % where Y is the radius of the first surface.
    
    leftX  = subSection(1); lowerY = subSection(2);
    rightX = subSection(3); upperY = subSection(4);
    
    % Make the rectangular samples
    firstApertureRadius = obj.surfaceArray(1).apertureD/2;
    xSamples = linspace(firstApertureRadius *leftX, firstApertureRadius*rightX, obj.apertureSample(1));
    ySamples = linspace(firstApertureRadius *lowerY, firstApertureRadius*upperY, obj.apertureSample(2));
    [X, Y] = meshgrid(xSamples,ySamples);
    
    if(randJitter)
        % Add random jitter to the positions (x,y) on the front surface.
        % Uniform distribution.  Scales to plus or minus half the sample width
        X = X + (rand(size(X)) - .5) * (xSamples(2) - xSamples(1));
        Y = Y + (rand(size(Y)) - .5) * (ySamples(2) - ySamples(1));
    end
    aGrid.X = X(:); aGrid.Y = Y(:);
end

% Set Z to the position of the front surface
nPts    = numel(aGrid.X(:));
aGrid.Z = repmat(obj.get('lens thickness'),[nPts,1]);

%debug check
%
% ieFigure; plot(aGrid.X, aGrid.Y, 'o');

end
