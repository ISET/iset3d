%% Copy an asset with object instances
%
% Object instances let a recipe reuse geometry while placing copies at
% different transforms.  This tutorial makes a few sphere instances and
% renders the result once.
%
% See also
%   piObjectInstance, piObjectInstanceCreate, t_piSceneInstances

%% Init

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Create a small instanced sphere scene

thisR = piRecipeCreate('sphere');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('nbounces',2);

mainLight = piLightCreate('mainLight_L',...
    'type','point',...
    'spd spectrum','D65',...
    'specscale float',1,...
    'cameracoordinate',true);
thisR.set('light',mainLight,'add');

piObjectInstance(thisR);

sphereID = piAssetSearch(thisR,'object name','Sphere');
thisR.set('asset',sphereID,'scale',0.5);

p2Root = thisR.get('asset',sphereID,'pathtoroot');
topSphereID = p2Root(end);

nCopies = 3;
for ii=1:nCopies
    thisR = piObjectInstanceCreate(thisR, topSphereID, ...
        'position',ii*[-0.3 0.1 0.0]);
end
thisR.assets = thisR.assets.uniqueNames;

fprintf('Created %d sphere copies\n',nCopies);

%% Render once

scene = piWRS(thisR,'name','Multiple spheres','render flag','hdr');
sceneSize = sceneGet(scene,'size');
fprintf('Instanced scene image size: %d x %d\n',sceneSize(1),sceneSize(2));

%% END
