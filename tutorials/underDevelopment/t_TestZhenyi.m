% This is an example of an isetauto scene
%
% It has object instances
%

%%

ieInit;
if ~piDockerExists, piDockerConfig; end

%%
chdir(piRootPath);
addpath(genpath(pwd));

%% This rendering seems to match on dev and dev-resources

fileName = fullfile(piRootPath, 'data/scenes/low-poly-taxi/low-poly-taxi.pbrt');
thisR = piRead(fileName);
thisR.set('skymap',fullfile(piRootPath,'data/skymaps','sky-rainbow.exr'));

piWrite(thisR);
thisR.show('objects');

scene = piWRS(thisR);
ip = piRadiance2RGB(scene,'etime',1/30);
ipWindow(ip);


%% Add a different car
carName = 'taxi';

rotationMatrix = piRotationMatrix('z', -15);
position       = [-4 0 0];

thisR   = piObjectInstanceCreate(thisR, [carName,'_m_B'], ...
    'rotation',rotationMatrix, 'position',position);
thisR.assets = thisR.assets.uniqueNames;

scene = piWRS(thisR);

ip = piRadiance2RGB(scene,'etime',1/30);

ipWindow(ip);

%%