% Export objects to JSON for use in oi2sensor
%
% D. Cardinal, Stanford University, 2022
%
%% Set output folder
outputFolder = fullfile(piRootPath,'local','computed');
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

%% Export sensor(s)
sensorFiles = {'ar0132atSensorrgb.mat', 'MT9V024SensorRGB.mat'};

if ~isfolder(fullfile(outputFolder,'sensors'))
    mkdir(fullfile(outputFolder,'sensors'))
end
for ii = 1:numel(sensorFiles)
    load(sensorFiles{ii}); % assume they are on our path
    % change suffix to json
    [~, fName, fSuffix] = fileparts(sensorFiles{ii});
    jsonwrite(fullfile(outputFolder,'sensors',[fName '.json']), sensor);
end

%% TBD Export Lenses

%% TBD Export Scenes

%% Export OIs
%% NOTE:
% They can include complex numbers that are not directly
% usable in JSON, so we need to encode or re-work somehow
imageArray = [];
metadataArray = [];
oiFiles = {'oi_001.mat', 'oi_002.mat', 'oi_fog.mat'};
for ii = 1:numel(oiFiles)
    load(oiFiles{ii}); % assume they are on our path
    % change suffix to json
    [~, fName, fSuffix] = fileparts(oiFiles{ii});

    % This is slow, and the files are too large for
    % direct use, so turned off by default
    % jsonwrite(fullfile(outputFolder,[fName '.json']), oi);

    % Now, pre-compute sensor images
    if ~isfolder(fullfile(outputFolder,'images'))
        mkdir(fullfile(outputFolder,'images'))
    end
    for iii = 1:numel(sensorFiles)
        load(sensorFiles{iii}); % assume they are on our path
        % change suffix to json
        [~, sName, fSuffix] = fileparts(sensorFiles{iii});

        % Auto-Exposure breaks with oncoming headlights, etc.
        eTime  = autoExposure(oi,sensor,.3,'mean');
        sensor = sensorSet(sensor,'exp time',eTime);

        sensor = sensorCompute(sensor,oi);
        % append to our overall array
        imageArray = [imageArray sensor];

        % Here we save the preview images
        % Should cache the name with the metadata!
        ipJPEG = fullfile(outputFolder,'images',[fName '-' sName '.jpg']);
        ip = ipCreate('ourIP',sensor);
        ip = ipCompute(ip, sensor);

        % save using default IP as preview
        outputFile = ipSaveImage(ip, ipJPEG);
        % we can save without an IP if we want
        %sensorSaveImage(sensor, sensorJPEG  ,'rgb');

        % we'd better have metadata by now!
        sensor.metadata.jpegName = sensorJPEG;
        metadata = sensorSet(sensor,'volts',[]);
        metadataArray = [metadataArray metadata];
        jsonwrite(fullfile(outputFolder,'images', [fName '-' sName '.json']), sensor);

    end

    % NOTE: Full images are large,
    %       So look at metadata JSON array
    %       and separate images
    jsonwrite(fullfile(outputFolder,'images','images.json'), imageArray);
    jsonwrite(fullfile(outputFolder,'images','metadata.json'), metadataArray);


end