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
%
% Henryk Blasinski, 2023

%%
p = inputParser;
p.addOptional('sizeX',1,@isnumeric);
p.addOptional('sizeY',1,@isnumeric);
p.addOptional('sizeZ',1,@isnumeric);
p.addOptional('offsetX',0, @isnumeric);
p.addOptional('offsetY',0, @isnumeric);
p.addOptional('offsetZ',0, @isnumeric);

p.parse(varargin{:});
inputs = p.Results;

%%

submerged = copy(thisR);
submerged.set('integrator','volpath');

dx = inputs.sizeX/2;
dy = inputs.sizeY/2;
dz = inputs.sizeZ/2;


% Vertices of the cube
P = [ dx -dy  dz;
    dx -dy -dz;
    dx  dy -dz;
    dx  dy  dz;
    -dx -dy  dz;
    -dx -dy -dz;
    -dx  dy -dz;
    -dx  dy  dz;]';

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

%{
figure;
hold on; grid on; box on;
for i=1:size(indices,1)
    face = P(indices(i,:) + 1,:);
    face = cat(1,face,face(1,:));
   
    plot3(face(:,1),face(:,2),face(:,3),'lineWidth',2);
end

for p=1:size(P,1)
    text(P(p,1),P(p,2),P(p,3),sprintf('%i',p-1), 'fontsize',20);
end
            xlabel('x');
            ylabel('y');
            zlabel('z');
    %}
    
waterCubeMesh = piAssetCreate('type','trianglemesh');
waterCubeMesh.integerindices = indices(:)';
waterCubeMesh.point3p = P(:);


water = piAssetCreate('type','branch');
water.name = 'Water';
water.size.l = inputs.sizeX;
water.size.h = inputs.sizeY;
water.size.w = inputs.sizeZ;
water.size.pmin = [-dx; -dy; -dz];
water.size.pmax = [dx; dy; dz];
water.position = [inputs.offsetX; inputs.offsetY; inputs.offsetZ];

waterID = piAssetAdd(submerged, 1, water);

waterMaterial = piMaterialCreate('WaterInterface','type','interface');

% This step loses the container maps
submerged.set('material','add',waterMaterial);

waterCube = piAssetCreate('type','object');
waterCube.name = 'WaterMesh';
waterCube.mediumInterface.inside = medium.name;
waterCube.mediumInterface.outside = [];
waterCube.material.namedmaterial = 'WaterInterface';
waterCube.shape = waterCubeMesh;

piAssetAdd(submerged, waterID, waterCube);
submerged.set('medium', 'add', medium);

    
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