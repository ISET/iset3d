function removeDead(obj, deadIndices)
% Sets unused (dead) ray parameters to NaNs.

% These are usually those that do not make it out an aperture by
% setting these dead indices to Nan.
obj.origin(deadIndices, : ) = NaN;
obj.direction(deadIndices, : ) = NaN;
obj.waveIndex(deadIndices) = NaN;
obj.distance(deadIndices) = NaN;
end