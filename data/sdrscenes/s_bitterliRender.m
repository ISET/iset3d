%% Bitterli rendering test
%
% I have a directory of the bitterli scenes on my local drive, and
% also on the Google Cloud.  Prior to uploading these scenes to the
% SDR, I tried rendering them.
%
% 8/27/2024 - Everything rendered with iset3d-tiny on the dev-zhenyi
% branch. 
%
% Notes
%
% Inside of living-room-3, we had to change the entries in the
% models/.pbrt file from "point P" to "point3 P".  I did that with
% emacs.
%
% We plan to make these scenes accessible with ieWebGet() via the SDR.
%
% We will add a metadata comment about acknowledging Bitterli with the
% reference, and also clearly mark them on the web site.
%
% This may become
%
%  v_iset3d_tiny_bitterli
%
% See also
%  s_iset3dRender, s_pharrRender

%%
ieInit; 
clear ISETdb;
piDockerConfig;
ieDocker = isetdocker;
ieDocker.reset;

%% Wandell's Google drive.  We will move these to SDR
%

% These all ran this way on Aug 27, 2024.  From Google Drive.
% bDir = '/Users/wandell/Google Drive/My Drive/Data/PBRT-V4/bitterli';

% Now I decided to use the local USB drive.
bDir = '/Volumes/TOSHIBA EXT/bitterli';

fileList = dir(bDir);
for ii=1:numel(fileList)
    if ~isequal(fileList(ii).name(1),'.')  && ~contains(fileList(ii).name,'webloc')
        fprintf('File:  %s\n',fileList(ii).name);
        sceneFile = fullfile(bDir,fileList(ii).name,'scene-v4.pbrt');
        thisR = piRead(sceneFile,'exporter','copy');
        scene = piWRS(thisR,'gamma',0.5,'name',fileList(ii).name);
    end
end

%%


