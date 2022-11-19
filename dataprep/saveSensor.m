function [status, result] = saveSensor(sensor)
%SAVESENSOR Save a sensor to mongoDB
%   D. Cardinal, Stanford University, November, 2022

% The hard part here is deciding on one or more unique "keys",
% which for mongo are indices. There is always _id, whic we can
% allow to be auto-assigned, or create one
%
% Indices/Keys can be objects, but there are rules for what happens
% when you add more fields, and you can't have duplicate values
% if you make them a unique index/key (makes sense of course)
%
% In our case we start with the metadata slot of a sensor object
% Hard to know if we want to save sensorImage separate from a
% "sensor only" definition of the attributes of the sensor.
%

% Use default dbName
db().store(sensor, 'collection','sensorImage');

