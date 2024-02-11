function [outputR, letterNames] = textRender(aRecipe, aString, options)
% Add a string of characters to a recipe
%
% Synopsis
%   outputR = textRender(aRecipe, aString, options)
%
% Brief
%   Loads the characters saved in the ISET3d assets file for characters,
%   and merges them into the input recipe.  Requires ISET3d and ISETCam (or ISETBio).
%   Used by ISETauto, and ISETonline
%
% Input
%  aRecipe
%  aString
%
% Options (key/val pairs)
%  letterSpacing
%  letterMaterial
%  letterPosition
%  letterRotation
%  letterSize
%
% Output
%  outputR - Modified recipe
%
% D. Cardinal, Stanford University, December, 2022
%
% See also
%  ISETauto and ISETonline
%

% Example:
%{
thisR = piRecipeCreate('macbeth checker');
piMaterialsInsert(thisR,'name','wood-light-large-grain');
to = thisR.get('to') - [0.5 0 -0.8];
delta = [0.15 0 0];
str = 'Lorem';
pos = zeros(numel(str),3);
for ii=1:numel(str), pos(ii,:) = to + ii*delta; end
pos(end,:) = pos(end,:) + delta/2;  % Move the 'm' a bit
thisR = textRender(thisR, str,'letterSize',[0.15,0.1,0.15],'letterRotation',[0,15,15],...
    'letterPosition',pos,'letterMaterial','wood-light-large-grain');
thisR.set('skymap','sky-sunlight.exr');
thisR.set('nbounces',4);
piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('Cornell_Box');
 piMaterialsInsert(thisR,'name','marble-beige');
 piMaterialsInsert(thisR,'name','wood-light-large-grain');

 thisR.set('film resolution',[384 256]*2);
 to = thisR.get('to') - [0.32 -0.1 -0.8];
 delta = [0.09 0 0];
 str = 'marble';
 idx = piAssetSearch(thisR,'object name','003_cornell_box');
 thisR.set('asset',idx,'material name','marble-beige');
 for ii=1:numel(str), pos(ii,:) = to + ii*delta; end
 thisR = charactersRender(thisR, str,'letterSize',[0.1,0.03,0.1]*0.7,...
    'letterRotation',[0,0,-10],'letterPosition',pos,'letterMaterial','wood-light-large-grain');
 thisR.set('skymap','sky-sunlight.exr');
 thisR.set('nbounces',4);
 piWRS(thisR);
%}

%%
arguments
    aRecipe; % recipe where we'll add the characters
    aString; % one or more characters to add to the recipe

    % Optional parameters
    options.letterSpacing = [.4 0 0]; % right shift if positions not specified
    options.letterMaterial = '';
    options.letterPosition = [0 0 1];  % Meters, default 'just ahead'
    options.letterRotation = [0 0 0];  % Degrees
    options.letterSize = [];
    options.letterTreatment = '';

    % ASPIRATIONAL / TBD
    options.fontSize = 12;
    options.fontColor = 'black';
    options.direction = 'horizontal_lr';
    options.billboard = false; % whether to have a background box

end

%-----------------------------------------------------------------
% NOTE: We don't handle strings with duplicate characters yet
%       We need to create Instances for subsequent ones, I think!
% 
% BW: Conceptually, we run unique on the input letters and add each as an
% asset once. Then we use piObjectInstance(thisR) to create instances on
% the whole recipe.  (I don't know if we can just make instances for only
% the letters, but maybe. If not, we might modify piObjectInstance to
% specify.  Or maybe it is not important.).
%   Finally, each time we insert a character we add it as an instance using
% piObjectInstanceCreate().
%   Use t_piSceneInstances as a model.
%-----------------------------------------------------------------

% Set output recipe to our initial input
outputR = aRecipe;
%piMaterialsInsert(outputR,'groups',{'diffuse'});

% Allows for testing duplicate characters by using '00' as the string
gotZero = false;

% Our Blender-rendered Characters [width height depth] 
% Per Matlab these are [l w h]
characterAssetSize = [.88 .25 1.23];

% Always make the number of positions equal to the number of letters.
% If the user specifies a position for each, use it
% Otherwise use letterspacing
if size(options.letterPosition,1) == 1
    letterPosition = repmat(options.letterPosition,strlength(aString),1);
else
    letterPosition = options.letterPosition;
    options.letterSpacing = 0; % user has specified positions
end

letterNames = [];

%% add letters
for ii = 1:strlength(aString)
    fprintf('Rendering Character(s): %s\n', aString(ii));
    ourLetter = aString(ii);

    % Addresses non-case-sensitive file systems
    % by using _uc to denote Uppercase letter assets
    % use bold version if available (we only have for Uppercase though!
    if isequal(options.letterTreatment, 'bold')
        treatment = '-courier-bold';
    else
        treatment = '';
    end
    if isstrprop(ourLetter, 'alpha') && isequal(upper(ourLetter), ourLetter)
        ourAssetName = [lower(ourLetter) '_uc' treatment '-pbrt.mat'];
        ourAsset = [lower(ourLetter) '_uc' treatment];
    else
        % TEST TO SEE IF WE CAN DUPLICATE ASSETS
        if isequal(ourLetter,'0')
            if gotZero == false
                gotZero = true;
                ourAssetName = [ourLetter '-pbrt.mat'];
                ourAsset = ourLetter;
            else
                ourAssetName = '0-pbrt-1.mat';
                ourAsset = ourLetter;
            end
        else
            % This is the normal case
            ourAssetName = [ourLetter '-pbrt.mat'];
            ourAsset = ourLetter;
        end
    end
    % return object names to caller
    letterNames = [letterNames ourAsset];

    %% Load letter assets

    % This should only happen once -- Once per character
    ourLetterAsset = piAssetLoad(ourAssetName,'asset type','character'); 

    % Try merging before we do anything else
    outputR = piRecipeMerge(outputR, ourLetterAsset.thisR);

    % The letter we need to place
    letterObject = piAssetSearch(outputR,'object name',['_' ourAsset '_O']);
    
    % location, scale, and material elements
    if ~isempty(options.letterMaterial)
        % we can assume our caller has already loaded the material?
        % outputR = piMaterialsInsert(outputR,'names',{options.letterMaterial});
        outputR.set('asset',letterObject(1),...
            'material name',options.letterMaterial);
    end

    outputR.set('asset', letterObject(1), ...
        'rotate', options.letterRotation);

    % We want to scale by our characterSize compared with the desired size
    if ~isempty(options.letterSize)
        letterScale = options.letterSize ./ characterAssetSize;
        outputR.set('asset',letterObject(1), ...
            'scale', letterScale);
    end

    % The order of the transformations matters.  In general, I think we
    % want 'scale' to be last not first, because the scale is applied to
    % the translate.  This works for our current demos, so I am not
    % changing.  But this issue - of ordering the transformations - will
    % come up a lot as we work through things. BW.

    % maybe we don't always want this?
    % need to make sure we know
    outputR.set('asset',letterObject(1), 'rotate', [-90 00 0]);
    
    % translate goes after scale or scale will reduce translation
    % if user has given us positions for each letter, use them
    % otherwise use start position + spacing
    outputR = outputR.set('asset', letterObject(1), ...
        'translate', letterPosition(ii,:) + options.letterSpacing * (ii-1));

    
end

