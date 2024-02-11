%% Make images with Krithin's assets
%
% I think there are more.   I should find them all!  The letters and
% numbers.  And I should put them here.
%
% See also
%

%% The table

sceneDir = 'table';
sceneFile = 'Table-pbrt.pbrt';
exporter = 'PARSE';

FilePath = fullfile(piDirGet('scenes'),'web',sceneDir);
fname = fullfile(FilePath,sceneFile);
exist(fname,'file')

thisR = piRead(fname, 'exporter', exporter);
ss = thisR.get('spatial samples');

thisR.set('nbounces',3);
thisR.set('spatial samples',ss/4);
thisR.set('rays per pixel',64);
thisR.set('skymap','room.exr');

thisR.set('asset','001_Table_O','rotate',[30 0 0]);

piWRS(thisR);

%% Try the Arch

sceneDir = 'arch';
sceneFile = 'Arch3d-pbrt.pbrt';
exporter = 'PARSE';

FilePath = fullfile(piDirGet('scenes'),'web',sceneDir);
fname = fullfile(FilePath,sceneFile);
exist(fname,'file')

thisR = piRead(fname, 'exporter', exporter);
ss = thisR.get('spatial samples');

thisR.set('nbounces',3);
thisR.set('spatial samples',ss/4);
thisR.set('rays per pixel',64);

thisR.set('asset','001_Arch3d_O','rotate',[30 0 0]);

thisR.set('skymap','room.exr');

thisR.set('skymap','room.exr');

scene = piWRS(thisR);