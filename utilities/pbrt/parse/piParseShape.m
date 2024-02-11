function shape = piParseShape(txt)
% Parse the shape information into struct
%
% Input
%   txt - The line of text with the shape information
%
% Output
%   shape - 
% Logic:
%   Normally the shape line has this format:
%
%   'Shape "SHAPE" "integerindices" [] "point P" [] "float uv" [] "normal N" []'
%
%   We split the string based on the '"' and read each component
%

% Examples: 
%{
% This reads shapes from the MCC
thisR = piRecipeDefault('scene name', 'MacBethChecker');
%}
%%
keyWords = strsplit(txt, '"');
shape = shapeCreate;
% keyWords
if find(piContains(keyWords, 'Shape '))
    shape.meshshape = keyWords{find(piContains(keyWords, 'Shape ')) + 1};
    switch shape.meshshape
        case 'disk'
            shape.height = piParameterGet(txt, 'float height');
            shape.radius = piParameterGet(txt, 'float radius');
            shape.phimax = piParameterGet(txt, 'float phimax');
            shape.innerradius = piParameterGet(txt, 'float innerradius');
        case 'sphere'
            shape.radius = piParameterGet(txt, 'float radius');
            shape.zmin = piParameterGet(txt, 'float zmin');
            shape.zmax = piParameterGet(txt, 'float zmax');
            shape.phimax = piParameterGet(txt, 'float phimax');
        case 'cone'
            shape.height = piParameterGet(txt, 'float height');
            shape.radius = piParameterGet(txt, 'float radius');
            shape.phimax = piParameterGet(txt, 'float phimax');
        case 'cylinder'
            shape.radius = piParameterGet(txt, 'float radius');
            shape.zmin = piParameterGet(txt, 'float zmin');
            shape.zmax = piParameterGet(txt, 'float zmax');
            shape.phimax = piParameterGet(txt, 'float phimax');
        case 'hyperboloid'
            shape.p1 = piParameterGet(txt, 'point p1');
            shape.p2 = piParameterGet(txt, 'point p2');
            shape.phimax = piParameterGet(txt, 'float phimax');
        case 'paraboloid'
            shape.radius = piParameterGet(txt, 'float radius');
            shape.zmin = piParameterGet(txt, 'float zmin');
            shape.zmax = piParameterGet(txt, 'float zmax');
            shape.phimax = piParameterGet(txt, 'float phimax');
        case 'curve'
            % todo
        case {'trianglemesh', 'plymesh'}

            if find(piContains(keyWords, 'filename'))
                shape.filename = piParameterGet(txt, 'string filename');
            end

            if find(piContains(keyWords, 'integer indices'))
                shape.integerindices = uint64(piParameterGet(txt, 'integer indices'));
            end

            if find(piContains(keyWords, 'integer faceIndices'))
                shape.integerindices = uint64(piParameterGet(txt, 'integer faceIndices'));
            end

            if find(piContains(keyWords, 'point3 P'))
                shape.point3p = piParameterGet(txt, 'point3 P');
            end
            if find(piContains(keyWords, 'point2 uv'))
                ext = '';
                if ~isempty(shape.filename)
                    [~, ~, ext] = fileparts(shape.filename);
                end
                if isequal(ext, '.ply')
                    % do something
                else
                    shape.point2uv = piParameterGet(txt, 'point2 uv');
                end
            end

            if find(piContains(keyWords, 'normal N'))
                shape.normaln = piParameterGet(txt, 'normal N');
            end
            
            if find(piContains(keyWords,'texture alpha'))
                shape.alpha = piParameterGet(txt, 'texture alpha');
            end
            % to add
            % float/texture shadowalpha
        case 'heightfield'
            % todo
        case 'loopsubdiv'
            % We are not sure we have this fully correct.
            shape.integerlevels  = piParameterGet(txt,'integer levels');
            shape.integerindices = piParameterGet(txt,'integer indices');
            shape.point3p = piParameterGet(txt,'point3 P');
        case 'nurbs'
            % todo
    end
end

end

function s = shapeCreate
    s.meshshape = '';
    s.filename='';
    s.integerindices = '';
    s.point3p = '';
    s.point2uv = '';
    s.normaln = '';
    s.height = '';
    s.radius = '';
    s.zmin = '';
    s.zmax = '';
    s.p1 = '';
    s.p2='';
    s.phimax = '';
    s.alpha = '';
end
