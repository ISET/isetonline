function result = docUpdate(obj,useCollection, doc)
%DOCUPDATE Update document in the database
%   Assumes the same _id, pass the updated version

% Example:
%{
assetCollection = 'assetsPBRT';
ourDB = isetdb();
assets = ourDB.find(assetCollection);
changed = ourDB.docUpdate(obj,assetCollection, assets(1));
%}

% We actually have the doc we want to update, so
% there is probably a mongo primitive to do it,
% but Matlab seems to want a find query and an update query
% From Help
% "{""_id"":{""$oid"":""593fec95b78dc311e01e9204""}}"
% "{""$inc"":{""salary"":5000}}"
%        queryString = sprintf("{""sceneID"": ""%s""}", sceneID);

% Assume our db is open & query
if ~isopen(obj.connection)
    result = 0; % oops!
else

    % Have to rename to access, then we put it back
    renameStructField(doc,'_id','ID');
    docID = doc.ID;
    renameStructField(doc,'ID','_id');

    fQuery = sprintf("{""_id"":{""oid"": ""%s""}", docID);

    % test with null
    uQuery = "{}";

    result = obj.connection.update(useCollection,fQuery,uQuery);
end
end

