function [sceneDir, zipfilenames] = piSceneWebTest(sceneName,sceneFile)
% Get a PBRTV4 (ISET3d) scene from the Stanford Digital Repository (SDR)
%
% Synopsis
%  [sceneDir, zipfilenames] = piSceneWebTest(sceneName,sceneFile)
%
% The scene is downloaded into fullfile(piRootPath,'data','scenes','web')
%
% Input
%   sceneName
%   sceneFile
%
% Optional key/val
%   N/A
%
% Output
%  sceneDir     - Name of the directory of the downloaded scene
%  zipfilenames - Cell array of files in the directory
%
% Description
%  The sceneName should correspond to one of the lowercase.zip files in the
%  ISET3D Scenes deposit on SDR. To see all the scene names we currently
%  know about use
%
%    piSDRSceneNames
% 
%  There may be different acceptable
%  sceneFile strings for a sceneName.  For example, there are several
%  legitimate sceneFile names for the scenes bistro, dambreak, and others.
%
%  For bistro, we have sceneName as bistro and different sceneFiles, such
%  as bistro_vespa
%
%  The file piSceneDeposit has a list of the scenes in the different
%  subdirectories of the SDR.
%
% See also.
%   piSceneDeposit, piRead, piRecipeDefault, piRecipeCreate
%

zipfilenames = {};

% See if the scene is already in data/scene/web
sceneFileName = sceneFile;
sceneRoot = fullfile(piRootPath,'data','scenes','web');
localAssertNoCaseOnlyMatch(sceneRoot,sceneName);
sceneDir = fullfile(sceneRoot,sceneName);
localAssertNoCaseOnlyMatch(sceneDir,sceneFileName);
sceneFile = fullfile(sceneDir,sceneFileName);

% Download the file to data/scene/web
if ~localPathExistsExact(sceneRoot,sceneName)
    depositName = piSceneDeposit(sceneName);
    [sceneDir, zipfilenames] = ieWebGet('deposit name', depositName, ...
        'deposit file', [sceneName,'.zip'],  ...
        'download dir', sceneRoot,...
        'unzip', true, ...
        'confirm',false);
elseif ~localPathExistsExact(sceneDir,sceneFileName)
    error('Folder exists, but sceneFile (%s) is not there.\n',sceneFile);
else
    fprintf('File %s already present in %s.\n',sceneName,sceneDir)
end

end

function tf = localPathExistsExact(rootDir, relativePath)
%% True only when every path component matches the requested case.

tf = false;

if isempty(relativePath)
    tf = isfolder(rootDir);
    return;
end

if ~isfolder(rootDir)
    return;
end

pathParts = regexp(relativePath,'[\\/]+','split');
currentDir = rootDir;

for ii = 1:numel(pathParts)
    thisPart = pathParts{ii};
    if isempty(thisPart)
        continue;
    end

    dirListing = dir(currentDir);
    exactMatch = find(strcmp({dirListing.name},thisPart),1);
    if isempty(exactMatch)
        return;
    end

    if ii < numel(pathParts) && ~dirListing(exactMatch).isdir
        return;
    end

    currentDir = fullfile(currentDir,thisPart);
end

tf = true;

end

function localAssertNoCaseOnlyMatch(rootDir, relativePath)
%% Error when a path exists only through a case-insensitive match.

if isempty(relativePath) || ~isfolder(rootDir)
    return;
end

pathParts = regexp(relativePath,'[\\/]+','split');
currentDir = rootDir;

for ii = 1:numel(pathParts)
    thisPart = pathParts{ii};
    if isempty(thisPart)
        continue;
    end

    dirListing = dir(currentDir);
    dirNames = {dirListing.name};
    exactMatch = find(strcmp(dirNames,thisPart),1);

    if ~isempty(exactMatch)
        if ii < numel(pathParts) && ~dirListing(exactMatch).isdir
            return;
        end
        currentDir = fullfile(currentDir,thisPart);
        continue;
    end

    caseMatch = find(strcmpi(dirNames,thisPart));
    if isscalar(caseMatch)
        error('piSceneWebTest:CaseMismatch', ...
            ['Found "%s" when looking for "%s". ', ...
            'Remove or rename the stale local scene cache so the canonical SDR casing is used.'], ...
            fullfile(currentDir,dirNames{caseMatch}), fullfile(currentDir,thisPart));
    elseif numel(caseMatch) > 1
        error('piSceneWebTest:AmbiguousPathCase', ...
            'Multiple case-insensitive matches for "%s" in "%s".', ...
            thisPart, currentDir);
    else
        return;
    end
end

end
