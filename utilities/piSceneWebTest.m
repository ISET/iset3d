function fname = piSceneWebTest(sceneName,sceneFile)
% Check for a web scene

% See if the scene is already in data/scene/web
FilePath = fullfile(piRootPath,'data','scenes','web',sceneName);
fname = fullfile(FilePath,sceneFile);

% Download the file to data/scene/web
if ~exist(fname,'file') && ~isfolder(FilePath)
    % Download and confirm.
    ieWebGet('resourcename', sceneName, 'resourcetype', 'pbrtv4', 'unzip', true);
    if ~exist(fname, 'file'), error('File not found'); end
else
    fprintf('File found %s in data/scene/web.\n',sceneName)
end

end