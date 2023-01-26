% Update the metadata.json file for ISETonline from our ISETdb
%
% NOTE: This assumes all supporting files are already in place
%       It is mostly useful when we have added to the database schema
%       or corrected data stored in the sensorImages Collection.

% open our default ISET database
ourDB = isetdb();

if ~isopen(ourDB.connection)
    warning("Didn't get a valid database connection.");
    return;
else
    % Our webserver pulls metadata from a private folder
    privateDataFolder = fullfile(onlineRootPath,'simcam','src','data');
    if ~isfolder(privateDataFolder)
        mkdir(privateDataFolder);
    end

    ourDB.collectionToFile('sensorImages', fullfile(privateDataFolder,'metadata.json'));
end