function [status, result] = store(obj, isetObj, options)
%SAVEMONGO Explore saving to mongodb
%   D. Cardinal, Stanford University, 2022

arguments
    obj;
    isetObj;
    options.isetDB;
    options.collection = 'images'; % default collection
end

if ~isempty(obj.connection) && isopen(obj.connection)
    isetDB = obj.connection;
else
    isetDB = idb();
end

if isempty(obj.connection)
    status = -1;
    return;
end

% need to add update logic & type specific keys and such
try
    status =insert(obj.connection,options.collection,isetObj);
catch ex
    status = -1;
    fprintf("Database insert failed: %s\n", ex.message);
end
end

