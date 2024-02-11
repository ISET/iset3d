function  setPrefs(varargin)
% Set a Matlab pref (getpref('docker')) variables.
%
% Syntax
%    dockerWrapper.setPrefs(varargin)
%
% Brief synopsis
%  Interface to Matlab setpref(), getpref().  The Matlab prefs are
%  persistent across Matlab sessions.  When these parameters are changed,
%  dockerWrapper.reset() is called.
%
% If you call this with no arguments, nothing happens.  The general
% call should be 
%
%    dockerWrapper.setPrefs('remoteImage','YOUR IMAGE HERE');
%
% Inputs
%   N/A
%
% Key/Val pairs - hopefully meaning is clear (see examples below)
%
%   verbosity - Controls printouts during rendering (0,1 or 2)
%   whichGPU  - When multiple GPUs are present, selects
%   gpuRendering - True/False
%
%   remoteMachine - machine (e.g., mux.stanford.edu)
%   remoteUser    - User name on remote machine
%   remoteRoot    - User root directory on remote machine
%   remoteImage   - Docker image to be used, otherwise default from
%   ...
%   remoteImageTag - Usually 'latest'
%   remoteContext  - Often remote-mux.  You can use
%                       docker context list
%                    to see the contexts on your machine
%
%   localRoot     -  Mainly needed for Windows (WSL).  This is the
%                    drive root 
%   localRender   -  True/false  (render remotely or on user's local
%                    computer)
%   localVolumePath - Directory that will be mounted by the
%                     Docker image.  Also called hostLocalPath in the
%                     dockerWrapper code.
%
% Return
%   No return.  Changes the Matlab prefs.  To see the new prefs use
%
%      dockerWrapper.getPrefs
%
% Notes
%   developed to replace dockerWrapper.setParams
%
% See also
%   dockerWrapper.getPrefs;  

%% Parse

p = inputParser;
p.addParameter('verbosity','',@isnumeric);
p.addParameter('whichGPU','',@isnumeric);
p.addParameter('gpuRendering','',@islogical);
p.addParameter('gpuRender','',@islogical);
p.addParameter('remoteMachine','',@ischar);
p.addParameter('remoteUser','',@ischar);
p.addParameter('remoteImage','',@ischar);
p.addParameter('remoteImageTag','',@ischar);
p.addParameter('remoteRoot','',@ischar);
p.addParameter('remoteRender','',@islogical);  % Inverted form of localRender

% for using shared resources
p.addParameter('remoteResources','',@islogical);

p.addParameter('renderContext','',@ischar);

p.addParameter('localRoot','',@ischar);
p.addParameter('localRender','',@islogical);
p.addParameter('localImageTag','',@ischar);
p.addParameter('localVolumePath','',@ischar);
p.parse(varargin{:});

%%
% Interface
if ~isempty(p.Results.verbosity)
    setpref('docker','verbosity', p.Results.verbosity);
end

% GPU related parameters
if ~isempty(p.Results.whichGPU)
    setpref('docker','whichGPU', p.Results.whichGPU);
end
if ~isempty(p.Results.gpuRendering)
    setpref('docker','gpuRendering', p.Results.gpuRendering);
end

% An alias for gpuRendering, because I often forget which string is
% right.
if ~isempty(p.Results.gpuRender)
    setpref('docker','gpuRendering', p.Results.gpuRender);
end

% Remote rendering parameters
if ~isempty(p.Results.remoteUser)
    setpref('docker', 'remoteUser', p.Results.remoteUser);
end
if ~isempty(p.Results.remoteImage)
    setpref('docker', 'remoteImage', p.Results.remoteImage);
end
if ~isempty(p.Results.remoteImageTag)
    setpref('docker', 'remoteImageTag', p.Results.remoteImageTag);
end
if ~isempty(p.Results.remoteRoot)
    setpref('docker', 'remoteRoot', p.Results.remoteRoot);
end
if ~isempty(p.Results.renderContext)
    setpref('docker', 'renderContext', p.Results.renderContext);
end
if ~isempty(p.Results.remoteMachine)
    setpref('docker', 'remoteMachine', p.Results.remoteMachine);
end
if ~isempty(p.Results.remoteResources)
    setpref('docker', 'remoteResources', p.Results.remoteResources);
end

% Local rendering parameters
if ~isempty(p.Results.localRoot)
    % We think this is the local root on either the remote machine or
    % the local machine.  It is local w.r.t. the container.
    setpref('docker', 'localRoot', p.Results.localRoot);
end

% Some people want to set remote render true/false.  So we flip the
% sign for them and call the localRender set.
if ~isempty(p.Results.remoteRender)
    dockerWrapper.setPrefs('localRender',~p.Results.remoteRender);
end
if ~isempty(p.Results.localRender)
    % Run the container on the user's local machine.  This is a
    % logical variables, default's to false.
    setpref('docker', 'localRender', p.Results.localRender);
    if p.Results.localRender
        if getpref('docker','gpuRendering','')
            disp('Set for local GPU rendering.')
        else
            disp('Set for local CPU rendering.');
        end
    end
end
if ~isempty(p.Results.localImageTag)
    % By default this will be 'latest'
    setpref('docker', 'localImageTag', p.Results.localImageTag);
end
if ~isempty(p.Results.localVolumePath)
    % By default this will be 'latest'
    setpref('docker', 'localVolumePath', p.Results.localVolumePath);
end

% If you change these parameters, we need to reset the dockerWrapper.
% Not sure I understand this (BW).
dockerWrapper.reset;

end

