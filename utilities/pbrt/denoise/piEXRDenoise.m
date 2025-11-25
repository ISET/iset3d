function status = piEXRDenoise(exrFileName,varargin)
% A denoising method (AI based and specific to Ray Traced images)
% that applies to multi-spectral HDR data tuned for Intel's OIDN
%
% NOTE: Intel's denoiser binary only accepts 3-channel images, so we need
%       to pull our typical 31 channel images apart, then replicate each
%       channel to make it a pseudo grayscale, and denoise each in turn.
%       This is very expensive, but we haven't found a better approach yet.

% Synopsis
%   <output exr file> = piAIdenoise(<input exr file>)
%
% Inputs
%   <exr  file>:
%
%   'channels': 'exr_radiance', 'exr_albedo', 'exr_all'
%   'filter': 'RT' (Default) | 'RTLightmap' (for denoising lightmaps?)
%
% Output:
%    Denoised version of <exr file> in the same location
%    Other known channels are re-written intact
%
% Returns
%   status -- 0 if successful, otherwise - <error code>
%
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

% Set to no error
status = 0;
tic; % start timer

%% Parse
p = inputParser;
p.addRequired('exrfilename',@(x)(isfile(x)));
p.addParameter('channels','');
p.addParameter('filter','RT'); % RTLightmap is also an option
p.addParameter('glom',true); % use one large file
p.parse(exrFileName, varargin{:});

glom = p.Results.glom;

% Generate file names for albedo and normal if we have them
[pp, ~, ~] = fileparts(p.Results.exrfilename);
albedoFileName = fullfile(pp, 'Albedo.pfm');
normalFileName = fullfile(pp, 'Normal.pfm');

% Decide whether to use additional data for denoising. There is improvement
% in detail but the process takes longer
if all([ismember(p.Results.channels, ['exr_albedo', 'exr_all']), ~glom])
    useAlbedo = true;
else
    useAlbedo = false;
end
if all([ismember(p.Results.channels, 'exr_all'), ~glom])
    useNormal = true;
else
    useNormal = false;
end

% only set filter flag if needed, to keep the command short
if ~isequal(p.Results.filter, 'RT') % RT is the default
    filterFlag = [' -f ' p.Results.filter ' '];
else
    filterFlag = '';
end

%% Set up the denoiser path information and check

oidn_Binary = 'oidnDenoise';

% Someone should unzip the 2.0 mac & linux binaries I stuck in the repo and
% test them
if ismac
    switch computer('arch')
        case 'maca64'
            oidn_pth  = fullfile(piRootPath, 'external', 'oidn-2.3.3.arm64.macos', 'bin');
        case 'maci64'
            oidn_pth  = fullfile(piRootPath, 'external', 'oidn-2.3.3.arm64.macos', 'bin');
    end
elseif isunix
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-2.1.0.x86_64.linux', 'bin');
elseif ispc
    oidn_pth = fullfile(piRootPath, 'external', 'oidn-2.1.0.x64.windows', 'bin');
end

if ~isfolder(oidn_pth)
    warning('Could not find the directory:\n%s',oidn_pth);
    status = -2;
    return;
else
    % Add to path to shorten the batch command, otherwise it is too
    % long to execute as a single system() call.

    % DEFINITELY HACKY, but adding the binary to the path doesn't seem to
    % work. Maybe add /local to the path for all the output files instead?

    if ~glom % then we need to have shorter binary paths
        originalFolder = cd(oidn_pth);
    else
        originalFolder = pwd();
    end
    baseCmd = fullfile(oidn_pth, oidn_Binary);
    % non-batch version -- about 20-25% slower
    %baseCmd = fullfile(oidn_pth, oidn_Binary);
end

%% NOW WE HAVE A "RAW" EXR FILE
% That we need to turn into pfm files.
% piAIDenoise normalizes each channel, but not sure if we should?

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

% set command flags
commandFlags = [filterFlag ' --hdr '];

for ii = 1:numel(eChannelInfo.Properties.RowNames) % what about Depth and RGB!
    %fprintf("Channel: %s\n", eChannelInfo.Properties.RowNames{ii});
    channelName = convertCharsToStrings(eChannelInfo.Properties.RowNames{ii});
    if contains(channelName,'Radiance') % we always want radiance channels
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

% Read radiance, normal and albedo data both so we can restore them
% to our output file, and in case we want to use them in the denoiser
radianceData(:, :, :, 1) = exrread(exrFileName, "Channels",radianceChannels);
if ~isempty(albedoChannels)
    albedoData = exrread(exrFileName, "Channels",albedoChannels);
    if useAlbedo
        % Denoise the albedo for cleaner luminance processing
        writePFM(albedoData, albedoFileName);

        % First we denoise the albedo channels, to improve our results
        % We only do this once per image, as it is the same for all
        % of our radiance iterations, so it doesn't add much time
        [status, result] = system(strcat(baseCmd, commandFlags, " ", albedoFileName, " -o ",albedoFileName ));
        albedoFlag = [' --clean_aux --alb ' albedoFileName];
    else
        albedoFlag = '';
    end
else
    albedoFlag = '';
end
if ~isempty(normalChannels)
    normalData = exrread(exrFileName, "Channels",normalChannels);

    % Normal doesn't seem particularly useful, but here for completeness
    if useNormal
        writePFM(normalData,normalFileName);
        [status, result] = system(strcat(baseCmd, commandFlags, " ", normalFileName, " -o ",normalFileName ));
        normalFlag = [ ' --nrm ' normalFileName];
    else
        normalFlag = '';
    end

