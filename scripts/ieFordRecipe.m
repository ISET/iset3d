%% Create a driving scene from the recipe file in the iset/isetauto/Ford/sceneRecipes
% 
% 
% I downloaded some files from /acorn/data/iset/isetauto/Ford/sceneRecipe
%
% There are a lot of files there.  I just got a couple and put them in
% the web folder.
%

%% Initialize location

fname = '1112153442.pbrt';
chdir(fullfile(piRootPath,'data','scenes','web','1112153442'));

%%
load('1112153442.mat','thisR');

% There is no thisR.media slot.  I check for this in piWrite, but we could
% add 
thisR.media.list = [];
outDir = fullfile(piRootPath,'local','1112153442');
if ~exist(outDir,'dir')
    mkdir(outDir);
end

thisR.outputFile = fullfile(piRootPath,'local','1112153442','1112153442.pbrt');

%%

% A lot of warnings
piWrite(thisR);