%% Write out the letters in lettersAtDepth as loadable assets
%
%   thisAsset = piAssetLoad('latterA.mat');
%
% There are also letters from Krithin stored in the characters directory,
% made using Blender. They are now usable via the characters scripts
% and tutorials, such as s_eyeChart, charactersRender, and
% s_varyBackgrounds
%
% See also
%   s_assetsRecipe, v_Assets, piAssetLoad, piRecipeMerge

%% This is where we will save them
assetDir = piDirGet('assets');

%% Pull out each of the letters separately and position them.

letters = {'A','B','C'};
for ii=1:numel(letters)
    letter = letters{ii};
    
    sceneName = 'letters at depth';
    thisR = piRecipeDefault('scene name', sceneName);
    % thisR.show('objects');
    
    % Eliminate everything example A,B,C    
    objects = {'Ground','Wall'};
    for jj=1:numel(objects)
        idx = piAssetSearch(thisR,'object name',objects{jj});
        thisR.set('asset',idx,'delete');
    end
    thisR.set('lights','all','delete');
    thisR.set('asset','Camera_B','delete');
    % thisR.show('objects');

    idxA = piAssetSearch(thisR,'object name','A');
    idxB = piAssetSearch(thisR,'object name','B');
    idxC = piAssetSearch(thisR,'object name','C');

    if letter == 'A'
        thisR.set('asset', idxA, 'world position', [0 0 1]);
        thisR.set('asset',idxA,'name','letterA');
        thisR.set('asset',max(idxB,idxC),'delete');
        thisR.set('asset',min(idxB,idxC),'delete');
    end
    % thisR.show('objects');
    
    if letter == 'B'
        thisR.set('asset', idxB, 'world position', [0 0 1]);
        thisR.set('asset',idxB,'name','letterB');
        thisR.set('asset',max(idxA,idxC),'delete');
        thisR.set('asset',min(idxA,idxC),'delete'); 
    end
    % thisR.show('objects');
    
    if letter == 'C'
        thisR.set('asset', idxC, 'world position', [0 0 1]);
        thisR.set('asset',idxC,'name','letterC');
        thisR.set('asset',max(idxB,idxC),'delete');
        thisR.set('asset',min(idxB,idxC),'delete');
    end
    % thisR.show('objects');
    
    thisR.set('from',[0 0 0]);
    thisR.set('to',[0 0 1]);
    
    %{
     % I checked the letters this way
     %
        l = piLightCreate('distant','type','distant');
        thisR.set('light',l,'add');
        piAssetGeometry(thisR);
        thisR.show('objects')
        idx = piAssetSearch(thisR,'object name','A');
        thisR.get('asset',idx,'material name')
        thisR.set('material','White','reflectance',[.5 .5 .5]);
        piWRS(thisR);
    %}
    
    %
    mergeNode = [letter,'_B'];
    fname = ['letter',letter,'.mat'];
    oFile = thisR.save(fullfile(assetDir,fname));
    save(oFile,'mergeNode','-append');
    
end

%% Merge a letter into the Chess set

%{
% This is an example to test that it worked.
chessR = piRecipeDefault('scene name','chess set');
chessR = piMaterialsInsert(chessR);

% Lysse_brikker is light pieces
% Mrke brikker must be dark pieces
% piAssetGeometry(chessR);

theLetter = piAssetLoad('letterA.mat');

piRecipeMerge(chessR,theLetter.thisR,'node name',theLetter.mergeNode);
chessR.show('objects');

to = chessR.get('to');
idx = piAssetSearch(chessR,'object name','letterA');
chessR.set('asset',idx,'world position',to + [0 0.1 0]);
piWRS(chessR,'render type','radiance');

%}


