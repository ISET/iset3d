%% s_makeSimpleScene
%
% DEPRECATED
%

% Not up to date ... either fix or deprecate
% We use the simple scene in various t_piIntro examples now
% The methods here are out of date.
%
thisR = piRecipeCreate('simple scene');
piWRS(thisR);

%%
thisR.set('assets','Camera_B','delete');
thisR.set('assets','001_mirror_O','delete');
thisR.set('lights','delete','#1_Light_type:infinite');

% Trees outside the room
piLightProperties('spot');
fileName = 'room.exr';
lgt = piLightCreate('outdoors light', ...
    'type', 'infinite',...
    'filename', fileName);

% The image in the light exr file needs to be rotated around so the camera
% sees good stuff 
lgt = piLightSet(lgt, 'rotation val', {[0 0 1 0], [-90 1 0 0]});
thisR.set('light',lgt,'add');

%{
fileName = 'clouds-sky.exr';
lgt = piLightCreate('infinite light', ...
    'type', 'distant');
thisR.set('light',lgt,'add');
thisR.show('lights');
%}
%{
% It would be nice to make another blue spot light or something
%
lgt = piLightCreate('blue point', 'type','point',...
    'rgb spd',[0.5 0.7 1]);
thisR.set('light',lgt,'add');
%}

% Render
piWRS(thisR);

%%
disp(thisR.save())

%%
load('SimpleScene-recipe','thisR');
piWRS(thisR);

%%  Checking different V4 materials

thisR.set('spatial resolution',[320 320]);
materialName = 'newMirror';

mts = {'coatedconductor', 'coateddiffuse', 'conductor', ...
      'diffuse', 'diffusetransmission', ...
      'measured', ...
      'dielectric', 'thindielectric', ...
      'hair', 'subsurface', 'mix'};
  
% They do not all render.
newMat = piMaterialCreate(materialName, 'type', mts{1});
thisR.set('material', 'add', newMat);

% This is the current black ceiling
assetName = '001_mirror_O';
% curName = thisR.get('asset', assetName, 'material name');

% And now we change it.
thisR.set('asset', assetName, 'material name', materialName);
piWRS(thisR);
