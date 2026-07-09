%% Lens basics
%
% Create a lens object, inspect a few accessors, and compute a focal
% distance.  This tutorial is adapted from the former ISETLens `t_lens.m`.
%
% See also
%   lensC, lensFocus, piDirGet

%% Initialize
ieInit;

%% List available lens files
lenses = lensC.list('quiet',true);
names = {lenses.name};
idx = find(strcmp(names,'dgauss.22deg.3.0mm.json'),1);
assert(~isempty(idx),'Expected standard dgauss lens file was not found.');

%% Create and inspect one lens
thisLens = lensC('filename',lenses(idx),'aperture sample',[9 9]);

nSurfaces = thisLens.get('n surfaces');
lensDiameter = thisLens.get('lens diameter','mm');
filmDistance = lensFocus(thisLens,1e6);

fprintf('Lens: %s\n',thisLens.get('name'));
fprintf('Surfaces: %d\n',nSurfaces);
fprintf('Diameter: %.4f mm\n',lensDiameter);
fprintf('Film distance at infinity: %.4f mm\n',filmDistance);

assert(nSurfaces == 11);
assert(lensDiameter > 0);
assert(filmDistance > 0);

%% Draw the lens layout
thisLens.draw;

%% END
