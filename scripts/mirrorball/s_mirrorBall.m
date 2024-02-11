%% s_illuminationMirrorBall
%
% Move script around and create other examples.  This is just a scratch
% beginning.  Change names.
%
% Puts a mirror ball (sphere) into the scene.  Testing the lighting.
%
% See some necessary debugging below.

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Set up the parameters

resolution = [320 320]*2;

thisR = piRecipeDefault('scene name','kitchen');
thisR.set('n bounces',5);
thisR.set('rays per pixel',512);
thisR.set('film resolution',resolution);
thisR.set('render type',{'radiance','depth'});

% Load the sphere and change its size to fit.  It comes in as 1 meter
% diameter.
tmp = piAssetLoad('sphere');
sphereR = tmp.thisR;
mergedR = piRecipeMerge(thisR,sphereR);
mergedR.set('asset','Sphere_O','scale',0.15);

piMaterialsInsert(mergedR,'names',{'mirror'});
mergedR.set('asset','Sphere_O','material name','mirror');

%% Choose a position

% The 'to' is in the middle of the air.  This seems to be the 0,0,0
% position.  The object positions seem to be defined by the values in their
% meshes rather than be branch nodes.  
% 
% I suspect we can find the positions using
%
%   mean(mergedR.get('object vertices',id))
%
% For example
%  v = mergedR.get('object vertices','Mesh110_O');
%  mean()

mergedR.set('to distance',1.5);
to = mergedR.get('to');
mergedR.set('asset','Sphere_O','world position',to);

%% The positions in kitchen seem to be based on the mean values of the mesh
% that is a guess for me now.
%{
kettlePos = mergedR.get('asset','Mesh241_O','world position');
thisR.set('to',kettlePos);
mergedR.set('asset','Sphere_O','world position',pos);
%}

%%
piWRS(mergedR,'render flag','hdr');

%% Move the ball
mergedR.set('asset','Sphere_O','translate',[0.3 0 0]);
piWRS(mergedR,'render flag','hdr');

%% Move the camera
fromOrig = mergedR.get('from');
mergedR.set('from',fromOrig + [-0.3 0 0]);
piWRS(mergedR,'render flag','hdr');

%% Denoise all three
for ii=1:3
    scene = ieGetObject('scene',ii);
    scene = piAIdenoise(scene); ieReplaceObject(scene,ii);
end
sceneWindow;

%%  Look at the sphere from near the Kettle
sphereP = mergedR.get('asset','Sphere_O','world position');
toNew   =sphereP;
fromNew = [0.5 1.7 1.5 ];
mergedR.set('from',fromNew);
mergedR.set('to',toNew);
piWRS(mergedR,'render flag','hdr');

%% Flip from and to.  Move the Sphere also
%
% The kitchen scene has nothing back there.  You can see the sphere, but
% everything else seems black.
%
% A good routine would be
%
%   mergedR.flipfromto;
%

%{
from = mergedR.get('from');
to   = mergedR.get('to');
mergedR.set('to',from);
mergedR.set('from',to);
% This should move the sphere out of the way.  But ...
mergedR.set('asset','Sphere_O','world position',mergedR.get('to'));
piWRS(thisR);
%}

%% Add in a cube light
%
% Keep the existing lights.  Make the cube a little bigger than default.
piLightCube(mergedR,'keep',true);

mergedR.show('lights');
piWRS(thisR);

%%  Things to fix.

% Not understanding the 'translate'. This translate blocks the image. The
% names are also duplicated, which is bad.  The translate doesn't show up
% right.
piLightCube(mergedR,'keep',true,'translate',[1 1 0]);
mergedR.show('lights');
piWRS(thisR);

%%
