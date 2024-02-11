function [objectslist,instanceIdMap, renderCMD,thisRecipe] = piRenderLabel(thisRecipe, renderLater)


InstanceR = piRecipeCopy(thisRecipe);

outputDir = InstanceR.get('outputdir');
[~,scenename] = fileparts(InstanceR.get('outputfile'));

InstanceR.set('rays per pixel',1);
InstanceR.set('nbounces',1);
InstanceR.set('film render type',{'instance'});
InstanceR.set('integrator','path');
InstanceR.film = rmfield(InstanceR.film, 'saveDepth');
InstanceR.film.saveRadiance.value = false;

% Add this line: Shape "sphere" "float radius" 500
InstanceR.world(numel(InstanceR.world)+1) = {'Shape "sphere" "float radius" 5000'};

nNodes = numel(InstanceR.assets.Node);
NodeList = InstanceR.assets.Node;
for nn = nNodes:-1:1
    thisNode =  NodeList{nn};
    if contains(thisNode.name, {'light','lamp','sky'})
        InstanceR.assets = InstanceR.assets.chop(nn);
    end
end

% force all materials to be diffuse
materialKeys = keys(InstanceR.materials.list);
for mm = 1:numel(materialKeys)
    newMat = piMaterialCreate(materialKeys{mm}, ...
        'type', 'diffuse', ...
        'reflectance value',[1 1 1]);
    InstanceR.materials.list(materialKeys{mm}) = newMat;
%     InstanceR = InstanceR.set('material', 'replace', materialKeys{mm}, newMat);
end

spotWhite = piLightCreate('spotWhite',...
    'type','spot',...
    'spd','equalEnergy',...
    'specscale float', 1,...
    'coneangle',20,...
    'cameracoordinate', true);

InstanceR.set('light', spotWhite, 'add');

InstanceR.set('outputFile',fullfile(outputDir, [scenename, '_instanceID.pbrt']));

piWrite(InstanceR);

outputFile = InstanceR.get('outputfile');
fname = strrep(outputFile,'.pbrt','_geometry.pbrt');
fileID = fopen(fname);
tmp = textscan(fileID,'%s','Delimiter','\n');
txtLines = tmp{1};
fclose(fileID);
objectslist = txtLines(piContains(txtLines,'ObjectInstance'));

instanceIdMap = piRender(InstanceR);

end