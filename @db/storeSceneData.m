function [status, result] = storeSceneData(obj, sceneData,varargin)
%STORESCENEDDATA Create a DB document of general information for a scene
%   Work in progress for helping keep track of our scenes & related data

% Need code to ensure we have a unique name-key 

p = inputParser;

%addRequired(p, 'itemid'); % Needs to be unique across the collection
addParameter(p, 'collection','scene',@ischar);
addParameter(p, 'update', false); % update existing record

varargin = ieParamFormat(varargin);
p.parse(varargin{:});

useCollection = p.Results.collection;

% Matlab doesn't natively support creating indices and (unique) keys.
% So we probably need to do that via mongosh. We can then try to 
% insert and will just get a failure on any that already exist

% DO we want to have similar unique keys for all Collections? If so,
% then we could automatically set those up when we create them.

% Create collection if needed
try
    obj.connection.createCollection(useCollection);
catch
end




end

