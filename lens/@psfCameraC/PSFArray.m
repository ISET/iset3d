function PSF = PSFArray(obj,pointSources)
% Create the pointspread functions (PSF) at field heights and depths
%
%   PSF = psfCamera.PSFArray(pointSources)
%
%  WORK REMAINS TO BE DONE HERE
%
% The point sources define a set of depths and field heights where we will
% calculate the point spread function.
%
% The psf camera is initiated with a relatively large and low resolution
% film.  This routine figures out where the each of the points will be
% imaged on the film, and then makes a higher resolution image of the point
% spread at that field height.
%
% The UNITS ARE NOT PROPERLY CALIBRATED HERE YET.  IT SHOULD BE THAT THE
% PSF SAMPLE POINTS ARE RETURNED WITH REAL UNITS, SAY EVERY XX MM.
%
% A point spread function is an image matrix over (x,y).  They are
% indexed by field height, depth, and wavelength.  So, the point spread
% function for wavelength, depth, and field height is
%
%   PSF(:,:,ww,dd,ff)
%
% Inputs:
%   obj:  psfCamera
%   pointSources:  These define the field heights and depths of the PSFs
%
% The array of PSFs can be applied in the slow forward calculation.  See
% p_renderOiMatlabToolFull.m, for an example. 
%
% AL/BW Vistasoft 2015

%% Parameters

nLines     = 0;     % Don't draw
jitterFlag = true;  % Do jitter

% Properties of the points
nFH    = size(pointSources,1);
nDepth = size(pointSources,2);
fPosition = obj.film.position;

% Properties of the film
fZ   = obj.film.position(3);

% Store the original film size
fSize = obj.film.size; 
fRes  = obj.film.resolution;

% Film resolution (final render, small film size)
% For now - the width of the high quality sensor is set manually - this
% should be automated in the future.  Maybe the new width is 1/5th of the
% original, but the sample density per unit width is 2x?
highRes = 101;  % Number of samples.  So, this is 100 microns per sample?
newSize = 10;   % Film size in mm

% Initial lens properties
wave     = obj.lens.wave;
nWave    = obj.lens.get('nwave');
lSamples = obj.lens.apertureSample;

% High lens sampling resolution
nSamplesHQ = 801;   % Could be 100*lSamples?

% PSF output
PSF = zeros(highRes, highRes, nWave, nDepth, nFH);



%% Compute PSFs

wbar = waitbar(0,sprintf('Creating %i point spreads for %i wavelengths',numel(pointSources),nWave));
cnt = 0;

% ii = 1; dd = 1;  % Debugging
for ii = 1:nFH
    for dd = 1:nDepth
        waitbar(cnt/(nDepth*nFH),wbar);
        
        % Rebuild psf camera this specific point source
        %         psfCamera = psfCameraC('lens', lens, ...
        %             'film', film, ...
        %             'pointsource', pointSources{ii,dd});
        obj.pointSource = pointSources{ii,dd};
        
        % What happens to each of the wavelengths?
        obj.estimatePSF();       
        % oi = obj.oiCreate;
        
        fprintf('Field height %i\nDepth %i\n',ii,dd);
        centroid = obj.get('image centroid');
        fprintf('Centroid %.2f, %.2f\n',centroid.X,centroid.Y);
        
        % Create this method to match the older script
        % centroid = psfCamera.centroid(oi)
        % [centroid, oi] = psfCamera.centroid();
        % vcAddObject(oi); oiWindow;
        
        % Debugging
        %         disp([ii dd])
        %         disp(centroid)
        
        % Render image using new center position and width and higher resolution
        obj.film.position = [centroid.X, centroid.Y, fZ];
        obj.film.size = [newSize newSize];
        obj.film.resolution = [highRes highRes nWave];
        obj.film.clear;
        
        obj.lens.apertureSample = ([nSamplesHQ nSamplesHQ]);

        % Use more samples in the lens aperture to produce a high quality psf.
        % NOTE:  Changing the number of samples also changes the oi size.
        % This isn't good.  We need to change the sampling density without
        % changing the size.
        
        %         psfCamera = psfCameraC('lens', lens, ...
        %             'film', film, ...
        %             'pointsource', pointSources{ii,dd});
        
        obj.estimatePSF('n lines', nLines, 'jitter flag', jitterFlag);
        oi = obj.oiCreate();  % vcAddObject(oi); oiWindow;
        
        % Extract the point spread data
        for ww = 1:nWave
            PSF(:,:,ww,dd,ii) = oiGet(oi, 'photons',wave(ww));
        end
        
                
        % Reset film and lens parameters to initial values.  These are
        % changed below. These are usually sent in for a low resolution,
        % wide field of view, just to figure out where the center of the
        % point is.  This could all be put at the end of the loop, since
        % these are the original values anyway.
        obj.film.position = fPosition;
        obj.film.size = fSize;
        obj.film.resolution = fRes;
        obj.film.clear;
        
        obj.lens.apertureSample = lSamples;
        
        % Update wait bar counter
        cnt = cnt+1;
    end
end
delete(wbar)

end


