function collectionJSON = exportCollection(obj, collectionName, varargin)
%% exportCollection create JSON file of Collection, with optional filtering

p = inputParser;

addParameter(p, 'mongoquery', '{}'); % default is return all documents
varargin = ieParamFormat(varargin);

p.parse(varargin{:})

mongoQuery = p.Results.mongoquery;

% Assume our db is open & query
if ~isopen(obj.connection)
    collectionJSON = [];
    return;
end

found = find(obj.connection, collectionName, 'Query', mongoQuery);

% Are these JSON already?
collectionJSON = found;

end
