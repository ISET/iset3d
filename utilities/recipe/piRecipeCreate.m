function thisR = piRecipeCreate(rName,varargin)
% Return a recipe that can be rendered immediately with piWRS
%
% Synopsis
%   thisR = piRecipeCreate(rName,varargin)
%
% Brief
%   Many of the piRecipeDefault cases still need a light or to position the
%   camera to be rendered.  This routine adjusts the recipe so that it can
%   be rendered with piWRS immediately.
%
%   To see the valid recipe list use piRecipeCreate('help').  You can
%   also get a valid list from any recipe (thisR) using the command
%
%          thisR.list
%
% Input
%   rName - Recipe name from the cell array returned by 
%             validNames = piRecipeCreate('help');
%
% Key/Val pairs
%
% Return
%   thisR - the recipe
%
% See also
%   piRecipeDefault, thisR.list
%

% TODO
%   Maybe this should replace piRecipeDefault

% Examples:
%{
 thisR = piRecipeCreate('macbeth checker');
 piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('Cornell_Box');
 piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('Cornell Box Reference');
 piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('Simple scene');
 piWRS(thisR);
%}
%{
 thisR = piRecipeCreate('chess set');
 piWRS(thisR);
%}

%% Input parsing

validRecipes = {'macbethchart','chessset','head',...
    'cornell-box','cornellboxreference',...
    'simplescene','arealight','bunny','car','checkerboard', ...
    'flatsurface', ...
    'lettersatdepth','materialball','materialball_cloth',...
    'sphere','slantededge','testplane','teapotset'};

varargin = ieParamFormat(varargin);

p = inputParser;
p.addRequired('rName',@ischar);
p.addParameter('quiet',false,@islogical);

p.parse(rName,varargin{:});

rName    = ieParamFormat(rName);
if isequal(rName,'help') || isequal(rName,'list')
    thisR = validRecipes;
    if p.Results.quiet, return;
    else
        fprintf('\n-------Known recipes-----\n\n')
        for ii=1:numel(validRecipes)
            fprintf('%02d - %s\n',ii,validRecipes{ii});
        end
    end
    return;
end

%% 
%{
  rList = thisR.list;
    {'chessset'               } - OK
    {'cornellboxreference'    } - Requires HDR because light is bright
    {'head'                   } - Working on it
    {'macbethchecker'         } - Needs a light
    {'simplescene'            } - Renders
    {'arealight'              } - Broken
    {'bunny'                  } - Needs a light
    {'car'                    } - Needs a light
    {'checkerboard'           } - OK
    {'coordinate'             } - Needs a light
    {'cornell_box'            } - Needs a light
    {'flatsurface'            } - OK but boring.
    {'flatsurfacewhitetexture'} - Not sure about the texture
    {'lettersatdepth'         } - OK
    {'materialball'           } - OK
    {'materialball_cloth'     } - OK
    {'slantedEdge'            } - Needs a light
    {'sphere'                 } - Needs a light
    {'teapot'                 } - Many problems
    {'teapotset'              } - Bad file name
    {'testplane'              } - Bad FBX

thisR = piRecipeDefault('scene name',rList{4});
piWRS(thisR);

%}

