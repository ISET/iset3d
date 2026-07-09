function camera = estimatePSF(camera, varargin)
% Estimate the psfCamera point spread function (PSF)
%
% Syntax:
%   camera = psfCamera.estimatePSF(camera)
%
% Description:
%  The psf camera has a cell array of point sources, a lens, and a film
%  surface.  This method calculates the images from each of the points in
%  the psfCamera object and saves the result by calling 'recordOnFilm',
%  a ray object method.
%
% Inputs:
%  obj:          psfCameraC
%  jitterFlag:   Jitter position of rays, not regularly sample, first start
%                with rays on a grid, then jitter the positions
%  subsection:   Only allow rays through a subsection of the front aperture
%  diffractionMethod: Two methods are implemented, Huygens and HURB,
%                     Heisenburg uncertainty ray bending.
%  rtType:            Realistic or ideal
%
% You can visualize the point spread using the optical image derived from
% the psfCamera
%
%   oi = psfCamera.oiCreate(varargin);
%
% AL/BW Vistasoft Team, Copyright 2014
% ZLY, 2020
%
% See also:
%  s_isetauto.m

%% Parse inputs
p = inputParser;

varargin = ieParamFormat(varargin);

p.addRequired('camera');
p.addParameter('jitterflag', false, @islogical);
p.addParameter('subsection', []);
p.addParameter('rttype', 'realistic', @ischar);
p.addParameter('nlines', 0);
p.addParameter('visualize',false);

validOpt = {'HURB','huygens'};
p.addParameter('diffractionmethod', 'HURB', @(x)(ismember(x,validOpt)));

p.parse(camera, varargin{:});

camera = p.Results.camera;
jitterFlag = p.Results.jitterflag;
subsection = p.Results.subsection;
diffractionMethod = p.Results.diffractionmethod;
rtType = p.Results.rttype;
nLines = p.Results.nlines;
vis = p.Results.visualize;

%%
if isequal(diffractionMethod, 'HURB') 
    % This is the main and typical path
    
    % There may be more than one point in the camera structure.
    for ii=1:length(camera.pointSource)
        
        % (pointSource, ppsfCFlag, jitterFlag, rtType, subSection, depthTriangles)
        % subsection specifies a field eight.
        camera.rays = camera.lens.rtSourceToEntrance(camera.pointSource{ii}, jitterFlag, rtType, subsection);
        
        % Duplicate the existing rays for each wavelength
        % Note that both lens and film have a wave, sigh.
        % obj.rays.expandWavelengths(obj.film.wave);
        camera.rays.expandWavelengths(camera.lens.wave);
        
        %lens intersection and raytrace
        [h, samps] = camera.lens.rtThroughLens(camera.rays, nLines,'visualize',vis);
        % title('Point source to final surface')
        %         obj.lens.rays.aExitInt.XY = origin
        %         obj.lens.rays.aExitInt.XY = direction
        
        % intersect with "film" and add to film
        if isempty(h)
            camera.rays.recordOnFilm(camera.film, 'nLines',nLines,'visualize',vis);
        else
            camera.rays.recordOnFilm(camera.film, 'nLines',nLines,...
                    'fig', h, 'samps', samps);
        end

    end
    
