%% Insert materials into a recipe
%
% Deprecated.  Just use t_piIntro_materials
%
% We use piMaterialsInsert to select some materials that we add to a
% recipe.  In the future this will look like
%
%    thisR = piMaterialsInsert(thisR,{'materialClass1','materialClass2', ...});
%
% For now we just insert all 14 of the materials we are experimenting with.
%
% ZLy and BW
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%%  Show them on the MCC

thisR = piRecipeDefault('scene name', 'MacBethChecker');

thisR.set('asset','001_colorChecker_O','delete');

% Widen the field of view
thisR.set('fov',40);

% Add a light with bright windows
% fileName = 'cathedral_interior.exr';
fileName = 'room.exr';
[~, skyMap] = thisR.set('skymap', fileName);
% thisR.set('lights', envLight, 'add');     

% thisR.set('lights','background','rotation val',{[0 0 5 0], [0 1 0 0]});

% thisR.set('lights',skyMap.name,'rotate',[0 0 5]); % {[0 0 5 0], [135 1 0 0]});
thisR.set('lights',skyMap.name,'rotate',[-90 0 0]);
% Insert the materials
thisR = piMaterialsInsert(thisR,'groups',{'all'});

objNames = thisR.get('object names');
matNames = thisR.get('material', 'names');

% Materials containing 'Patch' are the current materials.  We don't want to
% use them again.
newMatNames = matNames(~piContains(matNames, 'Patch'));

% N.B.  Glass is wrong.  I haven't found a good one yet (BW). 
%
% Assign each of the 24 patches a material.  If we run out of materials,
% make it a mirror.  There is one mirror in the list.
for ii=2:numel(objNames)
    if (ii - 1) <= numel(newMatNames)
        thisR.set('asset', objNames{ii}, 'materialname', newMatNames{ii-1});
    else
        thisR.set('asset',objNames{ii},'material name','mirror');
    end
end

thisR.set('nbounces',4);
thisR.set('rays per pixel',128);
scene = piWRS(thisR);
sceneSet(scene,'gamma',0.7);

%% END

%{
% This is an interesting arrangement with every other row being a mirror
% But it includes fewer textures
newMatNames = matNames(~piContains(matNames, 'Patch'));
nMaterials = numel(newMatNames);
for ii = 2:2:(numel(objNames))
    thisMaterial = mod(ii/2,nMaterials);
    thisR.set('asset', objNames{ii}, 'material name', newMatNames{thisMaterial});
    thisR.set('asset', objNames{ii+1}, 'material name', 'mirror');
end
%}
% for ii=(numel(newMatNames)+2):numel(objNames)
%     thisR.set('asset',objNames{ii},'material name','mirror');
% end
