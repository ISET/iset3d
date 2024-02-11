function [status,result,dockercmd] = piDockerPBRT(varargin)
% Directly run pbrt in a Docker container
%
% Brief description
%   Uses the Docker Container to run pbrt directly
%
% Synopsis
%   [status,result,dockercmd] = piDockerPBRT(varargin)
%
% Inputs
%
% Optional key/val pairs
%   infile:   Full path to the input file
%
% Outputs
%   status    - 0 means success
%   result    - Text returned by the command
%   dockercmd - The docker command
%
% See also

% Example:
%{
% NOTE: This is a complex scene, requiring > 8GB of GPU RAM
tic
infile = fullfile(iaFileDataRoot, 'Ford', 'SceneRecipes', '1113181929_skymap.pbrt');
[status, result, dockercmd] = piDockerPBRT('infile',infile);
toc
%}

%% Parse

varargin = ieParamFormat(varargin);

p = inputParser;

p.addParameter('infile','',@(x)(exist(x,'file')));
p.addParameter('outfile','pbrt-output.exr',@ischar);

%p.addParameter('dockerimage',dockerWrapper.localImage(),@ischar);
p.addParameter('dockerimage', 'digitalprodev/pbrt-v4-gpu-ampere-ti', @ischar);
p.addParameter('verbose',true,@islogical);
p.parse(varargin{:});

% Maybe outfile should be handled separately as above.

dockerimage = p.Results.dockerimage;
outputFile = p.Results.outfile;

% This is the pbrt recipe file
if ~isempty(p.Results.infile)
    % Extract working dir and file name for the docker
    infile = p.Results.infile;
    [workdir, fname, ext] = fileparts(infile);
    fname = [fname,ext];
end


if ~ispc
    runDocker = 'docker run -ti --gpus device=0';
else
    runDocker = 'docker run -i --gpus device =0';
end


basecmd = [runDocker ' --workdir=%s --volume="%s":"%s" %s %s'];
cmd = sprintf('pbrt --gpu %s --outfile %s', ...
    dockerWrapper.pathToLinux(fname), dockerWrapper.pathToLinux(outputFile));

dockercmd = sprintf(basecmd, ...
    dockerWrapper.pathToLinux(workdir), ...
    workdir, ...
    dockerWrapper.pathToLinux(workdir), ...
    dockerimage, ...
    cmd);



% Run dockercmd and show any result.  Maybe
[status,result] = system(dockercmd);
if p.Results.verbose || status ~= 0
    fprintf('Run command:  %s\n',dockercmd);
    fprintf('Status %d (0 is good)\n',status);
    if ~isempty(result)
        disp(result)
    end
end


end
