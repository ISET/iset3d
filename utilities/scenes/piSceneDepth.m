function [depthrange, depthmap] = piSceneDepth(thisR)
% Compute the depth (meters) of the objects in the scene
%
% Syntax
%   [depthrange, depthmap] = piSceneDepth(thisR)
%
% Brief description
%   Calculate the depth image quickly and return the depth range and a
%   depth map histogram (meters).
%
% Wandell, 2019
%
% See also
%  t_piIntro_lens

% TODO:  See issue we have with the lens.  Here we remove the camera and
% replace it with a pinhole.  But really PBRT should also return the same
% depth map even if there is a lens.  When we are computing the depth map
% PBRT should use a pinhole.  I think!

%% Make a version of the recipe that matches but with a pinhole

% We think we should not have to do this to correctly get the depth.  The
% PBRT calculation should be independent of the lens!!!
pinholeR        = thisR.copy;
pinholeR.set('camera','delete');
pinholeR.camera = piCameraCreate('pinhole');
% Note: We put back the original recipe later
piWrite(pinholeR);


%% The render returns the depth map in meters

% only asking for depth might not return anything, so ask for both?
depthmap   = piRender(pinholeR, 'film render type','depth');
if isstruct(depthmap)
    tmp        = depthmap.depthMap(depthmap.depthMap > 0);
else
    tmp        = depthmap(depthmap > 0);
end
depthrange = [min(tmp(:)), max(tmp(:))];

piWrite(thisR); % put it back the way the user wanted it

%% If no output arguments plot the histogram

if nargout == 0
    ieNewGraphWin;
    histogram(depthmap(:));
    xlabel('m'); ylabel('n pixels'); set(gca,'yscale','log');
    grid on;
end

end
