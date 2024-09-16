function [object, results, outputHDR] = piAIdenoise(object,varargin)
% A denoising method (AI based) that applies to scene photons
%
% Synopsis
%   [object, results] = piAIdenoise(object)
%
% Inputs
%   object:  An ISETCam scene or oi
%
% Optional key/value
%   quiet     - Do not show the waitbar
%   useNvidia - try to use GPU denoiser if available
%   batch     - write & read all channels at once
%
% Returns
%   object: The ISETCam object (scene or optical image) with the photons
%           denoised 
%
% Description
%  Runs executable for the Intel denoiser in the oidn_pth/bin directory. %
%  This is a Monte Carlo denoiser based on a trained model from intel open
%  image denoise: 'https://www.openimagedenoise.org/'.
%
%  The executable must be installed on your machine.  If we do not find it,
%  we try to download it using oidn_fetch.
%
%   You can download versions for various types of architectures from the
%   URL
%
%    https://www.openimagedenoise.org/downloads.html
%
% The directory location is
%
%   fullfile(piRootPath, 'external', oidn_pth, 'bin');
%
% where oidn_pth will be something like oidn-2.2.2.arm64.macos, or
% oidn-2.2.2.x86.macos, depending on your Mac.  Or something else if it is
% a Windows machine.
%
% We have used the denoiser to clean up PBRT rendered images when we only
% use a small number of rays.  We use it for show, not for accurate
% simulations of scene or oi data.
%
% We may embed this denoiser in the PBRT docker image that can integrate
% with PBRT.  We are also considering the denoiser that is part of imgtool,
% distributed with PBRT.
%
% See also
%   sceneWindow, oiWindow

%% Parse
p = inputParser;
p.addRequired('object',@(x)(isequal(x.type,'scene') || isequal(x.type,'opticalimage') ));
p.addParameter('quiet',true,@islogical);

% Try using Nvidia GPU de-noiser
p.addParameter('useNvidia',false,@islogical);
p.addParameter('keepHDR',false); % return the EXR file

p.addParameter('batch',false);
p.addParameter('interleave',false);

p.parse(object,varargin{:});

quiet = p.Results.quiet;
keepHDR = p.Results.keepHDR;

doBatch = p.Results.batch;

%% Set up the denoiser path information and check
% get the latest release for oidn denoiser
persistent oidn_dir;
if isempty(oidn_dir)
    oidn_dir = oidn_fetch('OpenImageDenoise', 'oidn');
end
if ~p.Results.useNvidia
    oidn_pth  = fullfile(string(oidn_dir), 'bin');
else
    if ispc
        oidn_pth = fullfile(piRootPath, 'external', 'nvidia_denoiser.windows');
    else
        warning("Don't know if we have a binary yet\n");
    end
end

if ~isempty(oidn_pth) && ~isfolder(oidn_pth)
    error('Could not find the directory:\n%s',oidn_pth);
end

tic; % start timer for deNoise

%%  Get the photon data

switch object.type
    case 'opticalimage'
        wave = oiGet(object,'wave');
        photons = oiGet(object,'photons');
        [rows,cols,chs] = size(photons);
    case 'scene'
        wave = sceneGet(object,'wave');
        photons = sceneGet(object,'photons');
        [rows,cols,chs] = size(photons);
    otherwise
        error('Should never get here.  %s\n',object.type);
end

if p.Results.useNvidia
    outputTmp = fullfile(piDirGet('local'),sprintf('tmp_input_%05d%05d.exr',randi(1000),randi(1000)));
    DNImg_pth = fullfile(piDirGet('local'),sprintf('tmp_dn_%05d%05d.exr',randi(1000),randi(1000)));
elseif doBatch
    outputTmp = {};
    DNImg_pth = {};
    for ii = 1:chs
        % see if we can use only the channel number
        % would be an issue if we do multiple renders in parallel
        outputTmp{ii} = fullfile(piDirGet('local'),sprintf('tmp_input-%d.pfm',ii));
        DNImg_pth{ii} = fullfile(piDirGet('local'),sprintf('tmp_dn-%d.pfm',ii));
    end
else
    outputTmp = fullfile(piDirGet('local'),sprintf('tmp_input_%05d%05d.pfm',randi(1000),randi(1000)));
    DNImg_pth = fullfile(piDirGet('local'),sprintf('tmp_dn_%05d%05d.pfm',randi(1000),randi(1000)));
