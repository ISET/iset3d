%% s_headLens
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%
thisR = piRecipeDefault('scene name','head');

thisR.set('rays per pixel',512);
thisR.set('film resolution',[320 320]*2);
thisR.set('n bounces',5);
%% This renders
[scene, results] = piWRS(thisR);

%%
thisR.set('asset','001_head_O','rotate',[5 20 0]);
[scene, results] = piWRS(thisR);

%% Change the camera position
oFrom = thisR.get('from');
oTo = thisR.get('to');
oUp = thisR.get('up');

thisR.set('object distance', 1.3);

thisR.set('lights','all','delete');
% Need to un-comment one of these or else we don't have a light:
% thisR.set('skymap','sky-brightfences');
% thisR.set('skymap','glacier_latlong.exr');
% thisR.set('skymap','sky-sun-clouds.exr');   % Needs rotation
% thisR.set('skymap','sky-rainbow.exr');
% thisR.set('skymap','sky-sun-clouds');
% thisR.set('skymap','sky-sunlight.exr');
% thisR.set('skymap','ext_LateAfternoon_Mountains_CSP.exr');
thisR.set('skymap','sky-cathedral_interior');

% thisR.show('skymap');

% thisR.set('from',oFrom);
[scene, results] = piWRS(thisR);

%{
coord = piAssetLoad('coordinate');
thisR = piRecipeMerge(thisR,coord.thisR,'node name',coord.mergeNode,'object instance', false);
thisR.set('asset','mergeNode_B','world position',thisR.get('from') + -0.5*thisR.get('fromto'));
thisR.set('asset','mergeNode_B','scale',0.2);
piWRS(thisR);
%}

%% Textures on the head.
%
% The white is good for the illumination!

%%  Materials
thisR.set('lights','all','delete');
thisR.set('skymap','sky-brightfences.exr');

piMaterialsInsert(thisR,'name','diffuse-white');
thisR.set('asset','001_head_O','material name','diffuse-white');
piWRS(thisR);

%%
matName = 'tiles-marble-sagegreen-brick';
piMaterialsInsert(thisR,'name',matName);
thisR.set('asset','001_head_O','material name',matName);
piWRS(thisR);

%%
matName = 'wood-mahogany';
piMaterialsInsert(thisR,'name',matName);
thisR.set('asset','001_head_O','material name',matName);
piWRS(thisR);

%%
%{
thisR.set('asset','001_head_O','material name','marbleBeige');
piWRS(thisR);
thisR.set('asset','001_head_O','material name','mahogany_dark');
piWRS(thisR);
thisR.set('asset','001_head_O','material name','mirror');
piWRS(thisR);
thisR.set('asset','001_head_O','material name','macbethchart');
piWRS(thisR);
thisR.get('texture','macbethchart')
ans.scale
thisR.set('texture','macbethchart','scale',0.3);
piWRS(thisR);
thisR.set('texture','macbethchart','uscale',0.3);
thisR.set('texture','macbethchart','vscale',0.3);
piWRS(thisR);
thisR.set('texture','macbethchart','vscale',10);
thisR.set('texture','macbethchart','uscale',10);

thisR.set('asset','001_head_O','material name','head');

piWRS(thisR);
%}


%%
% The depth map is crazy, though.
% scenePlot(scene,'depth map');

%%

% depthRange = thisR.get('depth range');
% depthRange = [1 1];

% Need to un-comment one lens to have the script run
% thisR.set('lens file','fisheye.87deg.100.0mm.json');
% lensFiles = lensList;
% lensfile = 'fisheye.87deg.100.0mm.json';
% lensfile  = 'dgauss.22deg.50.0mm.json';    % 30 38 18 10

fprintf('Using lens: %s\n',lensfile);
thisR.camera = piCameraCreate('omni','lensFile',lensfile);
thisR.set('focal distance',5);
thisR.set('film diagonal',33);

oi = piWRS(thisR);
