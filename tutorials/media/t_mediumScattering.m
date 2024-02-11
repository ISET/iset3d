% Experiment with the scattering parameter for the medium
%
%
%
% See also
%   t_mediumExample

%%
ieInit
piDockerConfig();

%% Create a scene with a Macbeth Chart.
macbeth = piRecipeCreate('macbeth checker');
macbeth.show('objects');

macbeth.set('pixel samples', 128);
macbethScene = piWRS(macbeth, 'ourDocker', dockerWrapper, 'show', true, 'meanluminance', -1);
macbeth.show('objects');

%{
sceneWindow(macbethScene);
%}
%{
rgb = sceneGet(macbethScene,'srgb');
figure; 
imshow(rgb);
%}
%% Create sea water medium

% The struct 'water' is a description of a PBRT object that desribes a
% homogeneous medium.  The waterProp are the parameters that define the
% seawater properties, including absorption, scattering, and so forth.
%
% vsf is volume scattering function. Outer product of the scattering
% function and the phaseFunction.  For pbrt you only specify the scattering
% function and a single scalar that specifies the phaseFunction.
%
% phaseFunction 
%
% PBRT allows specification only of the parameters scattering, scattering 
[water, waterProp] = piWaterMediumCreate('seawater');
disp(waterProp)

%{
   uwMacbeth = sceneSet(uwMacbeth,'medium property',val);
   medium = sceneGet(uwMacbeth,'medium');
   medium = mediumSet(medium,'property',val);
   mediumGet()....
%}

% Submerge the scene in the medium.
% It returns a modified recipe that has the 'media' slot built in the
% format that piWrite knows what to do with.
thisR = piSceneSubmerge(macbeth, water, 'sizeX', 50, 'sizeY', 50, 'sizeZ', 5);
piWRS(thisR,'meanluminance', -1);
% sceneWindow(uwMacbethScene);

%% Let's change the scattering parameter
val = thisR.get('media scattering','seawater');
val.scatter = val.scatter*10;   % If it is a single number, just scale by that number.

% thisR.media.list('seawater')

thisR.set('medium','seawater','scatter',val);
val = thisR.get('media scattering','seawater');
val.scatter

piWRS(thisR,'meanluminance', -1);

%% Let's change the absorption parameter
val = thisR.get('media absorption','seawater');
val.absorption = fliplr(val.absorption);   % If it is a single number, just scale by that number.

% thisR.media.list('seawater')

thisR.set('medium','seawater','absorption',val);
val = thisR.get('media absorption','seawater');
% val.absorption

piWRS(thisR,'meanluminance', -1);


%%  Try the chess set
%{
thisR = piRecipeCreate('Chess Set');
chessSet = piWRS(thisR);

%%
thisR = piRecipeCreate('Chess Set');
[water, waterProp] = piWaterMediumCreate('seawater');

sz = [1 1 1];
thisR = piSceneSubmerge(thisR, water, 'sizeX', sz(1), 'sizeY', sz(2), 'sizeZ', sz(3));
uwChessSet = piWRS(thisR,'name',sprintf('Size %.1f-%.1f-%.1f',sz),'meanluminance',-1);
%}
