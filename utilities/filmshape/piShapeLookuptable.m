function lookuptable = piShapeLookuptable(pointsXYZ_meters)
% Convert XYZ points into a lookuptable struct for PBRT film shape
% 
% Synopsis
%  lookuptable = piShapeLookuptable(pointsXYZ_meters)
%
% Brief
%   This function maps index to position. Usually, wese
%   jsonwrite(lookuptable) to generate the appropriate json file
%
% INPUTS
%  pointsXYZ - Nx3 -matrix with N the number of points in meters
%
% OUTPUTS
%   lookuptable - A struct that can be written out to a json file in the
%   format expected by PBRT as a lookuptable (e.g. for humaneye)
%
% Description
%   The format of the JSON file is rather complex for this simple task.
%   But it is easier to just go along with the PBRT format than rewrite the
%   PBRT code.  So we 
%
% See also
%   piShapeWrite

lookuptable = struct;
lookuptable.numberofpoints= size(pointsXYZ_meters,1);

% Construct map
for index = 1:size(pointsXYZ_meters,1)
    map = struct;
    map.index = index-1;                    % Array index (start counting at zero)
    map.point = pointsXYZ_meters(index,:);  % Target point in mters

    % Add map to lookup table
    lookuptable.table(index) = map; 
end

end