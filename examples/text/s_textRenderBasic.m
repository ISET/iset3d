%% Render text in a simple scene
%
% Demonstrates the current textRender workflow for adding character assets
% to an ISET3d recipe.
%
% See also
%   textRender, s_eyeChart

%% Initialize
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create a small scene with text
thisR = piRecipeCreate('macbeth checker');
thisR.set('name','text render basic');
thisR.set('film resolution',[320 240]);
thisR.set('rays per pixel',64);
thisR.set('nbounces',3);
thisR.set('skymap','sky-sunlight.exr');

light = piLightCreate('text example distant','type','distant', ...
    'cameracoordinate',true);
thisR.set('light',light,'add');

letterMaterial = 'diffuse-white';
piMaterialsInsert(thisR,'name',letterMaterial);

textString = 'ISET';
letterSize = [0.12 0.08 0.12];
letterSpacing = [0.14 0 0];
letterStart = thisR.get('to') - [0.25 -0.05 -0.8];

thisR = textRender(thisR,textString, ...
    'letterSize',letterSize, ...
    'letterSpacing',letterSpacing, ...
    'letterPosition',letterStart, ...
    'letterRotation',[0 0 0], ...
    'letterMaterial',letterMaterial);

thisR.camera = piCameraCreate('pinhole');

%% Render
scene = piWRS(thisR,'name','Text Render Basic');
sceneWindow(scene);
