function documents = docFind(obj,collection, useQuery)
%FIND Return all the documents that match a find command on a collection
% 
% Input:
%   Our db object
%   collection name
%   query string
%
% Output:
%   matching documents
%
% Examples:
%{
   ourDB.docFind('autoScenesEXR');

   dbTable = 'autoScenesEXR';
   % sceneIDs are unique for auto scenes
   sceneID = '1112154540';
   queryString = sprintf("{""sceneID"": ""%s""}", sceneID);
   ourScene = ourDB.docFind(dbTable, queryString);

    ourDB = isetdb(); 
    dbTable = 'sensorImages';
    filter = 'closestTarget.label';
    target = 'truck';
    queryString = sprintf("{""closestTarget.label"": ""%s""}", target);
    sensorImages = ourDB.docFind(dbTable, queryString);
    fprintf("Found %d images\n",numel(sensorImages));
%}
%
% D.Cardinal, Stanford University, 2023
%

% Assume our db is open & query
if isempty(obj)
    obj = idb();    
end

%{
if ~isopen(obj.connection)
    documents = -1; % oops!
    return;
end
%}

try
    if isempty(useQuery)
        documents = find(obj.connection, collection);
    else
        documents = find(obj.connection, collection, Query = useQuery);
    end
catch
    documents = [];
end
end

