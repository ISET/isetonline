function [status, result] = createSchema(obj)
% Create our ISET DB schema in the database connection

%%NB: Matlab has limited capability for schema management.
%     Can't add indices, for example, so we might
%     use a mongosh sript or commands.

% We check each createcollection in case
% they already exist. No versioning yet

% I'm sure there is a nicer way to do this
% NB Of course doesn't work directly with the remote case!
switch obj.dbServer
    case 'localhost'
        scriptFile = fullfile(onlineRootPath,'dataprep','mongoSchema');
        [status, result] = system(['mongosh < ' scriptFile]);
    otherwise
        % we can only create collections from Matlab, not indices
        % so those have to get done another way
        collectionNames = {'scene', 'sensor', 'lens',...
            'oi','sensorimage'};
        for ii = 1:numel(collectionNames)
            try
            % use try block in case they exist and we get an error
            createCollection(obj.connection, collectionNames{ii});
            catch
                %warning("Problems creating schema");
            end
        end
end
