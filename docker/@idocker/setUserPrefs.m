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
%   myObj = idocker();
%   setUserPrefs(myObj);
%
% Zhenyi, Stanford, 2024

prefGroupName = 'ISETDocker';

% Check if preferences have already been set
if ispref(prefGroupName)
    updateChoice = input('User preferences already set. Do you want to update them? [y/n]: ', 's');
    if strcmpi(updateChoice, 'n')
        disp('Preferences update canceled.');
        updateChoice = input('Do you want to check your preferences? [y/n]: ', 's');
        if strcmpi(updateChoice, 'y')
            disp('-----Preferences Summary-----');
            listPrefs(groupName)
        end
        return;
    end
end

% Prompt user for device preference
device = input('Choose a device (GPU/CPU) [g/c]: ', 's');
if strcmpi(device,'g')
    device = 'gpu';
elseif strcmpi(device,'c')
    device = 'cpu';
end
% Prompt user for device ID
deviceID = input('Enter device ID (-1 for none or CPU): ');

% Define presets for the render context and prompt user to choose or type their own
disp('Available render contexts:');
disp('1. remote-orange');
disp('2. remote-mux');
disp('3. Use my own');
renderContextChoice = input('Choose a render context (1-3): ');

switch renderContextChoice
    case 1
        renderContext = 'remote-orange';
    case 2
        renderContext = 'remote-mux';
    otherwise
        renderContext = input('Enter your custom render context: ', 's');
end

% Additional prompts based on selected renderContext
if ~strcmpi(renderContext, 'Type yours') && ~isempty(renderContext)
    remoteUser = input('Enter remote user name: ', 's');
    remoteWorkDir = ['/home/' remoteUser '/ISETRemoteRender'];

    switch renderContext
        case 'remote-orange'
            remoteHost = 'orange.stanford.edu';
            dockerImage = 'digitalprodev/pbrt-v4-gpu-ampere-ti';
        case 'remote-mux'
            remoteHost = 'mux.stanford.edu';
            dockerImage = 'digitalprodev/pbrt-v4-gpu-volta-mux';
        otherwise
            remoteHost = input('Enter remote host address: ', 's');
    end
end

if strcmpi(device, 'cpu')
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
setpref(prefGroupName, 'renderContext', renderContext);
setpref(prefGroupName, 'remoteHost', remoteHost);
setpref(prefGroupName, 'remoteUser', remoteUser);
setpref(prefGroupName, 'remoteWorkDir', remoteWorkDir);
if ~isempty(remoteHost)
    if strcmpi(renderContext,'remote-orange') || strcmpi(renderContext,'remote-mux')
        remotePBRTResources = '/acorn/data/iset/PBRTResources';
    else
        remotePBRTResources = input('Enter your remote PBRT resources path: ', 's');
    end
    setpref(prefGroupName, 'remotePBRTResources', remotePBRTResources);
end

% Set object properties
obj.device = device;
obj.deviceID = deviceID;
obj.dockerImage = dockerImage;
obj.remoteHost = remoteHost;
obj.remoteUser = remoteUser;
obj.remoteWorkDir = remoteWorkDir;
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


