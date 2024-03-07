function [chartR, gName, oName]  = piChartCreate(chartName)
% Create a small calibration chart to insert in another scene
%
% Synopsis
%  [chartR, sName] = piChartCreate(chartName)
%
% Describe
%   Used by s_assetsRecipe to create a recipe we later merge with other
%   recipes.
%
% Input
%   chartName - 'EIA','rings rays','slanted bar','grid lines',
%               'face','macbeth'
%
% Output
%   chartR  - Recipe for the chart
%   gName   - Geometry node name
%   oName   - Object node name
%
% See also
%  s_assetsRecipe, piRecipeMerge

% Examples:
%{
thisChart = piChartCreate('EIA');
piWRS(thisChart);
%}
%{
thisChart = piChartCreate('ringsrays');
piWRS(thisChart);
%}
%{
thisChart = piChartCreate('slanted bar');
piWRS(thisChart);
%}
%{
thisChart = piChartCreate('grid lines');
piWRS(thisChart);
%}
%{
thisChart = piChartCreate('face');
piWRS(thisChart);
%}
%{
thisChart = piChartCreate('macbeth');
piWRS(thisChart);
%}

%% Make the flat surface recipe.

% This can get simpler once we get piWrite/piRead working with ZLY

chartR = piRecipeCreate('flatsurface');

%%  Add the chart you want

uniqueKey = randi(1e4,1);

switch ieParamFormat(chartName)
    case 'eia'        
        textureName = sprintf('EIAChart-%d',uniqueKey);
        imgFile   = 'EIA1956-300dpi-center.png';
        
    case 'slantedbar'        
        textureName = sprintf('slantedbar-%d',uniqueKey);
        imgFile   = 'slantedbar.png';
        
    case 'ringsrays'
        textureName = sprintf('ringsrays-%d',uniqueKey);
        imgFile   = 'ringsrays.png';
        
    case 'gridlines'
        textureName = sprintf('gridlines-%d',uniqueKey);
        imgFile = 'gridlines.png';
        
    case 'macbeth'
        % This has the macbeth as an image (texture). There is a separate
        % script (s_assetMCCCBCreate) that includes the true spectral data.
        % That one is used for the Cornell Box project.
        textureName = sprintf('macbeth-%d',uniqueKey);
        imgFile = 'macbeth.png';
        
    case 'face'
        textureName = sprintf('face-%d',uniqueKey);
        imgFile = 'monochromeFace.png';
        
    case 'pointarray_512_64'
        textureName = sprintf('pointarray_512_64-%d',uniqueKey);
        imgFile = 'pointArray_512_64.png';
        
    otherwise
        error('Unknown chart name %s\n',chartName);
end

%% Make a chart material and texture

% Create a new material and add it to the recipe
surfaceMaterial = piMaterialCreate(textureName,'type','diffuse');
chartR.set('material','add',surfaceMaterial);

% Create a new texture and add it to the recipe
chartTexture = piTextureCreate(textureName,...
    'format', 'spectrum',...
    'type', 'imagemap',...
    'filename', fullfile('textures',imgFile));
chartR.set('texture', 'add', chartTexture);

% Specify the texture as part of the material
chartR.set('material', surfaceMaterial.name, 'reflectance val', textureName);

% chartR.get('material print');
% chartR.show('objects');

%% Name the object and geometry node
cubeID = piAssetSearch(chartR,'object name','Cube');
oName = sprintf('%s_O',textureName);
chartR.set('asset',cubeID,'name',oName);

% Specify the chart as having this material
chartR.set('asset',oName,'material name',surfaceMaterial.name);

parent = chartR.get('asset parent id',oName); 
gName = sprintf('%s_B',textureName);
chartR.set('asset',parent,'name',gName);

switch oName(1:7)
    case 'macbeth'
        % Adjust aspect ratio x,y,z
        chartR.set('asset',cubeID,'scale',[1 0.67 1]);
    otherwise
end

%% Copy the texture file to the output dir

textureFile = fullfile(piDirGet('texture'),imgFile);
outputdir = chartR.get('output dir');
if ~exist(textureFile,'file'), error('No texture file!'); end
if ~exist(outputdir,'dir'), fprintf('Making output dir %s',outputdir); mkdir(outputdir); end
copyfile(textureFile,outputdir);

end

