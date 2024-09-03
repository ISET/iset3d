function fname = piSceneWebTest(sceneName,sceneFile)
% Get a PBRTV4 (ISET3d) scene on the SDR
%
% Synopsis
%  fname = piSceneWebTest(sceneName,sceneFile)
%
% Input
%   sceneName
%   sceneFile
%
% Optional key/val
%   N/A
%
% Output
%  fname
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
FilePath = fullfile(piRootPath,'data','scenes','web',sceneName);
fname = fullfile(FilePath,sceneFile);

% Download the file to data/scene/web
if ~exist(fname,'file') && ~isfolder(FilePath)
    
    % Find the scene on the Stanford Digital Repository
    switch sceneName
        case {'bathroom','bathroom2','bedroom','classroom',...
                'cornell-box','glass-of-water','kitchen','lamp',...
                'living-room','living-room-2','living-room-3',...
                'staircase','staircase2','teapot-full',...
                'veach-ajar','veach-bidir','veach-mis'}
            depositName = 'bitterli';
        case {'barcelona-pavilion','bistro','bunny-cloud','bunny-fur',...
                'clouds','contemporary-bathroom','crown','dambreak',...
                'disney-cloud','ganesha','hair','head-pbrt','killeroos',...
                'landscape','lte-orb','pbrt-book','sanmiguel',...
                'smoke-plume','sportscar','sssdragon',...
                'transparent-machines','zero-day'}
            depositName = 'pbrtv4';
        case {'arealight','bunny','car','characters','checkerboard',...
                'chessset','coordinate','cornell_box',...
                'cornellboxreference','flashcards','flatsurface',...
                'lettersatdepth','low-poly-tax','macbethchecker'...
                'materialball','materialball_cloth','simplescene',...
                'slantededge','stepfunction','teapot-set','testplane'}
            depositName = 'iset3d-scenes';
        otherwise
            error('Scene not local and not on SDR: %s\n',sceneName);
    end

    ieWebGet('deposit name', depositName, 'deposit file', [sceneName,'.zip'],  'unzip', true);

else
    fprintf('File found %s in data/scene/web.\n',sceneName)
end

end