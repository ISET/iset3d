function birdsEye(thisR)
%BIRDSEYE Zoom out and preview our scene/recipe
%   Sometimes it is hard to see the forest for the trees
%
% Example:
%  thisR.birdsEye();
%
% D. Cardinal, Stanford University, 2022

% Start by saving params we'll change
saveTo = recipeGet(thisR,'to');
saveFrom = recipeGet(thisR,'from');
saveRays = recipeGet(thisR,'rays per pixel');
saveRez = recipeGet(thisR,'film resolution');

% Get a box around all assets
[coords, boxRange, hdl] = piAssetGeometry(thisR);

% Figure out where to put the camera, given boxRange is min max
% in a 3 x 2 array
camOffset = 10; % experiment

% set camera far enough away (we hope)
recipeSet(thisR, 'to', [boxRange(1, 2), ...
    boxRange(2,2), boxRange(3,2)] );
recipeSet(thisR, 'from', [boxRange(1,1)-camOffset, ...
    boxRange(2,1) - camOffset, boxRange(3,1) - camOffset]);

% lower viewing parameters
recipeSet(thisR, 'film resolution', [256 256]);
recipeSet(thisR, 'rays per pixel', 64);

% show the user
piWRS(thisR);

% put things back
recipeSet(thisR,'to', saveTo);
recipeSet(thisR,'from', saveFrom);
recipeSet(thisR,'rays per pixel', saveRays);
recipeSet(thisR,'film resolution', saveRez);

% and now save them back
piWrite(thisR);

end