elseif isequal(diffractionMethod, 'huygens') && camera.lens.diffractionEnabled
    % This path and what is computed here is no longer clear to me (BW).
    %

    % Trace from the point source to the entrance aperture of the
    % multi-element lens
    wbar = waitbar(0,'Huygens wavelength and job');
    
    lensMode = true;  %set false if ideal lens focused at infinity
    
    % Get up to the entrance aperture
    camera.lens.diffractionEnabled = false;
    camera.rays = camera.lens.rtSourceToEntrance(camera.pointSource,jitterFlag,rtType,subsection);
    
    % Duplicate the existing rays for each wavelength
    % Note that both lens and film have a wave, sigh.
    % obj.rays.expandWavelengths(obj.film.wave);
    camera.rays.expandWavelengths(camera.lens.wave);
    
    %lens intersection and raytrace
    camera.lens.rtThroughLens(camera.rays, nLines, rtType);
    
    % Something like this?  Extend the rays to the film plane?
    % if nLines > 0; obj.rays.draw(obj.film); end
    
    % intersect with "film" and add to film
    % obj.rays.recordOnFilm(obj.film, nLines);
    
    % Huygens ray-trace portion (PUT THIS IN A FUNCTION)
    % use a preset sensor size and pitch for now ... somehow integrate this
    % with PSF camera later
    binSize = [camera.film.size(1)/camera.film.resolution(1) camera.film.size(2)/camera.film.resolution(2)] .* 1e6;
    numPixels = [camera.film.resolution(1) camera.film.resolution(2)];
    imagePlaneDist = camera.film.position(3) * 10^6;
    
    % For each wavelength...
    nWave = length(camera.lens.wave);
    for wIndex = 1:nWave
        %estimated that the width of the 1st zero of airy disk will be .0336
        apXGridFlat = camera.rays.origin(:,1) * 10^6; %convert to nm
        apYGridFlat = camera.rays.origin(:,2) * 10^6;
        
        apXGridFlat = apXGridFlat(camera.rays.waveIndex == wIndex);
        apYGridFlat = apYGridFlat(camera.rays.waveIndex == wIndex);
        
        apXGridFlat = apXGridFlat(~isnan(apXGridFlat));
        apYGridFlat = apYGridFlat(~isnan(apYGridFlat));
        
        lambda = camera.lens.wave(wIndex);
        
        numApertureSamplesTot = length(apXGridFlat);
        
        % ieFigure;
        % plot(apXGridFlat, apYGridFlat, 'o');  %plot the aperture samples
        
        % Create sensor grid
        % These are the locations on the sensor
        endLocations1DX = linspace(-numPixels(1)/2 * binSize(1), numPixels(1)/2 * binSize(1), numPixels(1));
        endLocations1DY = linspace(-numPixels(2)/2 * binSize(2), numPixels(2)/2 * binSize(2), numPixels(2));
        [endLGridX, endLGridY] = meshgrid(endLocations1DX, endLocations1DY);
        
        %flatten the meshgrid
        endLGridXFlat = endLGridX(:);
        endLGridYFlat = endLGridY(:);
        endLGridZFlat = ones(size(endLGridYFlat)) * imagePlaneDist;
        
        intensity = zeros(numPixels(1), numPixels(2), length(camera.lens.get('wave')));
        
        % lensMode is set true above.  So ... this needs to be fixed.
        if (lensMode)
            initialD = camera.rays.distance(~isnan(camera.rays.distance));
        else
            initialD = zeros(numApertureSamplesTot, 1);
        end
        
        intensityFlat = zeros(numPixels);
        intensityFlat = intensityFlat(:);
        jobInterval = 10000;
        nJobs = ceil(numApertureSamplesTot/jobInterval);
        
        % I think AL proposes dividing the calculation into independent
        % jobs for parallel computing.  This is preparation for that.
        %
        % Split aperture into segments and do bsxfun on that, then combine later.
        % This can be parallelized later (AL)
        for job = 1:nJobs
            waitbar((((wIndex-1)*nJobs) + job)/(nWave*nJobs),wbar);
            
            fprintf('job %i of %i total\n',job,nJobs)
            apXGridFlatCur = apXGridFlat((job-1) * jobInterval + 1:min(job * jobInterval, numApertureSamplesTot));
            apYGridFlatCur = apYGridFlat((job-1) * jobInterval + 1:min(job * jobInterval, numApertureSamplesTot));
            
            
            xDiffMat = bsxfun(@minus, endLGridXFlat, apXGridFlatCur');
            yDiffMat = bsxfun(@minus, endLGridYFlat, apYGridFlatCur');
            zDiffMat = repmat(endLGridZFlat, [1, length(apXGridFlatCur)]);
            
            initialDCur = initialD(((job-1) * jobInterval + 1:min(job * jobInterval, numApertureSamplesTot)));
            initialDMat = repmat(initialDCur', [length(endLGridXFlat), 1]);
            
            expD = exp(2 * pi * 1i .* ((sqrt(xDiffMat.^2 + yDiffMat.^2 + zDiffMat.^2) + initialDMat * 1e6)/lambda));
            intensityFlat = sum(expD, 2) + intensityFlat;
        end
        
        intensityFlat = 1/lambda .* abs(intensityFlat).^2;
        
        % plot results
        intensity1Wave = reshape(intensityFlat, size(intensity, 1), size(intensity, 2));
        camera.film.image(:,:,wIndex) = intensity1Wave;
        
    end
    
    camera.lens.diffractionEnabled = true;
    close(wbar);
    %End Huygens ray-trace
end

if ((isnumeric(nLines) && nLines) || (isstruct(nLines) && nLines.numLines)) && vis
    
    %% Set Focal point, principle point and nodal point
    hold on
    
    % Image focal point
    p1 = pointVisualize(camera.lens, 'image focal point', 'p size', 10, 'color', 'b');
    % Image principle point
    p2 = pointVisualize(camera.lens, 'image principal point', 'p size', 10, 'color', 'g');
    % Image nodal point
    p3 = pointVisualize(camera.lens, 'image nodal point', 'p size', 5, 'color', 'r');
    legend([p1 p2 p3],...
        {'Image focal point', 'Image principal point', 'Image nodal point'});
    
    title(sprintf('Lens: %s %.1f',camera.lens.get('name')));
end



end
