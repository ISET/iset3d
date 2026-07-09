function elementsSet(obj, sOffset, sRadius, sAperture, sN, sAsphericCoeff, sConicConst)
% Converts lens data from a PBRT file into the the values of surfaceArray
% object, which is part of the lens.
%
% Description
%   The data in the lens.dat files stores different parameters from the
%   data in the lens.surfaceArray.  This method converts from the lens.dat
%   format to the surfaceArray format
%
% Inputs:
%  The input vectors should have equal length, and be of type
%  double.  They are the surface offset (relative to ...) in mm,
%  radius (mm), aperture (mm) and index of refraction.
%
% The conventional way to set the surface array is to create a
% surface array object and call lens.set('surface array',obj)
%
% This function is used by lens.fileRead, which converts the
% PBRT lens data into a surface array.

%% Check argument size
if (length(sOffset)     ~= length(sRadius) || ...
        length(sOffset) ~= length(sAperture) || ...
        length(sOffset) ~= size(sN,1))
    error('Input vectors must be of equal length');
end

% If no wavelength dependence of index of refraction specified,
% we assume constant across all measurement wavelengths
% sN is nSurfaces x nWave
if (size(sN,2) == 1)
    sN = repmat(sN, [1 length(obj.wave)]);
end

%% Create array of surfaces
obj.surfaceArray = surfaceC();

%% Compute surface array centers
centers = obj.centersCompute(sOffset, sRadius);

for ii = 1:length(sOffset)
    if notDefined('sAsphericCoeff')
        obj.surfaceArray(ii) = ...
            surfaceC('sCenter', centers(ii, :), ...
            'sRadius', sRadius(ii), ...
            'apertureD', sAperture(ii), 'n', sN(ii, :));
    else
        obj.surfaceArray(ii) = ...
            surfaceC('sCenter', centers(ii, :), ...
            'sRadius', sRadius(ii), ...
            'apertureD', sAperture(ii), 'n', sN(ii, :),...
            'aspheric coeff', sAsphericCoeff{ii},...
            'conic constant', sConicConst(ii));
    end

    if sRadius(ii) == 0
        obj.surfaceArray(ii).subtype = 'diaphragm';
    else
        obj.surfaceArray(ii).subtype = 'refr';
    end
end

end
