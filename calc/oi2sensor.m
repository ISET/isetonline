function [outputFile] = oi2sensor(options)
%function [outputFile] = oi2sensor(oiFile, sensorFile)
%OI2SENSOR Accept an OI file, a sensor file, and output the sensor image
% D. Cardinal, B. Wandell, Zhenyi Liu, Stanford University, 2022

% This version is designed so it can be compiled into a standalone
% application for use with an online gateway to ISET functionality
% As a result, it takes full file names to either .mat or .json files
% and returns one as well.

% Parameters:

% 'oiFiles' is (for now) the data file(s) for an Optical Image
% 'sensorFile' is (for now) the data file for the desired sensor
% 'exposure time' is the desired shutter speed for the compute
%

% other options would be changed parameters to the sensor file
% _unless_ those are already written in to a modified sensor file?
%

% Should test for oiFiles as some type of array here
arguments
    options.oiFile = 'sampleoi.mat';
    options.sensorFile = 'ar0132atSensorRGB.mat';
    options.exposuretime = [];
end

load(options.oiFile, 'oi');
sensor = sensorFromFile(options.sensorFile);

% Modify shutter open time if the user asks
if ~isempty(options.exposuretime)
    sensor = sensorSet(sensor,'exposure time', options.exposuretime);
end

% generate our modified sensorImage
% which when running on the web we need to put somewhere useful:)

sensorImage = sensorCompute(sensor, oi);

% below is partially to test to see if the app runs, but also might give us
% a useful modified preview

ip = ipCreate();
ipImage = ipCompute(ip, sensorImage);

% ipWindow(ipImage);
outputFile = ipSaveImage(ipImage, 'sensorRGB.png');

end

