function [status, result] = store(obj, isetObj, options)
%SAVEMONGO Explore saving to mongodb
%   D. Cardinal, Stanford University, 2022

arguments
    obj;
    isetObj;
    options.isetDB;
    options.collection = 'images'; % default collection
end

persistent isetDB; % instance of db class
if ~isempty(obj.connection) && isopen(obj.connection)
    isetDB = obj.connection;
else
    isetDB = db();
end

% need to add update logic & type specific keys and such
insert(obj.connection,options.collection,isetObj);
status = 0;

end

