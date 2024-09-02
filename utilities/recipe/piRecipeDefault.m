function [thisR, info] = piRecipeDefault(varargin)
% Returns a recipe to an ISET3d (v4) standard scene
%
% Syntax
%   [thisR, info] = piRecipeDefault(varargin)
%
% Description:
%  piRecipeDefault reads in PBRT scene text files in the data/V3
%  repository.  It can also call ieWebGet to retrieve pbrt scenes,
%  from the web and install them locally.
%
%  Some of these scenes are missing lights and will not render, or
%  they will render in an awkward view.  I created piRecipeCreate() as
%  a wrapper that calls this function and then adds the necessary
%  lights and viewpoints for a reasonable piWRS() render.
%
% Inputs
%   N/A  - Default returns the Macbeth Checker scene 
%
% Optional key/val pairs
%   scene name - Specify a PBRT scene name based on the directory.
%   file  - The name of a file in the scene directory.  This is used
%   because some PBRT have multiple files from different points of
%   view.  We always have a default, but if you want one of the other
%   ones, set this parameter
%
%     piRecipeDefault('scene name','landscape','file','view-1.pbrt')
%     piRecipeDefault('scene name','bistro','file','bistro_boulangerie.pbrt')
%
% Outputs
%   thisR - the ISET3d recipe with information from the PBRT scene file.
%
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
p.addParameter('file','',@ischar);   
p.addParameter('loadrecipe',true,@islogical);  % Load recipe if it exists

p.parse(varargin{:});

sceneDir   = p.Results.scenename;
sceneFile  = p.Results.file;  % Should include the pbrt extension.
loadrecipe = p.Results.loadrecipe;

%%  To read the file,the upper/lower case must be right

