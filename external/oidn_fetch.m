function folderName = oidn_fetch(repoOwner, repoName)
    % Define the GitHub API URL for the latest release
    apiUrl = ['https://api.github.com/repos/', repoOwner, '/', repoName, '/releases/latest'];

    % Fetch the latest release data
    options = weboptions('ContentType', 'json');
    releaseData = webread(apiUrl, options);

    % Identify the correct asset based on the platform
    platformName = computer;
    if contains(platformName, 'WIN')
        platformName = 'windows';
    elseif contains(platformName, 'MAC')
        platformName = 'macos';
    elseif contains(platformName, 'GLNX')
        platformName = 'linux';
    end

    for i = 1:numel(releaseData.assets)
        asset = releaseData.assets(i);
        if contains(asset.name, platformName)
            downloadUrl = asset.browser_download_url;
            fileName = asset.name;
            folderName = strrep(fileName, '.tar.gz', '');
            if isfolder(folderName)
                disp(['Folder already exists: ', folderName]);
                return;
            end

            % Download the file
            websave(fileName, downloadUrl);
            disp(['Download completed: ', fileName]);

            % Unzip if it's a .tar.gz file
            gunzip(fileName);
            untar(strrep(fileName, '.gz', ''));
            delete(fileName);  % Clean up the tar.gz file
            disp(['Extracted ', fileName, ' into folder: ', folderName]);
            return;
        end
    end

    error('No suitable asset found for the current platform.');
end
