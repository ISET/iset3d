function [translation, rotation, scale] = parseTransform(txt)
% Parse a ConcatTransform line into conventional translate/scale/rotate 
%
% Synopsis
%   [translation, rotation, scale] = parseTransform(txt)
%
% Input:
%   txt - The ConcatTransform or Transform line with 16 values between left
%         and right square brackets, from the PBRT scene file 
%
% Output
%   translation - 1x3 vector of translations 
%   rotation    - 4x3 matrix.  Top row is rotx,roty,rotz.  The 3x3 is a
%                 rotation matrix in PBRT format.
%   scale       - 1x3 vector of scalars
%
% See also
%   piTransformDecompose, parseGeometryText (via piRead)

% Read the values from the input (the 'Transform' or 'ConcatTransform' line)

% The square brackets
openidx  = strfind(txt,'[');
closeidx = strfind(txt,']');
tmp = sscanf(txt(openidx(1):closeidx(1)), '[%f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f]');

% Reformat
T = reshape(tmp,[4,4]);

% Derive the parameters
[translation, rotation, scale] = piTransformDecompose(T);

end


