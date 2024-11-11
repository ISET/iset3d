function [thisR, info] = piReadIDB(idbScene,isetDocker,info)
% Return a scene recipe from the image database 
%
% Synopsis
%  [thisR, info] = piReadIDB(idbScene,isetDocker,info)
%
% Input
%   idbScene:   idbContent defining a scene with a recipe
%   isetDocker: As its name
%   info:       Text string.
%
% Output:
%   thisR:  Created for rendering
%   info:   Modified
%
% See also
%

%{
  [thisR,info] = piReadIDB(thisScene,isetdocker,'');
%}

remoteFile = strrep(idbScene.mainfile,'.pbrt','.mat');
localDir   = fullfile(piRootPath,'local',[idbScene.name]);
cd(isetDocker.sftpSession,idbScene.filepath);
mget(isetDocker.sftpSession, remoteFile, localDir);

recipeMat = fullfile(localDir, strrep(idbScene.mainfile,'.pbrt','.mat'));

% Access and change variables in MAT-file without loading file into memory.
% I think this is because the matfile may have more than the recipe?
thisload = matfile(recipeMat);
thisR = thisload.thisR;
thisR.set('input file',fullfile(idbScene.filepath, idbScene.mainfile));
thisR.set('output file',strrep(recipeMat,'.mat','.pbrt'));

info = addText(info,sprintf('[INFO]: Use a database scene: [%s].\n',[idbScene.filepath,'/',idbScene.mainfile]));

end
