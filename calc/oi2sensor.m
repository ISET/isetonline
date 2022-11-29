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
    options.outputFile = 'custom_image.png';
end

load(options.oiFile, 'oi');

% sensorFile may be a json struct already
if contains(options.sensorFile, '.json')
    sensor = jsonread(options.sensorFile);
else
    sensor = sensorFromFile(options.sensorFile);
end

%% Modify sensor params to try to match what we did in default

% At least for now, scale sensor to match the FOV
hFOV = oiGet(oi,'hfov');
sensor = sensorSetSizeToFOV(sensor,hFOV,oi);

% Default Auto-Exposure breaks with oncoming headlights, etc.
% Experimenting with others
%aeMethod = 'mean';
%aeMean = .5;
aeMethod = 'specular';
aeLevels = .8;
aeTime = autoExposure(oi,sensor, aeLevels, aeMethod);

% generate our modified sensorImage
% which when running on the web we need to put somewhere useful:)

sensorImage = sensorCompute(sensor, oi);

% below is partially to test to see if the app runs, but also might give us
% a useful modified preview

ip = ipCreate('ourIP', sensor);
% For RCCC we need to set the IP differently
if contains(sensor.name, 'RCCC')
    ip.demosaic.method = 'analog rccc'; end

ipImage = ipCompute(ip, sensorImage);

% We use the output file name we've been passed
outputFile = options.outputFile;
ipSaveImage(ipImage, outputFile);

% Consider adding YOLO support here

end

