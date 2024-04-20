function folderName = oidn_fetch(repoOwner, repoName)
% Define the GitHub API URL for the latest release
%
% Example:
%   oidn_fetch('OpenImageDenoise','oidn');
%
% This will download 

apiUrl = ['https://api.github.com/repos/', repoOwner, '/', repoName, '/releases/latest'];

% Fetch the latest release data
options = weboptions('ContentType', 'json');
releaseData = webread(apiUrl, options);

% Identify the correct asset based on the platform
platformName = computer;
arch = [];
if contains(platformName, 'WIN')
    platformName = 'windows';
elseif contains(platformName, 'MAC')
    platformName = 'macos';

    % Distinguish Mac architectures
    arch = computer('arch');
    if isequal(arch,'maci64'), arch = 'x86';
    else, arch = 'arm';
    end
elseif contains(platformName, 'GLNX')
    platformName = 'linux';
end

for i = 1:numel(releaseData.assets)
    asset = releaseData.assets(i);

    % Additional test to distinguish ARM and Intel Mac
    if contains(asset.name, platformName) && (isempty(arch) || contains(asset.name,arch))

        downloadUrl = asset.browser_download_url;
        fileName = fullfile(piRootPath,'external',asset.name);
        folderName = strrep(fileName, '.tar.gz', '');
        if isfolder(folderName)
            return;
        end

        % Download the file
        websave(fileName, downloadUrl);
        disp(['Download completed: ', fileName]);

        % Unzip if it's a .tar.gz file
        gunzip(fileName);
        untar(strrep(fileName, '.gz', ''),fullfile(piRootPath,'external'));
        
        % Delete both .tar and the tar.gz files
        delete(fileName);  
        delete(strrep(fileName,'.gz',''));

        disp(['Extracted ', fileName, ' into folder: ', folderName]);
        return;
    end
end

error('No suitable asset found for the current platform.');
end
