function documents = docFind(obj,collection, useQuery)
%FIND Return all the documents that match a find command on a collection
% 
% Input:
%   Our db object
%   collection name
%   query string
%
% Output:
%   matching documents
%
% Example:
%   ourDB.find('autoScenesEXR');
%
% D.Cardinal, Stanford University, 2023
%

% Assume our db is open & query
if ~isopen(obj.connection)
    documents = -1; % oops!
    return;
end


try
    if isempty(useQuery)
        documents = find(obj.connection, collection);
    else
        documents = find(obj.connection, collection, Query = useQuery);
    end
catch
    documents = [];
end
end

