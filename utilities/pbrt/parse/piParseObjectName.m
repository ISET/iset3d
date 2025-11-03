function [name, sz] = piParseObjectName(txt)
% Parse an ObjectName string in 'txt' to extract the object name and size.

patternList = {'#ObjectName','#object name','#CollectionName',...
    '#Instance MeshName','#MeshName','#Instance CollectionName','#Instance Parent'};

for ii = 1:numel(patternList)
    pattern = patternList{ii};
    loc = strfind(txt,pattern);
    if ~isempty(loc)
        loc_dimension = strfind(txt,'#Dimension');
        break;
    end
end

if isempty(loc_dimension)
    name = txt(loc(1)+length(pattern)+1:end);
    sz.l = [];
    sz.w = [];
    sz.h = [];
else
    name = txt(loc(1)+length(pattern)+1:loc_dimension-1);

    posA = strfind(txt,'[');
    posB = strfind(txt,']');
    raw = strtrim(txt(posA(1)+1:posB(1)-1));

    if isempty(raw)
        % No numbers inside the brackets → return empty sizes
        sz.l = [];
        sz.w = [];
        sz.h = [];
    else
        res = sscanf(raw,'%f');
        if numel(res) < 3
            % Not enough numbers → treat as empty
            sz.l = [];
            sz.w = [];
            sz.h = [];
        else
            % Assign values
            sz.pmin = [-res(1)/2 -res(3)/2];
            sz.pmax = [ res(1)/2  res(3)/2];
            sz.l = res(1);
            sz.w = res(2);
            sz.h = res(3);
        end
    end
end

% Clean name
name = erase(name,'"');
name = erase(name,' ');

end
