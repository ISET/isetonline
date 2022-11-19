classdef db < handle
    %DB Store and retrieve ISET objects from a db
    %   currently only mongoDB

    % For reference:
    % docker run --name mongodb -d -v YOUR_LOCAL_DIR:/data/db mongo
    % docker run --name mongodb -d -e MONGO_INITDB_ROOT_USERNAME=AzureDiamond -e MONGO_INITDB_ROOT_PASSWORD=hunter2 mongo

    % I don't know if we can create a db directly from matlab,
    % or quite what we want to do about making the db part
    % of the repo (/data) versus per-user (/local) or both

    properties
        dbDataFolder = fullfile(onlineRootPath,'data','db'); % database volume to mount
        dbContainerFolder = '/data/db'; % where mongo db is in container
        dbContainerName = 'mongodb';
        dbServer  = 'localhost';
        dbPort = 27017; % port to use and connect to
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
        function obj = db(options)

            arguments
                options.dbServer = 'localhost';
                options.dbPort = 27017;
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

            obj.connection = mongoc(obj.dbServer, obj.dbPort, obj.dbName);
            if isopen(obj.connection)
                obj.createSchema;
                return; % not sure how we signal trouble?
            else
                error("unable to connect to database");
            end
        end


    end
end

