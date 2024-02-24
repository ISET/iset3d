classdef idb < handle
    %DB Store and retrieve ISET objects from a db
    %   currently only mongoDB

    % For reference:
    % docker run --name mongodb -d -v YOUR_LOCAL_DIR:/data/db mongo
    % docker run --name mongodb -d -e MONGO_INITDB_ROOT_USERNAME=AzureDiamond -e MONGO_INITDB_ROOT_PASSWORD=hunter2 mongo
    %
    % setpref('db','server','acorn');
    % Ask DJC about the port
    % setpref('db','port',....)
    % Typically we only connect to a single db instance, where our 
    % ISET data is kept. So make this the default
    methods (Static)
        function defaultDB = ISETdb()
            persistent ISETdb;
            if ~exist('ISETdb', 'var')
                ISETdb = [];
            end
            if isempty(ISETdb)
                defaultDB = idb();
                ISETdb = defaultDB;
            else
                defaultDB = ISETdb;
            end
        end
    end

    properties
        dbDataFolder = fullfile(piRootPath,'data','db'); % database volume to mount
        dbContainerFolder = '/data/db'; % where mongo db is in container
        dbContainerName = 'mongodb';

        % Read this from prefs or just use a local instance
        dbServer  = getpref('db','server','localhost');
        dbPort = getpref('db','port',27017); % port to use and connect to

        % we don'w support username or password yet
        dbUserName  = getpref('db','username','');
        dbPassword  = getpref('db','password','');
        
        dbName = 'iset';
        dbImage = 'mongo';

        dockerCommand = 'docker run'; % sometimes we need a subsequent conversion command
        dockerFlags = '';

        dockerContainerName = '';
        dockerContainerID = '';

        connection;
    end

    methods
        % default is a local Docker container, but we also want
        % to support storing remotely to a running instance
        function obj = idb(options)

            arguments
                options.dbServer = getpref('db','server','localhost');
                options.dbPort = getpref('db','port',27017);
            end
            obj.dbServer = options.dbServer;
            obj.dbPort = options.dbPort;

            %DB Connect to db instance
            %   or start it if needed

            switch obj.dbServer
                case 'localhost'
                    % do we need to check for docker here?
                    [~, result] = system('docker ps | grep mongodb');
                    if strlength(result) == 0
                        % mongodb isn't running, so start it
                        % NOTE: Could be a dead process, sigh.
                        runme = [obj.dockerCommand ' --name ' obj.dbContainerName ...
                            ' -d -v ' obj.dbDataFolder ':' obj.dbContainerFolder ...
                            ' ' obj.dbImage];
                        [status,result] = system(runme);
                        if status ~= 0
                            error("Unable to start database with error: %s",result);
                        end
                    end
            end

            try
                obj.connection = mongoc(obj.dbServer, obj.dbPort, obj.dbName);
                % sometimes this doesn't work the first time, but
                % I don't know why. Try a pause
                if isopen(obj.connection)
                    % ASSUME already created: obj.createSchema;
                    return; % not sure how we signal trouble?
                else
                    warning("unable to connect to database");
                end
            catch
                warning("Can't connect to mongoDB")
            end
        end

        function close(obj)
            close(obj.connection);
        end
        function [outlist] = collectionList(obj,isprint)
            % ourDB = idb.ISETdb()
            % ourDB.colletionlist('collections')
            outlist = obj.connection.CollectionNames;
            if exist('isprint','var') && ~isprint, return;end
            indices = (1:length(outlist))';
            T = table(indices,outlist, 'VariableNames', {'Index', 'Collection Items'});
            disp(T);
        end

        function collectionCreate(obj,name)
            % Add different type of contents in the database
            % Database structure
            if ~ismember(name,obj.connection.CollectionNames)
                createCollection(obj.connection,name);
            else
                fprintf('[INFO]: Collection %s already exists.\n',name);
            end
        end

        function thisCollection = docList(obj,collectionName)
            % list documents inside a collection

            thisCollection = find(obj.connection,collectionName);
        end

        function [status,out] = upload(localpath,remotedir)
            % this function rsync the local data to a remote dir by default, and only
            % updates the changed files if exists.

            commandline = sprintf('rsync -avz --update %s %s',localpath,remotedir);

            [status,out] = system(commandline);

            if status
                error(out);
            end

        end

        function documents = contentRemove(obj,collection, struct)

            queryString = queryConstruct(struct);
            try
                documents = remove(obj.connection, collection, Query = queryString);
            catch
                documents = [];
            end
        end
    end
end

