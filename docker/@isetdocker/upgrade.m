function [outFile,result] = upgrade(obj,inFile,outFile)
p = inputParser();

p.KeepUnmatched = true;

verbose = 1; % 0, 1, 2
if ~exist('commandonly','var')
    commandonly = false;
end

if ~exist(inFile,'file'), error('Could not find %s',inFile); end

[sceneFolder, currName,~] = fileparts(inFile);
if ~exist('outFile','var')
    outFile = fullfile(sceneFolder,[fname,'-v4.pbrt']);
end
%% Build up the render command
[outputFolder,outName,~] = fileparts(outFile);

iDockerPrefs = getpref('ISETDocker');

% Check that the container is running remotely.  If not, start.
if isfield(iDockerPrefs,'PBRTContainer')
    % Test that the container is running remotely
    result = obj.dockercmd('psfind','string',iDockerPrefs.PBRTContainer);

    % Couldn't find it.  Restart.
    if isempty(result), obj.startPBRT; end
else
    % No PBRTContainer specified, so restart.
    obj.startPBRT();
end

ourContainer = getpref('ISETDocker','PBRTContainer');

if ispc,     flags = '-i ';
else,        flags = '-it ';
end

[~, sceneDir, ~] = fileparts(outputFolder);

if isempty(getpref('ISETDocker','remoteHost'))
    contextFlag = ' --context default ';
else
    contextFlag = [' --context ' getpref('ISETDocker','renderContext')];
end

% use cpu
device = '';

upgradeFolder = 'upgrade';
% Running remotely.
if ~isempty(getpref('ISETDocker','remoteHost'))
    if ispc
        remoteSceneDir = [getpref('ISETDocker','workDir') '/' upgradeFolder];
    else
        remoteSceneDir = fullfile(getpref('ISETDocker','workDir'),upgradeFolder);
    end
    remoteDirCheck = dir(obj.sftpSession,fullfile(remoteSceneDir));
    if ~isempty(remoteDirCheck)
        obj.remove(remoteSceneDir);
    end
    % sync files from local folder to remote
    obj.upload(sceneFolder, remoteSceneDir);
    inF_remote  = fullfile(remoteSceneDir,[currName,'.pbrt']);
    outF_remote = fullfile(remoteSceneDir,'v4',[outName,'.pbrt']);

     % check if there is renderings folder
    outDirRemoteCheck = dir(obj.sftpSession,fullfile(remoteSceneDir,'v4'));
    if isempty(outDirRemoteCheck)
        mkdir(obj.sftpSession,fullfile(remoteSceneDir,'v4'));
    end

    renderCommand = sprintf('pbrt --upgrade %s > %s',...
        inF_remote,outF_remote);

    containerCommand = sprintf('docker %s exec %s %s sh -c " %s "',...
        contextFlag, flags, ourContainer, renderCommand);

    if verbose > 0
        fprintf('[INFO]: USE Docker: %s\n', containerCommand);
    end
    
    if ~commandonly
        renderStart = tic;
        if verbose > 1
            [status, ~] = system(containerCommand, '-echo');
            fprintf('[INFO]: File has updated remotely in: %4.2f sec\n', toc(renderStart))
        elseif verbose == 1

            [status, result] = system(containerCommand);
            if status == 0
                fprintf('[INFO]: File has updated remotely in: %4.2f sec\n', toc(renderStart))
            else
                cprintf('red','[ERROR]: Docker Command: %s\n', containerCommand);
                error('Error Rendering: %s', result);
            end

        else
            [status, result] = system(containerCommand);
        end

        if status == 0
            if ~isempty(getpref('ISETDocker','remoteHost'))
                if ~getpref('ISETDocker','batch',false)
                    obj.download(remoteSceneDir, outputFolder);
                else
                    return;
                end
            end
        end
    end
else
    % Running locally. -- TODO
    % SceneDir = [getpref('ISETDocker','workDir') '/' sceneFolder]; % this should be local folder
    % outF = fullfile(SceneDir,'renderings',[currName,'.exr']);
    if ~exist(fullfile(outputFolder,'renderings'),'dir'),mkdir(fullfile(outputFolder,'renderings'));end
    outF = fullfile(outputFolder,'renderings',[currName,'.exr']);
    
    % Add support for 'remoteResources' even in local case
    renderCommand = sprintf('pbrt %s --outfile %s %s', device, outF, pbrtFile);

    containerCommand = sprintf('docker %s exec %s %s sh -c " %s "',...
        contextFlag, flags, ourContainer, renderCommand);

    renderStart = tic;
    [status, result] = system(containerCommand);
    if verbose > 0
        if status == 0
            fprintf('[INFO]: Rendered remotely in: %4.2f sec\n', toc(renderStart))
        else
            cprintf('red','[ERROR]: Docker Command: %s\n', containerCommand);
            error('Error Rendering: %s', result);
        end
    end
end
end

