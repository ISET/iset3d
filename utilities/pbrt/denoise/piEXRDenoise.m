function outputFileName = piEXRDenoise(exrFileName,varargin)
% A denoising method (AI based) that applies to multi-spectral HDR data
% tuned for Intel's OIDN
%
% Synopsis
%   <output exr file> = piAIdenoise(<input exr file>)
%
% Inputs
%   <exr  file>:
%
%
% Returns
%   <denoised exr file>
%
% Description
%
% Runs executable for the Intel denoiser (oidn_pth).  The executable
% must be installed on your machine.
%
% This is a Monte Carlo denoiser based on a trained model from intel
% open image denoise: 'https://www.openimagedenoise.org/'.  You can
% download versions for various types of architectures from
%
% https://www.openimagedenoise.org/downloads.html
%
% We have used the denoiser to clean up PBRT rendered images when we
% only use a small number of rays.  We use it for show, not for
% accurate simulations of scene or oi data.
%
% We may embed this denoiser in the PBRT docker image that can
% integrate with PBRT.  We are also considering the denoiser that is
% part of imgtool, distributed with PBRT.
%

%% Parse
p = inputParser;
p.addRequired('exrfilename',@(x)(isfile(x)));
p.addParameter('placebo',true);
p.parse(exrFileName, varargin{:});

% Generate file names for albedo and normal if we have them
[pp, nn, ee] = fileparts(p.Results.exrfilename);
albedoFileName = fullfile(pp, 'Albedo.pfm');
normalFileName = fullfile(pp, 'Normal.pfm');

%% Set up the denoiser path information and check

if ismac
    oidn_pth  = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.macos', 'bin');
elseif isunix
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-1.4.3.x86_64.linux', 'bin');
elseif ispc
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-2.0.1.x64.windows', 'bin');
else
    warning("No denoise binary found.\n")
end

if ~isfolder(oidn_pth)
    warning('Could not find the directory:\n%s',oidn_pth);
    return;
end

% Baseline do nothing, this is helpful for profiling & debugging
outputFileName = exrFileName;

tic; % start timer for deNoise


%% NOW WE HAVE A "RAW" EXR FILE
% That we need to turn into pfm files.
% "regular" denoiser normalizes each channel, but not sure if we should?

%% Get needed data from the .exr file
% First, get channel info
eInfo = exrinfo(exrFileName);
eChannelInfo = eInfo.ChannelInfo;

% Need to read in all channels. I think we can do this in exrread() if we
% put them all in an a/v pair
radianceChannels = [];
albedoChannels = [];
normalChannels = [];
rgbChannels = [];
depthChannels = [];

for ii = 1:numel(eChannelInfo.Properties.RowNames) % what about Depth and RGB!
    %fprintf("Channel: %s\n", eChannelInfo.Properties.RowNames{ii});
    channelName = convertCharsToStrings(eChannelInfo.Properties.RowNames{ii});
    if contains(channelName,'Radiance')
        radianceChannels = [radianceChannels, channelName];
    elseif contains(channelName, 'Albedo')
        albedoChannels = [albedoChannels channelName]; % Blue, Green, Red
    elseif ismember(channelName, ["Nx", "Ny", "Nz"])
        normalChannels = [normalChannels, channelName];
    elseif ismember(channelName, ["R", "G", "B"])
        rgbChannels = [rgbChannels, channelName]; % Blue, Green, Red
    elseif ismember(channelName, ["Px", "Py", "Pz"])
        depthChannels = [depthChannels, channelName]; % Px, Py, Pz
    end
end

% Read radiance, normal and albedo data
radianceData(:, :, :, 1) = exrread(exrFileName, "Channels",radianceChannels);
albedoData(:, :, :, 1) = exrread(exrFileName, "Channels",albedoChannels);
normalData(:, :, :, 1) = exrread(exrFileName, "Channels",normalChannels);

% We now have all the data in the radianceData array with the channel being the
% 3rd dimension, but with no labeling
for ii = 1:numel(radianceChannels)
    % We  want to write out the radiance channels using their names into
    % .pfm files, AFTER tripline them!
    radianceData(:, :, ii, 2 ) = radianceData(:,:,ii,1);
    radianceData(:, :, ii, 3 ) = radianceData(:,:,ii,1);
    rFileNames{ii} = fullfile(pp, strcat(radianceChannels(ii), ".pfm"));

    % Write out the .pfm data as a grayscale for each radiance channel
    writePFM(squeeze(radianceData(:, :, ii, :)),rFileNames{ii}); % optional scale(?)
end

% Albedo is also 3 channels

%% Now write albedo and Normal if they exist

outputTmp = {};

%% NEED TO SET DN Path
DNImg_pth = {};

%% Run the Denoiser binary

denoiseFlags = " -v 0 -hdr "; % we need hdr for our scenes, -v 0 might help it run faster
for ii = 1:numel(radianceChannels)

    baseCmd = fullfile(oidn_pth, "oidnDenoise");

    % what if we try to write over our input file?
    %denoiseImagePath{ii} = fullfile(piRootPath,'local',sprintf('tmp_dn-%d.pfm',ii));
    denoiseImagePath{ii} = rFileNames{ii};

    if isequal(ii, 1)
        cmd = strcat(baseCmd, denoiseFlags, rFileNames{ii}," -o ", denoiseImagePath{ii});
    else
        cmd = strcat(cmd , " && ", baseCmd, denoiseFlags, rFileNames{ii}," -o ", denoiseImagePath{ii} );
    end
end

%Run the full command executable once assembled
tic
[status, results] = system(cmd);
toc

if status, error(results); end


% NOW we have a lot of pfm files (one per radiance channel)
%     We can/could read them all back in and write them to an
%     output .exr file, unless there is something more clever

return
% Cut things off here for now, as we only have it working this far

for ii = 1:numel(radianceChannels)

    % now read back the results
    denoisedData = readPFM(denoiseImagePath{ii});

    % In this case each PFM is a channel, that we want to re-assemble into
    % an output .exr file (I think)
    % This gives us data, but we don't have a labeled  channel for it
    % at this point
    denoisedImage(:, :, ii) = denoisedData(:, :, 1);

    % Now we want to write our channel to our outputFile with the correct
    % name
    outputFileName = fullfile(pp, 'denoised.exr'); % for now
    ourChannelName = eChannelInfo.Properties.RowNames{ii};
    % !! Need to provide te correct channel name. Sigh.
    exrwrite(denoisedImage(:,:,ii),outputFileName, 'AppendToFile',true, "Channels",ourChannelName);

    delete(denoiseImagePath{ii});
end


fprintf("Denoised in: %2.3f\n", toc);

