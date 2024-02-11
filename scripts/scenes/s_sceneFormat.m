%% Wild to Tame
%
% We take some of the complex scripts from the wild, and convert them
% to our format.
%{
 ieInit;
 if ~piDockerExists, piDockerConfig; end
%}

% kitchen
% landscape

% This reads it in from the saved version on the web
thisR = piRecipeDefault('scene name','kitchen');
% thisR = piRecipeCreate('Cornell_Box');

% This writes it to local in our format and renders
piWRS(thisR);

% We check that this file, produced by piWrite, still reads and renders
outfile = thisR.get('output file');
thisR = piRead(outfile);

% Set up the new version
[p,n,e] = fileparts(outfile);
newOut = fullfile([p,'-new'],[n,e]);
thisR.set('output file', newOut)

disp(thisR)

% See if the file in kitchen-new renders
piWRS(thisR);

%% Reformat the simple scene

thisR = piRecipeDefault('scene name','Simple scene');

