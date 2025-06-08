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

% See if the scene is already in data/scene/web
sceneDir = fullfile(piRootPath,'data','scenes','web',sceneName);
sceneFile = fullfile(sceneDir,sceneFile);

% Download the file to data/scene/web
if ~isfolder(sceneDir)
    depositName = piSceneDeposit(sceneName);
    [sceneDir, zipfilenames] = ieWebGet('deposit name', depositName, ...
        'deposit file', [sceneName,'.zip'],  ...
        'download dir', fullfile(piRootPath,'data','scenes','web'),...
        'unzip', true);
elseif ~exist(sceneFile,'file')
    error('Folder exists, but sceneFile (%s) is not there.\n',sceneFile);
else
    fprintf('File %s already present in %s.\n',sceneName,sceneDIr)
end

end

