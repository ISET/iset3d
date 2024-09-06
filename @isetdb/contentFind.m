function docIDBContent = contentFind(obj, collection, varargin)
% Return documents stored in the ISET database (mongodb)
%
% Synopsis
%   idbContent = contentFind(obj, collection, varargin)
%   obj.contentFind(collection,varargin)
%
% Input
%   collection: 'PBRTResources' or ... ?
%
% Key/val pairs
%  type:      {'asset','scene','bsdf','skymap','spd','lens','texture'}
%  name:      Object names
%  filepath:  Path to the data
%  category:  Category of the data
%  sizeInMB:  Document size
%  createdat: When it was created
%  updatedat: Has it been updated?
%  author:    Who put it here
%  tags:      For search help
%  description: For people help
%  format:    Good to know
%  mainfile:  What file represents this
%  source:    Original source of the file or information
%  show:      Print out the results prior to return
%
% Description
%  We are building up a database of ISET3d related objects.
%  Potentially there will be other ISET objects in the database in the
%  future.  These are used for ISET3d rendering, such as finding
%  scenes (recipes), skymaps, or textures.
%
%  We have only started.  To add an object to the database see
%  s_dbSceneUpload and related.
%
%  We are just starting to upload textures.
%
% Author:  Zhenyi Liu, Dave Cardinal, Wandell
%
% See also
%  s_dbRendering

%%
varargin = ieParamFormat(varargin);
p = inputParser;
p.addRequired('obj',@(x)(isa(x,'isetdb')));
p.addRequired('collection');  % For the future it can be other

% There is a valid list of types.
resourceTypes = {'asset','scene','bsdf','skymap','spd','lens','texture'};
p.addParameter('type', '',@(x)(ismember(x,resourceTypes)));
p.addParameter('name', '',@ischar);
p.addParameter('filepath', '',@ischar);
p.addParameter('category', '',@ischar);
p.addParameter('sizeInMB', '',@isnumeric);
p.addParameter('createdat', '',@ischar);
p.addParameter('updatedat', '',@ischar);
p.addParameter('createdby', '',@ischar);
p.addParameter('updatedby', '',@ischar);
p.addParameter('author', '',@ischar);
p.addParameter('tags', '',@ischar);
p.addParameter('description', '',@ischar);
p.addParameter('format', '',@ischar);

% assets and scenes
p.addParameter('mainfile', '',@ischar);
p.addParameter('source','',@ischar);

p.addParameter('show',false,@islogical);

p.parse(obj,collection,varargin{:});

%% Generate SHA256 hash for the content

% Make a structure with the parameters passed in the key/val pairs
contentStruct = contentSet(p.Results);

% Get the field names out
fieldNames = fieldnames(contentStruct);

% Iterate over field names and remove fields with empty values
for i = 1:numel(fieldNames)
    fieldName = fieldNames{i};
    if isempty(contentStruct.(fieldName))
        contentStruct = rmfield(contentStruct, fieldName);
    end
end

% Create the string we will send to the database
queryString = queryConstruct(contentStruct);

try
    if isempty(contentStruct)
        % Empty, so get everything back.
        documents = find(obj.connection, collection);
    else
        % Get the user's query back.
        documents = find(obj.connection, collection, Query = queryString);
    end
catch
    % If it didn't work, null it is.
    documents = [];
end

%% Show the returned values

if p.Results.show
   disp('---------------------------------------------------------------');
   fprintf('[INFO]: %d items are found.\n',numel(documents));
   if isscalar(documents)
        disp(struct2table(documents,'AsArray',true));
   elseif numel(documents)>20
        disp('[INFO]: Number of requested items is larger than 20, showing only the first 20 here.')
        disp(struct2table(documents(1:20)));
   elseif isempty(documents)
       return;
   else
       % Print it
       disp(struct2table(documents));
   end
   disp('---------------------------------------------------------------');
end
for ii = 1:numel(documents)
    docIDBContent(ii)=IDBContent(documents(ii));
end

% Convert the documents into the IDBContent class.
% Allocate the array
docIDBContent = repmat(IDBContent, numel(documents), 1);

% Put each document into a docIDBContent.
for ii = 1:numel(documents)
    docIDBContent(ii)=IDBContent(documents(ii));
end

end

%% Creates the struct we will use for the query string
function s = contentSet(parameters)
s = struct(...
    'type', parameters.type, ...
    'category', parameters.category, ...
    'name', parameters.name, ...
    'sizeInMB', parameters.sizeInMB, ...
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
