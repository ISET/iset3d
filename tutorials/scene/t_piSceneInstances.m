%% t_piSceneInstances
%
% Show how to add multiple instances of an object into a scene.  
% 
% The original object stores the mesh data of an object.  To reuse the
% mesh but transformed, we create an instance.  The instance has a
% different transform, but references the original mesh.
% 
% Instances are used heavily in the ISETAuto work and will also be used for
% text rendering (e.g., piTextInsert).  Some day.
%  
% See also
%  piObjectInstanceCreate, piObjectInstanceRemove
%

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Render the basic scene

thisR = piRecipeDefault('scene name','simple scene');
piWRS(thisR);

%% Create a second instance of the yellow guy

% Converts the whole recipe.  Is this necessary or 
piObjectInstance(thisR);
% thisR.show;

% Maybe this should be thisR.get('asset',idx,'top branch')
yellowID = piAssetSearch(thisR,'object name','figure_6m');
p2Root = thisR.get('asset',yellowID,'pathtoroot');
idx = p2Root(end);

% This position is relative to the position of the original object
for ii=1:3
    thisR = piObjectInstanceCreate(thisR, idx, 'position',ii*[-0.3 0 0.0]);
end
% Done this way, we need to adjust the names of the nodes after inserting.
thisR.assets = thisR.assets.uniqueNames;

%% Blue man copies

blueID = piAssetSearch(thisR,'object name','figure_3m');
p2Root = thisR.get('asset',blueID,'pathtoroot');
idx = p2Root(end);

% This position is relative to the position of the original object
% Note: It is also possible to run the create setting the 'unique'
% flag to true.
steps = [-0.3 0.3];
for ii=1:numel(steps)
    thisR = piObjectInstanceCreate(thisR, idx, 'position',[steps(ii) 0 0.0],'unique',true);
end

piWRS(thisR);

%% Use the Chess Set

thisR = piRecipeCreate('Chess Set');
piWRS(thisR);

%% Copy the king using instances

% To see the different pieces, try
%   [idMap, oList] = piLabel(thisR);
%   ieNewGraphWin; image(idMap);
%
% Click on the pieces to see the index
% Then use oList(idx) to see the mesh name
% 72 is the ruler.  The king is made of two meshes: mesh 7 and mesh 65.
%
% The queen is 141.

piObjectInstance(thisR);

pieceID = piAssetSearch(thisR,'object name','ChessSet_mesh_00007');
p2Root  = thisR.get('asset',pieceID,'pathtoroot');
idx = p2Root(end);

% This position is relative to the position of the original object
% The Chess set dimensions are small.  
steps = [-0.2 0.2]*1e-1;
for ii=1:numel(steps)
    [~,newBranch] = piObjectInstanceCreate(thisR, idx, ...
        'position',[steps(ii) 0 0.0], ...
        'unique',true);
    disp(newBranch)
end

topID = piAssetSearch(thisR,'object name','ChessSet_mesh_00065');
p2Root = thisR.get('asset',topID,'pathtoroot');
idx = p2Root(end);

% This position is relative to the position of the original object
% The Chess set dimensions are small.  
steps = [-0.2 0.2]*1e-1;
for ii=1:numel(steps)
    [~,newBranch] = piObjectInstanceCreate(thisR, idx, ...
        'position',[steps(ii) 0 0.0], ...
        'unique',true);
    disp(newBranch)
end

piWRS(thisR,'gamma',0.6);

%% END
