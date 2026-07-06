function obj = recordOnFilm(obj, film, varargin)
% Records the rays on the film surface
%
% Syntax:
%  rays.recordOnFilm(obj, film, varargin)
%
% Brief description:
%  The rays from the final lens element are transformed to the film
%  surface.  They are binned into the pixels at the film resolution to
%  create an image in the film.image slot.
%
% Inputs
%   obj:    A rayC object
%   film:   The filmC object can be either a plane or a spherical surface
%
% Optional key/value pairs
%   nLines: number of lines to draw for the illustration. If 0, then no
%           lines are drawn
%   fig:    Matlab.ui.figure where the lines are drawn.  Default is gcf.
%
%
% AL Copyright Vistasoft Team, 2014

%%
varargin = ieParamFormat(varargin);

p = inputParser;

p.addRequired('obj',@(x)(isa(x,'rayC')));
p.addRequired('film',@(x)(isa(x,'filmC')));
p.addParameter('nLines',0);
p.addParameter('fig',[],@(x)(isa(x,'matlab.ui.Figure')));
p.addParameter('samps', [], @isvector);
p.addParameter('visualize',true);

p.parse(obj,film,varargin{:});
nLines = p.Results.nLines;
h      = p.Results.fig;
samps  = p.Results.samps;
vis    = p.Results.visualize;

% There are cases we don't want a figure to pop up.  Need to figure out how
% to suppress.  If we can do it without another parameter, that would be
% good.
if isempty(h) && (nLines > 0) && vis, h = ieFigure; end

% We need to separate out the case of plenoptic rays and standard rays

%% Remove dead rays
liveRays = obj.get('live rays');

if isempty(liveRays), warning('No rays at exit aperture'); return; end

%% Get existing samples
if ~isempty(samps)
    samps = find(ismember(liveRays.origin, obj.origin(samps,:), 'rows') & ...
        ismember(liveRays.direction, obj.direction(samps,:), 'rows'));
end
%% Calculate intersection point of the rays at the sensor z-plane

% Save original origin points for plotting.
oldOrigin  = liveRays.origin;

% Figure out the position of the rays on the film z-plane
liveRays.origin = rayIntersection(liveRays,film.position(3));


%% Plot ray-trace
if (isnumeric(nLines) && nLines > 0 || isstruct(nLines) && nLines.numLines > 0) && vis
    raysVisualize(oldOrigin,liveRays.origin,'nLines',nLines,'fig',h,...
        'samps', samps);
    film.draw;
    xlabel('mm'); ylabel('mm');
end

%% This section calculates imagePixel.position of the rays
%
% The computation is managed separately for the planar film (typical) and
% spherical case.
%
% The ray positions are still in millimeters after this section.

if(isa(film, 'filmSphericalC'))
    % Project spherical film
    
    sensorRadius = film.radius;
    sensorCenter = film.get('sphericalCenter');
    intersectPosition = liveRays.sphereIntersect(sensorCenter,sensorRadius);
    
    % Convert intersection point into spherical coordinate system...
    x = intersectPosition(:,1);
    y = intersectPosition(:,2);
    z = intersectPosition(:,3) - sensorCenter(3);
    r = sqrt(x.^2 + y.^2 + z.^2);
    theta = atan(x./z);
    phi = asin(y./r);
    
    imagePixel.position = [phi * abs(sensorRadius) theta * abs(sensorRadius) ];
    
    % Not sure why these are always shown.  Consider making an option.
    if vis
        ieFigure; hist(theta);
        ieFigure; hist(phi);
    end

    
elseif(isa(film, 'filmC'))
    % When the filmC is the plane, this ....
    intersectPosition = liveRays.origin;
    
    %imagePixel is the pixel that will gain a photon due to the traced ray
    imagePixel.position = [intersectPosition(:,2) intersectPosition(:, 1)];
    imagePixel.position = real(imagePixel.position); % Add error handling for this
else
    error('Invalid film type detected.');
end

%% Count the rays into row/col bins on the film
%
% This makes an image histogram of the ray positions on the film.  I think
% we have other imageHistogram functions, and they might be used here.

% At this point the positions are recorded in millimeters at the film.
%  imagePixel.position(:,1) is the x-value on the film in millimeters
%  and (:,2) is the y-value on the film.
%
% ieNewGraphWin; histogram(imagePixel.position(:,1),100);

% Count the number of rays incident on the film at different pixel
% positions.  This makes a histogram of the rays within each of the
% bins form the film size and number of film resolution.
%
% MAKE THIS A FUNCTION WITH COMMENTS in utility, say rays2image
%
% This code takes the locations specified in millimeters and converts
% them to a film location specified in terms of the film pixels (size and
% resolution).

