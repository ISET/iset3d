function name = piShapeNameCreate(shape,isNode,baseName)
% Create a name for an asset that is an object with a shape
%
% Synopsis
%   name = piShapeNameCreate(shape,[isNode],[baseName])
%
% Input
%   shape  - Shape struct built by piRead and parseGeometryText
%   isNode - This is a shape node name or a shape filename.
%            Default (true, a node)
%   baseName - Scene base name (thisR.get('input basename'));
%
% Output
%    name - The node or file name
%
% Brief description
%   (1) If shape.filename is part of the shape struct, use it.
%   (2) If not, use ieHash on the point3p slot in the shape struct to
%     create a name using the baseName and the hash on point3p.  We only
%     use the first 8 characters in the hex hash. I think that should be
%     enough (8^16), especially combined with the base scene name.
%
% If this is a node name, we append an _O to indicate it is an object.
% If it is a filename, we do not append an _O.
%
% I am not sure why, but we sometimes have a _mat0 in the filename.
% We erase that.  Some historian needs to tell me how that gets there
% (BW 4/4/2023).
%
% See also
%   parseGeometryText, piGeometryWrite

if ieNotDefined('isNode'),isNode = true; end
if ~isNode && ~exist('baseName','var')
    error('Scene base name required for a shape file name.');
end

if ~isempty(shape.filename)
    [~, name, ~] = fileparts(shape.filename);

    % If there was a '_mat0' added to the ply file name
    % remove it.
    % DJC did this for some reason.  It's probably a mistake.  Let's leave
    % the mat in the name if it was there.
    % if contains(name,'_mat0'), name = erase(name,'_mat0'); end

    % Add the _O because it is an object.
    if isNode && ~isequal(name(end-1:end),'_O')
        name = sprintf('%s_O', name);    
    end
else
    str = ieHash(shape.point3p);
    name = sprintf('%s-%s',baseName,str(1:8));
    if isNode && ~isequal(name(end-1:end),'_O')
        name = sprintf('%s_O', name); 
    end
end

end
