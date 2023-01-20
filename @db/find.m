function documents = find(obj,collection, varargin)
%FIND Return all the documents that match a find command on a collection
% 
% Input:
%   Our db object
%   collection name
%   (optional) query string
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

p = inputParser();
addParameter(p, 'query', '', @ischar);

p.Parse(varargin{:});
query = p.Resuls.query;

try
    if isempty(query)
        documents = find(obj.connection, collection);
    else
        documents = find(ojb.connection, collection, Query = query);
    end
catch
    documents = [];
end
end

