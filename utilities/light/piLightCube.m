function params = piLightCube(thisR,varargin)
% Add a cube of area lights to the recipe
%
% Synopsis
%    thisR = piLightCube(thisR,varargin);
%
% Brief description
%  Each side of the cube of area lights has a different color.  If you
%  place the lights in the scene near an object, the color of the
%  illuminant on the object informs you about the area light rotation
%  required to aim the area light at an object.
%
%  By default, the cube is created at a small distance from the camera
%  position.
%
%  The lights are specified as RGB (red,green; blue, yellow; cyan,
%  magenta).
%
% Inputs
%  thisR - Main recipe
%
% Optional key/val pairs
%
%  spd scale   - Spectral intensity scale of the light
%  spread      - Angular spread of the light
%  twosided    - Illuminate from both sides of the area light
%  shape scale - Scale the size (shape) of the area light
%  translate   - Translation of the cube from the camera position
% 
%  keep - Keep existing lights in the recipe (false)
%  show - Plot the positions and fromto
%
% Outputs
%   params - p.Results
%
% See also
%   oraleye:  oeLight
%   iset3d:   t_arealight*, t_lightCube

% TODO:  Check for duplicate light names.  We want to be able to run this
% routine twice on the same recipe with different translations.

% Examples:
%{
thisR = piRecipeCreate('flat surface');
cubeID = piAssetSearch(thisR,'object name','Cube');

piMaterialsInsert(thisR,'names',{'mirror','diffuse-white','marble-beige','wood-mahogany'});
thisR.set('asset',cubeID,'material name', 'diffuse-white');
thisR.set('skymap','room.exr');
piLightCube(thisR,'shape scale',0.1,'translate',[0.2 0.2 0]);
thisR.set('skymap','room.exr');

% We can see the reflected light.  
piWRS(thisR);

% Its color tells us the rotation of the plane of the area light that
will aim at the surface.
piLightCube('help');

% Look at the cube from above
cameraP = thisR.get('camera position');
planeP  = thisR.get('asset','Cube_O','world position');
thisR.set('from',[-3 -3 -3]); thisR.set('to',cameraP);
piWRS(thisR,'render flag','hdr');
%}

%{
% Make this work!  It works as part of the piLightCreate, but not via
% this set
% thisR.set('light',lights{ii},'spd',cubeRGB(:,ii));
%}


%% Parse parameters

% Help
if ischar(thisR) && isequal(thisR,'help')
    cubeRot = [0 -90 0; 0 90 0; 90 180 0; -90 -180 0; 0 180 -90; 180 -180 0]';
    colorNames = {'red    ','green  ','yellow ','blue   ','magenta','cyan   '};
    for ii=1:size(colorNames,2)
        fprintf('%s - [%d,%d,%d]\n',colorNames{ii},cubeRot(:,ii)');
    end
    return;
end

%%
varargin = ieParamFormat(varargin);

p = inputParser;

p.addRequired('thisR',@(x)(isa(x,'recipe')));

p.addParameter('spdscale',1,@isnumeric);       % SPD scale
p.addParameter('spread',30,@isnumeric);        % Angular (deg) spread
p.addParameter('twosided',false,@islogical);   % One or two sides
p.addParameter('shapescale',0.2,@isnumeric);   % Size of the light
p.addParameter('translate',[0.3 0.3 0],@isnumeric);   % Translate cube away from 'from'

p.addParameter('show',false,@islogical);
p.addParameter('keep',false,@islogical);   % Keep existing lights

p.parse(thisR,varargin{:});

spdScale   = p.Results.spdscale;
spread     = p.Results.spread;
twosided   = p.Results.twosided;
shapeScale = p.Results.shapescale;
translate  = p.Results.translate;

keep = p.Results.keep;
show = p.Results.show;

%% Calculate area light positions

cubePos = [1 0 0; -1 0 0; 0 1 0; 0 -1 0; 0 0 1; 0 0 -1]';

% With these rotations, all the lights are pointing at the plane at 0,0,1
% cubeRot = [0 180 0; 0 180 0; 0 180 0; 0 -180 0; 0 180 -90; 0 180 -90]';

% Adjusting to outward facing
cubeRot = [0 -90 0; 0 90 0; 90 180 0; -90 -180 0; 0 180 -90; 180 -180 0]';

cubeRGB = [1 0 0; 0 1 0; 1 1 0; 0 0 1; 1 0 1; 0 1 1]';
nCubes = size(cubePos,2);

cubePos = cubePos*shapeScale;

% Center the cube on the camera position plus a translation away.
from    = thisR.get('from');
cubePos = cubePos + translate(:) + from(:);

%%
if ~keep, thisR.set('lights','all','delete'); end

%% 
lights = cell(nCubes,1);
for ii=1:nCubes

    lights{ii} = piLightCreate(sprintf('cubelight-%d',ii),...
        'type','area',...
        'spd',cubeRGB(:,ii), ...
        'twosided',twosided,...
        'specscale',spdScale);

    thisR.set('light',lights{ii},'add');
    thisR.set('light',lights{ii},'world position',cubePos(:,ii));
    thisR.set('light',lights{ii},'shape scale',shapeScale);
    thisR.set('light',lights{ii},'rotate',cubeRot(:,ii)');   
    thisR.set('light',lights{ii},'spread',spread);      % 
end


%%
if show
    piAssetGeometry(thisR);
end

params = p.Results;

end
