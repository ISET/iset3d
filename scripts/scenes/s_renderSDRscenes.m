%% Create ISETCam scenes from the SDR PBRT files
%
% We do this to save computation in the future
%
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

% Setting these parameters isn't working corretly.  Not sure why.
% resolution = [320 320];
% resolution = [160 160];
resolution = [1920,1080];

% Rays per pixel
rpp = 2048;

% Get a list of the PBRT scenes up on SDR
sdrNames = piSDRSceneNames;

%%
for ii=1:numel(sdrNames.bitterli.names)
    sceneName = sdrNames.bitterli.names{ii};
    thisR = piRecipeDefault('scene name',sceneName);

    thisR.set('n bounces',5);
    thisR.set('rays per pixel',rpp);
    thisR.set('film resolution',resolution);
    thisR.set('render type',{'radiance','depth'});
    
    % Write the modified parameters.
    piWrite(thisR,'overwrite resources',false);
    scene = piRender(thisR);   
    scene = piAIdenoise(scene);

    % Save it in ISET3d-tiny local
    fname = fullfile(piRootPath,'local','prerender',sceneName);
    save(fname,'scene');
    % sceneWindow(scene);
    % ieReplaceObject(scene); sceneWindow;
end


%% Now the Pharr pbrtv4 files

% Some of the more complex scenes have multiple possible scene files.
% There is a default that is rendered here.  If you would like to
% render another version you can change the name of the scene file in
% this recipe to match one of the other views. 
%
% For example
% the default: bistro_boulangerie.pbrt
%{
 sceneNames = {'bistro_cafe.pbrt'; 'bistro_vespa.pbrt'}
 thisR = piRecipeDefault('scene name','bistro','scene filename',sceneName); 
%}
%{
% This is the default:  'sanmiguel-entry.pbrt';
sceneNames = {...
    'sanmiguel-balcony-plants.pbrt';
    'sanmiguel-courtyard-second.pbrt'; 'sanmiguel-in-tree.pbrt';
    'sanmiguel-upstairs.pbrt';'sanmiguel-upstairs-across.pbrt';
    'sanmiguel-upstairs-corner.pbrt';};
%}
%{
% resolution = [160 160];
% rpp = 512;
for ss = 1:numel(sceneNames)
    sceneName = sceneNames{ss};
    thisR = piRecipeDefault('scene name','sanmiguel','scene filename',sceneName); 
    thisR.set('n bounces',5);
    thisR.set('rays per pixel',rpp);
    thisR.set('film resolution',resolution);
    thisR.set('render type',{'radiance','depth'});

    piWrite(thisR,'overwrite resources',true);
    scene = piRender(thisR);
    scene = piAIdenoise(scene);
    % sceneWindow(scene);

    [~,n,e] = fileparts(sceneName);

    % Save it in ISET3d-tiny local/prerender
    fname = fullfile(piRootPath,'local','prerender',n);
    save(fname,'scene');
    
    disp(['saved ',fname]);

end
%}

% Several of the others have additional options, including hair and
% zero_day and dambreak and who knows ...


%% 
for ii=1:numel(sdrNames.pbrtv4.names)
    try
        sceneName = sdrNames.pbrtv4.names{ii};
        thisR = piRecipeDefault('scene name',sceneName);
        fprintf('Downloaded %s.\n',sceneName);

        thisR.set('n bounces',5);
        thisR.set('rays per pixel',2048);
        thisR.set('film resolution',resolution);
        thisR.set('render type',{'radiance','depth'});

        % Write the modified parameters.
        piWrite(thisR,'overwrite resources',false);

        scene = piRender(thisR);
        scene = piAIdenoise(scene);
        
        % Save it in ISET3d-tiny local
        fname = fullfile(piRootPath,'local','prerender',sceneName);
        save(fname,'scene');
        % if ii==1
        %     sceneWindow(scene);
        %     drawnow;
        % else
        %     ieReplaceObject(scene);
        %     sceneWindow; drawnow;
        % end

    catch
        fprintf('** %d - Failed on %s **\n',ii,sceneName);
    end  
    
end

%% Now the ISET3d scenes

% resolution = [320 320];

for ii=1:numel(sdrNames.iset3d.names)
    try
        sceneName = sdrNames.iset3d.names{ii};
        thisR = piRecipeDefault('scene name',sceneName);
        fprintf('Downloaded %s.\n',sceneName);

        if isempty(thisR.get('lights'))
            % fileName = fullfile(piDirGet('skymaps'),'room.exr');
            % thisR.set('skymap',fileName);

            distLight = piLightCreate('default_D65_light',...
                'type', 'distant', ...
                'spd spectrum', 'D65',...
                'specscale float', 1);
            distLight.from.value = thisR.get('from');
            distLight.to.value   = thisR.get('to');

            thisR.set('light',distLight,'add');

            fprintf('Added light\n')
            thisR.get('lights print');
        end

        thisR.set('n bounces',5);
        thisR.set('rays per pixel',2048);
        thisR.set('film resolution',resolution);
        thisR.set('render type',{'radiance','depth'});

        % Write the modified parameters.
        piWrite(thisR,'overwrite resources',false);

        scene = piRender(thisR);
        scene = piAIdenoise(scene);
        
        % Save it in ISET3d-tiny local
        fname = fullfile(piRootPath,'local','prerender',sceneName);
        save(fname,'scene');
        % {
        if ii==1
            sceneWindow(scene);
            drawnow;
        else
            ieReplaceObject(scene);
            sceneWindow; drawnow;
        end
        %}
    catch
        fprintf('** %d - Failed on %s **\n',ii,sceneName);
    end  
    
end

%{
** 4 - Failed on characters **
** 6 - Failed on chessset **  I made it work, but there is a bug because the
lightmap_v4.exr is in the chesset directory but we don't find it with
piGeometryWrite ... It looks for it in data/skymaps/...  I put it
there to make this run, but we should fix the bug.
** 14 - Failed on head **  This one is already in the repository.
Needs help.
** 26 - Failed on teapot-set **  Deeply broken.  Not sure why.

%}