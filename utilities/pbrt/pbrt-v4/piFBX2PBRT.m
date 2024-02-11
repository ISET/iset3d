function outfile = piFBX2PBRT(infile)
% Convert a FBX file to a PBRT file using assimp
%
% Input
%  infile (fbx)
% Key/val
%
% Output
%   outfile (pbrt)
%
% See also
%  

%% Find the input file and specify the converted output file

nativeDir = fileparts(infile); % need native & Linux names on Windows
[indir, fname,~] = fileparts(dockerWrapper.pathToLinux(infile));

% We need to wind up with a Native path on Windows
% so that subsequent code finds the file
outfile = fullfile(nativeDir, [fname,'-converted.pbrt']);
currdir = pwd;

% this is a little odd for Windows as I don't think we can cd
% to the desired directory so that the cp command after assimp
% works with a local name.
cd(nativeDir);

%% Runs assimp command

% build docker base cmd
dockerimage = dockerWrapper.localImage();
rng('shuffle');
dockercontainerName = ['Assimp-',num2str(randi(20000))];

if false % not sure we need this ispc
    % Example of what works:
    % docker run -ti --name Assimp-9995 <vols> <img> ... 
    %sh -c "assimp export /iset/iset3d-v4/data/V4/teapot-set/TeaTime.fbx TeaTime-converted.pbrt && ping localhost > NUL"
    basecmd = 'docker run -ti -d --name %s --volume="%s":"%s" %s %s';
    runCmd = ['assimp export ',dockerWrapper.pathToLinux(infile), ' ',[fname,'-converted.pbrt']];
    % for Windows need a wrapper
    wrapCmd = ['sh -c " apt install -y iputils-ping && ' runCmd ' && ping localhost > NUL "'];
        
    dockercmd = sprintf(basecmd, dockercontainerName, nativeDir, dockerWrapper.pathToLinux(indir), dockerimage, wrapCmd);

else
    basecmd = 'docker run -ti --name %s --volume="%s":"%s" %s %s';
    cmd = ['assimp export ',dockerWrapper.pathToLinux(infile), ' ',[fname,'-converted.pbrt']];
    dockercmd = sprintf(basecmd, dockercontainerName, nativeDir, dockerWrapper.pathToLinux(indir), dockerimage, cmd);
end



if ispc % can't use tty flag on Windows
    dockercmd = strrep(dockercmd,"-ti ","-i ");
    dockercmd = strrep(dockercmd,"-it ", "-i ");
    [status,result] = system(dockercmd); %,'-echo');
else
    [status,result] = system(dockercmd);
end

if status
    disp(result);
    error('FBX to PBRT conversion failed.')
end

% assimp in the docker container leaves our converted file in an
% odd place. We need to rescue it!
if true % ~ispc -- wrapper doesn't work right here.
    % can't use native filesep as we want linux version always
    cpcmd = sprintf('docker cp %s:/pbrt/pbrt-v4/build/%s %s',dockercontainerName, [fname,'-converted.pbrt'], nativeDir);
    [status_copy, result ] = system(cpcmd);

    % we tend to leave un-used containers around, so let's try to delete
    delCommand = sprintf('docker rm %s', dockercontainerName);
    [status_del,result] = system(delCommand);
else
    cpDocker = dockerWrapper();
    cpDocker.dockerImageName = ''; % use running container
    cpDocker.dockerCommand = 'docker cp';
    cpDocker.command = '';
    cpDocker.dockerFlags = '';
    linuxDir = cpDocker.pathToLinux(indir);
    cpDocker.inputFile = [dockercontainerName ':' linuxDir  filesep()  fname '-converted.pbrt'];
    cpDocker.outputFile = indir;
    cpDocker.outputFilePrefix = '';
    [status_copy, result] = cpDocker.run();
end


cd(currdir);
if status_copy
    disp(result);
    error('Copy file from docker container failed.\n ');
end

% sometimes we need it later!
% remove docker container
%rmCmd = sprintf('docker rm %s',dockercontainerName);
%system(rmCmd);
%end

