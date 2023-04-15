function [translation, rotation, scale] = piTransformDecompose(tMatrix)
% Moved in to parseTransform.m
%
% That was the only place it was called.
%

error('Deprecated.  Moved into parseTransform.')

if numel(tMatrix(:)) == 16
    tMatrix = reshape(tMatrix,[4,4]);
else
    error('Transform matrix has to be 4 by 4');
end

% Extract translation from the transformation matrix
translation = reshape(tMatrix(13:15),[3,1]);

% Compute new transformation matrix without translation
tMatrix = tMatrix(1:3,1:3);

% Extract the pure rotation component of the new transformation matrix
% using polar decomposition (the pbrt method)
R = tMatrix;
ii=0;
normii=1;
while ii<100 && normii>.0001
    % Successively average the matrix with its inverse transpose until
    % convergence
    Rnext = 0.5 * (R + inv(R.'));
    % Compute norm of difference between R and Rnext
    normii = norm(abs(R - Rnext));
    % Reset for next iteration
    R = Rnext;
    ii = ii+1;
end

% Calculate rotation angles about the X, Y, and Z axes from the transform matrix
% (citation: Slabaugh, Gregory G., "Computing Euler angles from a rotation matrix", 
% https://www.gregslabaugh.net/publications/euler.pdf, December 5, 2020)
if abs(round(R(3,1),2))~=1
    roty = -asin(R(3,1));
    cosy = cos(roty);
    rotx = atan2(R(3,2)/cosy, R(3,3)/cosy);
    rotz = atan2(R(2,1)/cosy, R(1,1)/cosy);
else
    rotz = 0;
    if R(3,1)==-1
        roty = pi/2;
        rotx = rotz + atan2(R(1,2),R(1,3));
    else
        roty = -pi/2;
        rotx = -rotz + atan2(-R(1,2),-R(1,3));
    end
end

% Convert rotation angles from radians to degrees
rotx = rotx*180/pi;
roty = roty*180/pi;
rotz = rotz*180/pi;

% Set up rotation matrix in pbrt format
rotation = [rotz, roty, rotx; fliplr(eye(3))];

% TODO: Deal with flip

% Compute scale matrix using rotation matrix and transformation matrix
S = R\tMatrix;

% Set up scale parameters in pbrt format
scale = [S(1,1) S(2,2), S(3,3)];
end