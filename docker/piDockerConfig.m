function status = piDockerConfig(varargin)
% Configure the Matlab environment and initiate the docker-machine
%
%   status = piDockerConfig(varargin)
%
% Description:
%   Sets up the Matlab environment to run Docker containers for
%   ISET3d.
%
%
% INPUTS:
%    'machine' - [Optional, type=char, default='default']
%                Name of the docker-machine on OSX. Should exist.
%    'debug'   - [Optional, type=logical, default=false]
%                If true then messages are displayed throughout the
%                process, otherwise we're quiet save for an error.
%
% OUTPUTS:
%    status    - boolean where 0=success and >0 denotes failure.
%
% EXAMPLE:
%    [status] = piDockerConfig('machine', 'default', 'debug', true);
%
% Notes:
%  Initializing for remote GPU rendering requires specifying the docker
%  image on the remote site, and also which GPU on that site.  These
%  combinations work on mux:
%
%{
%  These docker files are no longer accurate - BW
%
   'whichGPU' ,0, 'remoteImage, 'digitalprodev/pbrt-v4-gpu-ampere-mux'
   ‘whichGPU’ ,1, ‘remoteImage', ‘digitalprodev/pbrt-v4-gpu-volta-mux’
   ‘whichGPU’ ,2, ‘remoteImage', ‘digitalprodev/pbrt-v4-gpu-volta-mux’
%}
%
%   If you have a local GPU, ISET will attempt to find the correct GPU
%   image, if available. Otherwise it will default to:
%
%       digitalprodev/pbrt-v4-cpu
%
% NOTES: We are attempting to maintain both a :latest and a :stable
%       tag for the GPU and CPU images.
%
%
%   You can check that docker context exists this way
%
%       cmd = 'docker context list';
%       [str,r] = system(cmd)
%
%   Look in the r variable to find whether getpref remote context
%   exists.
%
%   For the GPU on V4, we might be able to config the docker context
%   for people.  That command is:
%
%       docker context create --docker host=ssh://wandell@mux.stanford.edu wandell-v4
%
%   renderString = getpref('docker','renderString');
%
% This might change, but for now, find 'renderContext' and the next
% argument is the context.
%
%
% (C) Stanford VISTA Lab, 2016

%% Parse input arguments

p = inputParser;
p.addParameter('machine', 'default', @ischar);
p.addOptional('debug', false, @islogical);
% p.addOptional('gpuRendering', 'true', @boolean);
% p.addOptional('remoteHost', '', @ischar); % experimental
% p.addOptional('remoteImage', '', @ischar); % image to use for remote render

p.parse(varargin{:})

args = p.Results;

% Causes an error if compiled!
if ~isdeployed
    %% Configure Matlab ENV for the machine

    % MAC OSX
    if ismac

        % By default, docker-machine and docker for mac are installed in
        % /usr/local/bin:
        initPath = getenv('PATH');
        if ~piContains(initPath, '/usr/local/bin')
            if args.debug
                disp('Adding ''/usr/local/bin'' to PATH.');
            end
            setenv('PATH', ['/usr/local/bin:', initPath]);
        end

        % Check for "docker for mac"
        [status, ~] = system('docker ps -a');
        if status == 0
            if args.debug
                disp('Docker configured successfully!');
                system('which docker', '-echo');
            end
            return
        elseif exist('/Applications/Docker.app/Contents/MacOS/Docker', 'file')
            if args.debug
                disp('Starting Docker for Mac...')
            end
            [s, ~] = system('open /Applications/Docker.app');
            [status, ~] = system('which docker', '-echo');
            if s==0 && status==0
                if args.debug
                    disp('Docker configured successfully!');
                    system('docker -v', '-echo');
                end
            end
            return
        end

        % Check that docker machine is installed
        [status, version] = system('docker-machine -v');
        if status == 0
            if args.debug
                fprintf('Found %s\n', version);
            end
        else
            error('%s \nIs docker-machine installed?', version);
        end

        % Check that the machine is running
        [~, result] = system(sprintf('docker-machine status %s', args.machine));
        if strcmp(strtrim(result),'Running')
            if args.debug
                fprintf('docker-machine ''%s'' is running.\n', args.machine);
            end

            % Start the machine
        else
            fprintf('Starting docker-machine ''%s'' ... \n', args.machine);
            [status, result] = system(sprintf('docker-machine start %s', args.machine), '-echo');
            if status && piContains(strtrim(result), 'not exist')

                % Prompt to create the machine
                resp = input('Would you like to create the machine now? (y/n): ', 's');
                if lower(resp) == 'y'
                    [status, result] = system(sprintf('docker-machine create -d virtualbox %s', args.machine), '-echo');
                    if status
                        error(result);
                    else
                        fprintf('The machine ''%s'' is up and running!\n', args.machine);
                    end
                else
                    warning(result);
                    status = 1;
                    return
                end
            end
        end

        % Get the docker env variables for the machine
        [status, docker_env] = system(sprintf('docker-machine env %s', args.machine));
        if status ~= 0; error(docker_env); end

        % Configure the Matlab ENV based on the machine ENV
        docker_env = strsplit(docker_env);
        docker_env_vars = {};
        for ii = 1:numel(docker_env)
            if strfind(docker_env{ii}, 'DOCKER')
                docker_env_vars{end+1} = docker_env{ii}; %#ok<AGROW>
            end
        end
        if args.debug
            fprintf('Configuring docker-machine env for machine: [%s] ...\n', args.machine);
        end
        for jj = 1:numel(docker_env_vars)
            env_var = strsplit(docker_env_vars{jj},'"');
            setenv(strrep(env_var{1},'=',''), env_var{2});
            if args.debug
                fprintf('%s=%s\n', strrep(env_var{1},'=',''), getenv(strrep(env_var{1},'=','')));
            end
        end

        % Check that the configuration worked
        [status, result] = system('docker ps -a');
        if status == 0
            if args.debug
                disp('Docker configured successfully!');
            end
            % dockerWrapper.config(args);
        else
            error('Docker could not be configured: %s', result);
        end

        % LINUX
    elseif isunix

        % Check for docker
        [status, result] = system('docker ps -a');
        if status == 0
            if args.debug; disp('Docker configured successfully!'); end
            % dockerWrapper.config(args);
        else
            if (args.debug); fprintf('Docker status: %d\n',status); end
            error('Docker not configured: %s', result);
        end
    elseif ispc
        % Check for docker
        [status, result] = system('docker ps -a');
        if status == 0
            if args.debug; disp('Docker configured successfully!'); end
            % dockerWrapper.config(args);
        else
            if (args.debug); fprintf('Docker status: %d\n',status); end
            error('Docker not configured: %s', result);
        end
    end
end
