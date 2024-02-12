function init(obj,varargin)
        device
        dockerImage
        % remote
        remoteHost
        remoteUser
        remoteWorkDir
        remoteContext
        sftpSession
%%
varargin = ieParamFormat(varargin);

p = inputParser;
p.addParameter('device','gpu', @ischar); 
p.addParameter('dockerimage', '', @ischar);

p.addParameter('remotehost','',@ischar); 
p.addParameter('remoteuser','',@ischar); % for data sync
p.addParameter('remoteworkdir', '', @ischar); % image to use for remote render
p.addParameter('remotecontext', '', @ischar); % experimental
p.addParameter('remotemachine','',@ischar); % for data sync


p.parse(varargin{:});

args = p.Results;

if ~isempty(args.device)
    obj.device = args.device;
end

if ~isempty(args.dockerimage)
    obj.dockerImage = args.dockerimage;
end

if ~isempty(args.remotehost)
    obj.remoteHost = args.remotehost;
end

if ~isempty(args.remoteuser)
    obj.remoteUser = args.remoteuser;
end

if ~isempty(args.remoteworkdir)
    obj.remoteWorkDir = args.remoteworkdir;
end

if ~isempty(args.remoteworkdir)
    obj.remoteWorkDir = args.remoteworkdir;
end

if ~isempty(args.remotecontext)
    obj.remoteContext = args.remotecontext;
end

% connect the server
obj.connect();

end

