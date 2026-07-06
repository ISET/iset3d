function obj = rtHURB(obj, rays, lensIntersectPosition, curApertureRadius)
%Performs the Heisenburg Uncertainty Ray Bending method on the rays, given
%a circular aperture radius, and lens intersection position. This
%calculation is based on Freniere et al. 1999
%
% obj = rtHURB(obj, rays, lensIntersectPosition, curApertureRadius)
%
% This function accepts both vector forms of inputs, or individual inputs.
%
% Look for cases when you can use: bsxfun ...
%
% This code is not readable yet.  Let's figure out the steps
% and write clarifying functions. (TL Working on this!)
%
% AL/TL Vistasoft Copyright 2014

%%

% Calculate the distance between the center of the aperture and the
% intersection point. 
ipLength = sqrt(sum(lensIntersectPosition(:, (1:2)).^2, 2));

% Calculate the direction that points along the shortest distance between
% the intersection point and the edge of the aperture. This is just the
% vector originating from the center of the aperture (the origin) toward
% the intersection. 
directionS = [lensIntersectPosition(:, 1) lensIntersectPosition(:,2) zeros(length(lensIntersectPosition), 1)];

% Calculate the orthogonal vector to directionS on the aperture
% plane. It is the longer direction, so we call it "directionL."
directionL = [-lensIntersectPosition(:,2) lensIntersectPosition(:,1) zeros(length(lensIntersectPosition), 1)];

% We need to normalize the directions above, but we don't want to divide by
% zero. Here we make sure that doesn't happen. 
normS = repmat(sqrt(sum(dot(directionS, directionS, 2), 2)), [1 3]);
normL = repmat(sqrt(sum(dot(directionL, directionL, 2), 2)), [1 3]);
divideByZero = sum(normS,2) ==0;
directionS(~divideByZero, :) = directionS(~divideByZero, :)./normS(~divideByZero, :);
directionL(~divideByZero, :) = directionL(~divideByZero, :)./normL(~divideByZero, :);
directionS(divideByZero, :) = [ones(sum(divideByZero == 1), 1) zeros(sum(divideByZero == 1), 2)];
directionL(divideByZero, :) = [zeros(sum(divideByZero == 1), 1) ones(sum(divideByZero == 1), 1) zeros(sum(divideByZero == 1), 1)];

% Calculate the distance between the intersection point and the edge
% of the aperture along our two orthogonal directions (directionS and
% directionL). The paper refers to this as delta x and delta y. 
pointToEdgeS = curApertureRadius - ipLength;     
pointToEdgeL = sqrt((curApertureRadius* curApertureRadius) - ipLength .* ipLength); 

% Grab all the wavelengths for this set of rays. We convert the
% wavelength to meters.
lambda = rays.get('wavelength')' * 1e-9;  

% Calculate the variance for the gaussian distribution as described in the
% paper. We convert distances from mm to meters. 
% The paper originally has 2 instead of sqrt(2). Andy added the sqrt(2) to
% produce PSF closer to the Airy disk (?)
% TL (3/18): I switched back to 2. 
sigmaS = atan(1./(2 * pointToEdgeS *.001 * 2 * pi./lambda));  
sigmaL = atan(1./(2 * pointToEdgeL * .001 * 2 * pi./lambda));

% Sample the gaussian distribution.
[randOut] = randn(length(sigmaS),2) .* [sigmaS sigmaL]; 

% Plot distribution of sampled values
%{
temp = randOut(~isnan(randOut(:,1)),:);
temp = rad2deg(temp);
temp = temp((temp(:,1) < 0.5) & (temp(:,1) > -0.5),:);
temp = temp((temp(:,2) < 0.5) & (temp(:,2) > -0.5),:);
histogram2(temp(:,1),temp(:,2),...
    'Normalization','pdf', ...
    'FaceAlpha',0.5,...
    'EdgeAlpha',0.5);
%}

% The output of the distribution gives us the angle deviation we want to
% apply.
noiseS = randOut(:,1);
noiseL = randOut(:,2);

% Project the original ray onto directionS and directionL. projS and projL
% are the magnitude of the projection. 
projS = (rays.direction(: , 1) .* directionS(: ,1)+ ...
         rays.direction(: , 2) .* directionS(:,2))./ ...
         sqrt(directionS(:,1) .* directionS(:,1) +...
         directionS(:,2) .* directionS(:,2));
projL = (rays.direction(: , 1) .* directionL(:, 1) +...
         rays.direction(: , 2 ) .* directionL(:,2))./...
         sqrt(directionL(:,1) .* directionL(:,1) +...
         directionL(:,2) .* directionL(:,2));
projU = rays.direction(:,3);

% We have now decomposed the original, incoming ray into three orthogonal
% directions: directionS, directionL, and directionU.
% directionS is the direction along the shortest distance to the aperture
% edge.
% directionL is the orthogonal direction to directionS in the plane of the
% aperture.
% directionU is the direction normal to the plane of the aperture, pointing
% toward the scene. 
% To orient our azimuth and elevation directions, imagine that the
% S-U-plane forms the "ground plane." "Theta_x" in the Freniere paper is
% therefore the deviation in the azimuth and "Theta_y" is the deviation in
% the elevation. 

% Calculate current azimuth and elevation angles
thetaA = atan(projS./projU);  % Azimuth
thetaE = atan(projL./sqrt(projS.*projS + projU.*projU)); % Elevation 

% Deviate them
thetaA = thetaA + noiseS;
thetaE = thetaE + noiseL;

% Recalculate the new ray direction
% Remember the ray direction is normalized, so it should have length = 1
newprojL = sin(thetaE);
newprojSU = cos(thetaE); 
newprojS = newprojSU .* sin(thetaA);
newprojU = newprojSU .* cos(thetaA);

% Add up the new projections to get a new direction.
rays.direction(:, 1) = (directionS(:, 1) .* newprojS + directionL(:, 1) .* newprojL)./sqrt(directionS(:,1) .* directionS(:,1) + directionL(:,1) .* directionL(:,1));
rays.direction(:, 2) = (directionS(:, 2) .* newprojS + directionL(:, 2) .* newprojL)./sqrt(directionS(:,2) .* directionS(:,2) + directionL(:,2) .* directionL(:,2));
rays.direction(:, 3) = newprojU;
normDirection = repmat(sqrt(sum(dot(rays.direction, rays.direction, 2),2)), [1 3]);
rays.direction = rays.direction./normDirection;

end