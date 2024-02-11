function [translation, rotation, scale] = piTransformDecompose(tMatrix)
% Mathematical decomposition of the ConcatTransform data
%
% Synopsis
%
%   [translation, rotation, scale] = piTransformDecompose(tMatrix)
%
% Input
%    tMatrix - 4x4 matrix derived from the ConcatTransform line
%
% Output
%   translation - 1x3 vector of translations 
%   rotation    - 4x3 matrix.  Top row is rotx,roty,rotz.  The 3x3 is a
%                 rotation matrix in PBRT format.
%   scale       - 1x3 vector of scalars
%
% Description:
%   The tMatrix is a 4x4 matrix in the usual computer graphics homogeneous
%   coordinate format.  The first 3x3 is a combination of rotation and
%   scale, and the last column is the translation.  This routine extracts
%   the translate, rotate and scale parameters from the 4x4.
%
%   The translate vector is the 3 values in the fourth column.
%
%   The rotation and scales are computed using a method from:
%
%    Slabaugh, Gregory G., "Computing Euler angles from a rotation matrix", 
%    https://www.gregslabaugh.net/publications/euler.pdf, December 5, 2020
%
%   The upper 3x3 is transformed to become a unitary matrix, and then the
%   rotx/roty/rotz terms are extracted.  Once those are known, the scalar
%   terms are known.
%
%   The rotation is returned in degrees (not radians).
%
% Implemented by Amy Ni, first in her piGeometryRead_Blender
% 
% For comments see parseTransform.  I considered putting
%
% See also
%  parseTransform

% Format from a line into a 4x4
if numel(tMatrix(:)) == 16
    tMatrix = reshape(tMatrix,[4,4]);
else
    error('Transform matrix has to be 4 by 4');
end

% Extract the translation vector from the transformation matrix
translation = reshape(tMatrix(13:15),[1,3]);

% Extract the scale/rotation matrix
tMatrix = tMatrix(1:3,1:3);

% Extract the pure rotation component of the new scale/rotation matrix
% using polar decomposition (the pbrt method)
R  = tMatrix;
ii = 0;
normii = 1;
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

% Calculate rotation angles about the X, Y, and Z axes from the transform
% matrix 
% Citation: Slabaugh, Gregory G., "Computing Euler angles from a
% rotation matrix", https://www.gregslabaugh.net/publications/euler.pdf,
% December 5, 2020
if abs(round(R(3,1),2)) ~= 1  
    % Use the else condition if cosy = (cos(-asin(R(3,1))) is close to zero
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

% Set up rotation values in the PBRT format
rotation = [rotz, roty, rotx; fliplr(eye(3))];

% Compute scale matrix from the rotation matrix and the original matrix
S = R\tMatrix;

% Take the diagonal values of the scale matrix in pbrt format
scale = [S(1,1) S(2,2), S(3,3)];
end
