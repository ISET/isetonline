function [outputFile] = oi2sensor(options)
%function [outputFile] = oi2sensor(oiFile, sensorFile)
%OI2SENSOR Accept an OI file, a sensor file, and output the sensor image
% D. Cardinal, B. Wandell, Zhenyi Liu, Stanford University, 2022

% This version is designed so it can be compiled into a standalone
% application for use with an online gateway to ISET functionality
% As a result, it takes full file names to either .mat or .json files
% and returns one as well.

% Parameters:

% 'oiFile' is the data file for an Optical Image
% 'sensorFile' is the .json data file for the desired sensor & settings
% 'outputFile' is where the computed data should be stored
% TBD: Other bits of output, like an RGB version for viewing?
%

% ISSUE: What can we pass as params? Can we string together
%        kind of a varargin() with keywords, or do we need 
%        to make everything positional on the command line
%        Maybe there is a magic parameter "bundle" we can create?

arguments
    options.oiFile = 'sampleoi.mat';
    options.sensorFile = 'ar0132atSensorRGB.mat';
    options.outputFile = '';
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
% can we return a filename on the web, or do we need to have a fixed output?
outputFile = ipSaveImage(ipImage, 'sensorRGB.png');

end

