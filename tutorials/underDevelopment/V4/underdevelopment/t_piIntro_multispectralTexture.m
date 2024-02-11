%% Render scenes with multispectral texture
%% -------------------Caputure a multispectral scene------------------------
ieInit;
piDockerConfig;
%%
thisR = piRecipeDefault('scene name','MacBethChecker');
%%
thisR.set('film resolution',[500,500]);
thisR.set('pixel samples',16);
thisR.set('fov',40);
thisR.integrator.subtype = 'path';  
thisR.set('film render type',{'radiance','depth'});
%%
thisR.set('lights','all','delete');
newDistant = piLightCreate('new distant',...
                           'type', 'distant',...
                           'spd','d65',...
                           'cameracoordinate', true);
thisR.set('light', 'add', newDistant);
%%
scene = piWRS(thisR);

chartArea = round([19.0567 78.3351 461.8557 329.8969]);
scene = sceneCrop(scene, chartArea);
energyScene = sceneGet(scene, 'energy');
%% -------------Caputure illuminnace-----------------

thisR.set('film render type',{'illuminance'});
%% maybe we can handle this case better --zhenyi
scene_illum = piWRS(thisR.metadata.illuminanceRecipe);
scene_illum = sceneCrop(scene_illum, chartArea);

energyIllum = sceneGet(scene_illum, 'energy');

%% Get multispectral Texture (reflectance)
[w,h,c] = size(energyScene);
tex = zeros(w,h,c);
for rr = 1:w
    for cc = 1:h
        tex(rr,cc,:) = energyScene(rr,cc,:)./energyIllum(rr,cc,:);
        if isnan(tex(rr,cc,:))
            tex(rr,cc,:) = zeros(1,1,c);
        end
    end
end
%% create basis from multispectral texture
nBasis = 6;
[~, imgBasis, coef] = hcBasis(tex, nBasis);
offset = floor(min(coef(:)));

if offset<0
    offset = -offset;
else
    offset = 0;
end

% give coef an offset because pbrt will clip negative values to zero.
% get offset value
coef_offset = coef + offset;

[c_size,~] = size(imgBasis);
for ii = 1:6
    channelNames{ii} = sprintf('coef.%d',ii);
    channelData{ii}  = coef_offset(:,:,ii);
    outBasis(ii).basis = imgBasis(:,ii);
    outBasis(ii).offset = ones(c_size,1)*offset;
end
%% Use this texture in a different scene

fbxFile   = fullfile(piRootPath,'data','V4','testplane','testplane.fbx');
% convert fbx to pbrt
pbrtFile = piFBX2PBRT(fbxFile);
% format this file 
infile = piPBRTReformat(pbrtFile);

thisR = piRead(infile);

thisR.set('film resolution',[500,500]);
thisR.set('pixel samples',16);
thisR.set('fov',40);
thisR.integrator.subtype = 'path';  
thisR.set('film render type',{'radiance'});

thisR.set('lights','all','delete');
newDistant = piLightCreate('new distant',...
                           'type', 'distant',...
                           'spd','d65',...
                           'cameracoordinate', true);
thisR.set('light', 'add', newDistant);

[dir, ~, ~]=fileparts(thisR.outputFile);
basisFile = fullfile(dir, 'textures', 'basisJson.json');
texureBasisCoefFile = fullfile(dir, 'textures', 'BasisCoef.exr');
% write basis
jsonwrite(basisFile,outBasis); 
% write coefs
exrwritechannels(texureBasisCoefFile, 'none', 'float', channelNames, channelData);

newTextureName = 'basisTex';
newTexture = piTextureCreate(newTextureName,...
                       'format', 'spectrum',...
                       'type', 'imagemap',...
                       'filename', texureBasisCoefFile,...
                       'basisfilename',basisFile);
                   
thisR.set('texture', 'add', newTexture);   
thisR.set('material', 'mattex', 'reflectance val', newTextureName);

                   
piWrite(thisR);
scene = piRender(thisR);
sceneWindow(scene);












