function startingPoint = piMapToSphere(pFilm,filmRes,retinaDiag,retinaSemiDiam,retinaRadius,retinaDistance)
% Matlab implementation of the corresponding humanEye function in PBRT(c++)
%
% Synopsis
%    startingPoint = piMapToSphere(pFilm,filmRes,retinaDiag, ...
%         retinaSemiDiam,retinaRadius,retinaDistance)
%
% Brief description
%   Creates the (x,y,z) values of the retinal surface positions when
%   calculating with the default human eye code, as published in the
%   JOV paper (Lian et al.).
%
% Inputs
%  pFilm   - pFilm.x, pFilm.y containing the position on the  film of
%             a pixel as a float to allow for jitter in the rendering.
%              The representation is pixel, not physical units.
%  filmRes - filmRes.x filmRes.y the number of sample points in each
%            direction (uncertain if row/col or col/row).
%
% The default parameters from PBRT human eye model are:
%
%     retinaSemiDiam - Semi-diameter of retina Default: (6 mm)
%     retinaRadius   - Retina radius Default: 12 mm
%     retinaDiag     - thisSE.get('retina semidiam')*sqrt(2)*2
%     retinaDistance - Distance from lens to retina.  Default: 16.32 mm
%
% Optional key/val
%   N/A
%
% Outputs
%   startingPoint - 
%
% Description
%
% See also
%

% TODO:
%   This could take as an input the recipe, which would have the
%   various retinal shape parameters encoded in it.  

% Examples:
%{
 
%}

%% Parse


%% 
% To calculate the "film diagonal", we use the retina semi-diameter.
% The film diagonal is the diagonal of the rectangular image rendered
% out by PBRT, in real units. Since we restrict samples to a circular
% image, we can calculate the film diagonal to be the same as a square
% that circumscribes the circular image.

aspectRatio = filmRes.x / filmRes.y;
width = retinaDiag / sqrt((1 + 1./ (aspectRatio * aspectRatio)));
height = width / aspectRatio;


startingPoint=struct;
startingPoint.x = -((pFilm.x) - filmRes.x / 2 - .25) / (filmRes.y / 2);
startingPoint.y = ((pFilm.y) - filmRes.y / 2 - .25) / (filmRes.y / 2);

% Convert starting point units to millimeters
startingPoint.x = startingPoint.x * width / 2;
startingPoint.y = startingPoint.y * height / 2;
startingPoint.z = -retinaDistance;   % TG: Does not do much actually since it is overwritten

% Project sampled points onto the curved retina
if(retinaRadius ~= 0)
    % Right now the code only lets you curve the sensor toward the scene and not
    % the other way around. See diagram:
    %

    %                 The distance between the zero point on the z-axis (i.e. the lens element
    %             closest to the sensor) and the dotted line will be equal to the
    %             "retinaDistance." The retina curvature is defined by the "retinaRadius" and
    %             it's height in the y and x direction is defined by the "retinaSemiDiam."
    %
    %
    %                                         :
    %                                         |  :
    %                                         | :
    %                             | | |         |:
    %             scene <------ | | | <----   |:
    %                             | | |         |:
    %                         Lens System      | :
    %                                         |  :
    %                                         :
    %                                     retina
    %             <---- +z
    %
    %                 */

    % Limit sample points to a circle within the retina semi-diameter
    if ((startingPoint.x * startingPoint.x + startingPoint.y * startingPoint.y) > (retinaSemiDiam * retinaSemiDiam))
        % TG LSet to inf if it should not be traced in PBRT.
        startingPoint.x = inf;
        startingPoint.y = inf;
        startingPoint.z = inf;
    end

    %// Calculate the distance of a disc that fits inside the curvature of the
    %// retina.
    zDiscDistance = -1 * sqrt(retinaRadius * retinaRadius -retinaSemiDiam * retinaSemiDiam);

    %// If we are within this radius, project each point out onto a sphere. There
    %// may be some issues here with even sampling, since this is a direct
    %// projection...
    el = atan(startingPoint.x / zDiscDistance);
    az = atan(startingPoint.y / zDiscDistance);

    % Convert spherical coordinates to cartesian coordinates (note: we switch up
    % the x,y,z axis to match our conventions)

    xc = -1 * retinaRadius * sin(el);  % TODO: Confirm this flip?
    rcoselev = retinaRadius * cos(el);
    zc = -1 * (rcoselev * cos(az));  % The -1 is to account for the curvature
    % described above in the diagram
    yc = -1 * rcoselev * sin(az);    % TODO: Confirm this flip?

    zc = zc + -1 * retinaDistance + retinaRadius;


    startingPoint.x=xc;
    startingPoint.y=yc;
    startingPoint.z=zc;
end

end

