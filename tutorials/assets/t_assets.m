%% ISET3d: Assets
% A scene's *assets* are the collection of objects and lights that are used 
% in a PBRT scene.  The assets are stored in a recipe slot. Here we name our recipe 
% object thisR, so they are stored in thisR.assets*,* which is a Matlab *tree* 
% class.  Trees are a natural way to combine the description of objects with the 
% transforms applied to those objects.  The nodes in the thisR.assets tree represent 
% the assets (objects) and the transforms needed to render the assets.
% 
% The tree representation is simple.  It is a cell array of nodes (Node), each 
% with a unique name, and a vector of integers (Parent) that specifies the identity 
% of the parent node for every node.  
%%
% 
%   thisR.assets
%   ans = 
%     tree with properties:
%         Node: {28×1 cell}
%         Parent: [28×1 double]
%
%% 
% The @tree class has many methods for, say, visualizing the tree, grafting 
% onto the tree, chopping off a branch, and so forth. 
% 
% The asset tree can be thought of as the branches and leaves.  Often, the  
% *branches*  represent transformations that control the position, orientation, 
% and size of the objects.  These transformations are applied to all the objects 
% below the branch. The *leaves* define the shape and material of the object.  
% In some cases, a branch may be an object and beneath it may be additional branches 
% and leaves describing parts of that object.
% 
% This tutorial illustrates a few of the ways to control the properties and 
% transforms of objects in an asset tree.  
% 
% The software interface is intended to make controlling the objects close to 
% writing simple sentences.  The programming  consists of *set* and *get* commands 
% that apply to the nodes of the tree. These have the form 
%%
% 
%   thisR.set('asset',assetID,'parameter',value)
%
%% 
% or
%%
% 
%   thisR.get('asset',assetID,'parameter')
%
%% 
% ISET3d Methods illustrated in this script are
%%
% 
%   print, show, translate, rotate, scale, add, delete, obj2light
%
%% 
% *See also* 
% 
% t_piSceneInstances.m, t_assetsMotion.m, t_materials.m
%% The simple scene
% This simple scene has about 25 objects and is useful for demonstrating ISET3d 
% programming.  Here is a low resolution rendering of the scene.  

ieInit;
if ~piDockerExists, piDockerConfig; end

thisR = piRecipeDefault('scene name', 'SimpleScene');
%% We set a low resolution for speed.

thisR.set('film resolution',[160 120]);
thisR.set('rays per pixel',32);
thisR.set('fov',45);
thisR.set('nbounces',2)
%% Render the scene

piWRS(thisR, 'render type', 'radiance', ...
    'name', 'reference scene', ...
    'render flag','hdr');
%% The asset tree
% The recipe *thisR* contains the *assets* tree.  This is a simple tree with 
% only a few assets.

thisR.assets
%% You can display the tree data in several ways, using the show command.  

% By default, calling thisR.show opens a window to the top level of the tree. By 
% clicking on the black triangles, you can explore different depths of the tree.

assetTree = thisR.assets.show;
%% 
% You can also print the asset tree structure in the command window

thisR.assets.print;
%% 
% You can also visualize the positions of the assets this way

piAssetGeometry(thisR);
%% Tree methods 
% There are many tree methods that can be applied to the assets.  Here are a 
% few examples.
%%
% 
%   thisR.assets.findleaves
%   thisR.assets.names
%   t = thisR.assets.stripID
%   str = thisR.assets.tostring
%   thisR.assets.getsiblings(id) ...
%
%% 
% 
%% Referring to an object
% You can get the index into the asset tree for a particular object if you know 
% the object's name.  The full asset names are quite long and formatted as *XXXXID_MoreComplicatedInfo_AssetName_Type*.  
% You do not need to know all of this information when you find the index.  You 
% can just use *piAssetSearch.*
% 
% Here is a simple case.  There are two objects in the scene, one that is a 
% figure 3m away and another a figure that is 6m away.  

thisR.show('objects');
%% 
% The closer one is blue.  We can find the index to it because we know the names.

blueIDX = piAssetSearch(thisR,'object name','figure_3m');
thisR.get('node',blueIDX, 'world position')
%% Rotate the blue man
% The implementation is designed to simplfy changing the position, orientation 
% or other properties of an object.  For example, the blue man is stored in a 
% node that includes the string 'figure_3m'. We use piAssetSearch to find the 
% index into that object node.  Then we rotate the object with this 'set' command

thisR.set('node', blueIDX, 'rotate', [0, 0, 45]);
%% Translate
% The yellow man's position in the world can be translated this way.

yellowIDX = piAssetSearch(thisR,'object name','figure_6m');
thisR.set('node', yellowIDX, 'translate', [0, 0, -2]);
%% Scale
% We increase the size of the yellow man

thisR.set('node', yellowIDX, 'scale', 1.3);
piWRS(thisR, 'render type', 'radiance', ...
    'name', 'Transformed figures');
%% Add an object into a scene
% We have test charts and other assets stored as recipes that can be merged 
% into a scene.  Here we add the famous "Stanford Bunny" to our scene:

bunny = piAssetLoad('bunny');

thisR = piRecipeMerge(thisR,bunny.thisR,'object instance', false);

% scale the bunny so we can see it
thisR.show('objects');

bunnyIDX = piAssetSearch(thisR,'object name','Bunny');
thisR.recipeSet('asset', bunnyIDX, 'scale',[12 12 12]*5);

% s = thisR.get('asset',bunnyName,'scale');

bPos = thisR.get('asset',blueIDX,'world position');

thisR.set('asset',bunnyIDX,'world position',bPos + [0 0 2]);
piWRS(thisR, 'render type', 'radiance', ...
    'name','With Added Object');
%% Delete an object
% Let's remove the blue man so we can see the bunny more clearly.

thisR.set('node',blueIDX,'delete'); 
%%
bunnyIDX = piAssetSearch(thisR,'object name','Bunny');
thisR.set('asset',bunnyIDX,'scale',0.3);
scene = piWRS(thisR, 'render type', 'radiance', ...
    'name','bunny resized.');
%% END
