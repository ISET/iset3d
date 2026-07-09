%% t_material_white
%
% Change all object materials in a scene to diffuse white so the lighting
% is easy to inspect.
%
% See also
%   t_materials

%% Initialize

ieInit;
if ~piDockerExists, piDockerConfig; end

%% Work with the Cornell box

thisR = piRecipeDefault('scene name','cornell_box');
thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('nbounces',2);

spotLight = piLightCreate('new_spot_light_L',...
    'type','spot',...
    'spd','equalEnergy',...
    'specscale',1,...
    'coneangle',15,...
    'conedeltaangle',10,...
    'cameracoordinate',true);
thisR.set('light',spotLight,'add');

%% Insert one white diffuse material and assign it to every object

piMaterialsInsert(thisR,'name','diffuse-white');

oNames = thisR.get('object names');
for ii = 1:numel(oNames)
    thisR.set('asset',oNames{ii},'material name','diffuse-white');
end
fprintf('Assigned diffuse-white to %d objects\n',numel(oNames));

%% Render once

scene = piWRS(thisR,'render flag','hdr');
fprintf('Rendered white-material scene: %d x %d pixels\n',sceneGet(scene,'cols'),sceneGet(scene,'rows'));

%% END
