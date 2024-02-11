% t_radianceIrradiance - Method for determining Irradiance from
%                        measured radiance off the surface
%
% We want to put metal spheres into the scene.
%    
% See also
%   t_materials.m, tls_materials.mlx, t_assets, t_piIntro*,
%   piMaterialCreate.m
%

% With the recipes, it seems there are issues with whether we are
% editing the data or pointers and whether the changes we make persist
% ... something like that.
%

%% Initialize
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create recipe of the sphere with a spot light

sphereR = piRecipeCreate('Sphere');
from = sphereR.get('from');
to   = sphereR.get('to');

% Big light in the from to direction
lgt = piLightCreate('distant','type','distant', ...
    'from',from, ...
    'to',to);
sphereR.set('lights',lgt,'add');

piWRS(sphereR,'name','diffuse','mean luminance', -1,'render flag','rgb'); % works

%% Load the asset

EIA = piAssetLoad('eia');
EIA.thisR.set('from',from);
EIA.thisR.set('to',to);
piAssetShow(EIA.thisR);

%% Test viewing them immediately after merge

% Notice the hdr render because the room is bright
mergedR = piRecipeMerge(sphereR,EIA.thisR,'object instance', false);
mergedR.set('skymap','room.exr');
piWRS(mergedR,'render flag','hdr');

%% Delete the sphere, reveal the chart

sphereID = piAssetSearch(mergedR,'object name','Sphere');
mergedR.set('asset',sphereID,'delete');
piWRS(mergedR,'render flag','hdr');

%% Move the chart behind the sphere

% Build it again
mergedR = piRecipeMerge(sphereR,EIA.thisR,'object instance', false);
mergedR.set('skymap','room.exr');

sphereID = piAssetSearch(mergedR,'object name','Sphere');
eiaID    = piAssetSearch(mergedR,'object name','eiachart');
wp    = mergedR.get('asset',sphereID,'world position');
mergedR.set('asset',eiaID,'world position',wp + [0 0 2]);
piWRS(mergedR,'render flag','hdr');

%%
% eiaID    = piAssetSearch(mergedR,'object name','eiachart');
% mergedR.set('asset',eiaID,'scale',4);
% piWRS(mergedR,'render flag','hdr');

%%
% Move the chart behind the sphere.  It seems invisible.  
mergedR.set('asset',sphereID,'world position',[0 0 0]);
mergedR.set('asset',eiaID,'world position',[0 0 5]);
mergedR.set('to',[0 0 0]);
mergedR.set('from',[0 0 -1]);

lgt = piLightCreate('distant','type','distant');
mergedR.set('lights','all','delete');
mergedR.set('lights',lgt,'add');

piAssetGeometry(mergedR);
piWRS(mergedR);

mergedR.set('asset',eiaID,'delete');

%%
%{
bunnyID = piAssetSearch(mergedR,'object name','Bunny');
lgt = piLightCreate('point','type','point');
bunny.thisR.set('lights',lgt,'add');
piWRS(bunny.thisR);
%}

% piAssetGeometry(bunny.thisR);

%%

% Scale the macbeth to make it thin enough and position behind the sphere
bunnyID = piAssetSearch(mergedR,'object name','Bunny');
sphereR.set('assets',bunnyID,'scale',[15 15 15]);
mergedR.get('assets',bunnyID,'world position');
mergedR.set('assets',bunnyID,'world position',[0 -2 3]);
mergedR.get('assets',bunnyID,'world position')
mergedR.get('assets',bunnyID,'size')

sphereID = piAssetSearch(mergedR,'object name','Sphere');
mergedR.set('assets',sphereID,'scale',[.2 .2 .2]);

sphereR.show('objects');

%%
piWRS(mergedR,'name','sphere-bunny');

% thisR.set('skymap','room.exr');
% piWRS(mergedR,'name','sphere-macbeth');

% useMaterial = 'metal-ag';
% useMaterial = 'chrome';
% useMaterial = 'glass';
% useMaterial = 'glossy-red';  % This one works.
% 
% % Insert material and assign it to the sphere
% piMaterialsInsert(mergedR,'name',useMaterial);  
% mergedR.set('asset', sphereID, 'material name', useMaterial);
% piWRS(mergedR,'name','sphere-macbeth');

useMaterial = 'metal-ag';
piMaterialsInsert(mergedR,'name',useMaterial);  
sphereR.set('asset', sphereID, 'material name', useMaterial);
piWRS(mergedR,'name','sphere-macbeth');

mergedR.set('asset',sphereID,'translate',[0.5 0 0]);
piWRS(mergedR,'name','sphere-macbeth');

