function outputFull = piPBRTReformat(fname,varargin)
%% Format a pbrt file from arbitrary source to standard format
%
% Syntax:
%    outputFull = piPBRTReformat(fname,varargin)
%
% Brief
%    PBRT V3 files can appear in many formats.  This function uses the PBRT
%    docker container to read those files and write out the equivalent PBRT
%    file in the standard format.  It does this by calling PBRT with the
%    'toply' switch.  So PBRT reads the existing data, converts any meshes
%    to ply format, and writes out the results.
%
% Input
%   fname: The full path to the filename of the PBRT scene file.
%
% Key/val options
%   outputFull:  The full path to the PBRT scene file that we output
%                By default, this will be
%                   outputFull = fullfile(piRootPath,'local','formatted',sceneName,sceneName.pbrt)
%
% Example:
%    piPBRTReformat(fname);
%    piPBRTReformat(fname,'output full',fullfile(piRootPath,'local','formatted','test','test.pbrt')
% See also
%

% Examples:
%{
fname = fullfile(piRootPath,'data','V4','SimpleScene','SimpleScene.pbrt');
formattedFname = piPBRTReformat(fname);
%}

%% Parse

% Force to no spaces and lower case
varargin = ieParamFormat(varargin);

% fname can be the full file name.  But it is only required that it be
% found.
p = inputParser;
p.addRequired('fname',@(x)(exist(fname,'file')));

% This is ugly.  We find the full path to the fname.  Maybe we should just
% require the full path.
% fname = which(fname);
[inputdir,thisName,ext] = fileparts(fname);
p.addParameter('outputfull',fullfile(piRootPath,'local','formatted',thisName,[thisName,ext]),@ischar);

p.parse(fname,varargin{:});
outputFull = p.Results.outputfull;


[outputDir, ~, ~] = fileparts(outputFull);
if ~exist(outputDir,'dir')
    mkdir(outputDir);
end

% copy files from input folder to output folder
piCopyFolder(inputdir, outputDir);

%% convert %s mkdir mesh && cd mesh &&

% moved some of the static pathing up, so we can modify if needed for the
% ispc case -- DJC

% The directory of the input file
[volume, ~, ~] = fileparts(fname);

% Which docker image we run
dockerimage = dockerWrapper.localImage();

% Give a name to docker container
% make sure we don't have the same container numbers every time
% right answer is to housekeep them!
rng('shuffle');
dockercontainerName = ['ISET3d-',thisName,'-',num2str(randi(20000))];

% The Docker base command includes 'toply'.  In that case, it does not
% render the data, it just converts it.
% basecmd = 'docker run -t --name %s --volume="%s":"%s" %s pbrt --toply %s > %s && ls';

%% Build the command
%{
if false % disable for now ispc
    renderDocker = dockerWrapper();
    renderDocker.dockerCommand = 'docker run';
    renderDocker.dockerFlags = '-t --name ';
    renderDocker.dockerContainerName = dockercontainerName;
    renderDocker.workingDirectory = outputDir;
    renderDocker.dockerImageName = dockerimage;
    renderDocker.localVolumePath = volume;
    renderDocker.targetVolumePath = volume;
    templateCommand = 'sh -c "pbrt --toply %s > %s && ls mesh_*.ply"';
    renderDocker.command = sprintf(templateCommand,  renderDocker.pathToLinux(fname), ...
        dockerWrapper.pathToLinux(outputFull));
    %% Run the command
    % The variable 'result' has the formatted data.
    [~, result] = renderDocker.run();

else
    %}
if ispc
    flags = '-i ';
else
    flags = '-it ';
end

basecmd = 'docker run %s --name %s --volume="%s":"%s" %s /bin/bash -c "pbrt --toply %s > %s; ls mesh_*.ply"';
dockercmd = sprintf(basecmd, flags, dockercontainerName, volume, ...
    dockerWrapper.pathToLinux(volume), dockerimage, dockerWrapper.pathToLinux(fname), [thisName, ext]);
% d ockercmd = sprintf(basecmd, dockercontainerName, volume, volume, dockerimage, fname, outputFull);
% disp(dockercmd)
%% Run the command
% The variable 'result' has the formatted data.
[status_format, result] = system(dockercmd);
%end

%% Copy formatted pbrt files to local directory.
% I think only assimp puts them in build, so why are we looking there?
%cpcmd = sprintf('docker cp %s:/pbrt/pbrt-v4/build/%s %s',dockercontainerName, [thisName, ext], dockerWrapper.pathToLinux(outputDir));
cpcmd = sprintf('docker cp %s:/pbrt/pbrt-v4/build/%s %s',dockercontainerName, [thisName, ext], outputDir);
[status_copy, result_copy ] = system(cpcmd);
if status_copy
    disp('No converted file found.');
end

%% remove "Warning: No metadata written out."
% Do this only for the main pbrt file
if ~contains(outputFull,'_materials.pbrt') ||...
        ~contains(outputFull,'_geometry.pbrt')

    fileIDin = fopen(outputFull);
    outputFullTmp = fullfile(outputDir, [thisName, '_tmp',ext]);
    fileIDout = fopen(outputFullTmp, 'w');

    while ~feof(fileIDin)
        thisline=fgets(fileIDin);
        if ischar(thisline) && ~contains(thisline,'Warning: No metadata written out.')
            fprintf(fileIDout, '%s', thisline);
        end
    end
    fclose(fileIDin);
    fclose(fileIDout);
    
    % Force over-write???
    movefile(outputFullTmp, outputFull, 'f');

end
%%

% Status is good.  So do stuff
% find out how many ply mesh files are generated.
PLYmeshFiles = textscan(result, '%s');
PLYmeshFiles = PLYmeshFiles{1};
% PLYFolder    = fullfile(outputDir,'scene/PBRT/pbrt-geometry');
%
% if ~exist(PLYFolder,'dir')
%     mkdir(PLYFolder);
% end

for ii = 1:numel(PLYmeshFiles)
    cpcmd = sprintf('docker cp %s:/pbrt/pbrt-v4/build/%s %s',dockercontainerName, PLYmeshFiles{ii}, outputDir);

    [status_copy, ~ ] = system(cpcmd);
    if status_copy
        % If it fails we assume that is because there is no corresponding
        % mesh file.  So, we stop.
        break;
    end
end
% fprintf('Formatted file is in %s \n', outputDir);



%% Either way, stop the container if it is still running.

% Try to get rid of the return from this system command.
rmCmd = sprintf('docker rm %s',dockercontainerName);
system(rmCmd);
%%
% In case there are extra materials and geometry files
% format scene_materials.pbrt and scene_geometry.pbrt, then save them at the
% same place with scene.pbrt
inputMaterialfname  = fullfile(inputdir,  [thisName, '_materials', ext]);
outputMaterialfname = fullfile(outputDir, [thisName, '_materials', ext]);
inputGeometryfname  = fullfile(inputdir,  [thisName, '_geometry',  ext]);
outputGeometryfname = fullfile(outputDir, [thisName, '_geometry',  ext]);

if exist(inputMaterialfname, 'file')
    piPBRTReformat(inputMaterialfname, 'outputfull', outputMaterialfname);
end

if exist(inputGeometryfname, 'file')
    piPBRTReformat(inputGeometryfname, 'outputfull', outputGeometryfname);
end

end

