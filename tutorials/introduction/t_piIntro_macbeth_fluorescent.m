%% t_piIntro_macbeth_fluorescent
%
% Render a MacBeth color checker.  Then make an illuminant image to
% return a spatio-spectral illuminant.
% 
% Index numbers for MacBeth color checker:
%          ---- ---- ---- ---- ---- ----
%         | 01 | 05 | 09 | 13 | 17 | 21 |
%          ---- ---- ---- ---- ---- ----
%         | 02 | 06 | 10 | 14 | 18 | 22 | 
%          ---- ---- ---- ---- ---- ----
%         | 03 | 07 | 11 | 15 | 19 | 23 | 
%          ---- ---- ---- ---- ---- ----
%         | 04 | 08 | 12 | 16 | 20 | 24 | 
%          ---- ---- ---- ---- ---- ----
%
% Dependencies:
%
%    ISET3d, (ISETCam or ISETBio), JSONio
%
% Author:
%   ZLY, BW, 2020

%% init
ieInit;
if ~piDockerExists, piDockerConfig; end
if isempty(which('fiToolboxRootPath'))
    disp('No fluorescence toolbox.  Skipping');
    return;
end

%% Read the recipe

thisR = piRecipeDefault('write',false);

%% Set rendering parameters

thisR.integrator.subtype = 'path';
thisR.set('pixelsamples', 16);
thisR.set('filmresolution', [640, 360]);

%% Write 

piWrite(thisR, 'overwritematerials', true);

%% Show the region/material options
piMaterialList(thisR);

%% Assign fluorescent materials on some patches
concentrationUniform = 0.5;
thisR.set('material', 'Patch19Material', 'concentration val', concentrationUniform);
thisR.set('material', 'Patch11Material', 'concentration val', concentrationUniform);
thisR.set('material', 'Patch06Material', 'concentration val', concentrationUniform);
thisR.set('material', 'Patch02Material', 'concentration val', concentrationUniform);
thisR.set('material', 'Patch18Material', 'concentration val', concentrationUniform);

wave = 365:5:705;

% Collagen
eemCollagen = piMaterialGenerateEEM('Collagen');
thisR.set('material', 'Patch11Material', 'fluorescence val', eemCollagen);
% Porphyrins
eemPorphyrins = piMaterialGenerateEEM('Porphyrins');
thisR.set('material', 'Patch06Material', 'fluorescence val', eemPorphyrins);
% NADH
eemNADH = piMaterialGenerateEEM('NADH');
thisR.set('material', 'Patch02Material', 'fluorescence val', eemNADH);
% FAD
eemFAD = piMaterialGenerateEEM('FAD_webfluor');
thisR.set('material', 'Patch18Material', 'fluorescence val', eemFAD);
thisR.set('material', 'Patch19Material', 'fluorescence val', eemFAD);

%% First use a normal light
thisR.set('light', 'delete', 'all');
d65Light = piLightCreate('D65 light',...
                            'type', 'distant',...
                            'spd', 'D65',...
                            'specscale', 1,...
                            'cameracoordinate', true);
thisR.set('light', 'add', d65Light);
%% Write 
% Write modified recipe out
piWrite(thisR, 'overwritematerials', true);

%% Render - At some point we will make this the default (latest)

% If you want to use the fluorescent modeling, specify this docker
% container.  We will promote to the default after we test it more.

thisDocker = 'vistalab/pbrt-v3-spectral:basisfunction';
[scene, result] = piRender(thisR, 'docker image name', thisDocker,'wave',wave, 'render type', 'radiance');
scene = sceneSet(scene,'wavelength', wave);
scene = sceneSet(scene, 'name', 'D65 illuminant');
sceneWindow(scene);


%% Second use a blue LED light
thisR.set('light', 'delete', 'all');
fluoLight = piLightCreate('Blue light',...
                            'type', 'distant',...
                            'spd', 'blueLEDFlood.mat',...
                            'specscale', 1,...
                            'cameracoordinate', true);
thisR.set('light', 'add', fluoLight);

%% Write 
% Write modified recipe out
piWrite(thisR, 'overwritematerials', true);

%% Render - At some point we will make this the default (latest)

% If you want to use the fluorescent modeling, specify this docker
% container.  We will promote to the default after we test it more.

thisDocker = 'vistalab/pbrt-v3-spectral:basisfunction';
[scene, result] = piRender(thisR, 'docker image name', thisDocker,'wave',wave, 'render type', 'radiance');
scene = sceneSet(scene,'wavelength', wave);
scene = sceneSet(scene, 'name', 'Blue LED illuminant');
sceneWindow(scene);

%%