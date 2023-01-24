function result = docUpdate(obj,useCollection, forDoc)
%DOCUPDATE Update document in the database
%   Assumes the same _id, pass the updated version
%   Replacing entire doc is hard. Maybe by field?

%!!: Only replaces GTObject for now

% Example:
%{
useCollection = 'testScenesEXR';
ourDB = isetdb();
docs = ourDB.find(useCollection);
changed = ourDB.docUpdate(useCollection, docs(1));

OR

useCollection = 'testScenesEXR';
ourDB = isetdb();
docs = ourDB.find(useCollection, "{""_id"":{""$oid"":""63c5e66c96206d471352d197""}}");
changed = ourDB.docUpdate(useCollection, docs);

%}

% We actually have the doc we want to update, so
% there is probably a mongo primitive to do it,
% but Matlab seems to want a find query and an update query
% From Help
% "{""_id"":{""$oid"":""63c5e66c96206d471352d197""}}"
% "{""_id"":{""$oid"":""63c5e66c96206d471352d197""}}"
% "{""$inc"":{""salary"":5000}}"
%        queryString = sprintf("{""sceneID"": ""%s""}", sceneID);

% Assume our db is open & query
if ~isopen(obj.connection)
    result = 0; % oops!
else

    % Can't use . notation for an _ field
    docID = getfield(forDoc,'_id');

    fQuery = sprintf("{""_id"":{""$oid"":""%s""}}", docID);

    % Can't just put our object name here apparently?
    uQuery = sprintf("{""$set"":{""newGTObject"":%s}}", jsonencode(forDoc.GTObject));

    result = obj.connection.update(useCollection,fQuery,uQuery);
end
end

