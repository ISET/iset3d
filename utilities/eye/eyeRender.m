function [oi, cMosaic] = eyeRender(thisSE, options)
%EYERENDER Wrapper for commonly called human eye model rendering functions
%  Group a few common humanEye related processing steps into a function
%
% Examples:
%
% D. Cardinal, Stanford University, 2022

    arguments
        thisSE;
        options.dockerWrapper = [];
        options.fovScale = .1; % how much to reduce the FOV
        options.show = false; %display output in windows
        options.numThreads = 0; % use the default unless the user sets a value
        options.emGenSequence = 50; 
    end

    if piCamBio
        Warning("Can't use eye rendering without ISETBio");
        return
    else
        if ~isempty(options.dockerWrapper)
            oi = thisSE.render('docker wrapper',options.dockerWrapper);
        else
            oi = thisSE.render();
        end
        if options.show, oiWindow(oi); end

        % Mod for faster parpool startup
        poolobj = gcp('nocreate');
        if isempty(poolobj)
            if options.numThreads > 0
                parpool('Threads', options.numThreads);
            else
                parpool('Threads'); % let it use its default
            end
        end

        cMosaic = coneMosaic;   % Create cone mosaic.  Many parameters can be set.

        % Mosaics are expensive so make a smaller one
        cMosaic.setSizeToFOV(options.fovScale * oiGet(oi, 'fov'));
        cMosaic.emGenSequence(options.emGenSequence);
    
        cMosaic.compute(oi);    % Compute the absorptions from the optical image, oi
        cMosaic.computeCurrent; % Compute the photocurrent using the attached outerSegment model

        if options.show, cMosaic.window; end   % An interactive window to view the mosaic, absorptions and current

    end
end



