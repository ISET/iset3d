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

thisR = piRecipeDefault('scene name','car');
thisR.set('skymap','noon_009.exr');

oDist = thisR.get('object distance');
thisR.set('object distance',3*oDist);  % Better view
scene = piWRS(thisR);

%%
scene = piAIdenoise(scene);
ieReplaceObject(scene); sceneWindow;

%%  Could denoise

%% END

