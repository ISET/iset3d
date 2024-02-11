%% s_kitchen
%
% Worked with cardinal download on July 11, 2022
%
% In most recent work, I had to copy the 'models' directory to the 'local'
% directory by hand.  And then it rendered.
%
% Rerunning piWRS() wipes out the models directory.  Bummer.
%
% On cardinal.stanford.edu, I put both kitchen.zip and kitchen.save.zip The
% original (kitchen.save.zip) has the mesh files inside of models.  The
% kitchen.zip is edited so that the mesh files are in the geometry folder.
%
% It seems that running kitchen once with 'push resources' enabled me to
% start running again.

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Se6t up the parameters

resolution = [320 320]*1;

thisR = piRecipeDefault('scene name','kitchen');
thisR.set('n bounces',5);
thisR.set('rays per pixel',512);
thisR.set('film resolution',resolution);
thisR.set('render type',{'radiance','depth'});

%% This renders the scene

% I have been copying the geometry files into the local/kitchen directory
% and then running piRender by hand.  Sometimes for increased resolution.
%{
 resolution = [320 320]*2;
 thisR.set('film resolution',resolution);
 piWrite(thisR,'overwrite resources',false);
 scene = piRender(thisR);  sceneWindow(scene);%
 scene = piAIdenoise(scene);
 ieReplaceObject(scene); sceneWindow;
%}
% I need to ask Dave or Zhenyi how to make sure the ply files are
% uploaded and in the proper place on acorn.  I also wonder what we are
% doing about resource file names.
%  
% Finally, I edited the wiki page about remote rendering considerably, and
% Dave should read it to check.
%

% After running this once, I was able to run just piWRS(thisR);
%
% scene = piWRS(thisR,'push resources',true);
scene = piWRS(thisR);
%{
 scene = piAIdenoise(scene);
 ieReplaceObject(scene); sceneWindow;
%}
% dRange = sceneGet(scene,'depth range');

%% Samples the scene from a few new directions around the current from

from = thisR.get('from'); to = thisR.get('to');
direction = thisR.get('fromto');
direction = direction/norm(direction);
nsamples = 5;
frompts = piRotateFrom(thisR,direction,'nsamples',nsamples,'degrees',5,'method','circle');

%% Do it.
for ii=1:size(frompts,2)
    fprintf('Point %d ... of %d\n',ii,size(frompts,2));
    thisR.set('from',frompts(:,ii));
    piWRS(thisR,'render flag','hdr');
    fprintf('\n');
end

%%
thisR.set('from',from); thisR.set('to',to);
piWRS(thisR);

%%  You can see the depth from the depth map.
% scenePlot(scene,'depth map');

%% Another double Gauss

% lensList
lensfile  = 'dgauss.22deg.3.0mm.json';    % 30 38 18 10
thisR.camera = piCameraCreate('omni','lensFile',lensfile);

thisR.set('film diagonal',5);    % 3 mm is small
thisR.set('object distance',2);  % Move closer. The distance scaling is weird.
oi = piWRS(thisR,'name','DG');
oi = piAIdenoise(oi); ieReplaceObject(oi); oiWindow;
%% Fisheye

lensfile = 'fisheye.87deg.3.0mm.json';
thisR.set('film diagonal',7);  %% 3 mm is small

thisR.camera = piCameraCreate('omni','lensFile',lensfile);
oi = piWRS(thisR,'name','fisheye');
oi = piAIdenoise(oi); ieReplaceObject(oi); oiWindow;

%% END

