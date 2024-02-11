function [status,result,dockercmd] = piDockerImgtool(command,varargin)
% Use imgtool for various PBRT related tasks
%
% Brief description
%   Uses the Docker Container to run the imgtool.
%
% Synopsis
%   [status,result,dockercmd] = piDockerImgtool(command,varargin)
%
% Inputs
%   command:  The imgtool command.  Options are
%      help
%      make equiarea
%      make sky - Makes an exr skymap with name sky-
%      convert  - Conversion between various file types
%      denoise  - We have other denoisers, haven't tested this one
%
% Optional key/val pairs
%   infile:   Full path to the input file
%   outfile:  Full path to the output file (if needed)
%   msparms:  make sky parameters.  Select from: {albedo, elevation,
%                    outfile, turbidity, resolution} 
%
% Outputs
%   status    - 0 means success
%   result    - Text returned by the command
%   dockercmd - The docker command
%
% See also
%   piAIDenoise, tev (executable viewer for the exr files)
%   piEXRDenoise

%{
% Other imgtool commands
%
% imgtool convert
% imgtool makesky
% imgtool bloom
% imgtool average
% imgtool makeequiarea old.exr --outfile new.exr
%
%}
% Example:
%{
   piDockerImgtool('help')
   [~,result] = piDockerImgtool('help','help parameter','convert');
%}
%{
infile = '20060807_wells6_hd.exr';
infile = 'room.exr';
infile = 'brightfences.exr';
infile = which(infile);
data = piDockerImgtool('makeequiarea','infile',infile)
%}
%{
exrfile = 'wtn-texture3-grass.exr'
exrfile = 'wtn-hurricane2.exr';
exrfile = which(exrfile);
piDockerImgtool('makeequiarea','infile',exrfile);

%}

%% Parse

command = ieParamFormat(command);
varargin = ieParamFormat(varargin);

p = inputParser;

validCommands = {'makesky','makeequiarea','convert','denoise','help'};
p.addRequired('command',@(x)(ismember(x,validCommands)));
p.addParameter('infile','',@(x)(exist(x,'file')));
p.addParameter('outfile','',@ischar);

p.addParameter('dockerimage',dockerWrapper.localImage(),@ischar);

p.addParameter('helpparameter','',@ischar);
p.addParameter('verbose',true,@islogical);

% Maybe outfile should be handled separately as above.
validMSparams = {'albedo', 'elevation', 'outfile', 'turbidity', 'resolution'};
p.addParameter('msparams','',@(x)(ismember(x,validMSparams)));

% dockerimage = 'camerasimulation/pbrt-v4-cpu:latest';
p.parse(command,varargin{:});

dockerimage = p.Results.dockerimage;

if ~isempty(p.Results.infile)
    % Extract working dir and file name for the docker
    infile = p.Results.infile;
    [workdir, fname, ext] = fileparts(infile);
    fname = [fname,ext];
end

%% Switch on the cmds

% Read the exr file and convert into the same directory
if ~ispc
    runDocker = 'docker run -ti ';
else
    runDocker = 'docker run -i ';
end

