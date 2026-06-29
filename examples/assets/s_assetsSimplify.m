% s_assetsSimplify
% v_iset3d_simplify
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Area light

fileName = fullfile(piRootPath, 'data','scenes','arealight','arealight.pbrt');
thisR    = piRead(fileName);
thisR.get('n nodes')
piWRS(thisR,'render flag','hdr');

thisR.simplify;
thisR.get('n nodes')
piWRS(thisR,'render flag','hdr');

%%  Simple scene

thisR = piRecipeCreate('Simple Scene');
thisR.get('n nodes')
piWRS(thisR,'render flag','rgb');

thisR.simplify;
thisR.get('n nodes')
piWRS(thisR,'render flag','rgb');

%% Simplify chess set
thisR = piRecipeCreate('ChessSet');
thisR.get('n nodes')
piWRS(thisR,'render flag','rgb');

thisR.simplify;
thisR.get('n nodes')
piWRS(thisR,'render flag','rgb');

%%