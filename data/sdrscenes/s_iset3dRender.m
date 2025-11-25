%% Test the iset3d-scenes

%% Initialize

ieInit; 
clear ISETdb;
piDockerConfig;
ieDocker = isetdocker;
ieDocker.reset;

%% These all ran this way on Aug 27, 2024.  From Google Drive.

% Wandell's Google drive.  We will move these to SDR
% bDir = '/Users/wandell/Google Drive/My Drive/Data/PBRT-V4/iset3d-scenes';

% Now I decided to use the local USB drive.
bDir = '/Volumes/TOSHIBA EXT/iset3d-scenes';

% Get a list of all files and folders in the current directory
allItems = dir(bDir);

% Filter the list to keep only directories
dirFlags = [allItems(:).isdir] & ~strcmp({allItems(:).name}, '.') & ~strcmp({allItems(:).name}, '..');

% Extract the names of the directories
directoryList = allItems(dirFlags);

% Display the names of the directories
% subDirNames = {subDirs.name}

%% They are all formatted for this simple loop.

for ii=1:numel(directoryList)
    dirName = directoryList(ii).name;
    if ~isequal(dirName(1),'.')  && ~contains(dirName,'webloc') && ~contains(dirName,'.zip')
        fprintf('Directory:  %s\n',dirName);
        sceneName= [dirName,'.pbrt'];
        sceneFile = fullfile(bDir,dirName,sceneName);
        thisR = piRead(sceneFile,'exporter','parse');
        piWrite(thisR);
        if thisR.get('n lights')==0
            thisR.set('skymap','room.exr');
        end
        piWRS(thisR,'gamma',0.5,'name',sceneName);
    end
end

%%