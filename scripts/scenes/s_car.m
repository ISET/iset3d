%% s_car
%
% This one PARSED up without any editing.
% It is a lousy object, though.
%
% See also
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

% docker
isetDocker = isetdocker('preset','remote orange');

% database
isetDB     = idb.ISETdb();
%%
pbrtFile = '/Users/zhenyi/git_repo/dev/iset3d/data/scenes/ChessSet/ChessSet.pbrt';
thisR = piRead(pbrtFile);
piWrite(thisR);
scene = piWRS(thisR);

%%
scene = piAIdenoise(scene);
ieReplaceObject(scene); sceneWindow;

%%  Could denoise

%% END

