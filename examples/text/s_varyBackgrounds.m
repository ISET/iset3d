% Experiment with different materials and backgrounds for characters
%
% D. Cardinal Stanford University, 2022
%

%% clear the decks
ieInit;
if ~piDockerExists, piDockerConfig; end

Alphabet_UC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
chartRows = 4;
chartCols = 6;

humanEye = ~piCamBio(); % if using ISETBio, then use human eye

%% We can process through the humaneye camera
% Otherwise we use a pinhole camera
if humanEye == false
    % Use the patches of the MCC as placeholders
    thisR = piRecipeDefault('scene name','MacBethChecker');
    thisR = addLight(thisR);
    % nice aspect ratio & fov for the chart
    thisR.set('fov', 30);
    thisR.set('filmresolution', [640, 360]);
else
    % Use Humaneye
    % create a modern human eye ready scene
    thisSE = sceneEye('MacBethChecker');
    thisSE.recipe = addLight(thisSE.recipe);

    % set our recipe
    thisR = thisSE.recipe;
end

% Set quality parameters
% High-res
%thisR.set('film resolution', [2048 2048]);
thisR.set('rays per pixel',1024);
% Normal-res
%thisR.set('film resolution', [512 512]);
thisR.set('rays per pixel',128);

thisR.set('name','Sample Character Backgrounds');
thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);

% Put our characters in front, starting at the top left
to = thisR.get('to') - [0.5 -0.28 -0.8];

% This needs to be changed to chart box size
horizontalDelta = 0.2;
verticalDelta = -.21;
letterIndex = 0;

letterSize = [0.12,0.1,0.12];
letterRotation = [0 0 0];
letterMaterial = 'wood-light-large-grain';
piMaterialsInsert(thisR, 'names', {letterMaterial});

letterNames = {};
useBold = true; % test bold
for ii = 1:chartRows
    for jj = 1:chartCols
        letterIndex = letterIndex + 1;
        letter = Alphabet_UC(letterIndex);
        % Move right based on ii, down based on jj, don't change depth for
        % now
        pos = to + [((jj-1) *horizontalDelta) ((ii-1)*verticalDelta) 0]; %#ok<SAGROW>
        if useBold
            [thisR, addLetters] = textRender(thisR, letter,'letterSize',letterSize,'letterRotation',letterRotation,'letterPosition',pos,'letterMaterial',letterMaterial, 'letterTreatment', 'bold');
        else
            [thisR, addLetters] = textRender(thisR, letter,'letterSize',letterSize,'letterRotation',letterRotation,'letterPosition',pos,'letterMaterial',letterMaterial);
        end
        letterNames{end+1} = addLetters;
    end
end

%% For debugging try to back way off and get a view
%recipeSet(thisR,'from', [-5 5 -15]);
%recipeSet(thisR,'to', [0 0 8]);

% See if making a copy of the recipe avoids any artifacts
if humanEye
    varyLettersSE = thisSE.copy();
    varyPatchSE = thisSE.copy();
end

if humanEye
    %%  Render
    oiVanilla = eyeRender(thisSE, 'fovScale', .5);
else
    piWRS(thisR);
end

%add materials from our library
addMaterials(thisR);

% Now vary the materials that compose the letters
varyLettersR = doMaterials(thisR,'type','letters','letterNames',letterNames);
if humanEye
    oiVaryLetters = eyeRender(varyLettersSE, 'show', true);
else
    piWRS(varyLettersR);
end

% Vary patch materials -- except inherits the letter materials also
varyPatchR = doMaterials(thisR,'type','patch');
if humanEye
    oiVaryBackgrounds = eyeRender(varyPatchSE, 'show', true);
else
    piWRS(varyPatchR);
end


%% Start Support Functions here...
%
function thisR = doMaterials(thisR, options)

arguments
    thisR;
    options.type = 'patch';
    options.letterNames = [];
end


ourMaterialsMap = thisR.get('materials');
ourMaterials = values(ourMaterialsMap);

% we only have 24 patches to modify
for iii = 1:min(numel(ourMaterials),24)
    try
        if isequal(options.type, 'patch')
            if iii < 9
                ourAsset = piAssetSearch(thisR,'object name',['00' num2str(iii+1) '_colorChecker_O']);
            else
                ourAsset = piAssetSearch(thisR,'object name',['0' num2str(iii+1) '_colorChecker_O']);
            end
        else
            ourAsset = piAssetSearch(thisR,'object name',options.letterNames{iii});
        end

        % patches are all first, so start from the back
        % (or we could just add 25 -- mat + 24)
        thisR.set('asset',ourAsset,'material name',ourMaterials{25+iii}.name);
    catch EX
        warning('Material: %s failed with %s. \n',ourMaterials{25+iii}.name, EX.message);
    end
end
end

function addMaterials(thisR)
% should inherit from parent
letterMaterial = 'wood-light-large-grain';

% See list of materials, if we want to select some
allMaterials = piMaterialPresets('list');

% Loop through our material list, adding whichever ones work
for iii = 1:numel(allMaterials)
    try
        % it doesn't like it if we add a material twice
        if ~isequal(allMaterials{iii}, letterMaterial)
            piMaterialsInsert(thisR, 'names',allMaterials{iii});
        end
    catch
        warning('Material: %s insert failed. \n',allMaterials{ii});
    end
end
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