mergedR.set('skymap','room.exr');
piWRS(mergedR,'name','sphere-macbeth');

mergedR   = piMaterialsInsert(mergedR,'names','checkerboard');
mergedR.set('asset',bunnyID,'material name','checkerboard');
piWRS(mergedR,'name','sphere-macbeth');



% thisR.set('outputfile',something good);
%
% piWRS(macbeth.thisR);
lensname = 'dgauss.22deg.12.5mm.json';
lensname = 'wide.77deg.4.38mm.json';
c = piCameraCreate('omni','lens file',lensname);
mergedR.set('camera',c);
mergedR.set('film diagonal',10,'mm');

piWRS(mergedR,'name','sphere-macbeth');

%% Now try to get a reflective material working

% useMaterial = 'mirror';    % fails
useMaterial = 'glossy-red';  % This one works.

% useMaterial = 'metal-ag';
% useMaterial = 'chrome';
% useMaterial = 'glass';

% Insert material and assign it to the sphere
piMaterialsInsert(sphereR,'name',useMaterial);  
sphereR.set('asset', sphereID, 'material name', useMaterial);

% Render
piWRS(sphereR,'name',useMaterial,'mean luminance', -1); 

%% Optionally add a skymap as a test
% since it seems to light everything
fileName = 'room.exr';
%thisR.set('skymap',fileName); % works

%{ 
% here is a light that sort of works, hand-coded for now
AttributeBegin
  AreaLightSource "diffuse" "blackbody L" [ 6500 ] "float power" [ 100 ]
  Translate 0 10 0
  Shape "sphere" "float radius" [ 20 ]
AttributeEnd
%}

% create a test area light (create doesn't like shape?)
lightTest = piLightCreate('lightTest','type','area', ...
    'radius',20, 'specscale',1, 'rgb spd',[1 1 1], ...
    'cameracoordinate',true);

% This doesn't work as coded, not sure how to set shape to sphere
%so now try to set the shape -- But this doesn't work
%lightTest = piLightSet(lightTest,'shape','sphere');

sphereR.set('light',lightTest,'add');
piWRS(sphereR,'name', useMaterial, 'mean luminance',-1);

%% Now add a headlamp
% Currently this illuminates diffuse surfaces, but doesn't seem to have
% any measurable impact on reflective or dielectric objects
% NB Requires ISETAuto for headlamp
forwardHeadLight = headlamp('preset','level beam', 'name','forward'); 
forwardLight = forwardHeadLight.getLight(); % get actual light

sphereR.set('lights',forwardLight,'add');

% Move the headlamp closer to the spheres
fLight = piAssetSearch(sphereR,'light name','forward');
sphereR.set('asset',fLight,'translate',[0 0 300]);
piWRS(sphereR,'name', 'headlamp', 'mean luminance',-1);

%% Try adding a second sphere
% Off to the right of the first one, also scaled down
sphere2 = piAssetLoad('sphere');
assetSphere2 = piAssetSearch(sphere2.thisR,'object name','Sphere');
piAssetTranslate(sphere2.thisR,assetSphere2,[-100 0 00]);
piAssetScale(sphere2.thisR,assetSphere2,[.5 .5 .5]);

sphereR = piRecipeMerge(sphereR,sphere2.thisR, 'node name',sphere2.mergeNode,'object instance', false);
piWRS(sphereR,'name','second sphere', 'mean luminance', -1);

%% Try aiming a light straight at us
% spot & point & area & headlamp don't seem to work
reverseHeadLight = headlamp('preset','level beam', 'name','reverse'); 
reverseLight = reverseHeadLight.getLight(); % get actual light
sphereR.set('lights',reverseLight,'add');

% Move it out from the camera and rotate it to look back
rLight = piAssetSearch(sphereR,'light name','reverse');
sphereR.set('asset',rLight,'translate',[0 0 160]);

% Note: We can see te effect of the headlamp on the spheres if we leave it
% pointed in the direction of the camera. But if we rotate it 180, we don't
% see any evidence of it. ...
sphereR.set('asset',rLight,'rotate',[0 180 0]);

% With reverse light
piWRS(sphereR,'name','reverse light', 'mean luminance', -1);

% Make both spheres reflective
sphereIndices = piAssetSearch(sphereR,'object name','sphere');
for ii = 1:numel(sphereIndices)
    sphereR.set('asset', sphereIndices(ii), 'material name', useMaterial);
end
piWRS(sphereR,'name','two reflective spheres', 'mean luminance', -1);

% Try without the sphere
sphereR.set('asset', sphereID, 'delete');
piWRS(sphereR,'name','no primary sphere', 'mean luminance', -1);
