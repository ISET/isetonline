function [outputArg1,outputArg2] = olGetGroundTrue(options)
%OLGETGROUNDTRUE Retrieve GT info from rendered scenes
%   D. Cardinal, Stanford University, 12/2022

% Currently needs the _instanceID.exr file, and
%   the instanceid.txt file

% Also assumes we only care about certain classes & know their IDs

arguments
    options.instanceFile = '';
    options.addtionalFile = '';
    % others?
end

%% Categories
catNames = ["person", "deer", "car", "bus", "truck", "bicycle", "motorcycle"];
catIds   = [0, 91, 2, 5, 7, 1, 3];
dataDict = dictionary(catNames, catIds);


instanceData = exrread(options.instanceFile); % DOUBLE CHECK

end

