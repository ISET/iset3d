function [hashSHA256,contentStruct] = contentCreate(obj, varargin)
%Create a content in the collection.
%
% Brief
%   This function creates a new content in the specified MongoDB collection. 
%   If a document with the same hash already exists, it updates the document 
%   based on specified criteria.
%
% Syntax
%   [hashSHA256, contentStruct] = obj.contentCreate(varargin)
%
% Inputs
%    obj: The database object representing the connection.
%
%    'collectionname' (char): Name of the MongoDB collection.
%    'type'          (char): Content type.
%    'name'          (char): Content name.
%    'filepath'      (char): File path associated with the content.
%    'category'      (char): Content category.
%    'size'          (numeric): Size of the content.
%    'createdat'     (char): Creation date. Defaults to the current datetime.
%    'updatedat'     (char): Last update date.
%    'createdby'     (char): Creator's username. Defaults to the system user.
%    'updatedby'     (char): Username of the person who last updated the content.
%    'author'        (char): Content author. Defaults to the system user.
%    'tags'          (char): Content tags.
%    'description'   (char): Content description.
%    'format'        (char): Content format.
%    'mainfile'      (char): Main file associated with assets and scenes.
%    'source'        (char): Source of the content.
%
% Optional Key/Value Parameters
%   None
%
% Returns
%     hashSHA256 (char): Unique SHA256 hash created by the MongoDB database.
%     contentStruct (struct): Struct containing content information.
%
% Description
%   The function inserts a new document into the specified collection with the 
%   provided content information. If a document with the same hash exists, it 
%   checks for changes in the 'filepath' or 'description' fields and updates the
%   document if necessary. The function generates a SHA256 hash based on the 
%   content's struct to use as a unique identifier.
%
% Example
%   dbObj = MongoDatabase('ServerURI', 'mongodb://localhost:27017');
%   [hash, content] = dbObj.contentCreate('collectionname', 'exampleCollection', ...
%                                         'type', 'image', 'name', 'exampleImage');
%
% Author
%   Zhenyi, Stanford, 2024

%% Parse inputs
varargin = ieParamFormat(varargin);
p = inputParser;
p.addParameter('collectionname', '',@ischar);
p.addParameter('type', '',@ischar);
p.addParameter('name', '',@ischar);
p.addParameter('filepath', '',@ischar);
p.addParameter('category', '',@ischar);
p.addParameter('sizeInMB', '',@isnumeric);
p.addParameter('createdat', char(datetime('now')),@ischar);
p.addParameter('updatedat', '',@ischar);
p.addParameter('createdby', getenv('USER'),@ischar);
p.addParameter('updatedby', '',@ischar);
p.addParameter('author', getenv('USER'),@ischar);
p.addParameter('tags', '',@ischar);
p.addParameter('description', '',@ischar);
p.addParameter('format', '',@ischar);

% assets and scenes
p.addParameter('mainfile', '',@ischar);
p.addParameter('source','',@ischar);

p.parse(varargin{:});
%% Generate SHA256 hash for the content
contentStruct = contentSet(p.Results);
hashSHA256 = hashStruct(contentStruct);
contentStruct.hash = hashSHA256;
queryString = sprintf("{""hash"": ""%s""}", hashSHA256);

%% Attempt to find an existing document with the same hash
try
    doc = find(obj.connection, p.Results.collectionname, Query = queryString);
    if isempty(doc)
        docCount = insert(obj.connection, p.Results.collectionname, contentStruct);
        if docCount<0
            fprintf("[INFO]: Database add failed: %s\n", p.Results.collectionname);
        end
    else
        difference = docCompare(doc, contentStruct);
        if difference  % update if filepath or description is changed.
            contentStruct.updatedat = char(datetime('now'));
            contentStruct.updatedby = getenv('USER');
            hashSHA256 = hashStruct(contentStruct);
            contentStruct.hash = hashSHA256;
            updatequery = sprintf("{""$set"": %s}", queryConstruct(contentStruct));
            docCount = update(obj.connection,p.Results.collectionname, ...
                queryString,updatequery);
            disp('[INFO]: Content is updated.');
            if docCount<0
                fprintf("[INFO]: Database add failed: %s\n", p.Results.collectionname);
            end
        else
            disp('[INFO]: Content already exists.');
        end

    end

catch ex
    fprintf("[INFO]: Database add failed: %s\n", ex.message);
end

end


%%
function s = contentSet(parameters)
s = struct(...
    'type', parameters.type, ...
    'category', parameters.category, ...
    'name', parameters.name, ...
    'sizeInMB', parameters.size, ...
    'mainfile', parameters.mainfile, ...
    'filepath', parameters.filepath, ...
    'description', parameters.description, ...
    'format', parameters.format, ...
    'createdat', parameters.createdat, ...
    'updatedat', parameters.updatedat, ...
    'createdby', parameters.createdby, ...
    'updatedby', parameters.updatedby, ...
    'author', parameters.author, ...
    'tags', parameters.tags, ...
    'source', parameters.source ...
    );
end


function difference = docCompare(old, new)
    difference = 0;
    if ~isequal(new.filepath, old.filepath) || ...
            ~isequal(new.description, old.description) || ...
            ~isequal(new.sizeInMB, old.sizeInMB)
        difference = 1;
    end
end