end

% Empty array to store results
newPhotons = zeros(rows, cols, chs);

%% Run the Denoiser binary
% Show waitbar if desired
if ~quiet, h = waitbar(0,'Denoising multispectral data...','Name','Intel or Nvidia denoiser'); end

channels = 1:chs;

if ~doBatch
    for ii = channels
        % For every channel, get the photon data, normalize it, and
        % denoise it
        img_sp(:,:,1) = photons(:,:,ii)/max2(photons(:,:,ii));
        img_sp(:,:,2) = photons(:,:,ii)/max2(photons(:,:,ii));
        img_sp(:,:,3) = photons(:,:,ii)/max2(photons(:,:,ii));

        if p.Results.useNvidia
            exrwrite(img_sp, outputTmp);
            cmd  = fullfile(oidn_pth,  ['Denoiser --hdr -i ', outputTmp,' -o ',DNImg_pth]);
        else
            % Write it out into a temporary file
            % For the Intel Denoiser,need to duplicate the channels
            % for doBatch want to write out ALL files
            writePFM(img_sp, outputTmp);

            % construct the denoise command, can also use -d and -q if desired
            if strcmpi(computer,'maca64')
                % ARM
                cmd = fullfile(oidn_pth, ['oidnDenoise --device metal --hdr ',outputTmp,' -o ',DNImg_pth]);
            else
                % Intel
                cmd  = fullfile(oidn_pth, ['oidnDenoise --hdr ',outputTmp,' -o ',DNImg_pth]);
            end
        end

        % Run the executable.
        %tic
        [status, results] = system(cmd);
        %toc
        if status, error(results); end

        % Read the denoised data and scale it back up
        if p.Results.useNvidia
            DNImg = exrread(DNImg_pth);
        else
            DNImg = readPFM(DNImg_pth);
        end

        newPhotons(:,:,ii) = DNImg(:,:,1).* max2(photons(:,:,ii));
    end

    if ~quiet, waitbar(ii/chs, h,sprintf('Spectral channel: %d nm \n', wave(ii))); end
else % batch alternative


    for ii = channels
        % For every channel, get the photon data, normalize it, and
        % denoise it
        img_sp(:,:,1) = photons(:,:,ii)/max2(photons(:,:,ii));
        img_sp(:,:,2) = photons(:,:,ii)/max2(photons(:,:,ii));
        img_sp(:,:,3) = photons(:,:,ii)/max2(photons(:,:,ii));

        % Write all the temp files at once
        % maybe do a parfor once this works!
        writePFM(img_sp, outputTmp{ii});

        baseCmd = fullfile(oidn_pth, 'oidnDenoise --hdr ');
        
        if isequal(ii, 1)
            cmd = [baseCmd, outputTmp{ii},' -o ', DNImg_pth{ii}];
        else
            cmd = [cmd , ' && ', baseCmd, outputTmp{ii},' -o ', DNImg_pth{ii} ];
        end
    end
        %Run the full command executable once assembled
        %tic
        [status, results] = system(cmd);
        %toc
        if status, error(results); end

        for ii = channels
        % now read back the results
            DNImg = readPFM(DNImg_pth{ii});
            newPhotons(:,:,ii) = DNImg(:,:,1).* max2(photons(:,:,ii));
            delete(DNImg_pth{ii});
            delete(outputTmp{ii});
        end


end


if p.Results.useNvidia
    exrwrite(newPhotons,DNImg_pth);
else
    % warning("We don't export .pfm yet");
end
if ~quiet, close(h); end

%% Set the data into the object

switch object.type
    case 'scene'
        object = sceneSet(object,'photons',newPhotons);
    case 'opticalimage'
        object = oiSet(object,'photons',newPhotons);
end

% Clean up the temporary file.
% For batch need to loop through!
if ~keepHDR
    if ~doBatch
        if exist(DNImg_pth,'file'), delete(DNImg_pth);
            outputHDR = '';
        end
    end
else

    outputHDR = DNImg_pth;
end
if ~doBatch
    if exist(outputTmp,'file'), delete(outputTmp); end
end

fprintf("Denoised in: %2.3f\n", toc);

end
