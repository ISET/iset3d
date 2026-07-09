%% piTextureFiles

%{
scene = sceneCreate('slanted bar',1024);
rgb = sceneGet(scene,'rgb');
textureFile = fullfile(piRootPath,'data','imageTextures','slantedbar.png');
imwrite(rgb,textureFile);
%}

%{
scene = sceneCreate('rings rays',8,1024);
rgb = sceneGet(scene,'rgb');
textureFile = fullfile(piRootPath,'data','imageTextures','ringsrays.png');
imwrite(rgb,textureFile);
%}

%{
scene = sceneCreate('grid lines',1024,128,'ee',10);
rgb = sceneGet(scene,'rgb');
textureFile = fullfile(piRootPath,'data','imageTextures','gridlines.png');
imwrite(rgb,textureFile);
%}

%{
scene = sceneCreate('point array',512,64);
rgb = sceneGet(scene,'rgb');
textureFile = fullfile(piRootPath,'data','imageTextures','pointArray_512_64.png');
imwrite(rgb,textureFile);
%}

%{
scene = sceneCreate('point array',1024,64);
rgb = sceneGet(scene,'rgb');
textureFile = fullfile(piRootPath,'data','imageTextures','pointArray_1024_64.png');
imwrite(rgb,textureFile);
%}

%{
scene = sceneCreate('point array',1024,64);
rgb = sceneGet(scene,'rgb');
textureFile = fullfile(piRootPath,'data','imageTextures','pointArray_1024_64.png');
imwrite(rgb,textureFile);
%}

%{
f = 1;
x = linspace(0,f*(2*pi) - 1/1024,1024);
rgb(:,:,1) = repmat(square(x),1024,1);
rgb(:,:,2) = rgb(:,:,1); rgb(:,:,3) = rgb(:,:,1);
textureFile = fullfile(piDirGet('textures'),sprintf('squarewave_v_%02d.png',f));
imwrite(rgb,textureFile);
rgb = imageTranspose(rgb);
textureFile = fullfile(piDirGet('textures'),sprintf('squarewave_h_%02d.png',f));
imwrite(rgb,textureFile);
%}