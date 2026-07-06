function rays = rtSourceToEntrance(obj, pointSource, jitterFlag, rtType, subSection)
% Calculate rays from a point to the aperture grid on the first lens surface
% (the lens furthest from the sensor).
%
% Syntax:
%  rays = rtSourceToEntrance(obj, pointSource, jitterFlag, rtType)
%
% Description:
%  The rays are calculated, but not drawn.  Each ray as one wavelength
%  assigned, but there is no wavelength dependence in air, so there is no
%  need to have multiple indices of refraction or wavelength for this
%  calculation.
%
%  The rays will be "expanded" later to save on computations that handle
%  wavelength differences.
%
% Inputs:
%  obj:          A lens object
%  pointSource   A 3 vector
%  jitterFlag:   Jitter the ray positions?
%  rtType:       Ray trace type
%  subSection:   To speed things up ... more comment!
%  
% Outputs:
%  rays:  Rays at the first lens surface
%
% Define the difference between 'ideal'and 'realistic' calculations here.
% 
% See also: 
%  lensC.rtThroughLens, rayC.recordOnFilm

%% PROGRAMMING NOTES
%
%  I don't think we are handling the case of multiple points.  That would
%  be a step forward.
%

%% Parameter checking

if notDefined('jitterFlag'),     jitterFlag = false;     end
if notDefined('rtType'),         rtType = 'realistic';   end
if notDefined('subSection'),     subSection = [];    end
% if notDefined('visualize'),      vis = true;         end

% Define rays object
rays = rayC();    % Classic rays

%% Find distance to first surface for different ray trace types

rtType = ieParamFormat(rtType);
switch rtType
    case 'realistic'
        % This is the position of the of the front surface of the multiple
        % element lens object in the z-coordinate.
        %
        % The size of the multiple lens object is in millimeters, and the
        % back surface is always at position 0.  The front surface, which
        % is towards the image, is a negative value.
        %
        % We should call the total offset the lens thickness, really, for
        % clarity.
        
    case 'ideal'
        % Not sure I understand this case.  More comments! (BW)
        % --------center ray calculation -------

        %trace ray from point source to lens center, to image.
        obj.centerRay.origin = pointSource;
        
        % This could be a call to rayDirection
        obj.centerRay.direction = [ 0 0 obj.centerZ] - obj.centerRay.origin;
        obj.centerRay.direction = obj.centerRay.direction./norm(obj.centerRay.direction);
        
        % Calculate the z-position of the in-focus plane using
        % thin lens equation.  Should be using lensFocus, I think.
        inFocusDistance = 1/(1/obj.focalLength - -1/pointSource(3));
        
        % Calculates the 3-vector for the in-focus position.
        % The in-focus position is the intersection of the
        % in-focus plane and the center-ray
        inFocusT = (inFocusDistance - obj.centerRay.origin(3))/obj.centerRay.direction(3);
        obj.inFocusPosition = obj.centerRay.origin + inFocusT .* obj.centerRay.direction;
        
    case 'linear'
        % VoLT Method.  Not yet implemented or maybe not needed.  AL to
        % check.
        error('Linear method not implemented yet')
    otherwise
        error('Unknown ray trace method:  %s\n',rtType)
end

%% Set up the aperture grid on the front surface

% For PSF calculations, we sample across the front aperture fully.
% But for drawing the rays in an image, we might want to only sample
% rays along the x-axis or y-axis.  These are the xFan and yFan
% conditions.  We would use the subSection parameter to define that
% type of sampling scheme.
aGrid = obj.apertureGrid('randJitter',jitterFlag, ...
                         'rtType',rtType, ...
                         'subSection',subSection);

% These are the end points of the ray in the aperture plane
ePoints = [aGrid.X(:),aGrid.Y(:),aGrid.Z(:)];

%% Directions from the point source to the end points in the aperture

nPts = size(ePoints,1);
rays.origin    = repmat(pointSource, [nPts, 1, 1] );
rays.direction = rayDirection(rays.origin,ePoints);
rays.distance  = zeros(nPts, 1);

%% Additional storage allocation 
%
% AL thinks we should store the XY positions at the front aperture,
% middle aperture, and exit aperture.  The slots for this information
% are created and storage space is initialized here.
%
rays.aEntranceInt.XY = [aGrid.X(:), aGrid.Y(:)];
rays.aEntranceInt.Z  = aGrid.Z(1);  % Saves one value only
rays.aEntranceDir    = rays.direction;

rays.aMiddleInt.XY = zeros(length(aGrid.X), 2);
rays.aExitInt.XY   = zeros(length(aGrid.X), 2);

end