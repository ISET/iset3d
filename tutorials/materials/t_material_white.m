%% t_material_white
%
%
% Illustrate how to change all the materials in a scene to
% white/diffuse so we get a sense of the lighting.
%
% See also

%%
ieInit;
if ~piDockerExists, piDockerConfig;end

%% Work with the cornell box?

thisR = piRecipeDefault('scene name','cornell_box');
%{
wLight    = piLightCreate('white','type','area');
thisR.set('light',wLight,'add');
thisR.set('asset',wLight.name,'world rotation',[180 0 0]);
% piWRS(thisR,'render flag','hdr');
%}
lightName = 'new_spot_light_L';
spotLight = piLightCreate(lightName,...
                        'type','spot',...
                        'spd','equalEnergy',...
                        'specscale', 1, ...
                        'coneangle', 15,...
                        'conedeltaangle', 10, ...
                        'cameracoordinate', true);
thisR.set('light', spotLight, 'add');
piWRS(thisR);

%%  Find the object IDs

thisR.show('objects');

redWallID  = piAssetSearch(thisR,'material name','cbox_red');
greenWallID = piAssetSearch(thisR,'material name','cbox_green');
largeBoxID = piAssetSearch(thisR,'object name','large_box');
smallBoxID = piAssetSearch(thisR,'object name','small_box');
boxID      = piAssetSearch(thisR,'object name','003_cornell');

%%  Assign some materials
% piMaterialPresets('list');

newMaterials = {'diffuse-white','wood-medium-knots','wood-mahogany',...
    'marble-beige','macbethchart','mirror'};
piMaterialsInsert(thisR,'name',newMaterials);

thisR.set('asset',smallBoxID,'material name','wood-medium-knots');
%thisR.set('asset',largeBoxID,'material name','wood-mahogany');
thisR.set('asset',largeBoxID,'material name','mirror');
%this doesn't work...
%thisR.set('asset',boxID,'material name','macbethchart');
thisR.set('asset',greenWallID,'material name','wood-medium-knots');
thisR.set('asset',redWallID','material name','marble-beige');
piWRS(thisR);

%%  Turn everything diffuse white to illustrate the big lighting change

oNames = thisR.get('object names');
for ii=1:numel(oNames)
 thisR.set('asset',oNames{ii},'material name','diffuse-white');
end
piWRS(thisR);

%% END