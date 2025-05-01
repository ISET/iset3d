classdef isetdb < handle
    % Initialize an ISET database object.  
    % 
    properties
        dbServer    = "localhost:27017"
        dbName      = "iset"
        dbImage     = "mongodb"
        dbUsername  = "demo"
        dbPassword  = "demopass"
    end
    properties (Access = private)
        connection
    end

    methods
        function obj = isetdb(options)
            % The obj values can be set in the call to isetdb in the
            % form isetdb(dbProp=dbPropValue, etc).  If they are not,
            % they are overwritten by the "db" pref field, if not we
            % let the generic values flow through
            arguments
                options.dbServer
                options.dbName
                options.dbImage
                options.dbUsername
                options.dbPassword
                options.noconnect = false; %usually we want to connect at creation
                options.noprefs = false; %don't populate with isetdb prefs
            end
            
            props = properties(obj);
            for ii=1:numel(props)
                if strcmp(props{ii},"connection")
                    % obj.connection should only be set by calling mongoc()
                    continue;
                end
                
                if isfield(options, props{ii})
                    % if we passed in an option, that overrides
                    obj.(props{ii}) = options.(props{ii});
                elseif ~options.noprefs && ispref("db") && ispref("db",props{ii})
                    % check for a preference, otherwise just let the value
                    % from the properties section flow through
                    obj.(props{ii}) = getpref("db",props{ii});
                end
            end
            if ~options.noconnect
                [server] = split(obj.dbServer,':');
                port = str2double(server(2));
                obj.connection = mongoc(server{1}, port, obj.dbName, ...
                UserName=obj.dbUsername, Password=obj.dbPassword);
            end
        end

        function isopen(obj)
            if obj.connection
                obj.connection.isopen;
            else
            end
        
        end
        function connect(obj)
        % default is a local Docker container, but we also want
        % to support storing remotely to a running instance
           
            %DB Connect to db instance
            %   or start it if needed

            switch obj.dbServer
                case 'localhost'
                    % If you are on the machine that might have the
                    % Mongo database running (at Stanford is mux or
                    % orange) then we see whether it's running
                    [~, result] = system('docker ps | grep mongodb');

                    % If it is not running, start it
                    if strlength(result) == 0
                        % NOTE: Could be a dead process, sigh.
                        runme = ['docker run --name mongodb -d -v' ...
                            obj.dbDataFolder, ':/data/db mongo'];                            
                        [status,result] = system(runme);
                        if status ~= 0
                            error("Unable to start database with error: %s",result);
                        end
                    end
            end

            % Open the connection to the mongo database
            % succeeds or throws an error.  We could do a 'try' and 'catch' if
            % we want to avoid blowing up entirely
            obj.connection = mongoc(obj.dbServer, obj.dbPort, obj.dbName, ...
                UserName=obj.dbUsername, Password=obj.dbPassword);
        end  

        % How we close the connection.
        % If we had an sftp, we should be using fclose()
        function close(obj)
            close(obj.connection);
        end

        % List the collection names
        function [outlist] = collectionList(obj,isprint)
            % ourDB = isetdb.ISETdb()
            % ourDB.colletionlist('collections')
            outlist = obj.connection.CollectionNames;
            if exist('isprint','var') && ~isprint, return;end
            indices = (1:length(outlist))';
            T = table(indices,outlist, 'VariableNames', {'Index', 'Collection Items'});
            disp(T);
        end

        function collectionCreate(obj,name)
            % name is a new collection that we are creating.  It will
            % not overwrite an existing collection.  To see the
            % current collections use isetdb.collectionList;
            %
            if ~ismember(name,obj.connection.CollectionNames)
                createCollection(obj.connection,name);
            else
                fprintf('[INFO]: Collection %s already exists.\n',name);
            end
        end

        % We need a collectionRemove
        function collectionDelete(obj,name)
            fprintf('collectionDelete is not yet implemented.\n');
        end

        % Content is within a collection
        function count = contentRemove(obj,collection, queryStruct)

            % This should be JSON-style Mongo Query.  
            % queryString = queryConstruct(queryStruct);
            queryString = jsonencode(queryStruct);
            try
                % count = remove(obj.connection, collection, Query = queryString);
                count = remove(obj.connection, collection, queryString);
            catch
                count = 0;
            end
        end

    end
    methods (Static = true)
        setDbUserPrefs();
    end
end

