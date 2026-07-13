function [mtfData, oiList, recipeList] = piCalculateSlantedEdgeMTF(varargin)
% Calculate lens MTF from a rendered slanted-edge target using ISO12233.
%
% Syntax
%   mtfData = piCalculateSlantedEdgeMTF('camera',camera,'filmwidth',filmwidthMM)
%   mtfData = piCalculateSlantedEdgeMTF('oi',oi)
%   [mtfData, oiList, recipeList] = piCalculateSlantedEdgeMTF(...)
%
% Brief
%   Render the ISET3D slanted-edge scene through a PBRT camera/lens and
%   estimate the modulation transfer function using ISETCam's ISO12233
%   implementation. An existing OI can be supplied to run the analysis
%   without rendering.
%
% Inputs
%   camera    - PBRT camera struct, usually from piCameraCreate.
%   filmwidth - Film diagonal in millimeters.
%
% Optional key/value pairs
%   oi          - Existing optical image or cell array of optical images.
%   distances   - Chart distances from film, in millimeters.
%   resolution  - Scalar or [x y] render resolution. Default 1024.
%   rays        - Rays per pixel. Default 64.
%   roifraction - Central image fraction analyzed by ISO12233. Default 0.65.
%   plot        - true for ISO12233 plots, false for no plots. Default false.
%   quiet       - Suppress render progress messages. Default false.
%
% Outputs
%   mtfData    - ISO12233 result struct array with distance/film metadata.
%   oiList     - Cell array of analyzed OIs.
%   recipeList - Cell array of render recipes, empty for analysis-only mode.
%
% See also
%   piCalculateMTF, ISO12233, piRecipeCreate, piRender

varargin = ieParamFormat(varargin);

p = inputParser;
p.addParameter('camera', [], @(x)(isempty(x) || isstruct(x)));
p.addParameter('filmwidth', [], @(x)(isempty(x) || isnumeric(x)));
p.addParameter('oi', [], @(x)(isempty(x) || isstruct(x) || iscell(x)));
p.addParameter('distances', 1000, @isnumeric);
p.addParameter('resolution', 1024, @isnumeric);
p.addParameter('rays', 64, @isnumeric);
p.addParameter('roifraction', 0.65, @(x)(isscalar(x) && x > 0 && x <= 1));
p.addParameter('plot', false, @(x)(islogical(x) || ischar(x) || isstring(x)));
p.addParameter('quiet', false, @islogical);
p.parse(varargin{:});

camera = p.Results.camera;
filmWidthMM = p.Results.filmwidth;
oiInput = p.Results.oi;

if isempty(oiInput) && isempty(camera)
    error('piCalculateSlantedEdgeMTF:CameraRequired', ...
        'A camera is required unless an existing OI is supplied.');
end
if isempty(oiInput) && isempty(filmWidthMM)
    error('piCalculateSlantedEdgeMTF:FilmWidthRequired', ...
        'A filmwidth value in millimeters is required when rendering.');
end

plotOptions = localPlotOptions(p.Results.plot);
filmResolution = localFilmResolution(p.Results.resolution);

if isempty(oiInput)
    distancesFromFilmMM = p.Results.distances(:)';
    oiList = cell(1, numel(distancesFromFilmMM));
    recipeList = cell(1, numel(distancesFromFilmMM));

    for ii = 1:numel(distancesFromFilmMM)
        if ~p.Results.quiet
            fprintf('Render slanted-edge chart position %d\n',ii);
        end

        thisR = piRecipeCreate('slantededge','quiet',true);
        thisR = localSetChartDistance(thisR, 1e-3*distancesFromFilmMM(ii));
        thisR.set('camera', camera);
        thisR.set('film resolution', filmResolution);
        thisR.set('rays per pixel', p.Results.rays);
        thisR.set('film diagonal', filmWidthMM);

        piWrite(thisR);
        oiList{ii} = piRender(thisR,'render type','radiance');
        oiList{ii}.name = sprintf('Slanted-edge chart distance from film: %.3f m', ...
            1e-3*distancesFromFilmMM(ii));
        recipeList{ii} = thisR;
    end
