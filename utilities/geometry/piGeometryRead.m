function thisR = piGeometryRead(thisR)
% Read a C4d geometry file and extract object information into a recipe
%
% Syntax:
%   renderRecipe = piGeometryRead(renderRecipe)
%
% Input
%   renderRecipe:  an iset3d recipe object describing the rendering
%     parameters.  This object includes the inputFile and the
%     outputFile, which are used to find the  directories containing
%     all of the pbrt scene data.
%
% Return
%    renderRecipe - Updated by the processing in this function
%
% Zhenyi, 2018
% Henryk Blasinski 2020
%
% Description
%   This includes a bunch of sub-functions and a logic that needs further
%   description.
%
% See also
%   piGeometryWrite

%%
p = inputParser;
p.addRequired('thisR',@(x)isequal(class(x),'recipe'));

%% Check version number
if(thisR.version ~= 3)
    error('Only PBRT version 3 Cinema 4D exporter is supported.');
end

%% give a geometry.pbrt

% Best practice is to initalize the ouputFile.  Sometimes peopleF
% don't.  So we do this as the default behavior.
[inFilepath, scene_fname] = fileparts(thisR.inputFile);
inputFile = fullfile(inFilepath,sprintf('%s_geometry.pbrt',scene_fname));
%% Open the geometry file

% Read all the text in the file.  Read this way the text indents are
% ignored.
fileID = fopen(inputFile);
tmp = textscan(fileID,'%s','Delimiter','\n');
txtLines = tmp{1};
fclose(fileID);

%% Check whether the geometry have already been converted from C4D

% If it was converted into ISET3d format, we don't need to do much work.

% It was not converted, so we go to work.
thisR.assets = parseGeometryText(thisR, txtLines,'');

%% Redo the node names by adjusting the ID strings

% This adds the IDs up front
[thisR.assets, ~] = thisR.assets.uniqueNames;
end

