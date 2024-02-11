%% Turning pbrt characters into assets 
%  We merge these characters into scenes as labels, using
%
% piRecipeMerge
%
%  D.Cardinal, Stanford University, December, 2022
%
% See also
%

%% Set up the directories

% The input directory with the pbrt files
recipeDir = piDirGet('character-recipes');

% The output directory where we write the mat-files
charAssetDir = piDirGet('character-assets');

%% number assets
for ii = 0:9 
    characterRecipe = [num2str(ii) '-pbrt.pbrt'];
    thisR = piRead(characterRecipe);

    % We do not want the input file to have the user's full path.  So we
    % reduce it to just the name of the pbrt file.
    thisR.set('inputfile',characterRecipe);

    % Assets do not get rendered directly.  They get merged into another
    % scene which has its own output. So they do not need an output file or
    % directory.
    thisR.set('outputfile','');   
    n = thisR.get('asset names');

    % Save in assets/characters instead...
    saveFile = [erase(characterRecipe,'.pbrt') '.mat'];
    oFile = thisR.save(lower(fullfile(charAssetDir,saveFile)));

    letter = num2str(ii); % hard-code for testing
    mergeNode = [letter,'_B'];
    save(lower(oFile),'mergeNode','-append');
end

%% Generate letters
Alphabet_UC = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
Alphabet_LC = lower(Alphabet_UC);

allLetters = [Alphabet_LC Alphabet_UC];

% Code currently assumes OS can tell UC from LC
% Otherwise instead of relying on Matlab path to get pbrt
% files, we'd need to provide a specific path
for ii = 1:numel(allLetters)
    disp(ii);
    if isequal(upper(allLetters(ii)),allLetters(ii))
        characterRecipe = [lower(allLetters(ii)) '_uc-pbrt.pbrt'];
    else
        characterRecipe = [allLetters(ii) '-pbrt.pbrt'];
    end

    if ~exist(characterRecipe,'file')
        warning("Help! %s\n", characterRecipe)
    end
    thisR = piRead(characterRecipe);

    % We do not want the input file to have the user's full path.  So we
    % reduce it to just the name of the pbrt file.
    thisR.set('inputfile',characterRecipe);

    % Assets do not get rendered directly.  They get merged into another
    % scene which has its own output. So they do not need an output file or
    % directory.
    thisR.set('outputfile','');

    % piRead changes asset names to lower case
    % This means things break when we merge UC letters into recipes
    
    n = thisR.get('asset names');

    % Save in assets/characters instead...
    saveFileStub = erase(characterRecipe,'.pbrt');
    saveFile = [saveFileStub '.mat'];
    %{
    % not sure why we needed this?
    if isequal(upper(allLetters(ii)),allLetters(ii))
        saveFile = [saveFileStub '.mat'];
    else
        saveFile = [saveFileStub '.mat'];
    end
    %}
    oFile = thisR.save(lower(fullfile(charAssetDir,saveFile)));

    letter = allLetters(ii); % hard-code for testing
    mergeNode = [letter,'_B'];
    save(oFile,'mergeNode','-append');
end

% UC-Courier-Bold
for ii = 1:numel(Alphabet_UC)
    disp(ii);
%    if isequal(upper(allLetters(ii)),allLetters(ii))
        characterRecipe = [Alphabet_UC(ii) '_UC-Courier-Bold-pbrt.pbrt'];
%    else
%        characterRecipe = [allLetters(ii) '-pbrt.pbrt'];
%    end

    if ~exist(characterRecipe,'file')
        warning("Help! %s\n", characterRecipe)
    end
    thisR = piRead(characterRecipe);

    % We do not want the input file to have the user's full path.  So we
    % reduce it to just the name of the pbrt file.
    thisR.set('inputfile',characterRecipe);

    % Assets do not get rendered directly.  They get merged into another
    % scene which has its own output. So they do not need an output file or
    % directory.
    thisR.set('outputfile','');

    % piRead changes asset names to lower case
    % This means things break when we merge UC letters into recipes
    
    n = thisR.get('asset names');

    % Save in assets/characters instead...
    saveFileStub = erase(characterRecipe,'.pbrt');
    saveFile = [saveFileStub '.mat'];
    %{
    % not sure why we needed this?
    if isequal(upper(allLetters(ii)),allLetters(ii))
        saveFile = [saveFileStub '.mat'];
    else
        saveFile = [saveFileStub '.mat'];
    end
    %}
    oFile = thisR.save(lower(fullfile(charAssetDir,saveFile)));

    letter = Alphabet_UC(ii); % hard-code for testing
    letter = [letter '_UC-Courier-Bold'];
    mergeNode = [letter,'_B'];
    save(oFile,'mergeNode','-append');
end

%{
% Test to see what it looks like:
        l = piLightCreate('distant','type','distant');
        thisR.set('light',l,'add');
        piAssetGeometry(thisR);
        thisR.show('objects')
        %thisR.get('asset','001_C_O','material')
        %thisR.set('material','White','reflectance',[.5 .5 .5]);
        piWRS(thisR);
%}