else
    if iscell(oiInput)
        oiList = oiInput;
    else
        oiList = {oiInput};
    end
    recipeList = cell(size(oiList));
    distancesFromFilmMM = nan(1,numel(oiList));
    if isempty(filmWidthMM), filmWidthMM = nan; end
end

mtfData = struct([]);
for ii = 1:numel(oiList)
    thisMTF = localAnalyzeOI(oiList{ii}, p.Results.roifraction, plotOptions);
    thisMTF.distanceFromFilmMM = distancesFromFilmMM(ii);
    thisMTF.filmWidthMM = filmWidthMM;

    if isempty(mtfData)
        mtfData = thisMTF;
    else
        mtfData(ii) = thisMTF;
    end
end

end

function thisR = localSetChartDistance(thisR,distanceFromFilmM)
% The slanted-edge chart is near z=0. Move the camera relative to it.

thisR.lookAt.from = [0 0 -distanceFromFilmM];
thisR.lookAt.to = [0 0 1];
thisR.lookAt.up = [0 1 0];

end

function filmResolution = localFilmResolution(resolution)
if isscalar(resolution)
    filmResolution = round([resolution resolution]);
elseif numel(resolution) == 2
    filmResolution = round(resolution(:)');
else
    error('piCalculateSlantedEdgeMTF:BadResolution', ...
        'Resolution must be a scalar or a two-element vector.');
end
end

function plotOptions = localPlotOptions(plotValue)
if islogical(plotValue)
    if plotValue
        plotOptions = 'all';
    else
        plotOptions = 'none';
    end
else
    plotOptions = char(plotValue);
end
end

function mtfData = localAnalyzeOI(oi, roiFraction, plotOptions)
if ~isstruct(oi) || ~isfield(oi,'type') || ~isequal(oi.type,'opticalimage')
    error('piCalculateSlantedEdgeMTF:BadOI', ...
        'The oi input must be an ISET optical image.');
end

barImage = oiGet(oi,'illuminance');
if isempty(barImage)
    oi = oiSet(oi,'mean illuminance',1);
    barImage = oiGet(oi,'illuminance');
end

[nRows, nCols, ~] = size(barImage);
roiRows = max(16, min(nRows, round(nRows*roiFraction)));
roiCols = max(16, min(nCols, round(nCols*roiFraction)));
rowStart = floor((nRows - roiRows)/2) + 1;
colStart = floor((nCols - roiCols)/2) + 1;
rowEnd = rowStart + roiRows - 1;
colEnd = colStart + roiCols - 1;

barROI = barImage(rowStart:rowEnd, colStart:colEnd, :);
deltaXMM = localSampleSpacingMM(oi);

[mtfData, fitme, esf, h] = ISO12233(barROI, deltaXMM, [], plotOptions);
if isempty(mtfData)
    error('piCalculateSlantedEdgeMTF:ISOFailed', ...
        'ISO12233 did not return MTF data for the selected OI region.');
end

mtfData.rect = [colStart rowStart roiCols-1 roiRows-1];
mtfData.esf = esf;
mtfData.fitme = fitme;
mtfData.win = h;
if isfield(mtfData,'mtf') && ~isempty(mtfData.mtf)
    dc = mtfData.mtf(1,:);
    dc(dc == 0) = 1;
    mtfData.mtf = mtfData.mtf ./ dc;
end

end

function deltaXMM = localSampleSpacingMM(oi)
try
    sampleSpacingM = oiGet(oi,'sample spacing');
    if numel(sampleSpacingM) > 1
        deltaXMM = sampleSpacingM(2)*1e3;
    else
        deltaXMM = sampleSpacingM(1)*1e3;
    end
catch
    widthMM = oiGet(oi,'width','mm');
    deltaXMM = widthMM/oiGet(oi,'cols');
end

if isempty(deltaXMM) || ~isfinite(deltaXMM) || deltaXMM <= 0
    error('piCalculateSlantedEdgeMTF:BadSampleSpacing', ...
        'Could not determine a positive OI sample spacing in millimeters.');
end

end
