%% s_chessSetMake
%
% Make a recipe for the standard Chess set scene.
%
% The recipe load faster than parsing the scene and objects.
%
% TODO:
%  We are getting warnings still like:
%
%    Warning: Parameter: encoding does not exist in texture type: imagemap 
%    Warning: An object has been created with its material name: planeTan 
%
% See also
%

%% We make it with a blue distant background.

thisR = piRecipeDefault('scene name','ChessSet');

% Clear the default lights
thisR.set('light', 'all', 'delete');

fileName = 'sunlight.exr';
dLight = piLightCreate('distant light', ...
    'type', 'infinite',...
    'filename', fileName);

% Rotating it this way brings the blue sky behind the chess set.
dLight = piLightSet(dLight, 'rotation val', {[0 0 1 0], [-90 1 0 0]});
thisR.set('lights', 'add', dLight);  

[~, result] = piWRS(thisR);

%% Save the recipe.

% By default it is saved in the data/V4 directory with a -recipe appended
% to the name.s
oFile = thisR.save();
disp('Recipe saved as')
disp(oFile);

%{
% This rotates the light file around so the background becomes more yellow,
% diffuse.
% 
dLight = thisR.get('light','distant light');
dLight = piLightSet(dLight, 'rotation val', {[0 0 1 0], [22 1 0 0]});
thisR.set('lights', 'replace', 'distant light',dLight);  
%}

%% END