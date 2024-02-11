function outFile = piPBRTUpdateV4(inFile,outFile)
% Update PBRT V3 file to V4 format
%
% Synopsis
%  outFile = piPBRTUpdateV4(inFile,outFile)
%
% Inputs
%   inFile -  PBRT V3 file
%   outFile - PBRT V4 file
%
% Output
%   outFile - File name
%
% Author: Zhenyi
%
% See also
%   s_updatePBRTFile is a script that manages the conversion

%%
if ~exist(inFile,'file'), error('Could not find %s',inFile); end
if ~exist('outFile','var'), outFile = ''; end 

%% First we call PBRT

[sceneDir, fname,ext] = fileparts(inFile);
dockerCMD = 'docker run -ti --rm';
dockerImage = dockerWrapper.localImage();

% Use default name for outFile
if isempty(outFile)
  outFile = fullfile(sceneDir,[fname,'-v4.pbrt']);
end

%% Call the pbrt docker image

VolumeCMD = sprintf('--workdir="%s" --volume="%s:%s"',sceneDir,sceneDir,sceneDir);
CMD = sprintf('%s %s %s pbrt --upgrade %s > %s',dockerCMD, VolumeCMD, dockerImage, inFile, outFile);

[status,result]=system(CMD);

if status
    error(result);
end

%% Deal with some cases which were not handled properly 

% Open the file
fileIDin = fopen(outFile);

% Create a tmp file
outputFullTmp = fullfile(sceneDir, [fname, '_tmp.pbrt']);
fileIDout = fopen(outputFullTmp, 'w');

while ~feof(fileIDin)
    thisline=fgets(fileIDin);
    
    % We can add other elseif cases as needed. float uv -> float2 uv
    if ischar(thisline) && contains(thisline,'float uv')
        thisline = strrep(thisline,'float uv','point2 uv');
    end
    % delete "string strategy" params
    if ischar(thisline) && contains(thisline,'string strategy')
        continue
        
    % delete "twosided" for arealight
    elseif ischar(thisline) && contains(thisline,'twosided')
        continue
        
        % delete "twosided" for arealight
    elseif ischar(thisline) && contains(thisline,'Warning')
        continue
        
    % change ":Vector (1,2,3)" to "# Dimension [1 2 2]"
    elseif ischar(thisline) && contains(thisline,':Vector')
        thisline = strrep(thisline, ':Vector','#Dimension:');
        thisline = strrep(thisline, ', ',' ');
        thisline = strrep(thisline, '(','[');
        thisline = strrep(thisline, ')',']');   
        fprintf(fileIDout, '%s', thisline);
        continue
    end
    
    fprintf(fileIDout, '%s', thisline);
end

fclose(fileIDin);

fclose(fileIDout);

movefile(outputFullTmp, outFile);

[outputDir,~,~]=fileparts(outFile);
inputMaterialfname  = fullfile(sceneDir,  [fname, '_materials', ext]);
outputMaterialfname = fullfile(outputDir, [fname, '_materials', ext]);
inputGeometryfname  = fullfile(sceneDir,  [fname, '_geometry',  ext]);
outputGeometryfname = fullfile(outputDir, [fname, '_geometry',  ext]);

if exist(inputMaterialfname, 'file')
    piPBRTUpdateV4(inputMaterialfname,outputMaterialfname);
end

if exist(inputGeometryfname, 'file')
    piPBRTUpdateV4(inputGeometryfname,outputGeometryfname);
end



end