function [thisR, info] = piRecipeDefault(varargin)
% Returns a recipe to an ISET3d (V4) standard scene
%
% Syntax
%   [thisR, info] = piRecipeDefault(varargin)
%
% Description:
%  piRecipeDefault converts PBRT scene text files into an ISET3d
%  recipe for rendering with piRender (or piWRS).  The text files
%  should be on your computer, or they should be on the SDR and
%  reachable via ieWebGet.  Here is the link to the SDR:
%
%    https://purl.stanford.edu/cb706yg0989
%
%  Note: Some of these scenes are missing lights and will not render,
%  or they will render in an awkward view.  I created piRecipeCreate()
%  as a wrapper that calls this function and then adds the necessary
%  lights and viewpoints for a reasonable piWRS() render.
%
%  There is a list of other scenes that we once had and should try to
%  find to add back into the SDR.
%
% Inputs
%   N/A  - Default returns the Macbeth Checker scene
%
% Optional key/val pairs
%   scene name - Specify a PBRT scene name based on the directory.
%
% Outputs
%   thisR - the ISET3d recipe with information from the PBRT scene file.
%   info  - Text returned by piRead
%
% See also
%  ieWebGet, @recipe, @recipe.list

% Examples:
%{
 recipe.list;
%}
%{
 thisR = piRecipeCreate('macbeth checker');  %Adds a light
 piWRS(thisR);
%}
%{
 thisR = piRecipeDefault('scene name','SimpleScene');
 piWRS(thisR);
%}
%{
 thisR = piRecipeDefault('scene name','checkerboard');
 piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('slanted edge');  % Adds a light
 piWRS(thisR);
%}
%{
 thisR = piRecipeDefault('scene name','chessSet');
 piWRS(thisR);
%}
%{
 % An error about materials not being defined.  DEBUG this!
 thisR = piRecipeDefault('scene name','teapot');
 piWRS(thisR);
%}

%%  Figure out the scene and whether you want to write it out

varargin = ieParamFormat(varargin);

p = inputParser;
p.addParameter('scenename','MacBethChecker',@ischar);

p.parse(varargin{:});

sceneDir   = p.Results.scenename;
% sceneFile  = p.Results.file;  % Should include the pbrt extension.
% loadrecipe = p.Results.loadrecipe;

%%  To read the file,the upper/lower case must be right

