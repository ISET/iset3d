% This tutorial shows how to create a simple scene,
% a medium, and how to render the scene submerged in that medium. 
%
% Henryk Blasinski, 2023

%%

%% Here are the docker prefs that work for DJC rendering 
%  from a Windows machine to mux.stanford.edu:

%{
>> getpref('docker')
          localRoot: '/mnt/c'
       gpuRendering: 1
         localImage: ''
           whichGPU: 0
      remoteMachine: 'mux.stanford.edu'
         remoteUser: '<username_on_mux'
        remoteImage: 'digitalprodev/pbrt-v4-gpu-ampere-mux'
         remoteRoot: '<home_folder_on mux>'
    localVolumePath: <path to iset3d\local> for example:'c:\iset\iset3d\local'
      renderContext: 'remote-mux'
        localRender: 0
     remoteCPUImage: 'digitalprodev/pbrt-v4-cpu'
     remoteImageTag: 'latest'
      localImageTag: 'latest'
          verbosity: 1

make sure that ssh <your_mux_username>@mux.stanford.edu
    succeeds without a password
make sure that the terminal command "docker context list"
    shows a remote-mux context
%}
      
      ieInit
piDockerConfig();

%% Create a scene with a Macbeth Chart.
macbeth = piRecipeCreate('macbeth checker');
macbeth.show('objects');

macbeth.set('pixel samples', 128);
dockerWrapper.reset; % get a clean docker, just in case

macbethScene = piWRS(macbeth, 'ourDocker', dockerWrapper, 'show', false, 'meanluminance', -1);
macbeth.show('objects');
sceneShowImage(macbethScene);

%% Create sea water medium



macbethScene = piWRS(macbeth, 'meanluminance', -1);

%%
% HB created a full representation model of scattering that has a number of
% different
%
% Create a seawater medium.
% water is a description of a PBRT object that desribes a homogeneous
% medium.  The waterProp are the parameters that define the seawater
% properties, including absorption, scattering, and so forth.
%
% vsf is volume scattering function. Outer product of the scattering
% function and the phaseFunction.  For pbrt you only specify the scattering
% function and a single scalar that specifies the phaseFunction.
%
% phaseFunction 
%
% PBRT allows specification only of the parameters scattering, scattering 
[water, waterProp] = piWaterMediumCreate('seawater');
disp(waterProp);

%{
   uwMacbeth = sceneSet(uwMacbeth,'medium property',val);
   medium = sceneGet(uwMacbeth,'medium');
   medium = mediumSet(medium,'property',val);
   mediumGet()....
%}
% Submerge the scene in the medium.   
% The size defines the volume of water.  It is centered at 0,0 and extends
% plus or minus 50/2 away from center in units of meters!  Excellent! 
% It returns a modified recipe that has the 'media' slot built in the
% format that piWrite knows what to do with it.
uwMacbeth = piSceneSubmerge(macbeth, water, 'sizeX', 50, 'sizeY', 50, 'sizeZ', 5);
% underwaterMacbeth.set('outputfile',fullfile(piRootPath,'local','UnderwaterMacbeth','UnderwaterMacbeth.pbrt'));

uwMacbeth.show('objects');

uwMacbethScene = piWRS(uwMacbeth,'meanluminance', -1);
%{
sceneWindow(uwMacbethScene);
%}
%{
rgb = sceneGet(uwMacbethScene,'srgb');
figure; imshow(rgb);
%}

%% Let's change a medium parameter - On BW's computer this is OK

% The depth of the water we are seeing through
depths = logspace(0,1.5,3);
for zz = 1:numel(depths)
    uwMacbeth = piSceneSubmerge(macbeth, water, 'sizeX', 50, 'sizeY', 50, 'sizeZ', depths(zz));

    idx = piAssetSearch(uwMacbeth,'object name','Water');
    sz = uwMacbeth.get('asset',idx,'size');
    uwMacbethScene    = piWRS(uwMacbeth, 'meanluminance', -1, 'name',sprintf('Depth %.1f',sz(3)));

end

%%  Try the chess set

thisR = piRecipeCreate('Chess Set');
chessSet = piWRS(thisR);

%%
thisR = piRecipeCreate('Chess Set');
[water, waterProp] = piWaterMediumCreate('seawater');

sz = [1 1 1];
thisR = piSceneSubmerge(thisR, water, 'sizeX', sz(1), 'sizeY', sz(2), 'sizeZ', sz(3));
uwChessSet = piWRS(thisR,'name',sprintf('Size %.1f-%.1f-%.1f',sz),'meanluminance',-1);

