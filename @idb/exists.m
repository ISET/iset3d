function doesExist = exists(obj, collectionName,mongoQuery)
%EXISTS Determine whether a given object with a unique key field
%       already exists.
%
%   Pass in the name of the collection where the object would be stored
%   and also a mongoDB query that uniquely identifies objects in that
%   collection (typically the same as a Unique Index already created)

% Assume our db is open & query
if ~isopen(obj.connection)
    doesExist = -1; % oops!
else

    found = find(obj.connection, collectionName, 'Query', mongoQuery);
    if ~isempty(found)
        doesExist = true;
    else
        doesExist = false;
    end

end

