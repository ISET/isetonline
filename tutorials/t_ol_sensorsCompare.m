% Demonstration of how to use our database of images to
% evaluate the effectiveness of two sensors for detecting
% a specific class of closest object

% D. Cardinal, Stanford University, 2023

% First we get a collection of images from our database that
% have a specific class of object as the closest:

% Get a collection of images with a specific class of closest target
ourDB = isetdb(); 
dbTable = 'sensorImages';
filter = 'closestTarget.label';
target = 'truck';
queryString = sprintf("{""closestTarget.label"": ""%s""}", target);
sensorImages = ourDB.docFind(dbTable, queryString);

% Now we can separate by sensor name
% Currently these are the two automotive sensors we have in our database
sensorNames = {'MTV9V024-RGB', 'AR0132AT-RGB'};

for ii = 1:numel(sensorNames)
    perSensorIndex = sensorImages(isequal(sensorname, sensorNames(ii)));
end

%{
Later on stuff:


[ap, precision, recall] = ol_apCompute(sensorImages, 'class','truck');

figure;
plot(recall, precision);
grid on
title(sprintf('Average precision = %.1f', ap))
%}