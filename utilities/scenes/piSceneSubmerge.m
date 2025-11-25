function [ submerged]  = piSceneSubmerge(thisR, medium, varargin)
% Add participating media to a recipe
%
% Synopsis
%   [submerged] = piSceneSubmerge(thisR, medium, varargin)
%
% Brief 
%   Take the recipe and immerse it in the medium. The medium occupies a
%   homogenous region in space (a cube), centered at the origin. The size
%   and the cube offset can be adjusted. 
%
% Inputs
%   thisR
%   medium - definition of the medium
%
% Optional key/val
%   sizeX, sizeY, sizeZ
%   offsetX, offsetY, offsetZ
%   surface, can specify the shape of the top surface of the water volume,
%   for example to model waves.
%
% Henryk Blasinski, 2023

%%
p = inputParser;
p.addOptional('sizeX', 1, @isnumeric);
p.addOptional('sizeY', 1, @isnumeric);
p.addOptional('sizeZ', 1, @isnumeric);
p.addOptional('offsetX', 0, @isnumeric);
p.addOptional('offsetY', 0, @isnumeric);
p.addOptional('offsetZ', 0, @isnumeric);
p.addOptional('volume', true, @islogical);
p.addOptional('surface', true, @islogical);

p.parse(varargin{:});
inputs = p.Results;

%%

submerged = copy(thisR);


sceneObjects = thisR.assets.getchildren(1);
for i=sceneObjects
    submerged.recipeSet('node',i, 'translate',[inputs.offsetX inputs.offsetY inputs.offsetZ]);
end
submerged.recipeSet('to', submerged.recipeGet('to') + [inputs.offsetX inputs.offsetY inputs.offsetZ]);


submerged.set('integrator','volpath');

dx = inputs.sizeX/2;
dy = inputs.sizeY/2;
dz = inputs.sizeZ/2;

submerged.set('medium', 'add', medium);


surfaceShape = repmat(sin(linspace(0,10,100))',[1 100])*0.5;

if inputs.volume
    waterBodyMesh = generateCube(inputs.sizeX, inputs.sizeY, inputs.sizeZ, ...
                                'topSurface', surfaceShape, 'wallsNS', true, 'wallsEW', true);

    water = piAssetCreate('type','branch');
    water.name = 'Water';
    water.size.l = inputs.sizeX;
    water.size.h = inputs.sizeY;
    water.size.w = inputs.sizeZ;
    water.size.pmin = [-dx; -dy; -dz];
    water.size.pmax = [dx; dy; dz];
    water.translation = {[inputs.offsetX; inputs.offsetY; inputs.offsetZ]};
    waterID = piAssetAdd(submerged, 1, water);

    waterMaterial = piMaterialCreate('WaterInterface','type','interface');

    % This step loses the container maps
    submerged.set('material','add',waterMaterial);

    waterCube = piAssetCreate('type','object');
    waterCube.name = 'WaterMesh';
    waterCube.mediumInterface.inside = medium.name;
    waterCube.mediumInterface.outside = [];
    waterCube.material.namedmaterial = 'WaterInterface';
    waterCube.shape = waterBodyMesh;

    piAssetAdd(submerged, waterID, waterCube);
end
    
if inputs.surface
    waterSurfaceMesh = generateCube(inputs.sizeX, inputs.sizeY, inputs.sizeZ, 'topSurface', surfaceShape + 0.0001, ...
        'bottom', false, 'wallsNS',false, 'wallsEW',false);
    waterSurfaceMaterial = piMaterialCreate('WaterSurface','type','dielectric','eta',1.33);

    submerged.set('material','add', waterSurfaceMaterial);


    waterSurface = piAssetCreate('type','branch');
    waterSurface.name = 'WaterSurface';
    waterSurface.size.l = inputs.sizeX;
    waterSurface.size.h = inputs.sizeY;
    waterSurface.size.w = inputs.sizeZ;
    waterSurface.size.pmin = [-dx; -dy; -dz];
    waterSurface.size.pmax = [dx; dy; dz];
    waterSurface.translation = {[inputs.offsetX; inputs.offsetY; inputs.offsetZ]};
    waterSurfaceID = piAssetAdd(submerged, 1, waterSurface);


    waterSurfaceObj = piAssetCreate('type','object');
    waterSurfaceObj.name = 'WaterSurfaceMesh';
    waterSurfaceObj.material.namedmaterial = 'WaterSurface';
    waterSurfaceObj.shape = waterSurfaceMesh;

    piAssetAdd(submerged, waterSurfaceID, waterSurfaceObj);
end


% Submerge the camera if needed
xstart = -dx + inputs.offsetX;
xend = dx + inputs.offsetX;

ystart = -dy + inputs.offsetY;
yend = dy + inputs.offsetY;

zstart = -dz + inputs.offsetZ;
zend = dz + inputs.offsetZ;

camPos = submerged.get('from');

if (xstart <= camPos(1) && camPos(1) <= xend) && ...
        (ystart <= camPos(2) && camPos(2) <= yend) && ...
        (zstart <= camPos(3) && camPos(3) <= zend)

    submerged.camera.medium = medium.name;

end

    
    
end