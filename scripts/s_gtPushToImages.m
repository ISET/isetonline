% Helper script to 'push' new Ground truth data from scenes
% into all of the sensor images that use them

% MIGHT ALREADY DOING THIS IN GTUPDATE!

%{
% pasted sample
    fQueryOID = sprintf("{""_id"":{""$oid"":""%s""}}", docID);
    fQueryImageID = sprintf("{""sceneID"":""%s""}", sceneID);

    % Can't just put our object name here apparently?
    gtQuery = sprintf("{""$set"":{""GTObjects"":%s}}", jsonencode(forDoc.GTObject));
    targetQuery = sprintf("{""$set"":{""closestTarget"":%s}}", jsonencode(forDoc.closestTarget));
%}
% open our ISET database
ourDB = isetdb();

% Retrieve all of our scenes
ourScenes = ourDB.docFind('autoScenesEXR',[]);

dbTable = 'sensorImages';

for ii = 1:numel(ourScenes)
    % find sensor images with the same scene id
    sceneID = ourScenes(ii).sceneID;
    queryString = sprintf("{""sceneID"": ""%s""}", sceneID);
    ourImages = ourDB.docFind(dbTable, queryString);


    gtQuery = sprintf("{""$set"":{""GTObjects"":%s}}", jsonencode(ourScenes(ii).GTObject));
    targetQuery = sprintf("{""$set"":{""closestTarget"":%s}}", jsonencode(ourScenes(ii).closestTarget));

    for jj = 1:numel(ourImages)


        result = obj.connection.update(useCollections{ii},fQueryImageID,gtQuery);
        result = obj.connection.update(useCollections{ii},fQueryImageID,targetQuery);

    end

end