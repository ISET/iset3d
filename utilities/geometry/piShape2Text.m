function txt = piShape2Text(shape)
% Convert data in the shape struct to text for the PBRT file
%
% Synopsis
%   txt = piShape2Text(shape)
%
% Input:
%   shape - a shape struct with various slots
%
% Output
%   txt  - Converted to the format needed to write out in a pbrt file
%
% See also
%
txt = "Shape ";

if isfield(shape, 'meshshape') && ~isempty(shape.meshshape)
    txt = strcat(txt, '"', shape.meshshape, '"');
end
if isfield(shape, 'filename') && ~isempty(shape.filename)
    txt = strcat(txt, ' "string filename" ', ' "',shape.filename,'"');
end
if isfield(shape, 'integerindices') && ~isempty(shape.integerindices)
    txt = strcat(txt, ' "integer indices"', [' [',num2str(shape.integerindices),']',]);
end
if isfield(shape, 'point3p') && ~isempty(shape.point3p)
    txt = strcat(txt, ' "point3 P"', [' [',piNum2String(shape.point3p),']',]);
end
if isfield(shape, 'point2uv') && ~isempty(shape.point2uv)
    txt = strcat(txt, ' "point2 uv"', [' [',piNum2String(shape.point2uv),']',]);
end
if isfield(shape, 'normaln') && ~isempty(shape.normaln)
    txt = strcat(txt, ' "normal N"', [' [',piNum2String(shape.normaln),']',]);
end
if isfield(shape, 'height') && ~isempty(shape.height)
    txt = strcat(txt, ' "float height"', [' [',piNum2String(shape.height),']',]);
end
if isfield(shape, 'radius') && ~isempty(shape.radius)
    txt = strcat(txt, ' "float radius"', [' [',piNum2String(shape.radius),']',]);
end
if isfield(shape, 'zmin') && ~isempty(shape.zmin)
    txt = strcat(txt, ' "float zmin"', [' [',piNum2String(shape.zmin),']',]);
end
if isfield(shape, 'zmax') && ~isempty(shape.zmax)
    txt = strcat(txt, ' "float zmax"', [' [',piNum2String(shape.zmax),']',]);
end
if isfield(shape, 'p1') && ~isempty(shape.p1)
    txt = strcat(txt, ' "float p1"', [' [',piNum2String(shape.p1),']',]);
end
if isfield(shape, 'p1') && ~isempty(shape.p1)
    txt = strcat(txt, ' "float p1"', [' [',piNum2String(shape.p1),']',]);
end
if isfield(shape, 'p2') && ~isempty(shape.p2)
    txt = strcat(txt, ' "float p2"', [' [',piNum2String(shape.p2),']',]);
end
if isfield(shape, 'phimax') && ~isempty(shape.phimax)
    txt = strcat(txt, ' "float phimax"', [' [',piNum2String(shape.phimax),']',]);
end
if isfield(shape, 'alpha') && ~isempty(shape.alpha)
    txt = strcat(txt, ' "texture alpha"', [' ["',piNum2String(shape.alpha),'"]',]);
end

end
