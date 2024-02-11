function [output,cmd] = piDockerLenstool(command,varargin)
% Use lenstool for various PBRT related tasks 
%
% D.Cardinal 02/2022
%
% Synopsis
%   [status,result] = piDockerlenstool(command,varargin)
%
% usage: lenstool <command> [options] <filenames...>
% 
% commands: convert insertmicrolens
% 
% convert options:
%     --inputscale <n>    Input units per mm (which are used in the output). Default: 1.0
%     --implicitdefaults  Omit fields from the json file if they match the defaults.
% 
% insertmicrolens options:
%     --xdim <n>             How many microlenses span the X direction. Default: 16
%     --ydim <n>             How many microlenses span the Y direction. Default: 16
%     --filmwidth <n>        Width of target film in mm. Default: 20.0
%     --filmheight <n>       Height of target film in mm. Default: 20.0
%     --filmtolens <n>       Distance from film to back of main lens system (in mm). Default: 50.0
%     --filmtomicrolens      Distance from microlens to film (mm?)
%
% Uses the Docker Container to execute
%
% Hopefully the distance from film to the imaging lens can be
% adjusted elsewhere, say by thisR.set() ...?
%
% TBD
%
% See also
%

%% Parse

command  = ieParamFormat(command);
varargin = ieParamFormat(varargin);

p = inputParser;

p.addRequired('command',@(x)(ismember(x,{'help', 'convert', 'insertmicrolens'})));
p.addParameter('dockerimage',dockerWrapper.localImage(),@ischar);
p.addParameter('helpparameter','',@ischar);
p.addParameter('xdim',16, @isnumeric);
p.addParameter('ydim',16, @isnumeric);
p.addParameter('filmwidth',20.0, @isnumeric);
p.addParameter('filmheight',20.0, @isnumeric);
p.addParameter('filmtolens', 50.0, @isnumeric);    % mm, I think.
p.addParameter('filmtomicrolens', 0, @isnumeric);  % Not sure of units.  Everything else is mm.
p.addParameter('microlens','', @ischar);
p.addParameter('imaginglens','', @ischar);
p.addParameter('combinedlens','', @ischar);
p.addParameter('outputfolder','', @ischar);
p.addParameter('verbose',true,@islogical);

p.parse(command,varargin{:});

dockerImage = p.Results.dockerimage;

%% Switch on the cmds

% Read the exr file and convert into the same directory
if ~ispc
    runDocker = 'docker run -ti ';
else
    runDocker = 'docker run -i ';
end

switch command
    case 'insertmicrolens'
        basecmd = sprintf('%s  --workdir=%s --volume="%s":"%s" %s lenstool insertmicrolens ', ...
            runDocker, dockerWrapper.pathToLinux(p.Results.outputfolder), ...
            p.Results.outputfolder, dockerWrapper.pathToLinux(p.Results.outputfolder), ...
            dockerImage);

        % Edited to add filmtomicrolens 12/9/22 (BW)
        partialcmd = sprintf('%s --xdim %d --ydim %d --filmheight %d --filmwidth %d --filmtolens %d --filmtomicrolens %d', ...
            basecmd, p.Results.xdim, p.Results.ydim, ...
            p.Results.filmheight, p.Results.filmwidth, p.Results.filmtolens,p.Results.filmtomicrolens);
        cmd = sprintf('%s %s %s %s ',...
            partialcmd, dockerWrapper.pathToLinux(p.Results.imaginglens), ...
            dockerWrapper.pathToLinux(p.Results.microlens), ...
            dockerWrapper.pathToLinux(p.Results.combinedlens));
    case 'convert'
        error('Convert not implemented.');
        % only an initial stab!
        %         basecmd = sprintf('%s  --workdir=%s --volume="%s":"%s" %s lenstool convert ', ...
        %             runDocker, dockerWrapper.pathToLinux(p.Results.outputfolder), ...
        %             p.Results.outputfolder, dockerWrapper.pathToLinux(p.Results.outputfolder), ...
        %             dockerImage);
        %         partialcmd = sprintf('%s --inputscale %d --implicitdefaults %s ', ...
        %             basecmd, p.Results.inputscale, p.Results.implicitdefaults);
        %         cmd = sprintf('%s %s %s %s ',...
        %             partialcmd, dockerWrapper.pathToLinux(p.Results.imaginglens), ...
        %             dockerWrapper.pathToLinux(p.Results.microlens), ...
        %             dockerWrapper.pathToLinux(p.Results.combinedlens));
        
    case 'help'
        if isempty(p.Results.helpparameter)
            helpCmd = sprintf('lenstool ');
        else % not sure if this works for lenstool?
            helpCmd = sprintf('lenstool help %s ',p.Results.helpparameter);
        end
        cmd = sprintf('%s %s %s ', ...
            runDocker, dockerImage, helpCmd);       
        system(cmd);
end

% Run it and show any result.  Maybe
[status,result] = system(cmd);
output = p.Results.combinedlens;
if p.Results.verbose
    fprintf('Status %d (0 is good)\n',status);
    if ~isempty(result)
        disp(result)
    end
end

        
end