else
    normalFlag = '';
end

% We only read the depth channels so that we can write them back out intact
% Currently they are not used by the de-noiser
if ~isempty(depthChannels)
    depthData = exrread(exrFileName, "Channels",depthChannels);
end

% Setup for glomming input channels
if glom
    padColumns = 100; % arbitrary for now
    rZeros = zeros([size(radianceData,1), padColumns,3]);
    %rZeros = zeros([size(radianceData,1), size(radianceData,2),3]);
    glommedData = rZeros;
    glommedDataFile = fullfile(pp, strcat('glommedData', ".pfm"));
end

% We now have all the data in the radianceData array with the channel being the
% 3rd dimension, but with no labeling of the channels
for ii = 1:numel(radianceChannels)
    % We  want to write out the radiance channels using their names into
    % .pfm files. But first we have to replicate each of our hyperspectral
    % channels into a 3-channel version for OIDN to work
    radianceData(:, :, ii, 2 ) = radianceData(:,:,ii,1);
    radianceData(:, :, ii, 3 ) = radianceData(:,:,ii,1);
    rFileNames{ii} = fullfile(pp, strcat(radianceChannels(ii), ".pfm"));

    if glom
        glommedData = [glommedData squeeze(radianceData(:,:,ii,:)) rZeros];
    else
        % Write out the resulting .pfm data as a grayscale for each radiance channel
        writePFM(squeeze(radianceData(:, :, ii, :)),rFileNames{ii}); % optional scale(?)
    end
    % default binary denoiser doesn't support .exr, but could be worth
    % an experiment if we can re-compile or find one that does
    %rFileNames{ii} = fullfile(pp, strcat(radianceChannels(ii), ".exr"));
    %exrwrite(squeeze(radianceData(:, :, ii, :)),rFileNames{ii}); % optional scale(?)
end

% More on big data test
if glom
    writePFM(glommedData,glommedDataFile);
end

%% Run the Denoiser binary

denoiseFlags = strcat(" -v 0 ", albedoFlag, normalFlag, commandFlags, " "); % we need hdr for our scenes, -v 0 might help it run faster

%% Build denoise command by iterating through our radiance channels
if glom
    cmd = strcat(baseCmd, denoiseFlags, glommedDataFile," -o ", glommedDataFile);
else
    for ii = 1:numel(radianceChannels)

        denoiseImagePath{ii} = rFileNames{ii};

        % Create a single command to denoise all of our .pfm files
        % in one call to the System
        % We denoise in place. Not sure if that is faster or slower?
        if isequal(ii, 1)
            cmd = strcat(baseCmd, denoiseFlags, rFileNames{ii}," -o ", denoiseImagePath{ii});
        else
            cmd = strcat(cmd , " && ", baseCmd, denoiseFlags, rFileNames{ii}," -o ", denoiseImagePath{ii} );
        end

        % IF we want to avoid using cd()
        %cmd = strcat(baseCmd, denoiseFlags, rFileNames{ii}," -o ", denoiseImagePath{ii});
        %[status, results] = system(cmd);
        %if status, error(results); end
    end
end

%Run the full command executable once assembled
[status, results] = system(cmd);
if status
    cd(originalFolder);
    error(results);
end


% NOW we have a lot of pfm files (one per radiance channel)
%     We can/could read them all back in and write them to an
%     output .exr file, unless there is something more clever

if glom
    denoisedData = readPFM(glommedDataFile);
    frameCols = size(radianceData,2);
    for ii = 1:numel(radianceChannels)
        % need to calculate the columns needed
        % we have padColumn 0s, then image, then padColumn 0s, etc
        startCol = padColumns + (ii - 1) * (frameCols + padColumns) + 1;
        endCol = startCol +  (frameCols - 1);
        denoisedImage(:, :, ii) = denoisedData(:, startCol:endCol, 1);
    end
else
    for ii = 1:numel(radianceChannels)

        % now read back the results
        denoisedData = readPFM(denoiseImagePath{ii});

        % In this case each PFM is a channel, that we want to re-assemble into
        % an output .exr file (I think)
        % This gives us data, but we don't have a labeled  channel for it
        % at this point
        denoisedImage(:, :, ii) = denoisedData(:, :, 1);

    end
end

completeImage = denoisedImage; % start with radiance channels
completeChannels = radianceChannels;
if ~isempty(albedoChannels)
    completeImage(:, :, end+1:end+3) = albedoData;
    completeChannels = [completeChannels albedoChannels];
end
if ~isempty(depthChannels)
    numDepth = numel(depthChannels);
    completeImage(:, :, end+1:end+numDepth) = depthData;
    completeChannels = [completeChannels depthChannels];
end
if ~isempty(normalChannels)
    completeImage(:, :, end+1:end+3) = normalData;
    completeChannels = [completeChannels normalChannels];
end

% Put the newly de-noised image back:
try
    delete(exrFileName); % we seem to need to delete this first on linux
    exrwrite(completeImage, exrFileName, "Channels",completeChannels);
catch
    cd(originalFolder);
    error('exrwrite failed');
end

% If using batch and we crash, user is stuck in the wrong place until we add a
% try/catch block
cd(originalFolder);

fprintf("Denoised in: %2.3f\n", toc);


