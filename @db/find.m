function documents = find(obj,collection, varargin)
%FIND Return all the documents that match a find command on a collection

% Assume our db is open & query
if ~isopen(obj.connection)
    documents = -1; % oops!
    return;
end

try
    documents = find(obj.connection, collection);
catch
    documents = [];
end
end