switch command
    case 'help'
        % piDockerImgtool('help','help parameter','convert')
        % piDockerImgtool('help','help parameter','makesky')
        basecmd = [runDocker ' %s %s'];
        if isempty(p.Results.helpparameter)
            cmd = sprintf('imgtool ');
        else
            cmd = sprintf('imgtool help %s ',p.Results.helpparameter);
        end
        dockercmd = sprintf(basecmd, dockerimage, cmd);

    case 'convert'
        % piDockerImgtool('convert','infile',fullfile(pwd,'pngExample.png'), 'outfile','pngExample.exr')
        basecmd = [runDocker ' --workdir=%s --volume="%s":"%s" %s %s'];

        if isempty(p.Results.outfile)
            % Assume exr extension with same file name
        else, outfile = p.Results.outfile;
        end

        cmd = sprintf('imgtool convert --outfile %s %s ', ...
            dockerWrapper.pathToLinux(outfile), dockerWrapper.pathToLinux(fname));

        dockercmd = sprintf(basecmd, ...
            dockerWrapper.pathToLinux(workdir), ...
            workdir, ...
            dockerWrapper.pathToLinux(workdir), ...
            dockerimage, ...
            cmd);

        %{
        usage: imgtool convert [options] <filename>
        options:
           --aces-filmic      Apply the ACES filmic s-curve to map values to [0,1].
           --bw               Convert to black and white (average channels)
           --channels <names> Process the provided comma-delineated set of channels.
                       Default: R,G,B.
            --clamp <value>    Rescale pixel components if necessary so that they do not
                       exceed <value>. Default: no clamping.
          --crop <x0,x1,y0,y1> Crop image to the given dimensions. Default: no crop.
           --colorspace <n>   Convert image to given colorspace.
                       (Options: "ACES2065-1", "Rec2020", "DCI-P3", "sRGB")
           --despike <v>      For any pixels with a luminance value greater than <v>,
                       replace the pixel with the median of the 3x3 neighboring
                       pixels. Default: infinity (i.e., disabled).
         --flipy            Flip the image along the y axis
          --gamma <v>        Apply a gamma curve with exponent v. (Default: 1 (none)).
          --maxluminance <n> Luminance value mapped to white by tonemapping.
                       Default: 1
          --outfile <name>   Output image filename.
         --preservecolors   By default, out-of-gammut colors have each component
                       clamped to [0,1] when written to non-HDR formats. With
                       this option enabled, such colors are scaled by their
                       maximum component, which preserves the relative ratio
                       between RGB components.
         --repeatpix <n>    Repeat each pixel value n times in both directions
            --scale <scale>    Scale pixel values by given amount
            --tonemap          Apply tonemapping to the image (Reinhard et al.'s
                       photographic tone mapping operator)
           --exr2bin [<ch1,ch2...>|<chx:chy>]
                      Convert input .exr file to binary file according to channels specified.
                      --outfile <path\to\output\dir\filename> can be specifiled for output path.
                      e.g. imgtool convert --exr2bin 1,2,3,5 pbrt.exr
                      e.g. imgtool convert --exr2bin 1:5 pbrt.exr
                      e.g. imgtool convert --exr2bin B,G,R,Radiance.C05 pbrt.exr
                      e.g. imgtool convert --exr2bin Radiance --outfile /path/to/dir/ pbrt.exr
                      e.g. imgtool convert --exr2bin Radiance --outfile /path/to/dir/filename pbrt.exr
                      Default: all channels at the same directory with pbrt.exr
        %}
    case {'denoise'}
        % piDockerImgtool('denoise','infile',fullPathFile)
        %{
            usage: imgtool denoise [options] <filename>
            options: options:
                --outfile <name>   Filename to use for the denoised image.
        %}

        % I tried running on a rendered file, but got an error that it
        % could not find the Pz channel.  To ask - (BW).
        % Brian -- It needs Pz (z depth) so the rendered file needs to have
        % it
        % HOWEVER
        % I just tried and get missing dzdx and dzdy, which I've never seen
        % maybe those are only generated for RGB images? - (DJC)
        
        basecmd = [runDocker ' --workdir=%s --volume="%s":"%s" %s %s'];
        cmd = sprintf('imgtool denoise %s --outfile denoise-%s', ...
            dockerWrapper.pathToLinux(fname), dockerWrapper.pathToLinux(fname));

        dockercmd = sprintf(basecmd, ...
            dockerWrapper.pathToLinux(workdir), ...
            workdir, ...
            dockerWrapper.pathToLinux(workdir), ...
            dockerimage, ...
            cmd);
    case 'denoise-optix'
        % only works with Nvidia GPU and optix library
        %{
        fullPathFile = which('room.exr');
        piDockerImgtool('denoise-optix','infile',fullPathFile,'dockerimage','digitalprodev/pbrt-v4-gpu-ampere-ti')
        %}
        runDocker = [runDocker ' --gpus all'];
        basecmd = [runDocker ' --workdir=%s --volume="%s":"%s" %s %s'];
        cmd = sprintf('imgtool denoise-optix %s --outfile denoise-%s', ...
            dockerWrapper.pathToLinux(fname), dockerWrapper.pathToLinux(fname));

        dockercmd = sprintf(basecmd, ...
            dockerWrapper.pathToLinux(workdir), ...
            workdir, ...
            dockerWrapper.pathToLinux(workdir), ...
            dockerimage, ...
            cmd);
    case 'makeequiarea'
        %  piDockerImgtool('make equiarea','infile',filename);

        basecmd = [runDocker ' --workdir=%s --volume="%s":"%s" %s %s'];

        cmd = sprintf('imgtool makeequiarea %s --outfile equiarea-%s', ...
            dockerWrapper.pathToLinux(fname), dockerWrapper.pathToLinux(fname));
        dockercmd = sprintf(basecmd, ...
            dockerWrapper.pathToLinux(workdir), ...
            workdir, ...
            dockerWrapper.pathToLinux(workdir), ...
            dockerimage, ...
            cmd);

    case 'makesky'
        % piDockerImgtool('makesky','infile',fname, ... params ...)

        workdir = pwd;
        basecmd = [runDocker ' --workdir=%s --volume="%s":"%s" %s %s'];

        str = datestr(now,'YYYY-mm-DD-HH-MM');

        %{
        % Add these additional options for makesky
        % usage: imgtool makesky [options] <filename>
        options:
        
        --albedo <a>       Albedo of ground-plane (range 0-1). Default: 0.5
        
        --elevation <e>    Elevation of the sun in degrees (range 0-90). Default: 10
        
        --outfile <name>   Filename to store environment map in.
        
        --turbidity <t>    Atmospheric turbidity (range 1.7-10). Default: 3
        
        --resolution <r>   Resolution of generated environment map. Default: 2048
        %}
        cmd = sprintf('imgtool makesky --outfile sky-%s.exr',str);

        dockercmd = sprintf(basecmd, ...
            dockerWrapper.pathToLinux(workdir), ...
            workdir, ...
            dockerWrapper.pathToLinux(workdir), ...
            dockerimage, ...
            cmd);

end

% Run dockercmd and show any result.  Maybe
[status,result] = system(dockercmd);
if p.Results.verbose || status ~= 0
    fprintf('Run command:  %s\n',cmd);
    fprintf('Status %d (0 is good)\n',status);
    if ~isempty(result)
        disp(result)
    end
end


end
