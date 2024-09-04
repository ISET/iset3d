function [sceneDir, zipfilenames] = piSceneWebTest(sceneName,sceneFile)
% Get a PBRTV4 (ISET3d) scene on the SDR
%
% Synopsis
%  [sceneDir, zipfilenames] = piSceneWebTest(sceneName,sceneFile)
%
% Input
%   sceneName
%   sceneFile
%
% Optional key/val
%   N/A
%
% Output
%  sceneDir - Name of the unzipped directory from SDR
%  zipfilenames - Cell array of zip files in the directory
%
% Description
%  The sceneName should correspond to one of the lowercase.zip files in the
%  ISET3D Scenes deposit on SDR.  There may be different acceptable
%  sceneFile strings for a sceneName.  For example, there are several
%  legitimate sceneFile names for bistro, dambreak, and others.
%
%  There is a scene called 'head' in both iset3d-scene and pbrtv4. By
%  default head gets the iset3d version, and head-pbrt gets the pbrtv4
%  version.
%
%  For bistro, we have sceneName as bistro and different sceneFiles, such
%  as bistro_vespa
%
% See also.
%   piRead, piRecipeDefault, piRecipeCreate
%

% See if the scene is already in data/scene/web
sceneDir = fullfile(piRootPath,'data','scenes','web',sceneName);
sceneFile = fullfile(sceneDir,sceneFile);

% Download the file to data/scene/web
if ~isfolder(sceneDir)
    depositName = piSceneDeposit(sceneName);
    [sceneDir, zipfilenames] = ieWebGet('deposit name', depositName, 'deposit file', [sceneName,'.zip'],  'unzip', true);
elseif ~exist(sceneFile,'file')
    error('Folder exists, but sceneFile (%s) is not there.\n',sceneFile);
else
    fprintf('File %s already present in data/scene/web.\n',sceneName)
end

end