% We check based on all lower case, but get the capitalization right by
% assignment in the case
switch ieParamFormat(sceneDir)

    % ----------- iset3d-scenes --------------
    case 'arealight'
        sceneDir = 'arealight';
        sceneFile = [sceneDir, '.pbrt'];
        exporter = 'PARSE';
    case 'bunny'
        sceneDir = 'bunny';
        sceneFile = ['bunny','.pbrt'];
        exporter = 'PARSE';
    case 'car'
        sceneDir = 'car';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'characters'
        sceneDir = 'characters';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'checkerboard'
        sceneDir = 'checkerboard';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'chessset'
        sceneDir = 'chessset';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'coordinate'
        sceneDir = 'coordinate';
        sceneFile = ['coordinate','.pbrt'];
        exporter = 'PARSE';
    case {'cornell_box','cornell-box-iset3d'}
        sceneDir = 'cornell_box';
        sceneFile = ['cornell_box','.pbrt'];
        exporter = 'PARSE';
    case {'cornellboxreference'}
        % Main Cornell Box
        sceneDir = 'CornellBoxReference';
        sceneFile = ['CornellBoxReference','.pbrt'];
        exporter = 'PARSE';
    case {'flashcards'}
        sceneDir = 'flashCards';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'flatsurface'
        sceneDir = 'flatSurface';
        sceneFile = 'flatSurface.pbrt';
        exporter = 'PARSE';
    case 'flatsurfacewhitetexture'
        sceneDir = 'flatsurfacewhitetexture';
        sceneFile = 'flatSurfaceWhiteTexture.pbrt';
        exporter = 'PARSE';
    case {'head-iset3d'}
        sceneDir = 'head';
        sceneFile = ['head','.pbrt'];
        exporter = 'PARSE';
    case 'lettersatdepth'
        sceneDir = 'lettersAtDepth';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'low-poly-taxi'
        sceneDir = 'low-poly-taxi';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case {'macbethchecker','macbethchart'}
        sceneDir = 'MacBethChecker';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case {'materialball'}
        sceneDir = 'materialball';
        sceneFile = ['materialball','.pbrt'];
        exporter = 'PARSE';
    case {'materialball_cloth'}
        sceneDir = 'materialball_cloth';
        sceneFile = ['materialball_cloth','.pbrt'];
        exporter = 'PARSE';
    case 'simplescene'
        sceneDir = 'simplescene';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'slantededge'
        sceneDir = 'slantedEdge';
        sceneFile = 'slantedEdge.pbrt';
        exporter = 'PARSE';
    case 'snellenatdepth'
        sceneDir = 'snellenatdepth';
        sceneFile = 'snellen.pbrt';
        exporter = 'Copy';
    case 'sphere'
        sceneDir = 'sphere';
        sceneFile = 'sphere.pbrt';
        exporter = 'PARSE';
    case 'stepfunction'
        sceneDir = 'stepfunction';
        sceneFile = 'stepfunction.pbrt';
        exporter = 'PARSE';
    case 'teapotset'
        sceneDir = 'teapot-set';
        sceneFile = 'TeaTime-converted.pbrt';
        exporter = 'Copy';
    case {'testplane'}
        % This scene has a bug.  See also piRecipeCreate
        % It has to do with Textures.
        sceneDir  = 'testplane';
        sceneFile = 'testplane-converted.pbrt';
        exporter = 'PARSE';

        % Bitterli scenes available on SDR
    case 'bathroom'
        % Bitterli
        sceneDir = 'bathroom';
        sceneFile = 'scene-v4.pbrt';
        exporter = 'Copy';
    case 'bathroom2'
        % Bitterli
        sceneDir = 'bathroom2';
        sceneFile = 'scene-v4.pbrt';
        exporter = 'Copy';
    case 'bedroom'
        % Bitterli
        sceneDir = 'bedroom';
        sceneFile = 'scene-v4.pbrt';
        exporter = 'Copy';
    case 'classroom'
        % Bitterli
        sceneDir = 'classroom';
        sceneFile = 'scene-v4.pbrt';
        exporter = 'Copy';
    case 'cornell-box'
        % On SDR
        sceneDir = 'cornell-box';
        sceneFile = 'scene-v4.pbrt';
        exporter = 'Copy';
    case 'glass-of-water'
        % On SDR
        sceneDir = 'glass-of-water';
        sceneFile = 'scene-v4.pbrt';
        exporter = 'Copy';
    case 'lamp'
        sceneDir = 'lamp';
        sceneFile = 'lamp.pbrt';
        exporter = 'Copy';
    case {'living-room-1'}
        sceneDir = 'living-room';
        sceneFile = 'living-room.pbrt';
        exporter = 'Copy';
    case 'living-room-2'
        sceneDir = 'living-room-2';
        sceneFile = 'living-room-2.pbrt';
        exporter = 'Copy';
    case 'living-room-3'
        sceneDir = 'living-room-3';
        sceneFile = 'living-room-3.pbrt';
        exporter = 'Copy';
    case 'staircase'
        sceneDir = 'staircase';
        sceneFile = 'staircase.pbrt';
        exporter = 'Copy';
    case 'staircase2'
        sceneDir = 'staircase2';
        sceneFile = 'staircase2.pbrt';
        exporter = 'Copy';
    case 'teapot-full'
        sceneDir = 'teapot-full';
        sceneFile = 'teapot-full.pbrt';
        exporter = 'Copy';
    case 'veach-ajar'
        sceneDir = 'veach-ajar';
        sceneFile = 'veach-ajar.pbrt';
        exporter = 'Copy';
    case 'veach-bidir'
        sceneDir = 'veach-bidir';
        sceneFile = 'veach-bidir.pbrt';
        exporter = 'Copy';
    case 'veach-mis'
        sceneDir = 'veach-mis';
        sceneFile = 'veach-mis.pbrt';
        exporter = 'Copy';

        % --------- PBRT (pharr) scenes
    case 'barcelona-pavillion-day'
        sceneDir = 'barcelona-pavillion';
        sceneFile = 'pavilion-day.pbrt';
        exporter = 'Copy';
    case 'barcelona-pavillion-night'
        sceneDir = 'barcelona-pavillion';
        sceneFile = 'pavilion-night.pbrt';
        exporter = 'Copy';
    case {'bistro-boulangerie'}
        sceneDir = 'bistro';
        sceneFile = 'bistro_boulangerie.pbrt';
        exporter = 'Copy';
    case 'bistro-vespa'
        sceneDir = 'bistro';
        sceneFile = 'bistro_vespa.pbrt';
        exporter = 'Copy';
    case 'bistro-cafe'
        sceneDir = 'bistro';
        sceneFile = 'bistro_cafe.pbrt';
        exporter = 'Copy';
    case 'bmw-m6'
        sceneDir = 'bmw-m6';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'Copy';
    case 'bunny-cloud'
        sceneDir = 'bunny-cloud';
        sceneFile = 'bunny_cloud.pbrt';
        exporter = 'Copy';
    case 'bunny-fur'
        sceneDir = 'bunny-fur';
        sceneFile = 'bunny-fur.pbrt';
        exporter = 'Copy';
    case 'clouds'
        sceneDir = 'clouds';
        sceneFile = 'clouds.pbrt';
    case 'contemporary-bathroom'
        sceneDir = 'contemporary-bathroom';
        sceneFile = 'contemporary-bathroom.pbrt';
        exporter = 'Copy';
    case 'crown'
        sceneDir = 'crown';
        sceneFile = 'crown.pbrt';
        exporter = 'Copy';
    case 'dambreak-0'
        sceneDir = 'dambreak';
        sceneFile = 'dambreak0.pbrt';
        exporter = 'Copy';
    case 'dambreak-1'
        sceneDir = 'dambreak';
        sceneFile = 'dambreak1.pbrt';
        exporter = 'Copy';
    case 'disney-cloud'
        sceneDir = 'disney-cloud';
        sceneFile = 'disney-cloud.pbrt';
        exporter = 'Copy';
    case 'explosion'
        sceneDir = 'explosion';
        sceneFile = 'explosion.pbrt';
        exporter = 'Copy';
    case 'ganesha'
        sceneDir = 'ganesha';
        sceneFile = 'ganesha.pbrt';
        exporter = 'Copy';
    case 'hair'
        sceneDir = 'hair';
        sceneFile = 'hair.pbrt';
        exporter = 'Copy';
    case 'head-pbrtv4'
        sceneDir = 'head';
        sceneFile = 'head.pbrt';
        exporter = 'Copy';
    case 'killeroos-gold'
        sceneDir = 'killeroos';
        sceneFile = 'killeroo-gold.pbrt';
        exporter = 'Copy';
    case 'killeroos-coated-gold'
        sceneDir = 'killeroos';
        sceneFile = 'killeroo-coated-gold.pbrt';
        exporter = 'Copy';
    case 'killeroos-simple'
        sceneDir = 'killeroos';
        sceneFile = 'killeroo-simple.pbrt';
        exporter = 'Copy';
    case 'kitchen'
        sceneDir = 'kitchen';
        sceneFile = 'kitchen.pbrt';
        exporter = 'Copy';
    case {'landscape-0'}
        sceneDir = 'landscape';
        sceneFile = 'view-0.pbrt';
        exporter = 'Copy';
    case {'landscape-1'}
        sceneDir = 'landscape';
        sceneFile = 'view-1.pbrt';
        exporter = 'Copy';
    case {'landscape-2'}
        sceneDir = 'landscape';
        sceneFile = 'view-2.pbrt';
        exporter = 'Copy';
    case {'landscape-4'}
        sceneDir = 'landscape';
        sceneFile = 'view-4.pbrt';
        exporter = 'Copy';
    case 'lte-orbblue-agat-spec'
        sceneDir = 'lte-orb';
        sceneFile = 'lte-orb-blue-agat-spec.pbrt';
        exporter = 'Copy';
    case 'lte-orb-rough-glass'
        sceneDir = 'lte-orb';
        sceneFile = 'lte-orb-rough-glass.pbrt';
        exporter = 'Copy';
    case 'lte-orb-silver'
        sceneDir = 'lte-orb';
        sceneFile = 'lte-orb-silver.pbrt';
        exporter = 'Copy';
    case 'lte-orb-simple-ball'
        sceneDir = 'lte-orb';
        sceneFile = 'lte-orb-simple-ball.pbrt';
        exporter = 'Copy';
    case 'pbrt-book'
        sceneDir = 'pbrt-book';
        sceneFile = 'book.pbrt';
        exporter = 'Copy';
    case 'sanmiguel-entry'
        sceneDir = 'sanmiguel';
        sceneFile = 'sanmiguel-entry.pbrt';
        exporter = 'Copy';
    case 'sanmiguel-balcony-plants'
        sceneDir = 'sanmiguel';
        sceneFile = 'sanmiguel-balcony-plants.pbrt';
        exporter = 'Copy';
    case 'sanmiguel-courtyard-second'
        sceneDir = 'sanmiguel';
        sceneFile = 'sanmiguel-courtyard-second.pbrt';
        exporter = 'Copy';
    case 'sanmiguel-in-tree'
        sceneDir = 'sanmiguel';
        sceneFile = 'sanmiguel-in-tree.pbrt';
        exporter = 'Copy';
    case 'sanmiguel-realistic-courtyard'
        sceneDir = 'sanmiguel';
        sceneFile = 'sanmiguel-realistic-courtyard.pbrt';
        exporter = 'Copy';
    case 'sanmiguel-upstairs'
        sceneDir = 'sanmiguel';
        sceneFile = 'sanmiguel-upstairs.pbrt';
        exporter = 'Copy';
    case 'sanmiguel-upstairs-across'
        sceneDir = 'sanmiguel';
        sceneFile = 'sanmiguel-upstairs-across.pbrt';
        exporter = 'Copy';
    case 'sanmiguel-upstairs-corner'
        sceneDir = 'sanmiguel';
        sceneFile = 'sanmiguel-upstairs-corner.pbrt';
        exporter = 'Copy';
    case 'smoke-plume'
        sceneDir = 'smoke-plume';
        sceneFile = 'plume.pbrt';
        exporter = 'Copy';
    case 'sportscar-sky'
        sceneDir = 'sportscar';
        sceneFile ='sportscar-sky.pbrt';
        exporter = 'Copy';
    case 'sportscar-area-lights'
        sceneDir = 'sportscar';
        sceneFile ='sportscar-area-lights.pbrt';
        exporter = 'Copy';
    case 'sssdragon_10'
        sceneDir = 'sssdragon';
        sceneFile = 'dragon_10.pbrt';
        exporter = 'Copy';
    case 'sssdragon_50'
        sceneDir = 'sssdragon';
        sceneFile = 'dragon_50.pbrt';
        exporter = 'Copy';
    case 'sssdragon_250'
        sceneDir = 'sssdragon';
        sceneFile = 'dragon_250.pbrt';
        exporter = 'Copy';
    case 'transparent-machines'
        sceneDir = 'transparent-machines';
        sceneFile = 'frame675.pbrt';
        exporter = 'Copy';

    case 'zero-day-25'
        sceneDir = 'zero-day';
        exporter = 'Copy';
        sceneFile = 'frame25.pbrt';
    case 'zero-day-35'
        sceneDir = 'zero-day';
        exporter = 'Copy';
        sceneFile = 'frame35.pbrt';
    case 'zero-day-52'
        sceneDir = 'zero-day';
        exporter = 'Copy';
        sceneFile = 'frame52.pbrt';
    case 'zero-day-85'
        sceneDir = 'zero-day';
        exporter = 'Copy';
        sceneFile = 'frame85.pbrt';
    case 'zero-day-120'
        sceneDir = 'zero-day';
        exporter = 'Copy';
        sceneFile = 'frame120.pbrt';
    case 'zero-day-180'
        sceneDir = 'zero-day';
        exporter = 'Copy';
        sceneFile = 'frame180.pbrt';
    case 'zero-day-210'
        sceneDir = 'zero-day';
        exporter = 'Copy';
        sceneFile = 'frame210.pbrt';
    case 'zero-day-300'
        sceneDir = 'zero-day';
        exporter = 'Copy';
        sceneFile = 'frame300.pbrt';
    case 'zero-day-380'
        sceneDir = 'zero-day';
        exporter = 'Copy';
        sceneFile = 'frame380.pbrt';


    otherwise
        error('Can not identify the scene, %s\n',sceneDir);
