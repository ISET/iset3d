function [macbethRecipe] = piCreateMacbethChart(varargin)
% [macbethRecipe] = piCreateMacbethChart(varargin)
%
% Create an iset3d scene with a 6x4 Macbeth chart target.
% The target is flat, centered at the origin and aligned with 
% the xy plane, the camera is placed 10m away from the chart.
% The light source is placed in the same location, and points in the 
% same direction as the camera
%
% Input params (all optional)
%    width - the dimension of one Macbeth chart element along the x axis
%    (in meters, default 1)
%    height - the dimension of one Macbeth chart element along the y axis
%    (in meters, default 1)
%    depth - the dimension of one Macbeth chart element along the z axis
%    (in meters, default 1)
%    defaultLight - a booleand indicating whether or not to include the
%    light source (default true)
%    lightIntensity - a light intensity scaling parameter (default 1)
%
% Output
%    macbethRecipe - an iset3d scene recipe
%
% Henryk Blasinski, 2020
%
% Examples:
%{
thisR = piCreateMacbethChart;
piWrite(thisR, 'creatematerial', true);
[scene, ~] = piRender(thisR, 'render type', 'radiance');
sceneWindow(scene);
%}
p = inputParser;
p.addOptional('width',1);
p.addOptional('height',1);
p.addOptional('depth',1);
p.addOptional('defaultLight',true);
p.addOptional('lightIntensity',1,@isnumeric);
p.parse(varargin{:});
inputs = p.Results;


macbethRecipe = recipe();

camera = piCameraCreate('pinhole');
macbethRecipe.recipeSet('camera',camera);
macbethRecipe.set('fov',45);

macbethRecipe.film.type = 'Film';
macbethRecipe.film.subtype = 'gbuffer';
macbethRecipe.set('film resolution',[640 480]);

cameraFrom = [0 0 10];
cameraTo = [0 0 0];

macbethRecipe.set('from',cameraFrom);
macbethRecipe.set('to',cameraTo);
macbethRecipe.set('up',[0 1 0]);

macbethRecipe.set('samplersubtype','halton');
macbethRecipe.set('pixel samples',16);

macbethRecipe.set('integrator','volpath');
macbethRecipe.set('rendertype',{'radiance'});

macbethRecipe.exporter = 'PARSE';

%% Create a cube
dx = inputs.width/2;
dy = inputs.height/2;
dz = inputs.depth/2;

% Vertices of a cube
P = [ dx -dy  dz;
      dx -dy -dz;
      dx  dy -dz;
      dx  dy  dz;
     -dx -dy  dz;
     -dx -dy -dz;
     -dx  dy -dz;
     -dx  dy  dz;]';

% Faces of a cube
indices = [4 0 3 
           4 3 7 
           0 1 2 
           0 2 3 
           1 5 6 
           1 6 2 
           5 4 7 
           5 7 6 
           7 3 2 
           7 2 6 
           0 5 1 
           0 4 5]'; 

cubeShape = piAssetCreate('type','trianglemesh');       
cubeShape.integerindices = indices(:)'; 
cubeShape.point3p = P(:);

macbethChart = piAssetCreate('type','branch');
macbethChart.name = 'MacbethChart';
macbethChart.size.l = 6 * inputs.width;
macbethChart.size.h = 4 * inputs.height;
macbethChart.size.w = inputs.depth;
macbethChart.size.pmin = [-dx; -dy; -dz];
macbethChart.size.pmax = [dx; dy; dz];

rootNodeID = piAssetAdd(macbethRecipe, 0, macbethChart);

wave = 400:10:700;
macbethSpectra = ieReadSpectra(which('macbethChart.mat'),wave);

for x=1:6
    for y=1:4
        
        cubeID = (x-1)*4 + y;
        
        xOffset = -(x - 3 - 1)*inputs.width - inputs.width/2;
        yOffset = -(y - 2 - 1)*inputs.height - inputs.height/2;

        
        macbethCubeBranch = piAssetCreate('type','branch');
        macbethCubeBranch.name = sprintf('Cube_%02i_B',cubeID);
        macbethCubeBranch.size.l = inputs.width;
        macbethCubeBranch.size.h = inputs.height;
        macbethCubeBranch.size.w = inputs.depth;
        macbethCubeBranch.size.pmin = [-dx; -dy; -dz];
        macbethCubeBranch.size.pmax = [dx; dy; dz];
        macbethCubeBranch.translation = {[xOffset; yOffset; 0]};
        cubeNodeID = piAssetAdd(macbethRecipe, rootNodeID, macbethCubeBranch);
        
        macbethCube = piAssetCreate('type','object');
        macbethCube.name = sprintf('Cube_%02i',cubeID);
        macbethCube.type = 'object';
        macbethCube.material{1}.namedmaterial = sprintf('Cube_%02i_material',cubeID);
        macbethCube.shape{1} = cubeShape;
        macbethCube.mediumInterface = []; 
        piAssetAdd(macbethRecipe, cubeNodeID, macbethCube);
        
        currentMaterial = piMaterialCreate(sprintf('Cube_%02i_material',cubeID),...
            'type','diffuse','reflectance',piSPDCreate(wave, macbethSpectra(:,cubeID)));
        
        macbethRecipe.set('material','add',currentMaterial);
                 
    end
end

if inputs.defaultLight

    wave = 300:5:800;
    spd = ones(numel(wave),1);
    
    val.value = piSPDCreate(wave, spd);
    val.type  = 'spectrum';
    
    light = piLightCreate('light','type','distant');
    light = piLightSet(light,'from',cameraFrom);
    light = piLightSet(light,'to',cameraTo);
    light = piLightSet(light,'spd',val);
    light = piLightSet(light,'cameracoordinate',0);
    light = piLightSet(light,'specscale',inputs.lightIntensity);
    macbethRecipe.set('light',light,'add');
   
end

outputName = 'MacbethChart';

macbethRecipe.set('outputfile',fullfile(piRootPath,'local','MacbethChart',sprintf('%s.pbrt',outputName)));
macbethRecipe.world = {'WorldBegin'};


end

