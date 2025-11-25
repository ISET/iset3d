function cube = generateCube(sizeX, sizeY, sizeZ, varargin)

% cube = generateCube(sizeX, sizeY, sizeZ, varargin)
%
% Generate a mesh of a cube, optinally the top surface (xz plane in the direction
% of positive y) can be modified by passing a 2D array of numbers
% representing offsets from the deafult surface plane. This can be used to
% model for example waves on a body of water.
%
% Henryk Blasinski, 2025.

p = inputParser;
p.addOptional('offsetX',0);
p.addOptional('offsetY',0);
p.addOptional('offsetZ',0);
p.addOptional('top', true, @islogical);
p.addOptional('bottom', true, @islogical);
p.addOptional('wallsNS', true, @islogical);
p.addOptional('wallsEW', true, @islogical);
p.addOptional('topSurface',zeros(2,2));

p.parse(varargin{:});
inputs = p.Results;

[nX, nZ] = size(inputs.topSurface);

startX = -sizeX/2 + inputs.offsetX;
endX = sizeX/2 + inputs.offsetX;

startY = -sizeY/2 + inputs.offsetY;
endY = sizeY/2 + inputs.offsetY;

startZ = -sizeZ/2 + inputs.offsetZ;
endZ = sizeZ/2 + inputs.offsetZ;

indices = [];
P = [];

[posZ, posX] = ndgrid(linspace(startX, endX, nX), linspace(startZ, endZ, nZ));

if inputs.top
    % Top surface

    PTop = [posX(:), endY + inputs.topSurface(:),  posZ(:)]';

    indicesTop = [];
    for xx=1:(nX-1)
        for zz=1:(nZ-1)

            topLeft = xx + (zz-1) * nX;
            topRight = xx + 1 + (zz-1) * nX;
            bottomLeft = xx + zz * nX;
            bottomRight = xx + 1 + zz * nX;

            % cell = [topLeft; bottomLeft; topRight; topRight; bottomLeft; bottomRight] - 1;
            cell = [topRight; bottomLeft; topLeft; bottomRight; bottomLeft; topRight] - 1;
            indicesTop = cat(1, indicesTop, cell);
        end
    end

    indices = cat(1, indices, indicesTop);
    P = cat(2, P, PTop);

end

if inputs.bottom
    % Bottom surface
    PBottom = [posX(:), startY * ones(nX*nZ,1), posZ(:)]';

    indicesBottom = [];
    for xx=1:(nX-1)
        for zz=1:(nZ-1)

            topLeft = xx + (zz-1) * nX;
            topRight = xx + 1 + (zz-1) * nX;
            bottomLeft = xx + zz * nX;
            bottomRight = xx + 1 + zz * nX;

            cell = [topRight; topLeft; bottomLeft; bottomRight; topRight; bottomLeft; ] - 1 + (nX * nZ) * inputs.top;
            indicesBottom = cat(1, indicesBottom, cell);
        end
    end

    indices = cat(1, indices, indicesBottom);
    P = cat(2, P, PBottom);

end



if inputs.wallsNS
    % Side walls
    indicesNS = [];

    for zz = [1, nZ]
        for xx=1:(nX-1)

            upperLeft = xx + (zz-1) * nX;
            upperRight = xx + 1 + (zz-1) * nX;
            lowerLeft = upperLeft + nX * nZ;
            lowerRight = upperRight + nX * nZ;

            if zz==nZ
                cell = [upperLeft; upperRight; lowerLeft; lowerLeft; upperRight; lowerRight]- 1;
            else
                cell = [upperRight; upperLeft; lowerRight; lowerRight; upperLeft; lowerLeft]- 1;
            end
            indicesNS = cat(1, indicesNS, cell);
        end
    end

    indices = cat(1,indices, indicesNS);
end

if inputs.wallsEW
    % Side walls
    indicesEW = [];

    for xx=[1, nX]
        for zz = 1:(nZ-1)

            upperLeft = xx + (zz-1) * nX;
            upperRight = xx + zz * nX;
            lowerLeft = upperLeft + nX * nZ;
            lowerRight = upperRight + nX * nZ;

            if xx == 1
                cell = [upperLeft; upperRight; lowerRight; lowerRight; lowerLeft; upperLeft]- 1;
            else
                cell = [upperRight; upperLeft; lowerLeft; lowerLeft; lowerRight; upperRight]- 1;
            end
            indicesEW = cat(1, indicesEW, cell);
        end
    end

    indices = cat(1,indices, indicesEW);
end

cube = piAssetCreate('type','trianglemesh');
cube.integerindices = indices(:)';
cube.point3p = P(:);


end

