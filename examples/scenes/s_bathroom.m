%% s_bathroom
%
% Worked with cardinal download on July 11, 2022
%
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%

resolution = [640 640]*0.5;

thisR = piRecipeDefault('scene name','contemporary-bathroom');

thisR.set('n bounces',5);
thisR.set('rays per pixel',512);
thisR.set('film resolution',resolution);

%% This renders the scene

%{
 % Positions are not right yet
 to = thisR.get('to') - [0 0 0];
 % delta = [0.15 0 0];
 % for ii=1:numel('Lorem'), pos(ii,:) = to + ii*delta; end
 % pos(end,:) = pos(end,:) + delta/2;  % Move the 'm' a bit
 thisR = charactersRender(thisR, 'Lorem','letterSize',[1 1 1],...
'letterRotation',[0,15,15],'letterPosition',[0 0 0],'letterMaterial','wood-light-large-grain');
%}

scene = piWRS(thisR);

%%  You can see the depth from the depth map.
% scenePlot(scene,'depth map');
% sceneGet(scene,'depth range')

%% A double Gauss.  But it is not working!!  We don't know why.

% lensList
lensfile  = 'dgauss.22deg.3.0mm.json';    % 30 38 18 10
thisR.camera = piCameraCreate('omni','lensFile',lensfile);
% thisR.set('sampler subtype','sobol');
thisR.set('film diagonal',5);     % 33 mm is small
thisR.set('focal distance',2);    %
thisR.set('object distance',2);   % Move closer. The distance scaling is weird.
[oi,results] = piWRS(thisR,'name','DG');

%% Fisheye - this lens does not work either.
% Yet they both work on other scenes.

lensfile = 'fisheye.87deg.3.0mm.json';
thisR.camera = piCameraCreate('omni','lensFile',lensfile);
oi = piWRS(thisR,'name','fisheye');

% oi = piAIdenoise(oi);
oiWindow(oi);

%%

