% s_assetsSimplify
% v_iset3d_simplify
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

% The commented piWRS calls below are useful for interactive before/after
% comparisons.  Keep only one active render in the automated smoke path.

%% Area light

thisR = piRecipeCreate('arealight');
thisR.set('rays per pixel',32);
thisR.set('film resolution',[160 120]);
thisR.get('n nodes')
% piWRS(thisR,'render flag','hdr');

thisR.simplify;
thisR.get('n nodes')
piWRS(thisR,'render flag','hdr');

%%  Simple scene

thisR = piRecipeCreate('Simple Scene');
thisR.set('rays per pixel',32);
thisR.set('film resolution',[160 120]);
thisR.get('n nodes')
% piWRS(thisR,'render flag','rgb');

thisR.simplify;
thisR.get('n nodes')
% piWRS(thisR,'render flag','rgb');

%% Simplify chess set
thisR = piRecipeCreate('ChessSet');
thisR.set('rays per pixel',32);
thisR.set('film resolution',[160 120]);
thisR.get('n nodes')
% piWRS(thisR,'render flag','rgb');

thisR.simplify;
thisR.get('n nodes')
% piWRS(thisR,'render flag','rgb');

%%
