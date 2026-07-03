% Demonstrate rendering a string from character assets

% D. Cardinal, Stanford University, December, 2022
% for ISET3d, ISETauto, and ISETonline

%%

% Use a background scene
thisR = piRecipeCreate('macbeth checker');
%piWRS(thisR);

thisR.set('object distance', 2);

piMaterialsInsert(thisR,'names',{'brickwall001'});

% mcc already has these
% piMaterialsInsert(thisR,'names',{'diffuse-red'});

%% Limitations:
% Assumes case-sensitive file system for character folders!!
% As we have assets of "a" and "A", for example
ourString = 'BaF';

%  'material_name','brickwall001',
%  'material_name','diffuse-red'
thisR = textRender(thisR, ourString, ...
    'letterPosition', [0, 0, 0], 'letterMaterial','brickwall001');

%idx = piAssetSearch(thisR,'object name','3_O');
%thisR.set('asset',idx,'world position',[0 0 -1]);

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.camera = piCameraCreate('pinhole'); 
%piAssetGeometry(thisR);
piWRS(thisR);
