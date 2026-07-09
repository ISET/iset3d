function rootPath = ilensRootPath()
% Return the path to the in-tree ISETLens runtime directory.
%
% This compatibility helper resides at the base of the imported lens subtree
% inside ISET3D. It is used by the former ISETLens class and utility code to
% determine the location of lens sub-directories.
%
% The standalone ISETLens repository used to provide this function at its
% repository root. In ISET3D, it returns fullfile(piRootPath,'lens').
%
% Example:
%   fullfile(ilensRootPath,'data')
%
% Wandell, SCIEN STANFORD, 2018

fullPath = which('ilensRootPath');

rootPath = fileparts(fullPath);

end
