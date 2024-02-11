%% Render a MacBeth color checker and show how to get a zmap image.
%
% Description:
%   The zmap differs from the depth map.  It is the z-coordinate, not
%   the distance from the camera to the point.
%    
%   We render both depth and coordinates here and compare them.
% 
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

%% Read the recipe
% thisR = piRecipeDefault('scene name','chessset');
thisR = piRecipeCreate('macbeth checker');
                      
%% Set rendering parameters 

thisR.set('integrator subtype','path');
thisR.set('pixelsamples', 16);
thisR.set('filmresolution', [640, 360]);
thisR.set('film render type',{'radiance','depth','coordinates'});

% Move the camera closer
thisR.set('object distance',0.5);

scene = piWRS(thisR);
rect = [71     2   489   342];
scene = sceneCrop(scene,rect);

%% Compare the z map and the depth map

ieNewGraphWin([],'wide');
dmap = sceneGet(scene,'depth map');
coords = scene.metadata.coordinates;
zmap = imcrop(coords(:,:,3),rect);

subplot(1,2,1); mesh(dmap);  view(-180,90); axis equal; colorbar; subtitle('Distance')
subplot(1,2,2); mesh(zmap); view(-180,90); axis equal; colorbar; subtitle('Z-coord')

%% End

