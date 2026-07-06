function points = psCreate(pX,pY,pZ)
% Create cell array of point sources (field height x depth)
%
%    points = psCreate(pX,pY,pZ)
%
% The point positions are specified.  Nothing is specified about their
% wavelengths here.  This can be specified elsewhere.
%
% We define the scene/image side of the lens with negative values, 
% so pZ < 0.
%
% Examples:
%   pZ = -100:20:-40
%   points = psCreate([],[],pZ);
%
%   pX = 0:10:30; pZ = -500;
%   points = psCreate(pX,[],[]);
%
% See also: 
%
% BW Copyright Vistasoft Team, 2014

if notDefined('pX'), pX = 0; end
if notDefined('pY'), pY = 0; end
if notDefined('pZ'), pZ = -500; end

nFH    = length(pX) * length(pY);
nDepth = length(pZ);

% At each depth, we have a set of 
[X,Y] = meshgrid(pX,pY);
X = X(:); Y = Y(:);

% Make the points
points = cell(nFH,nDepth);
for ii=1:nFH
    for dd = 1:nDepth
        points{ii,dd} = [X(ii), Y(ii), pZ(dd)]; 
    end
end

end