% We check based on all lower case, but get the capitalization right by
% assignment in the case
switch ieParamFormat(sceneDir)

    case {'macbethchecker','macbethchart'}
        sceneDir = 'MacBethChecker';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case {'flashcards'}
        sceneDir = 'flashCards';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'whiteboard'
        sceneDir = 'WhiteBoard';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'simplescene'
        sceneDir = 'SimpleScene';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'bmw-m6'
        sceneDir = 'bmw-m6';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'car'
        sceneDir = 'car';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'chessset'
        sceneDir = 'chessset';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'chesssetpieces'
        sceneDir = 'ChessSetPieces';
        sceneFile = ['ChessSet','.pbrt'];
        exporter = 'PARSE';
    case 'chessset_2'
        sceneDir = 'ChessSet_2';
        sceneFile = ['chessSet2','.pbrt'];
        exporter = 'Copy';
    case 'chesssetscaled'
        sceneDir = 'ChessSetScaled';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'Copy';

    case 'checkerboard'
        sceneDir = 'checkerboard';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'coloredcube'
        sceneDir = 'coloredCube';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';
    case 'teapot'
        sceneDir = 'teapot';
        sceneFile = 'teapot-area-light-v4.pbrt';
        exporter = 'Copy';
    case 'teapotset'
        sceneDir = 'teapot-set';
        sceneFile = 'TeaTime-converted.pbrt';
        exporter = 'Copy';
    case 'slantededge'
        % In sceneEye cases we were using piCreateSlantedBarScene.  But
        % going forward we will use the Cinema 4D model so we can use the
        % other tools for controlling position, texture, and so forth.
        sceneDir = 'slantedEdge';
        sceneFile = 'slantedEdge.pbrt';
        exporter = 'PARSE';
    case 'slantedbarPARSE'
        sceneDir = 'slantedBarPARSE';
        sceneFile = 'slantedBarPARSE.pbrt';
        exporter = 'PARSE';
    case 'slantedbarasset'
        sceneDir = 'slantedbarAsset';
        sceneFile = 'slantedbarAsset.pbrt';
        exporter = 'PARSE';
    case 'flatsurface'
        sceneDir = 'flatSurface';
        sceneFile = 'flatSurface.pbrt';
        exporter = 'PARSE';
    case 'sphere'
        sceneDir = 'sphere';
        sceneFile = 'sphere.pbrt';
        exporter = 'PARSE';
    case 'flatsurfacewhitetexture'
        sceneDir = 'flatSurfaceWhiteTexture';
        sceneFile = 'flatSurfaceWhiteTexture.pbrt';
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
    case 'bunny'
        sceneDir = 'bunny';
        sceneFile = ['bunny','.pbrt'];
        exporter = 'PARSE';
    case 'coordinate'
        sceneDir = 'coordinate';
        sceneFile = ['coordinate','.pbrt'];
        exporter = 'PARSE';
    case {'cornellbox', 'cornell_box'}
        sceneDir = 'cornell_box';
        sceneFile = ['cornell_box','.pbrt'];
        exporter = 'PARSE';


    case {'materialball'}
        sceneDir = 'materialball';
        sceneFile = ['materialball','.pbrt'];
        exporter = 'PARSE';
    case {'materialball_cloth'}
        sceneDir = 'materialball_cloth';
        sceneFile = ['materialball_cloth','.pbrt'];
        exporter = 'PARSE';
        %     case 'bathroom'
        %         sceneDir = 'bathroom';
        %         sceneFile = 'scene.pbrt';
        %         exporter = 'Copy';


    case {'cornellboxbunnychart'}
        if loadrecipe && exist('Cornell_Box_Multiple_Cameras_Bunny_charts-recipe.mat','file')
            load('Cornell_Box_Multiple_Cameras_Bunny_charts-recipe.mat','thisR');
            return;
        end
        sceneDir = 'Cornell_BoxBunnyChart';
        sceneFile = ['Cornell_Box_Multiple_Cameras_Bunny_charts','.pbrt'];
        exporter = 'PARSE';
    case {'cornellboxreference'}
        % Main Cornell Box
        sceneDir = 'CornellBoxReference';
        sceneFile = ['CornellBoxReference','.pbrt'];
        exporter = 'PARSE';
    case {'cornellboxlamp'}
        sceneDir = 'CornellBoxLamp';
        sceneFile = ['CornellBoxLamp','.pbrt'];
        exporter = 'PARSE';
    case 'snellenatdepth'
        sceneDir = 'snellenAtDepth';
        sceneFile = ['snellen','.pbrt'];
        exporter = 'Copy';
    case 'lettersatdepth'
        sceneDir = 'lettersAtDepth';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'PARSE';

        % ************* Start Benedikt V4
    case 'contemporary-bathroom'
        sceneDir = 'contemporary-bathroom';
        sceneFile = 'contemporary-bathroom.pbrt';
        % exporter = 'Copy';  % Mostly OK.  Not sure all OK.
        exporter = 'PARSE';   % Mostly OK.  Not sure all OK.
    case 'kitchen'
        sceneDir = 'kitchen';
        sceneFile = 'kitchen.pbrt';
        exporter = 'Copy';
        % exporter = 'PARSE';  % Worked in dev-resources on March 27, 2023
    case {'landscape'}
        % Not working perhaps because the pointers to the exr files
        % are in another directory.
        sceneDir = 'landscape';
        if isempty(sceneFile)
            sceneFile = 'view-0.pbrt';
        end
        exporter = 'Copy';
    case {'staircase2'}
        sceneDir = 'staircase2';
        if isempty(sceneFile)
            sceneFile = 'scene-v4.pbrt';
        end
        exporter = 'Copy';
        % exporter = 'PARSE';  % Very slow and no useful.
    case {'bistro'}
        % Downloaded from the computer, cardinal, put in data/scenes/web
        % Other versions of this scene are
        %    bistro_boulangerie.pbrt and 'bistro_cafe.pbrt'
        %
        % April 12, 2023.  Failing with dev-kitchen piRead branch with PARSE. 
        % Also getting a non-square error on sky.exr even with Copy.
        warning('Bistro not yet working.');
        sceneDir = 'bistro';
        if isempty(sceneFile)
            sceneFile = 'bistro_vespa.pbrt';
        end
        exporter = 'Copy';  % How I found it
        % exporter = 'PARSE';
   case {'head'}
        sceneDir = 'head';
        sceneFile = ['head','.pbrt'];
        exporter = 'PARSE'; 
         % ************* End Benedikt V4
         
    case {'blenderscene'}
        sceneDir = 'BlenderScene';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'Blender';   % Blender
    case {'testplane'}
        sceneDir  = 'testplane';
        sceneFile = 'testplane-converted.pbrt';
        % This scene has a bug.  See also piRecipeCreate
        % It has to do with Textures.
        exporter = 'PARSE';    
    case 'arealight'
        sceneDir = 'arealight';
        sceneFile = [sceneDir, '.pbrt'];
        exporter = 'PARSE';

        % Maybe deprecated V3?
    case 'classroom'
        sceneDir = 'classroom';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';
    case 'veach-ajar'
        sceneDir = 'veach-ajar';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';
    case 'villalights'
        sceneDir = 'villaLights';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';
    case 'plantsdusk'
        sceneDir = 'plantsDusk';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';
    case 'livingroom'
        sceneDir = 'living-room';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';
    case 'yeahright'
        sceneDir = 'yeahright';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';
    case 'sanmiguel'
        sceneDir = 'sanmiguel';
        if isempty(sceneFile)
            sceneFile = 'scene.pbrt';
        end
        exporter = 'Copy';
    case 'teapotfull'
        sceneDir = 'teapot-full';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';
    case {'whiteroom', 'white-room'}
        sceneDir = 'white-room';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';
    case 'bedroom'
        sceneDir  = 'bedroom';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';        
    case 'colorfulscene'
        % djc -- This scene loads but on my machine pbrt gets an error:
        %        "Unexpected token: "string mapname""
        sceneDir = 'ColorfulScene';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';
    case 'livingroom3'
        % Not running
        sceneDir = 'living-room-3';
        sceneFile = 'scene.pbrt';
        exporter = 'Copy';

    case {'livingroom3mini', 'living-room-3-mini'}    
        % Not running
        sceneDir = 'living-room-3-mini';
        sceneFile = [sceneDir,'.pbrt'];
        exporter = 'Copy';
        
        % End V3 to deprecate or update
        
    otherwise
        error('Can not identify the scene, %s\n',sceneDir);
