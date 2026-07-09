% script to illustrate usage of normvec
%
% File:         usage_example_normvec.m
% Author:       Ioannis Filippidis, jfilippidis@gmail.com
% Date:         2012.04.17
% Language:     MATLAB R2012a
% Purpose:      to illustrate usage of NORMVEC
% Copyright:    Ioannis Filippidis, 2012-

%% Case A: matrix of N-dimensional column vectors
v = rand(3, 10);

[v1] = normvec(v); % 2-norm along dimension 1
[v1] = normvec(v, 'p', 2); % 2-norm along dimension 1
[v1] = normvec(v, 'p', 2, 'dim', [] ); % 2-norm along dimension 1
[v1] = normvec(v, 'dim', [], 'p', 2); % 2-norm along dimension 1

[v2] = normvec(v, 'p', 3); % 3-norm along dimension 1

v = rand(3, 4, 5);

[v3] = normvec(v, 'p', 4, 'dim', 3); % 4-norm along dimension 3

%   v = matrix of column vectors
%     = [#dimensions x #vectors]
%   n = p-norm selected (e.g. 2 is the Euclidean norm ||.||_2)
%   d = norm for vectors defined along dimension d of matrix v
%     >= 1
%     or [] (vectors along first non-singleton dimension)

%% Case B: 2 component matrices of 2-dimensional vectors

% x,y components of 2-D vectors over a 2-D grid
px = rand(2, 3);
py = rand(2, 3);

[u1x, u1y] = normvec(px, py); % 2-norm
[u2x, u2y] = normvec(px, py, 'p', 3); % 3-norm

%   px = matrix [M x N] of x vector components
%   py = matrix [M x N] of y vector components
%   n = 'p' norm selected

%% Case C: 3 component matrices of 3-dimensional vectors

% x,y,z components of 3-D vectors over a 3-D grid
px = rand(2, 3, 3);
py = rand(2, 3, 3);
pz = rand(2, 3, 3);

[u1x, u1y, u1z] = normvec(px, py, pz); % 2-norm
[u2x, u2y, u2z] = normvec(px, py, pz, 'p', 5); % 5-norm

%   px = matrix [M x N x L] of x vector components
%   py = matrix [M x N x L] of y vector components
%   pz = matrix [M x N x L] of z vector components
%   n = 'p' norm selected

%% Case D: N component matrices of N-dimensional vectors

% x1,x2,x3,x4,x5 components of 5-D vectors over an N-D grid
px1 = rand(2, 3, 4, 2, 3);
px2 = rand(2, 3, 4, 2, 3);
px3 = rand(2, 3, 4, 2, 3);
px4 = rand(2, 3, 4, 2, 3);
px5 = rand(2, 3, 4, 2, 3);

[u1x1, u1x2, u1x3, u1x4, u1x5] = normvec(px1, px2, px3, px4, px5); % 2-norm
[u2x1, u2x2, u2x3, u2x4, u2x5] = normvec(px1, px2, px3, px4, px5, 'p', 3); % 3-norm

%   pxi = matrix [M1 x M2 x ... x MN] of xi vector components
%   n = 'p' norm selected