% Position  is in millimeters
% film.size is in millimeters
% film.resolution is the number of samples across the film
sampleSpacing = film.size ./ film.resolution;
nPositions    = size(imagePixel.position,1);
imageMiddle   = -film.position(2:-1:1) / sampleSpacing(2) + (film.resolution(2:-1:1) + 1) ./2;

% Position in millimeters on the film is converted to pixel location in the
% (row,col) film image by
%
%    Position / sampleSpacing + middlePixel
%
% So, something at (0,0) goes to the middlePixel.
% Example: Suppose the film is size is 0.5 mm, and the ray is -0.25 mm,
% then the position in the image is less than the middle pixel.
%
imagePixel.position = ...
    round(imagePixel.position / sampleSpacing(2) + ...
    repmat(imageMiddle, [nPositions 1]));
   
    imagePixel.wavelength = liveRays.get('wavelength');
    
    convertChannel = liveRays.waveIndex;
    
    %wantedPixel is the pixel that we wish to add 1 photon to pixel to update
    wantedPixel = [imagePixel.position(:, 1) imagePixel.position(:,2) convertChannel];
    
    recordablePixels = ...
        and(and(and ...
        (wantedPixel(:, 1) >= 1,  (wantedPixel(:,1) <= film.resolution(1))), ...
        (wantedPixel(:, 2) > 1)), (wantedPixel(:, 2) <= film.resolution(2)));
    
    % Remove the nonrecordable pixels
    wantedPixel = wantedPixel(recordablePixels, :);
    % ieNewGraphWin;
    % plot(wantedPixel(:,1,:),wantedPixel(:,2,:),'o');
    
    % Correct for y coordinates
    wantedPixel(:, 1) =  film.resolution(1) + 1 - wantedPixel( :, 1);
    
    %make a histogram of wantedPixel in anticipation of adding
    %to film
    %  [count bins] = hist(single(wantedPixel));
    %  [count bins] = hist(single(wantedPixel), unique(single(wantedPixel), 'rows'));
    uniqueEntries =  unique(single(wantedPixel), 'rows');
    
    % Serializes the unique entries.
    %
    % I had an error here once where the wavelength in the uniqueEntries
    % was 7 but there were only 4 wavelength dimensions in the film image.
    % (BW).
    serialUniqueIndex = sub2ind(size(film.image), uniqueEntries(:,1), uniqueEntries(:,2), uniqueEntries(:,3));
    serialUniqueIndex = sort(serialUniqueIndex);
    
    serialWantedPixel = sub2ind(size(film.image), single(wantedPixel(:,1)), single(wantedPixel(:,2)), single(wantedPixel(:,3)));
    
    % Special cases for lots of photons, one photon, or no photons
    if (isscalar(serialUniqueIndex(:)))
        % special case for length 1.  For some reason, hist has issues with
        % length 1.
        serializeFilm = film.image(:);
        %
        % When there is only 1 bin, it doesn't matter how many photons, so just add one
        serializeFilm(serialUniqueIndex) = serializeFilm(serialUniqueIndex) + 1;
        film.image = reshape(serializeFilm, size(film.image));
        
    elseif(~~any(serialUniqueIndex(:) > 0, "all"))
        
        % Make a histogram count of something.  Looks like AL counts the
        % number of rays using hist() and then adds that count to a
        % location in the film image.

        % [countEntriesTMP] = hist(serialWantedPixel, serialUniqueIndex);
        % edges = [serialUniqueIndex - 0.5; serialUniqueIndex(end) + 0.5];
        % Adjust edges so histcounts returns counts aligned with serialUniqueIndex bins:
        % construct edges between consecutive unique indices (midpoints) and extend at ends
        midpoints = (serialUniqueIndex(1:end-1) + serialUniqueIndex(2:end)) / 2;
        edges = [serialUniqueIndex(1) - 0.5; midpoints; serialUniqueIndex(end) + 0.5];
        countEntries = histcounts(serialWantedPixel, edges);

        %serialize the film, then the indices, then add by countEntries
        serializeFilm = film.image(:);
        
        % Add the count to the serialized film and then reshape and place
        % in the film image.
        serializeFilm(serialUniqueIndex) = serializeFilm(serialUniqueIndex) + countEntries(:);
        film.image = reshape(serializeFilm, size(film.image));
    else
        warning('No photons collected on film!');
    end
    
    
end