%%
switch ieParamFormat(rName)
    case {'macbethchecker','macbethchart'}
        % Necessary if wwe are getting it from the SDR
        rName = 'macbethchecker';   % Should automate this.
        
        thisR = piRecipeDefault('scene name',rName);
        thisR = thisR.set('lights','all','delete');

        % Add an equal energy distant light for uniform lighting
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum, ...
            'from',thisR.get('from'), ...
            'to', thisR.get('to'));
        thisR.set('light', lgt, 'add');
        
        thisR.set('integrator subtype','path');
        thisR.set('rays per pixel', 16);
        thisR.set('fov', 30);
        thisR.set('filmresolution', [640, 360]);

    case 'chessset'
        thisR = piRecipeDefault('scene name',rName);
        idx = piAssetSearch(thisR,'light name','_L');
        thisR.set('asset',idx,'name','mainLight_L');

    case 'cornell_box'
        thisR = piRecipeDefault('scene name',rName);

        thisR.set('rays per pixel',128);
        thisR.set('nbounces',5);
        thisR.set('lights','all','delete');
        distantLight = piLightCreate('distantLight', ...
            'type','spot',...
            'cameracoordinate', true);
        thisR.set('light',distantLight,'add');

        % By default, the fov is setted as horizontal and vertical
        fov = 25;
        thisR.set('fov',fov);

        % Increase the spatial resolution a bit
        filmRes = [384 256];
        thisR.set('film resolution',filmRes);
    case 'cornellboxreference'
        thisR = piRecipeDefault('scene name','CornellBoxReference');
        warning('Requires HDR because light source is bright.')
    case 'simplescene'
        thisR = piRecipeDefault('scene name',rName);
    case 'arealight'
        thisR = piRecipeDefault('scene name',rName);
    case 'bunny'
        % The bottom of the bunny is at 0,0,0
        % We see it from the side.
        thisR = piRecipeDefault('scene name',rName);
        bunnyID = piAssetSearch(thisR,'object name','bunny');
        thisR.set('from',[0 0 0]);
        thisR.set('to',[0 0 1]);
        thisR.set('up',[0 1 0]);
        thisR.set('asset',bunnyID,'scale',2);  % I don't think the size is right.
        thisR.set('asset',bunnyID,'world position',[0 0 1]);        
        thisR.show('objects');

        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('distant',...
            'from',[0 0 -5],...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum);
        thisR.set('light', lgt, 'add');
    case 'head'
        % The face is positioned towards the camera.
        % The 'to' is the upper right of the head, it seems.s
        thisR = piRecipeDefault('scene name','head');
        thisR.set('lights','all','delete');
        thisR.set('from',[0 0 0]);
        thisR.set('to',[0 0 1]);
        thisR.set('up',[0 1 0]);
        thisR.set('node',2,'name','head_B');
        thisR.set('node',3,'name','head_O');        
        id = piAssetSearch(thisR,'object name','head');
        thisR.set('asset',id,'world position',[0 0 1]);
        thisR.set('asset',id,'rotate',[0 180 0]);
        thisR.set('asset',id,'scale',0.5);

        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('distant',...
            'from',[0 0 -5],...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum);
        thisR.set('light', lgt, 'add');
        % piWRS(thisR);

    case 'car'
        % The materials do not look right.  Rendering needs help.
        thisR = piRecipeDefault('scene name',rName);
        thisR.set('object distance',6);
        thisR.set('to',[-1 1.2 -5.6]);
        
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', lgt, 'add');
        warning('Car scene needs work.')
    case 'checkerboard'
        % 1m x 1m at 0 0 1 with from at 0 0 0.  Zero thickness.
        thisR = piRecipeDefault('scene name',rName);
        idx = piAssetSearch(thisR,'object name','Checkerboard');
        thisR.set('asset',idx,'world position',[0 0 1]);
        sz = thisR.get('asset',idx,'size');
        thisR.set('asset',idx,'scale',[1/sz(1),1/sz(2),1]);

        thisR.set('from',[0 0 0]);
        thisR.set('to',[0 0 1]);

        % Equal energy infinite light.
        thisR.set('lights','all','delete');
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('infinite',...
            'type', 'infinite',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum);                
        thisR.set('lights',lgt,'add');
        % piWRS(thisR);

    case 'coordinate'
        thisR = piRecipeDefault('scene name',rName);
         
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('distant',...
            'from',[0 0 -5],...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum);
        thisR.set('lights',lgt,'add');

        % thisR.set('from',[0 0 0]);
        % thisR.set('to',[0 0 1]);
        % thisR.set('up',[0 1 0]);

        idx = piAssetSearch(thisR,'object name','origin');
        thisR.set('to',thisR.get('asset',idx,'world position'));
        warning('Not visible in HDR mode.')

    case 'flatsurface'
        % Some issues here.  Check piChartCreate for how to adjust.
        thisR = piRecipeDefault('scene name',rName);
        % piWRS(thisR);

        thisR.set('asset','Camera_B','delete');
        thisR.set('lights','all','delete');
        cubeID = piAssetSearch(thisR,'object name','Cube');

        % Delete all the branch nodes.  Nothing but root and the object.
        id = thisR.get('asset',cubeID,'path to root');
        fprintf('Geometry nodes:  %d\n',numel(id) - 1);
        for ii=3:numel(id)
            thisR.set('asset',id(ii),'delete');
        end
        cubeID = piAssetSearch(thisR,'object name','Cube');

        % thisR.show;

        % Aim the camera at the object and bring it closer.
        thisR.set('from',[0,0,0]);
        thisR.set('to',  [0,0,1]);
        thisR.set('up',  [0,1,0]);

        % We place the surface assuming the camera is at 0,0,0 and pointed in the
        % positive direction.  So we put the object 1 meter away from the camera.
        thisR.set('asset',cubeID,'world position',[0 0 1]);

        % We scale the surface size to be 1,1,0.1 meter.
        sz = thisR.get('asset',cubeID,'size');
        thisR.set('asset',cubeID,'scale', (1 ./ sz).*[1 1 0.1]);
        
    case 'flatsurfacewhitetexture'
        thisR = piRecipeDefault('scene name',rName);
        idx = piAssetSearch(thisR,'object name','Cube');
        thisR.set('to',thisR.get('asset',idx,'world position'));
        thisR.set('lights','all','delete');

        % Remove the '' (empty) texture.  We used to advice setting the
        % surface texture of the Cube.  But no longer.
        thisR.set('material','delete',1);

        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', lgt, 'add');
        idx = piAssetSearch(thisR,'object name','Cube');
        thisR.set('to',thisR.get('asset',idx,'world position'));

    case 'lettersatdepth'
        thisR = piRecipeDefault('scene name',rName);
    case 'materialball'
        thisR = piRecipeDefault('scene name',rName);
    case 'materialball_cloth'
        thisR = piRecipeDefault('scene name',rName);
    case {'slantededge','slantedbar'}
        rName = 'slantededge';
        thisR = piRecipeDefault('scene name',rName);
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum,...
            'cameracoordinate', true);
        thisR.set('light', lgt, 'add');

        idx = piAssetSearch(thisR,'object name','Plane');
        thisR.set('to',thisR.get('asset',idx,'world position'));
    case 'sphere'
        thisR = piRecipeDefault('scene name',rName);

        % Should we change to Unit sphere and a specific distance?
        sphere = piAssetSearch(thisR,'object name','Sphere');
        sz = thisR.get('asset',sphere,'size');
        thisR.set('asset',sphere,'scale',1./sz);        

        % Look at the sphere
        thisR.set('to',thisR.get('asset',sphere,'world position'));
        thisR.set('from',[0 0 -2]);

        % Get rid of the unused camera
        camera = piAssetSearch(thisR,'branch name','Camera');
        thisR.set('node',camera,'delete');

        % Set the light spectrum
        spectrumScale = 1;
        lightSpectrum = 'equalEnergy';
        lgt = piLightCreate('new distant',...
            'type', 'distant',...
            'specscale float', spectrumScale,...
            'spd spectrum', lightSpectrum);
        thisR.set('light', lgt, 'add');
    case 'stepfunction'
        thisR = piRecipeDefault('scene name',rName);
        warning('No assets.  Maybe use slanted edge.')
    case 'teapotset'
        thisR = piRecipeDefault('scene name',rName);
    case 'testplane'
        thisR = piRecipeDefault('scene name',rName);
        % Adjust the texture.
        warning('There is a bug with the textures for the testplane scene.')
    otherwise
        error('Unknown recipe name %s\n',rName);
end

end

