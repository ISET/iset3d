%% pbrt v4 introduction 
% User need to pull the docker image:
%     docker pull camerasimulation/pbrt-v4-cpu
%
% OpenExr libraries are needed for the matlab openexr MEX file.
% The issue is caused by openexr version…, 
% Use this version openexr2.5.3:
% https://github.com/AcademySoftwareFoundation/openexr/archive/refs/tags/v2.5.3.zip
% To install, download and unzip and in a terminal run
%   mkdir build
%   cd build
%   cmake ../
%   make
%   make install
%
% Then go to ISET3d=v4/external/openexr and create the MEX file
%   make
%
% This produces several mex files that we use for reading the rendered data
%
%  exrinfo.mexmaci64            exrreadchannels.mexmaci64
%  exrwritechannels.mexmaci64   exrread.mexmaci64
%  exrwrite.mexmaci64   
% 
% CPU only
% blender uses a coordinate system like this:
%    
%                 z
%                 ^  
%                 |
%                 |  
%                 x - - - - >y
% unit scale uses centermeter by default
%
% We modified
%    tree
%   added piWRS.m
%
% TO CHECK for updates
%    recipe.m, recipeSet.m recipeGet.m
%    
%   
%% Init
ieInit;
if ~piDockerExists, piDockerConfig; end

%% piRead support FBX and PBRT
% FBX is converted into PBRT
pbrtFile = '/Users/zhenyi/Desktop/cars_demo/cars_demo.pbrt';
%% 
thisR  = piRead(pbrtFile);
%%
% close up view
% thisR.set('from',[1.9645 0.2464 0.0337]);
% thisR.set('to',  [0.9655 0.2050 0.0198]);
% thisR.set('up',  [0 1 0]);

% thisR.set('film resolution',[600 600]);
thisR.set('rays per pixel',8);
%% set render type
% radiance 
% rTypes = {'radiance','depth','both','all','coordinates','material','instance', 'illuminant','illuminantonly'};
thisR.set('film render type',{'radiance','depth'})
%% move object
% thisR.set('asset','Cylinder.001_B','world translation',[0.2 0 0]);
thisR.show('objects');
%%
piLightDelete(thisR, 'all'); 
lightName = 'new light';
newLight = piLightCreate(lightName,...
                        'type','infinite',...
                        'spd',[0.4 0.3 0.3],...
                        'specscale',1);
thisR.set('light', 'add', newLight);

%% write the data out

scene = piWRS(thisR);
 %{
tic
piWrite(thisR);
scene = piRender(thisR);
sceneWindow(scene);
toc
%}
%%
piAssetGeometry(thisR);
