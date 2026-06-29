% Might become a way to render specific characters on a background
% in preparation to reconstruction and scoring
%
% D. Cardinal Stanford University, 2022
%

%% clear the decks
ieInit;
if ~piDockerExists, piDockerConfig; end

% Entire alphabet seems to be working
Alphabet_UC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
Alphabet_LC = 'abcdefghijklmnopqrstuvwxyz';
Digits = '0123456789';
allCharacters = [Alphabet_LC Alphabet_UC Digits];

% not always true. Sometimes we want film for the scene
%humanEye = ~piCamBio(); % if using ISETBio, then use human eye

% We will want to iterate over the charMultiple
% once we get this working for one multiple
charMultiple = 10; % 10; % how many times the 20/20 version

charBaseline = .00873; % 20/20 @ 6 meters
charMultiples = [10 5 1]; % using multiple sizes in a single recipe still fails
charSizes = charMultiples * charBaseline;
characterDistance = 6; % default for 20 foot eye chart

% and lower the character position by half its size
%{
% for testing
charactersRender(thisR,testChars,'letterSize',[charSize .02 charSize], ...
    letterPosition=[0 -1*(charSize/2) 6]); % 6 Meters out
%}
% Now generate a full set of flash cards with fixed background
% for now. Can add background rotation later.

% Can run one of the three, but maybe not all at once?
% Eventually we will concatenate or iterate through them
%useCharset = Digits; % Works
%useCharset = Alphabet_UC; % Works
%useCharset = Alphabet_LC; % Works
useCharset = 'd'; % for testing

numMat = 0; % keep track of iterating through our materials
for ii = 1:numel(useCharset)

    % also need to set material for letter
    % for just  black don't incrment
    numMat = 1; % numMat+ 1;

    % copying the recipe doesn't work right, unfortunately!
    %finalRecipe = thisR.copy(); % don't pollute the original
    for jj = 1:numel(charSizes)

        % right now we create a new recipe for every flashcard
        % but can experiment with trying to remove & replace
        % letters & background (has been confusing so far)
        
        % fixed background for now
        backgroundMaterial = 'asphalt-uniform';
        [thisR, ourMaterials, ourBackground] = prepRecipe('flashCards','raysPerPixel',256, ...
            'backgroundMaterial', backgroundMaterial, ...
            'characterDistance', characterDistance);
        useMat = ourMaterials{mod(numMat, numel(ourMaterials))};

        % from winds up at -6, so we need to offset
        wereAt = recipeGet(thisR,'from');
        letterSize = [charSizes(jj) .02 charSizes(jj)];
        textRender(thisR,useCharset(ii), 'letterSize',letterSize, ...
            'letterPosition',[0 -1*(charSizes(jj)/2), 6] + wereAt, ...
            'letterMaterial', useMat);
        % obj is either a scene, or an oi if we use optics
        [renderedObject] = piWRS(thisR);

        % Initialize our data sample
        cSample = characterSample();
        cSample.init(thisR); % for some reason we have a hard time setting an object specific ID in the constructors
        
        % now set some other metadata. Once we do this for real
        % add some methods that do this more elegantly
        cSample.metadata.characterName = useCharset(ii);
        cSample.metadata.characterSize = letterSize;
        cSample.metadata.characterMaterial = useMat;
        cSample.metadata.characterBackground = backgroundMaterial;
        cSample.metadata.characterDistance = characterDistance;
        cSample.metadata.characterFont = 'plain';

        % do we want to generate previews here or in cSample
        % currently we need to do the cone mosaic one there in any case
        if isequal(renderedObject.type, 'scene')
            cSample.scene = renderedObject;
        elseif isequal(renderedObject.type, 'oi')
            cSample.oi = renderedObject;
        else 
            error("Rendering didn't work");
        end    

        % set any additional needed parameters
        % call methods to write it out
        % I think we can probably do without the params?
        % and some of these come from the cSample!
        cSample.saveCharacterSample;

    end

end


%% ------------- Support Functions Start Here
%%

function addMaterials(thisR)

% See list of materials, if we want to select some
allMaterials = piMaterialPresets('list', [],'show',false);

% Loop through our material list, adding whichever ones work
for iii = 1:numel(allMaterials)
    try
        piMaterialsInsert(thisR, 'names',allMaterials{iii});
    catch
        warning('Material: %s insert failed. \n',allMaterials{ii});
    end
end
end

function [thisR, ourMaterials, ourBackground] = prepRecipe(sceneName, options)

arguments
    sceneName = '';
    options.raysPerPixel = 256; % "Normal" fidelity
    options.filmSideLength = 240;
    options.backgroundMaterial = 'asphalt-uniform';
    options.characterDistance = 6; % meters default
end

thisR = piRecipeDefault('scene name',sceneName);
thisR.set('render type', {'radiance', 'depth'});

% Give it a skylight (assumes we want one)
thisR.set('skymap','sky-sunlight.exr');

% now we want to make the scene FOV 1 degree
% I think we need a camera first
thisR.camera = piCameraCreate('pinhole');
thisR.recipeSet('fov', 1); % 50 arc-minutes is enough for 200/20

% Set quality parameters
% High-fidelity
%thisR.set('rays per pixel',1024);
thisR.set('rays per pixel',options.raysPerPixel);

% set our film to a square, like the characters on an eye chart
% and to mimic the fovea area later on
recipeSet(thisR, 'film resolution', [options.filmSideLength options.filmSideLength]);

% We've set our scene to be 1 degree (60 arc-minutes) @ 6 meters
% For 20/20 vision characters should be .00873 meters high (5 arc-minutes)
% For 200/20 they are 50 arc-minutes (or .0873 meters high)
% Note that letter size is per our Blender assets which are l w h,
% NOT x, y, z

addMaterials(thisR);
ourMaterialsMap = thisR.get('materials');
ourMaterials = keys(ourMaterialsMap);

recipeSet(thisR,'to',[0 .01 10]);

% set vertical to 0. -6 gives us 6m or 20 feet
recipeSet(thisR,'from',[0 .01 -1 * options.characterDistance]);

% Now set the place/color of the background
ourBackground = piAssetSearch(thisR,'object name', 'flashCard_O');
% Default background color is mat
% This resize doesn't work
%recipeSet(thisR,'asset', ourBackground, 'size',[10 10 1]);

recipeSet(thisR,'asset',ourBackground, 'material name',options.backgroundMaterial);

% background is at 0 0 0 by default
% Okay, I can't really figure out how to put something someplace:)
% worldposition doesn't always seem to work
piAssetTranslate(thisR,ourBackground,[0 .0 5]); % just behind center

thisR = addLight(thisR);

end


function thisR = addLight(thisR)
spectrumScale = 1;
lightSpectrum = 'equalEnergy';
lgt = piLightCreate('scene light',...
    'type', 'distant',...
    'specscale float', spectrumScale,...
    'spd spectrum', lightSpectrum,...
    'from', [0 0 0],  'to', [0 0 20]);
thisR.set('light', lgt, 'add');

end



