function init(obj,varargin)
% Initialize the dockerWrapper parameters using these values
%
%
% See also
%

% Examples
%{
  params = getpref('docker');
  thisD = dockerWrapper;
  thisD.init(params);
  thisR = piRecipeDefault('scene name','ChessSet');
  piWRS(thisR,'remote resources', true);
%}

%%
p = inputParser;
% p.addParameter('machine', 'default', @ischar);
% p.addParameter('debug', false, @islogical);
p.addParameter('verbosity', 0, @isnumeric); %

p.addParameter('gpuRendering', true, @islogical);
p.addParameter('whichGPU', -1, @isnumeric); % select gpu, -1 for default
p.addParameter('defaultContext', 'default', @ischar);

p.addParameter('remoteRoot','',@ischar); % for different remote path
p.addParameter('remoteUser','',@ischar); % for data sync
p.addParameter('remoteImage', '', @ischar); % image to use for remote render
p.addParameter('remoteImageTag', 'latest', @ischar); % image to use for remote render
p.addParameter('remoteResources',false,@islogical); % for different remote path
p.addParameter('renderContext', '', @ischar); % experimental
p.addParameter('remoteMachine','',@ischar); % for data sync

p.addParameter('localRoot','',@ischar); % for Windows/wsl
p.addParameter('localRender',false,@islogical);
p.addParameter('localImage','',@ischar);
p.addParameter('localImageTag','latest',@ischar);
p.addParameter('localVolumePath','',@ischar);

p.parse(varargin{:});

args = p.Results;

if ~isempty(args.verbosity)
    setpref('docker','verbosity', args.verbosity);
end
if ~isempty(args.gpuRendering)
    obj.gpuRendering = args.gpuRendering;
end

if args.whichGPU == -1 % theoretically any, but now just 0
    obj.whichGPU = 0;
else
    obj.whichGPU = args.whichGPU;
end

% Remote
if ~isempty(args.remoteMachine)
    obj.remoteMachine = args.remoteMachine;
end

if ~isempty(args.remoteUser)
    obj.remoteUser = args.remoteUser;
end

if ~isempty(args.remoteRoot)
    obj.remoteRoot = args.remoteRoot;
end

% since the remote system might have a different GPU
% currently we need to have that passed in as well
if ~isempty(args.remoteImage)
    obj.remoteImage = args.remoteImage;
end
if ~isempty(args.remoteImageTag)
    obj.remoteImageTag = args.remoteImageTag;
end

if ~isempty(obj.remoteImage) && ~contains(obj.remoteImage,':') % add tag
    obj.remoteImage = [obj.remoteImage ':' obj.remoteImageTag];
end

if ~isempty(args.remoteResources)
    obj.remoteResources = args.remoteResources;
end

if ~isempty(args.renderContext)
    dockerWrapper.staticVar('set','renderContext', args.renderContext);
end

% Local
if ~isempty(args.localRoot)
    obj.localRoot = args.localRoot;
end
if ~isempty(args.localRender)
    obj.localRender = args.localRender;
end
if ~isempty(args.localImageTag)
    obj.localImageTag = args.localImageTag;
end

% Configure the Matlab environment and initiate the docker-machine
% piDockerConfig;

end

