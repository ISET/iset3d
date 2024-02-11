% Demonstrate rendering our Character assets

% D. Cardinal, Stanford University, December, 2022
% for ISET3d, ISETauto, and ISETonline

%%  Characters and a light

% start with a simple 1 in the middle
thisR = piRead('1-pbrt.pbrt');

% characters don't have a light
lightName = 'from camera';
ourLight = piLightCreate(lightName,...
                        'type','distant',...
                        'cameracoordinate', true);
recipeSet(thisR,'lights', ourLight,'add');
piMaterialsInsert(thisR,'name','brickwall001');

% Generate letters
Alphabet_UC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
Alphabet_LC = lower(Alphabet_UC);
letterSpacing = .9;

% add letters
for ii = 1:numel(Alphabet_LC)
    ourLetter = num2str(Alphabet_LC(ii));
    ourLetterAsset = piAssetLoad([ourLetter '-pbrt.mat']);
    piRecipeMerge(thisR, ourLetterAsset.thisR);
    if rem(ii, 2) == 0
        thisR.set('asset',['001_001_' ourLetter '_O'],'material name','brickwall001');
    end
    spaceLetter = (ii - ceil(numel(Alphabet_LC)/2)) * letterSpacing;
    thisR.set('asset',['001_001_' ourLetter '_O'],'translate', [spaceLetter 0 0]);
end

%% No lens or omnni camera. Just a pinhole to render a scene radiance

thisR.set('object distance',20);
thisR.camera = piCameraCreate('pinhole'); 
%piAssetGeometry(thisR);
piWRS(thisR);
