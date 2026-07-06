function obj = rtIdealThroughLens(obj, rays, nLines)
% Deprecate
%
% Traces lens.rays through the ideal lens, this is a lens where we simply
% redirect all the rays to the focal point, which is determined by a thin
% lens equation. (TL/BW).
%
% This is tested by one script called
%
%     s_s3dRayTraceIdealLens
%
% This is different from the rtRealisticThroughLens, which also works quite
% well.  We are considering getting rid of this case because it isn't
% really called anywhere.
%
% TL/BW/AL Vistasoft, 2014

% WE ARE CONSIDERING DELETING THIS CASE

disp('rtIdealThroughLens called to BW surprise')

% When intersecting ideal lens, change the direction to intersect the
% inFocusPosition, and update the origin
lensIntersectT = (obj.centerZ - rays.origin(:,3))./ rays.direction(:,3);
lensIntersectPosition = rays.origin +  repmat(lensIntersectT, [1 3]) .* rays.direction;

% Debug visualization
% if (nLines)
%     raysVisualize ...
%         
% %     ieFigure;
% %     % Colors of the rays we will draw
% %     lWidth = 0.5; lColor = [.5 0 1];
% %     samps = randi(size(rays.origin,1),[nLines,1]);
% %     
% %     xCoordVector = [rays.origin(samps,3) lensIntersectPosition(samps,3) NaN([nLines 1])]';
% %     yCoordVector = [rays.origin(samps,2) lensIntersectPosition(samps,2) NaN([nLines 1])]';
% %     xCoordVector = real(xCoordVector(:));
% %     yCoordVector = real(yCoordVector(:));
% %     line(xCoordVector,  yCoordVector ,'Color',lColor,'LineWidth',lWidth);
% %     pause(0.2);
% %     
% end

% Calculate new direction
%  newRays = rayObject(); % added
rays.origin = lensIntersectPosition;
rays.direction = repmat(obj.inFocusPosition , [size(rays.origin,1) 1 ]) - rays.origin;

% diffraction HURB calculation
if (obj.diffractionEnabled)
    obj.rtHURB(rays, lensIntersectPosition, obj.apertureMiddleD/2);
end

end
