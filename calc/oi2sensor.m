function [outputFile] = oi2sensor(options)
%function [outputFile] = oi2sensor(oiFile, sensorFile)
%OI2SENSOR Accept an OI file, a sensor file, and output the sensor image
% D. Cardinal, B. Wandell, Zhenyi Liu, Stanford University, 2022

% This version is designed so it can be compiled into a standalone
% application for use with an online gateway to ISET functionality
% As a result, it takes full file names to either .mat or .json files
% and returns one as well.

%
% oiFiles is (for now) the data file(s) for an Optical Image
% sensorFile is (for now) the data file for the desired sensor
%

% Should test for oiFiles as some type of array here
arguments
    options.oiFiles = 'sampleoi.mat';
    options.sensorFile = 'ar0132atSensorRGB.mat';
end

load(options.oiFiles, 'oi');
sensor = sensorFromFile(options.sensorFile);

sensorImage = sensorCompute(sensor, oi);

ip = ipCreate();
ipImage = ipCompute(ip, sensorImage);

% ipWindow(ipImage);
outputFile = ipSaveImage(ipImage, 'sensorRGB.png');

end

