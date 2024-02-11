function piTextInsert(aRecipe, aString)
% Add a string of characters to a recipe
%
% Synopsis
%   piTextInsert(aRecipe, aString, options)
%
% Brief
%   Inserts text chararacters in the string into a recipe.
%
% Input
%  aRecipe - Rendering recipe
%  aString - List of letters to insert.  Only one copy is inserted.
%
% Optional key/val
%
% Return
%    aRecipe is modified upon return
%
% See also
%   charactersRender, s_arLetters2.m

% Example:
%{
%}

%%
arguments
    % These should be alphabetic (alpha)?  Don't we have numeric? Should we
    % test right here rather than in the code, below?
    aRecipe; % recipe where we'll add the characters
    aString; % one or more characters to add to the recipe
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

% We should be able to find the characters that are already present as
% objects.  This might be
%
% listOfChars = piAssetSearch(thisR,'text')
%

% Only add a character once as an object. TO do this properly, we need to
% check the listOfChars above, also.  NYI.
aString = unique(aString);

%% Add the letters not already in the recipe
for ii = 1:strlength(aString)

    fprintf('Adding character: %s\n', aString(ii));
    thisLetter = aString(ii);

    % To manage non-case-sensitive file systems, we use
    % _uc to denote UpperCase letters.
    if isstrprop(thisLetter, 'alpha') && isequal(upper(thisLetter), thisLetter)
        assetFile = [lower(thisLetter) '_uc-pbrt.mat'];
    else
        % This is the normal case
        assetFile = [thisLetter '-pbrt.mat'];
    end

    %% Add the asset to the recipe

    theAsset = piAssetLoad(assetFile,'asset type','character'); 

    % BW:  We should clean up the mat-files.  They have this extra cruft in
    % them.  I do it here now, but we should do it in the files and
    % eliminate it here.
    %
    % But testing shows that eliminating these branches breaks things.  Not
    % sure why.  As we figure out how to do instances, maybe this will
    % clarify.  The text does get stored with a 'referenceObject' slot.
    %
    % idx = piAssetSearch(theAsset.thisR,'branch name','SceneCollection');
    % theAsset.thisR.set('asset',idx,'subtree delete');
    % theAsset.thisR.show;

    % Try merging before we do anything else
    aRecipe = piRecipeMerge(aRecipe, theAsset.thisR);
    
end

%{
    % The letter we need to place
    letterObject = piAssetSearch(outputR,'object name',['_' letterName '_O']);
    
    % location, scale, and material elements
    if ~isempty(options.letterMaterial)
        % we can assume our caller has already loaded the material?
        % outputR = piMaterialsInsert(outputR,'names',{options.letterMaterial});
        ourLetterAsset.thisR = outputR.set('asset',letterObject(1),'material name',options.letterMaterial);
    end

    ourLetterAsset.thisR = outputR.set('asset', letterObject(1), ...
        'rotate', options.letterRotation);

    % We want to scale by our characterSize compared with the desired size
    if ~isempty(options.letterSize)
        letterScale = options.letterSize ./ characterAssetSize;
        outputR.set('asset',letterObject(1), ...
            'scale', letterScale);
    end

    % maybe we don't always want this?
    % need to make sure we know
    outputR.set('asset',letterObject(1), 'rotate', [-90 00 0]);
    
    % translate goes after scale or scale will reduce translation
    % if user has given us positions for each letter, use them
    % otherwise use start position + spacing
    outputR = outputR.set('asset', letterObject(1), ...
        'translate', letterPosition(ii,:) + options.letterSpacing * (ii-1));
%}
