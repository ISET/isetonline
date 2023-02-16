function result = gtUpdate(obj,useCollections, forDoc)
%DOCUPDATE Update ground truth for a document in the database
%   Assumes the same _id, pass the updated version
%   Only replaces GTObject & closestTarget for now

% Input:
% -- One or more collections to update with info from forDoc
% -- document that has the ground truth data we want to use

% Example:
%{
useCollection = 'testScenesEXR';
ourDB = isetdb();
docs = ourDB.find(useCollection);
changed = ourDB.gtUpdate(useCollection, docs(1));

OR

useCollection = 'testScenesEXR';
ourDB = isetdb();
docs = ourDB.find(useCollection, "{""_id"":{""$oid"":""63c5e66c96206d471352d197""}}");
changed = ourDB.gtUpdate(useCollection, docs);

%}

% We actually have the doc we want to update, so
% there is probably a mongo primitive to do it,
% but Matlab seems to want a find query and an update query
% Example queries From Help, just for reference
% "{""_id"":{""$oid"":""63c5e66c96206d471352d197""}}"
% "{""_id"":{""$oid"":""63c5e66c96206d471352d197""}}"
% "{""$inc"":{""salary"":5000}}"
%        queryString = sprintf("{""sceneID"": ""%s""}", sceneID);

% Assume our db is open & query
if ~isopen(obj.connection)
    result = 0; % oops!
else

    % Can't use . notation for an _ field
    docID = getfield(forDoc{1},'_id');
    sceneID = forDoc{1}.sceneID;

    fQueryOID = sprintf("{""_id"":{""$oid"":""%s""}}", docID);
    fQueryImageID = sprintf("{""sceneID"":""%s""}", sceneID);

    % Can't just put our object name here apparently?
    gtQuery = sprintf("{""$set"":{""GTObjects"":%s}}", jsonencode(forDoc{1}.GTObject));
    targetQuery = sprintf("{""$set"":{""closestTarget"":%s}}", jsonencode(forDoc{1}.closestTarget));

    for ii = 1:numel(useCollections)
        % These could be combined when we get adventurous
        switch useCollections{ii}
            case 'autoScenesEXR'
                result = obj.connection.update(useCollections{ii},fQueryOID,gtQuery);
                result = obj.connection.update(useCollections{ii},fQueryOID,targetQuery);
            case 'sensorImages'
                result = obj.connection.update(useCollections{ii},fQueryImageID,gtQuery);
                result = obj.connection.update(useCollections{ii},fQueryImageID,targetQuery);
        end
    end

    %% Update sensorImages as well
    % At this point we should update the ground truth in all the sensor
    % images that rely on our EXR scene


end
end