end

%% See if we can find the file in data/scenes/web

% Local
if isequal(sceneDir,'BlenderScene')
    FilePath = fullfile(piRootPath,'data','blender','BlenderScene');
else
    FilePath = fullfile(piRootPath,'data','scenes',sceneDir);
    if ~isfolder(FilePath)
        FilePath = fullfile(piRootPath,'data','scenes','web',sceneDir);
    end
end

% If we can not find it, check on the web.
fname = fullfile(FilePath,sceneFile);
if ~exist(fname,'file')
    fname = piSceneWebTest(sceneDir,sceneFile);
end

%% If we are here, we found the file.  So create the recipe.

% Parse the file contents into the ISET3d recipe and identify the type
% of parser.  PARSE has special status.  In other cases, such as the
% scenes from the PBRT and Benedikt sites, we just copy the files into
% ISET3d/local.
switch exporter
    case {'PARSE','Copy'}
        [thisR, info] = piRead(fname, 'exporter', exporter);
    case 'Blender'
        thisR = piRead_Blender(fname,'exporter',exporter);
    otherwise
        error('Unknown export type %s\n',exporter);
end
thisR.set('exporter',exporter);

% By default, do the rendering and mounting from ISET3d/local.  That
% directory is not part of the git upload area.
%
% outFile = fullfile(piRootPath,'local',sceneName,[sceneName,'.pbrt'];
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

end

