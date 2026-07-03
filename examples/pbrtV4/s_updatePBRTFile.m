%% Update PBRT V3 files to PBRT V4 files
%
% This script has a template for doing the update.  The key function that
% changes the pbrt source files is piPBRTUpdateV4.
%
% See also
%   piPBRTUpdateV4, piPBRTReformat

%% Read in the file and get set up for output

sceneName = 'simplescene';
inFile = fullfile(piRootPath,'data','V3',sceneName,[sceneName,'.pbrt']);

outputDir = fullfile(piDirGet('scenes'),sceneName);
if ~exist(outputDir,'dir'), mkdir(outputDir);end

outFile = fullfile(outputDir,[sceneName,'.pbrt']);

%% This function does the PBRT conversion 

outFile = piPBRTUpdateV4(inFile, outFile);
dir(fileparts(outFile))

%% Copy the auxiliary files from the V3 directory to the V4 directory

[inputDir,~,~]=fileparts(inFile);
fileList = dir(inputDir);
fileList(1:2)=[];
for ii = 1:numel(fileList)
    [~,~,ext]=fileparts(fileList(ii).name);
    if strcmp(ext,'.pbrt')
        continue;
    else
        copyfile(fullfile(fileList(ii).folder, fileList(ii).name), ...
            fullfile(outputDir, fileList(ii).name));
    end
end
dir(fileparts(outFile))

%{
infile = piPBRTReformat(outFile);
thisR  = piRead(infile);

piWrite(thisR);

scene = piRender(thisR);
sceneWindow(scene);
%}


%%

inFile = fullfile(piRootPath,'data','V4','web','kitchen','scene.pbrt');
exist(inFile,'file')

outputDir = fullfile(piGetDir('scenes'),'web','kitchen');
if ~exist(outputDir,'dir'), mkdir(outputDir);end

outFile = fullfile(outputDir,'kitchen.pbrt');

%% This function does the PBRT conversion 

outFile = piPBRTUpdateV4(inFile, outFile);
dir(fileparts(outFile))

