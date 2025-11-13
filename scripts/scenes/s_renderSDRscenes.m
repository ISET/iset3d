%% Create ISETCam scenes from the SDR PBRT files
%
% We do this to save computation in the future
%
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

resolution = [320 320]*2;

%% Get a list of the PBRT scenes up on SDR

sdrNames = piSDRSceneNames;
for ii=1:numel(sdrNames.bitterli.names)
    sceneName = sdrNames.bitterli.names{ii};
    thisR = piRecipeDefault('scene name',sceneName);

    thisR.set('n bounces',5);
    thisR.set('rays per pixel',2048);
    thisR.set('film resolution',resolution);
    thisR.set('render type',{'radiance','depth'});
    
    % piWrite(thisR,'overwrite resources',false);
    scene = piRender(thisR,'denoise',true);    
    scene = piAIdenoise(scene);

    % Save it in ISET3d-tiny local
    fname = fullfile(piRootPath,'local','prerender',sceneName);
    save(fname,'scene');
    % sceneWindow(scene);
    % ieReplaceObject(scene); sceneWindow;
end


%%
