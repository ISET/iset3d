function [siemensRecipe] = piCreateSiemensStar(varargin)
% [siemensRecipe] = piCreateSiemensStar(varargin)
%
% Create an iset3d scene with a Siemens Start test target.
% The Siemens star is a collection of interleaved disk sections
% with high and low reflectance. The target is used for sharpening testing.
%
% Input params (all optional)
%    radius - radius of the disk
%    numSections - number of dark sections.
%    darkReflectance - the reflectance of dark portions of the chart.
%    brightReflectance - the reflectance of bright portions of the chart.
%    defaultLight - whether or not to add light source to the scene. 
%
% Output
%    siemensRecipe - an iset3d scene recipe
%
% Henryk Blasinski, 2025
%
% Examples:
%{
thisR = piCreateSiemensStar;
piWrite(thisR, 'creatematerial', true);
[scene, ~] = piRender(thisR, 'render type', 'radiance');
sceneWindow(scene);
%}

p = inputParser;
p.addOptional('radius',1);
p.addOptional('numSections',10);
p.addOptional('darkReflectance', 0.1);
p.addOptional('brightReflectance', 0.9);
p.addOptional('defaultLight',true);
p.addOptional('lightIntensity',1,@isnumeric);
p.parse(varargin{:});
inputs = p.Results;


siemensRecipe = recipe();

camera = piCameraCreate('pinhole');
siemensRecipe.recipeSet('camera',camera);
siemensRecipe.set('fov',45);

siemensRecipe.film.type = 'Film';
siemensRecipe.film.subtype = 'gbuffer';
siemensRecipe.set('film resolution',[640 480]);

cameraFrom = [0 0 10];
cameraTo = [0 0 0];

siemensRecipe.set('from',cameraFrom);
siemensRecipe.set('to',cameraTo);
siemensRecipe.set('up',[0 1 0]);

siemensRecipe.set('samplersubtype','halton');
siemensRecipe.set('pixel samples',16);

siemensRecipe.set('integrator','volpath');
siemensRecipe.set('rendertype',{'radiance'});

siemensRecipe.exporter = 'PARSE';


% Create a gray background

P = [-1 1 0;
      1 1 0;
      1 -1 0;
     -1 -1 0]';
P = P * 10;

% Single face a cube
indices = [0 1 3;
           3 1 2]'; 

backgroundShape = piAssetCreate('type','trianglemesh');       
backgroundShape.integerindices = indices(:)'; 
backgroundShape.point3p = P(:);

SiemensStar = piAssetCreate('type','branch');
SiemensStar.name = 'Backround';

rootNodeID = piAssetAdd(siemensRecipe, 0, SiemensStar);


Background = piAssetCreate('type','object');
Background.name = sprintf('Background');
Background.material{1}.namedmaterial = sprintf('mBackground');
Background.shape{1} = backgroundShape;

piAssetAdd(siemensRecipe, rootNodeID, Background);


wave = 400:10:700;
mBackground = piMaterialCreate('mBackground',...
    'type','diffuse','reflectance',piSPDCreate(wave, ones(size(wave)) * inputs.brightReflectance));
mDisk = piMaterialCreate('mDisk',...
    'type','diffuse','reflectance',piSPDCreate(wave, ones(size(wave)) * inputs.darkReflectance));

siemensRecipe.set('material','add', mBackground);
siemensRecipe.set('material','add', mDisk);


angle = 360 / (inputs.numSections * 2);


section = piAssetCreate('type','disk');
section.radius = inputs.radius;
section.height = 0.1;
section.phimax = angle;


for i=1:2:(inputs.numSections * 2)

    sectionBranch = piAssetCreate('type','branch');
    sectionBranch.name = sprintf('Section_%i_B',i);
    sectionBranch.rotation = {piRotationMatrix('zrot',(i-1)*angle)};
    sectionBranchID = piAssetAdd(siemensRecipe, rootNodeID, sectionBranch);


    Disk = piAssetCreate('type','object');
    Disk.name = sprintf('Section_%i',i);
    Disk.material{1}.namedmaterial = sprintf('mDisk');
    Disk.shape{1} = section;
    
    piAssetAdd(siemensRecipe, sectionBranchID, Disk);

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
    siemensRecipe.set('light',light,'add');
   
end

outputName = 'SiemensStar';

siemensRecipe.set('outputfile',fullfile(piRootPath,'local','SiemensStar',sprintf('%s.pbrt',outputName)));
siemensRecipe.world = {'WorldBegin'};


end

