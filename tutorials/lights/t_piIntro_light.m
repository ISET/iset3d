%% Introduce scene lights
%
% This tutorial shows how to inspect scene lights, replace them with a spot
% light, and then switch to an environment light.
%
% See also
%   piLightCreate, recipe/get, recipe/set

%% Initialize ISET and Docker and read a file

ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeDefault('scene name','checkerboard');
thisR.set('film resolution',[160 160]);
thisR.set('rays per pixel',32);
thisR.set('nbounces',2);

%% Inspect and clear the starting lights

lNames = thisR.get('light print');
if ~isempty(lNames)
    thisR.get('light', lNames{1})
end

piLightCreate('list available types')
thisR.set('light', 'all', 'delete');

%% Add one camera-centered spot light and render

lightName = 'new_spot_light_L';
newLight = piLightCreate(lightName,...
    'type','spot',...
    'spd','equalEnergy',...
    'specscale', 1, ...
    'coneangle', 15,...
    'conedeltaangle', 10, ...
    'cameracoordinate', true);
thisR.set('light', newLight, 'add');
thisR.show('lights');

piCameraTranslate(thisR,'z shift',1);
scene = piWRS(thisR,'name','Equal energy spot','render flag','hdr');
fprintf('Spot-light mean luminance %.3f cd/m2\n',sceneGet(scene,'mean luminance'));

%% Replace the spot with an environment light

thisR.set('light', 'all', 'delete');
fileName = fullfile(piDirGet('skymaps'),'room.exr');
thisR.set('skymap',fileName);
thisR.set('light','room_L','specscale',0.3);
thisR.show('lights');

scene = piWRS(thisR,'name','Room environment','render flag','hdr');
fprintf('Environment mean luminance %.3f cd/m2\n',sceneGet(scene,'mean luminance'));

%% END
