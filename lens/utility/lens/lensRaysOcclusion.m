%% Project occlude - Experimental code. Does not run normally
%
% Need to deal with removing dead rays differently below.
%
% Some rays will be occluded from the aperture by scene objects.  If we
% have a triangle mesh, then we can check for which rays will be occluded
% by the objects.  We do that here.

% If this variable is included, we process for scene depth occlusions
% if(~notDefined('depthTriangles'))
% %if(false)
%     
%     %setup origin and direction of rays
%     epsilon = repmat([0 0 2], [size(rays.origin, 1) 1]);
%     orig = single(rays.origin + epsilon);
%     dir  = single(ePoints - rays.origin);
%     
%     vert1 = single(depthTriangles.vert1);
%     vert2 = single(depthTriangles.vert2);
%     vert3 = single(depthTriangles.vert3);
%     
%     %debug visualization
%     newE = orig + dir;    
%    % ieFigure;  
%     hold on;
%     samps = 1:10:size(orig(:,1));
%     nSamps = length(samps);
%     line([orig(samps,1) newE(samps,1) NaN(nSamps, 1)]',  [orig(samps,2) newE(samps,2) NaN(nSamps, 1)]', [orig(samps,3) newE(samps,3) NaN(nSamps, 1)]');
%     
%     % Setup for the function TriangleRayIntersection intersections with all
%     % combinations of rays and triangles We need to provide every
%     % combination of line and triangles.
%     %
%     % We need to make this faster and simpler and perhaps parallel.  It
%     % seems to run out of memory.
%     % 
%     % Repeat origin so can potentially intersect with all triangles
%     origExp = repmat(orig, [size(vert1,1) 1]);  
%     dirExp = repmat(dir, [size(vert1,1) 1]);    %cycles once before repeating ... ie 1 2 3 4 5 1 2 3 4 5
%     
%     %repeats each triangle size(orig) times
%     vert1Exp = repmat(vert1(:), [1 size(orig, 1)])';    
%     vert1Exp = reshape(vert1Exp, size(dirExp,1), [] );     %ex.  1 1 2 2 3 3 4 4 ... the 1st one represents potential intersection with 1st ray... 2nd repetition intersection with 2nd ray etc.
%     
%     vert2Exp = repmat(vert2(:), [1 size(orig, 1)])';
%     vert2Exp = reshape(vert2Exp, size(dirExp,1), [] );
%     
%     vert3Exp = repmat(vert3(:), [1 size(orig, 1)])';
%     vert3Exp = reshape(vert3Exp, size(dirExp,1), [] );
%     
%     %perform intersection
%     [intersect,~,~,~,xcoor] = TriangleRayIntersection(origExp, dirExp, ...
%         vert1Exp, vert2Exp, vert3Exp, 'lineType', 'segment'); %, 'lineType' , 'line');
%     
%     %separate out and figure out which rays intersected
%     % index = 1:length(intersect);
%     % blockedIndex = index' .* intersect;
%     % blockedIndex(blockedIndex==0) = [];  %remove 0's
%     % blockedRays = mod(blockedIndex, size(orig,1));  %do a mod
%     % blockedRays(blockedRays ==0) = size(orig, 1);  % so 0's are length rays instead of 0
%     % %blockedRays = blockedRays + 1;  %add 1 so index starts at 1 instead of 0
%     
%     %figure out which rays intersected
%     index = repmat(1:size(orig, 1), [1 size(vert1,1)]);  %is this line wrong??
%     blockedRays = index(intersect);
%     
%     %if(false)
%     if (~isempty(blockedRays))
%         
%         %debug visualization
%         
%         debugOn = true;
%         if (pointSource(2) < 10 && debugOn)
%             disp('blocked Rays');
%             %plot origin
%             hold on;
%             scatter3(origExp(1,1), origExp(1,2), origExp(1,3), 100, 'r', 'o', 'filled');
%             %plot intersections
%             hold on;
%             scatter3(xcoor(intersect,1), xcoor(intersect,2), xcoor(intersect,3), 100, 'b', 'o',  'filled');
%             %plot end points
%             hold on;
%             scatter3(ePoints(:,1), ePoints(:,2), ePoints(:,3) , 'r', 'o',   'filled');
%             
%             %plot blocked rays
%             hold on;
%             endP = rays.origin(blockedRays,:) + rays.direction(blockedRays, :) * 10;
%             scatter3(endP(:,1), endP(:,2), endP(:,3), 'r', 'o', 'filled');
%         end
%         
%         %    Remove blocked rays from the ray bundle
%         rays.origin(blockedRays, :) = [];
%         rays.direction(blockedRays, :) = [];   %perhaps make this more elegant in the future...
%         
%     end
%     
% 
% end
