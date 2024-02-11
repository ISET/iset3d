function [idmap,objectlist,result] = piLabel(thisRIn)
% Generate a map that labels (pixel-wise) the scene objects
%
% Synopsis
%    [instanceIdMap,objectList,result] = piLabel(thisR);
%
% Brief
%   Render an image showing which object at each pixel (instanceId map).
%   For now this only runs on a CPU.  
%
% Inputs
%   obj - roadgen object
% 
% Key-val/Outputs
%   N/A
%
% Outputs
%   idmap - Image with integers at each pixel indicating which
%                   object.
%   objectslist   - List of the objects
%   result - Output from the renderer
%
% Description
%  For object detection, we often want pixel maps indicating which object
%  is at each pixel. The correspondence between the pixel values and the
%  objects in the returned objectslist. This routine performs that
%  calculation, but it is tuned for isetauto.

% Examples:
%{
% It doesn't find the sphere.
thisR = piRecipeDefault('scene name','SimpleScene');
[idMap, oList, result] = piLabel(thisR);
ieNewGraphWin; imagesc(idMap); axis image
%}
%{
thisR = piRecipeDefault('scene name','ChessSet');
[idMap, oList, result] = piLabel(thisR);
ieNewGraphWin; imagesc(idMap); axis image
%}
%{
% The legend method is not correct yet.
str = '';
for ii=1:numel(oList)
    str = addText(str,oList{ii});
    str = addText(str,', ');
end
str = erase(str,'ObjectInstance');
str = strrep(str,'"','''');

legend(str(3:end-3));
%}

%% Set up the rendering parameters appropriate for a label render

thisR = thisRIn.copy;

thisR.set('rays per pixel',1);
thisR.set('nbounces',1);
thisR.set('film render type',{'instance'});
thisR.set('integrator','path');
thisR.film.saveRadiance.value = false;

% Add this line: Shape "sphere" "float radius" 500
% So we do not label the world lighting, I think.
thisR.world(numel(thisR.world)+1) = {'Shape "sphere" "float radius" 5000'};

outFile = thisR.get('outputfile');
[outDir, fname, ext] = fileparts(outFile);
thisR.set('outputFile',fullfile(outDir, [fname, '_instanceID', ext]));

objID = thisR.get('objects');

%%  Create an instance for each of the objects
for ii = 1:numel(objID)

    % The last index is the node just prior to root
    p2Root = thisR.get('asset',objID(ii),'pathtoroot');
    
    thisNode = thisR.get('node',p2Root(end));
    thisNode.isObjectInstance = 1;

    thisR.set('assets',p2Root(end), thisNode); 
    thisR.assets.uniqueNames;

    if isempty(thisNode.referenceObject)
        thisR = piObjectInstanceCreate(thisR, thisNode.name,'position',[0 0 0],'rotation',piRotationMatrix());
    end
    
end
%%
thisR.assets = thisR.assets.uniqueNames;

piWrite(thisR);

%%  Get the object list from the new Geometry file

% Read the text in the geometry file so we can find the object instances.
outputFile = thisR.get('outputfile');
fname = strrep(outputFile,'.pbrt','_geometry.pbrt');
fileID = fopen(fname);
tmp = textscan(fileID,'%s','Delimiter','\n');
txtLines = tmp{1};
fclose(fileID);

% Find the lines
objectlist = txtLines(piContains(txtLines, 'ObjectInstance'));

%% Render on a CPU

thisDocker = dockerWrapper('gpuRendering',false);
[ieObject, result]   = piRender(thisR,'our docker',thisDocker);
idmap      = ieObject.metadata;

end