end

%% See if we can find the file in data/scenes/web

% Local - just a couple of scenes
FilePath = fullfile(piRootPath,'data','scenes',sceneDir);
if ~isfolder(FilePath)
    FilePath = fullfile(piRootPath,'data','scenes','web',sceneDir);
end

% If we can not find it, check on the web.
fname = fullfile(FilePath,sceneFile);
if ~exist(fname,'file')
    sceneDir = piSceneWebTest(sceneDir,sceneFile);
    fname = fullfile(sceneDir,sceneFile);
end

%% If we are here, we found the file.  So create the recipe.

% Parse the file contents into the ISET3d recipe and identify the type
% of parser.  PARSE has special status.  In other cases, such as the
% scenes from the PBRT and Benedikt sites, we just copy the files into
% ISET3d/local.
[thisR, info] = piRead(fname, 'exporter', exporter);

% By default, do the rendering and mounting from ISET3d/local.  That
% directory is not part of the git upload area.
[~,n,e] = fileparts(fname);
outFile = fullfile(piRootPath,'local',sceneDir,[n,e]);
thisR.set('outputfile',outFile);
thisR.set('name',sceneDir);

% Set defaults for very low resolution (for testing)
thisR.integrator.subtype = 'path';
thisR.set('pixelsamples', 32);
thisR.set('filmresolution', [320, 320]);

