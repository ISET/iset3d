function data = piEXR2Mat(inputFile, channelname)
% Read exr channel data into MATLAB, docker image is needed.
%
%           data = piEXR2Mat(inputFile, channelname)
%
% Brief description:
%   We take an exr file from pbrt as input and return MAT file with
%   specific channel name.  Relies on the imgtool code inside our PBRT
%   docker container.
%
% Inputs
%   inputFile - Multi-spectral exr-file rendered by pbrt.
%
% Output
%   data - Matlab data.
%
% Zhenyi, 2021
% dockerWrapper Support, D. Cardinal, 2022
%

% tic
if exist('isMATLABReleaseOlderThan','file') > 0 && ~isMATLABReleaseOlderThan('R2022b')
    % Use Matlab builtin exrread from the image toolbox 

    % Matlab included exrread() in 2022b.  We included exread() in
    % ISETCam (imgproc/openexr) for earlier releases. This code forces
    % a call to the Matlab toolbox version.  It eliminates the openexr
    % version from the user's path (if it is still there).
    tmp = which('exrread','-all');
    if numel(tmp) > 1
        lst = ~contains(tmp,fullfile('toolbox',filesep,'images',filesep,'iptformats'));
        rmpath(fileparts(tmp{lst}));        
    end

    if strcmpi(channelname,'radiance')
        channels = strings([1, 31]);
        for ii = 1:31
            channels(ii) = sprintf('Radiance.C%02d',ii);
        end
    else
        channels = channelname;
        %{
        %  We should check that the channels are present in the file here.
        info = exrinfo(inputFile);
        %}
    end

    data = exrread(inputFile, Channels = channels);
    return;

elseif isfile(fullfile(isetRootPath,'imgproc','openexr','exrread.m'))
    
    % Use the exrread() from ISETCam.
    
    if strcmpi(channelname,'radiance')
        channels = cell(1,31);
        for ii = 1:31
            channels{ii} = sprintf('Radiance.C%02d',ii);
        end
    else
        channels = channelname;
    end
    
    channelData = exrreadchannels(inputFile, channels);
    
    if strcmpi(channelname,'radiance')
        data = [];
        for i=1:31
            data = cat(3,data,channelData(channels{i}));
        end
    else
        data = channelData;
    end
    
    return;
    
else

    % Use the docker image to perform the EXR read.
    [indir, fname,~] = fileparts(inputFile);
    dockerimage = dockerWrapper.localImage();

    if ~ispc
        % Use the imgtool to convert exr data.
        basecmd = 'docker --context default run -ti --volume="%s":"%s" %s %s';
        cmd = ['imgtool convert --exr2bin ',channelname, ' ', inputFile];
        dockercmd = sprintf(basecmd, indir, indir, dockerimage, cmd);
        [status,result] = system(dockercmd);
    else
        basecmd = 'docker --context default run -i --volume="%s":"%s" %s %s';
        cmd = ['imgtool convert --exr2bin ',channelname, ' ', dockerWrapper.pathToLinux(inputFile)];
        dockercmd = sprintf(basecmd, indir, dockerWrapper.pathToLinux(indir), dockerimage, cmd);
        [status,result] = system(dockercmd);
    end

    if status
        disp(result);
        error('EXR to Binary conversion failed.')
    end
    allFiles = dir([indir,sprintf('/%s_*',fname)]);
    fileList = [];

    % In an error case there might be additional files
    % This code is designed to help with that if needed
    baseName = '';
    height = 0;
    width = 0;


    for ii = 1:numel(allFiles)
        if ~isempty(strfind(allFiles(ii).name, channelname))
            dataFile = allFiles(ii);
            if isequal(baseName, '')
                baseName = strsplit(dataFile.name,'.');
            end
            nameparts = strsplit(dataFile.name,'_');

            % Extract the row/col values from the file name.  This should
            % be the same for all of the radiance channels and the depth
            % image and the pixel labels.
            Nparts = numel(nameparts);
            if height == 0, height = str2double(nameparts{Nparts-2}); end
            if width  == 0, width  = str2double(nameparts{Nparts-1}); end

            if isempty(fileList)
                fileList = dataFile;
            else
                fileList(end+1) = dataFile;
            end
        end
    end


    if strcmp(channelname,'Radiance')

        % Radiance data
        data = zeros(height,width,numel(fileList));

        for ii = 1:numel(fileList)
            filename = fullfile(fileList(ii).folder, fileList(ii).name);

            fid = fopen(filename, 'r');
            serializedImage = fread(fid, inf, 'float');
            fclose(fid);

            % We haven't had a warning here in a long time.  Probably safe
            % to delete the try catch that was here.
            data(:,:,ii) = reshape(serializedImage, height, width, 1);

            % these channel files sometimes seem to be protected?
            delete(filename);
        end
    else
        filename = fullfile(fileList(1).folder, fileList(1).name);
        fid = fopen(filename, 'r');
        serializedImage = fread(fid, inf, 'float');
        data = reshape(serializedImage, height, width, 1);
        fclose(fid);
        delete(filename);
    end


end

end

