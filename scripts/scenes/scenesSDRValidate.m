%% Start up ISET and check that docker is configured 

% Needs help.  Not running right.

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the recipe

% These aren't good.  Use piSDRSceneNames
% see s_renderSRDscenes.  Maybe that is all we need.

sdrFiles = {'arealight','bunny','car','characters','checkerboard',...
    'chessset','coordinate','cornell_box',...
    'flashcards',...
    'flatsurface','flatsurfacewhitetexture',...
    'head', ...
    'lettersatdepth','low-poly-tax','macbethchecker','macbethchart',...
    'materialball','materialball_cloth','simplescene',...
    'slantededge','snellenatdepth','sphere',...
    'stepfunction','teapot-set','testplane'};

%% Problems

% characters, chesset, cornellboxreference

%%
for ff = 1:numel(sdrFiles)
    disp(sdrFiles{ff})
    % Download and render it
    thisR = piRecipeDefault('scene name',sdrFiles{ff});
    if isempty(thisR.get('lights'))
        fprintf('Skipping %s, no light\n',sdrFiles{ff}');
    else
        scene = piWRS(thisR);
    end
end

%%
