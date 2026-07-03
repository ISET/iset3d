%% Calculating positions and rotations in world coordinates
%
% Many graphics transforms are specified relative to an object's local
% coordinate frame.  ISET3D also supports world-coordinate queries and
% transforms that account for parent nodes in the asset tree.
%
% See also
%   t_assetsWorld*, recipe/get, recipe/set

%% Set up a simple scene as an example

ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeDefault('scene name', 'simple scene');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',3);

assetName = 'figure_3m_O';

%% Query the initial world transform

initialRotation = thisR.get('asset', assetName, 'world rotation matrix');
initialPosition = thisR.get('asset', assetName, 'world position');

fprintf('Initial position: [%.2f %.2f %.2f]\n',initialPosition);
fprintf('Initial rotation determinant: %.2f\n',det(initialRotation));

%% Apply local rotations and a world translation

thisR.set('asset', assetName, 'rotation', [0 0 45]);
thisR.set('asset', assetName, 'rotation', [0 45 0]);
thisR.set('asset', assetName, 'world translation', [0 0.5 0]);

rotatedPosition = thisR.get('asset', assetName, 'world position');

fprintf('After world translation: [%.2f %.2f %.2f]\n',rotatedPosition);

%% Move the sphere to a requested world position

sphereStart = thisR.get('asset','Sphere_O','world position');
newSpherePosition = [1 2 3];
thisR.set('asset','Sphere_O','world position', newSpherePosition);
sphereEnd = thisR.get('asset','Sphere_O','world position');

fprintf('Sphere moved from [%.2f %.2f %.2f] to [%.2f %.2f %.2f]\n',...
    sphereStart,sphereEnd);

%% Render once after the transform edits

scene = piWRS(thisR,'render flag','hdr');
fprintf('Rendered scene mean luminance %.3f cd/m2\n',sceneGet(scene,'mean luminance'));

%% END