% If no camera was included, add a pinhole by default.
if isempty(thisR.get('camera'))
    thisR.set('camera',piCameraCreate('pinhole'));
end

% Set the render type to the default radiance and depth
thisR.set('render type',{'radiance','depth'});

% In principle, we might light to check that the scene has a light.
% But we don't yet have a clear way for the 'Copy' case.
if isequal(exporter,'PARSE') && thisR.get('n lights') == 0
    warning('No lights in this scene.');
end

end

%%
%{
% Maybe we look for these and add them to SDR?  Or delete?
    case 'coloredcube'
        sceneDir = 'coloredCube';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'slantedbarPARSE'
        sceneDir = 'slantedBarPARSE';
        sceneFile = 'slantedBarPARSE.pbrt';
        exporter = 'PARSE';
    case 'slantedbarasset'
        sceneDir = 'slantedbarAsset';
        sceneFile = 'slantedbarAsset.pbrt';
        exporter = 'PARSE';
    

    case 'flatsurfacerandomtexture'
        sceneDir = 'flatSurfaceRandomTexture';
        sceneFile = 'flatSurfaceRandomTexture.pbrt';
        exporter = 'PARSE';
    case 'flatsurfacemcctexture'
        sceneDir = 'flatSurfaceMCCTexture';
        sceneFile = 'flatSurfaceMCCTexture.pbrt';
        exporter = 'PARSE';

    case 'simplescenelight'
        sceneDir = 'SimpleSceneLight';
        sceneFile = 'SimpleScene.pbrt';
        exporter = 'PARSE';

    case {'cornellboxbunnychart'}
        if loadrecipe && exist('Cornell_Box_Multiple_Cameras_Bunny_charts-recipe.mat','file')
            load('Cornell_Box_Multiple_Cameras_Bunny_charts-recipe.mat','thisR');
            return;
        end
        sceneDir = 'Cornell_BoxBunnyChart';
        sceneFile = ['Cornell_Box_Multiple_Cameras_Bunny_charts','.pbrt'];
        exporter = 'PARSE';
    
    case {'cornellboxlamp'}
        sceneDir = 'CornellBoxLamp';
        sceneFile = ['CornellBoxLamp','.pbrt'];
        exporter = 'PARSE';
    case 'snellenatdepth'
        sceneDir = 'snellenAtDepth';
        sceneFile = ['snellen','.pbrt'];
        exporter = 'Copy';
    case 'villa' %27
%{
                [1m[31mWarning[0m: GBufferFilm is not supported by the "bdpt" integrator. The channels other than R, G, B will be zero.
                Rendering: [                                                                                                                                                             ] Segmentation fault
                (core dumped)
%}
                % Try with CPU.  Failed with GPU so far.
                % ieDocker.preset('orange-cpu'); ieDocker.reset;
                sceneName = {'villa-daylight.pbrt', 'villa-lights-on.pbrt'};

    case 'teapotfull'
        sceneDir = 'teapot-full';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';

    case 'colorfulscene'
        % djc -- This scene loads but on my machine pbrt gets an error:
        %        "Unexpected token: "string mapname""
        sceneDir = 'ColorfulScene';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';
    

%}