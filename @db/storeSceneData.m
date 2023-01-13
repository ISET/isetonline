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

% Create collection if needed
try
    obj.connection.createCollection(useCollection);
catch
end




end

