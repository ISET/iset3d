function result = collectionToFile(obj, useCollection,outputFile)
%COLLECTIONTOFILE Write contents of a collection to a JSON file
%   Useful for creating JSON files to be used by the web interface
%   or for export to other applications
%
% Inputs:
%  -- Collection to export to file
%  -- Output filename

% Working Usage -- Create metadata file for the ISETonline web interface
%{
   % This writes our web data file for real, so careful!
   dataFolder = fullfile(onlineRootPath,'simcam','src','data');
   ourDB = isetdb();
   ourDB.collectionToFile('sensorImages',fullfile(dataFolder,'metadata.json'));
%}

if ~isopen(obj.connection)
    result = -1; % oops!
    return;
end

% Get all the documents in the collection
ourData = obj.docFind(useCollection, []);

% Write them to a JSON file
jsonwrite(outputFile, ourData);
result = 0;
end