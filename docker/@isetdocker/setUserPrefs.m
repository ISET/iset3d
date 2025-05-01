function setUserPrefs(obj)
%% Sets user-specific preferences for a Docker wrapper application.
% 
% Syntax:
%   setUserPrefs(obj)
%
% Description:
%   This function prompts the user to set various preferences related to
%   Docker container management. It allows updating preferences if they are
%   already set and provides an option to review current preferences.
%
% Inputs:
%   obj - An object that stores the user preferences as properties.
%
% Outputs:
%   None. The function directly modifies the input object's properties
%   and saves preferences using MATLAB's setpref function.
%
% Example:
% isetdocker.setUserPrefs();
%
% Zhenyi, Stanford, 2024

prefGroupName = 'ISETDocker';

% Check if preferences have already been set
if ispref(prefGroupName)
    disp('Preferences already set:');
    listPrefs(prefGroupName)
    disp('');
    updateChoice = input('Do you want to update these preferences? [Y/n]: ', 's');
    if strcmpi(updateChoice, 'n')
        disp('Preferences update canceled.');
        return;
    end
end

% Define presets for the render context and prompt user to choose or type their own
disp('Available render contexts:');
disp('1. remote-orange');
disp('2. remote-mux');
disp('3. local-orange');
disp('4. local-mux');
disp('5. Use my own');
renderContextChoice = input('Choose a render context (1-5): ');

switch renderContextChoice
    case 1
        renderContext = 'remote-orange';
    case 2
        renderContext = 'remote-mux';
    case 3
        % Should become vistalab/pbrt-v4-gpu
        renderContext = 'default';
        dockerImage = 'digitalprodev/pbrt-v4-gpu-ampere-ti';
    case 4
        renderContext = 'default';
        dockerImage = 'vistalab/pbrt-v4-gpu';
    otherwise
        renderContext = input('Enter your custom render context: ', 's');
end

switch renderContext
    case 'remote-orange'
        remoteHost = 'orange.stanford.edu';
        dockerImage = 'digitalprodev/pbrt-v4-gpu-ampere-ti';
    case 'remote-mux'
        remoteHost = 'mux.stanford.edu';
        dockerImage = 'vistalab/pbrt-v4-gpu';
    case 'default'
        remoteHost = '';
    otherwise
        remoteHost = input('Enter remote host address: ', 's');
end
% Additional prompts based on selected renderContext
if ~strcmpi(renderContext, 'Use my own') && ~isempty(renderContext) &&...
    ~contains(renderContext,'default')
    remoteUser = input('Enter remote user name: ', 's');
    workDir = ['/home/' remoteUser '/ISETRemoteRender'];
else
    remoteUser = '';
    % username = char(java.lang.System.getProperty('user.name'));
    workDir = fullfile(piRootPath,'local');
end

% Prompt user for device preference
device = input('Choose a device (GPU/CPU) [g/c]: ', 's');
if strcmpi(device,'g')
    device = 'gpu';
    if ~isempty(remoteHost) && ~isempty(remoteUser)
        [status, remoteGPUAttrs]=isetdocker.getGpuAttrs(remoteUser, remoteHost);
        if ~status
            fprintf('Avaliable GPU on %s:\n',renderContext);
            for ii  = 1:numel(remoteGPUAttrs)
                disp(remoteGPUAttrs(ii));
            end
        else
            disp('[INFO]: Could not get remote GPU information.');
        end
    end
    % Prompt user for device ID
    deviceID = input('Enter device ID: ','s');
elseif strcmpi(device,'c')
    device = 'cpu';
    deviceID = '';
    dockerImage = 'digitalprodev/pbrt-v4-cpu';
    customImageChoice = input('Use digitalprodev/pbrt-v4-cpu, do you want to set your own? [y/n]: ', 's');
    if strcmpi(customImageChoice, 'y')
        dockerImage = input('Enter Docker image name: ', 's');
    end
end

% Set preferences
setpref(prefGroupName, 'device', lower(device));
setpref(prefGroupName, 'deviceID', deviceID);
setpref(prefGroupName, 'dockerImage', dockerImage);
setpref(prefGroupName, 'workDir', workDir);
setpref(prefGroupName, 'renderContext', renderContext);
setpref(prefGroupName, 'remoteHost', remoteHost);
setpref(prefGroupName, 'remoteUser', remoteUser);

% if ~isempty(remoteHost)
if strcmpi(renderContext,'remote-orange') || strcmpi(renderContext,'remote-mux') || strcmpi(renderContext,'default')
    PBRTResources = '/acorn/data/iset/PBRTResources';
else
    PBRTResources = input('Enter your remote PBRT resources path: ', 's');
end
setpref(prefGroupName, 'PBRTResources', PBRTResources);
% end

% Set object properties
obj.device = device;
obj.deviceID = deviceID;
obj.dockerImage = dockerImage;
obj.remoteHost = remoteHost;
obj.remoteUser = remoteUser;
obj.workDir = workDir;
obj.renderContext = renderContext;

disp('[INFO]: User preferences have been set.');
updateChoice = input('Do you want to check your preferences? [y/n]: ', 's');
if strcmpi(updateChoice, 'y')
    disp('-----Preferences Summary-----');
    listPrefs(prefGroupName)
end
end


function listPrefs(groupName)
%% Lists preferences within a specified preference group.
%
% Syntax:
%   listPrefs(groupName)
%
% Description:
%   This function retrieves and displays all preferences within the
%   specified preference group.
%
% Inputs:
%   groupName - Name of the preference group to list preferences from.
%
% Outputs:
%   None. The function displays preferences in the command window.
%
% Example:
%   listPrefs('ISETDocker');

if ispref(groupName)
    % Retrieve all preferences within the specified group
    prefs = getpref(groupName);

    % Display the group name
    fprintf('Preferences in group "%s":\n', groupName);

    % Iterate through each preference in the group and display its name and value
    prefNames = fieldnames(prefs); % Get names of individual preferences
    for i = 1:numel(prefNames)
        prefName = prefNames{i};
        prefValue = prefs.(prefName);
        fprintf('  %s: %s\n', prefName, mat2str(prefValue));
    end
else
    fprintf('Preference group "%s" does not exist.\n', groupName);
end
end


