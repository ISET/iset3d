%% t_piIntro_meshLabel
%
% Many scenes, but not all, can be labeled at each pixel by the object
% identity. The key routine is piLabel. 
%
% There are limitations on labeling.  These are related to the way the
% assets were created.  With scenes from the wild we may not be able to
% parse the files and determine the assets.  But for many scenes, and all
% the driving scenes we create, we can define the objects and label their
% pixel locations.
%
% The piLabel runs a CPU version of the docker container.  We have not been
% able to implement labeling on the GPU yet.  This is not very bad,
% however, because labeling requires a very small number of rays and no
% bounces.
%
% In our experience, the labeling fails sometimes.  We do not know why. We
% have run it the same way five times and it may fail once or twice.
% Confused here.
%
% See also
%  piLabel, t_piIntro*, 

%%
ieInit;
if ~piDockerExists, piDockerConfig; end

%% Read the pbrt file and render a noisy version of the scene

thisR = piRecipeDefault('scene name','SimpleScene');
piWRS(thisR,'render flag','hdr');

%% Now run the piLabel code.  

% This returns an image with integers that define the asset associated with
% each pixel.  The renderer for labeling does not work with GPU.  So,
% before running it converts to the CPU version of PBRT.
[idMap, oList] = piLabel(thisR);

%% Have a look at the image
ieNewGraphWin; 

% Notice that the red sphere in the original image is hidden, bewcause it
% is behind the glass object.  No transparencies in the labels.
imagesc(idMap); axis image

%% Display the object list
disp(oList)

%% The whole sequence again, but for the Chess Set
thisR = piRecipeDefault('scene name','ChessSet');
piWRS(thisR,'render flag','hdr');
[idMap, oList] = piLabel(thisR);

ieNewGraphWin; 
imagesc(idMap); axis image
fprintf('%d objects were labeled.\n',numel(oList));
disp(oList)

%% Show the pixels for a particular object

% If you query to full image you can find out the index of a particular
% object.
idx = 7;
idMapObject = (idMap== idx);

ieNewGraphWin;
subplot(1,2,1); imagesc(idMapObject); 
axis image

idx = 49;
idMapObject = (idMap== idx);
subplot(1,2,2), imagesc(idMapObject); 
axis image

%% END