function [ap, precision, recall] = ol_apCompute(sensorImages)
%OL_APCOMPUTE Compute Average Precision for one or more sensorImages

% Start with 1 GT & 1 YOLOv4

% Extract one or more sensorImages to get GTObjects and YOLO
% Example .sceneID: 1112154540
%         .sensorname: MTV9V024-RGB  
%         .GTObjects (Table with entries for each object)
%             Each cell: (.label, .bbox2d, .catId, .distance) 
%         .YOLOData (.bboxes, .scores, .labels) -- arrays of matching size

% I think we have an issue where the YOLOData is scaled to the sensor size,
% while the GTData is scaled to the scene size.

% Either we need to rescale YOLOData when we record it, or on the fly 
% When we need to use it to calculate AP, etc.

%{
% Test code:
ourDB = isetdb(); 
dbTable = 'sensorImages';
sceneID = '1112154540';
queryString = sprintf("{""sceneID"": ""%s""}", sceneID);
sensorImages = ourDB.docFind(dbTable, queryString);

[ap, precision, recall] = ol_apCompute(sensorImages);

%}

% Example call from docs:
%         [ap, recall, precision] = evaluateDetectionPrecision(results, blds);
%         results might be .YOLOData since we got it from a detector?
%
%         We need to create a BoxLabelDataStore from the GTObjects
%

% Need to massage GT into 1 row for each image
%  Col 1 is array of boxes
%  Col 2 is array of labels
% 

GTObjects = sensorImages(:).GTObjects;
sceneSize = sensorImages(:).sceneSize;
detectorResults = sensorImages(:).YOLOData;

% We need to scale YOLOData to match ther resolution of the GT Scene

ourDB = isetdb(); 
dbTable = 'sensors';

% Find the sensor so we can get its size
sensorName = sensorImages(1).sensorname;

queryString = sprintf("{""name"": ""%s""}", sensorName);
sensor = ourDB.docFind(dbTable, queryString);

unscaledDetectorResults = sensorImages(1).YOLOData; % gets bboxes, scores, labels
sensorSize = [sensor.rows sensor.cols];

scaleRatio = [single(sceneSize{1}) / single(sensorSize(1)), single(sceneSize{2}) / single(sensorSize(2))];
for qq = 1:numel(unscaledDetectorResults.bboxes)
    s{1} = unscaledDetectorResults.bboxes{qq}{1} * scaleRatio(1);
    s{2} = unscaledDetectorResults.bboxes{qq}{2} * scaleRatio(2);
    s{3} = unscaledDetectorResults.bboxes{qq}{3} * scaleRatio(1);
    s{4} = unscaledDetectorResults.bboxes{qq}{4} * scaleRatio(2);
    detectorResults(qq).bboxes = s;
end

GTStruct = [GTObjects{:}];
GTBoxes = [];
GTLabels = {};
for jj = 1:numel(GTObjects)

    % This gets us a 2 x N matrix of boxes
    tmpBox = GTStruct(jj).bbox2d;
    GTBoxes= [GTBoxes; [tmpBox{:}]];

    tmpLabel = GTStruct(jj).label;
    % fprintf("jj is: %d\n",jj);
    GTLabels{jj} = tmpLabel;
end

% Now we have a matrix of boxes & labels
GTBoxes = GTBoxes;
GTLabels = transpose(string(GTLabels));

GTTable = table({GTBoxes}, {GTLabels});
blds = boxLabelDatastore(GTTable);

tmpBoxes = {};
% Now we need to massage our detector results from their DB layout
% need cells with categoricals, to match Ground Truth
% HOWEVER, if we have "found" something with a different class
%          then the call fails, so we need to weed those out. Sigh.
allLabelData = detectorResults.labels;
allScoreData = detectorResults.scores;
numValid = 0;

% We may have an issue where the bboxes from the detector don't match
% the scale of the GT image (sigh). 
for kk = 1:numel(detectorResults)
    % First check to see if valid
    if max(matches(allLabelData{kk}, GTLabels)) == 0 % non-matched class
        % do nothing
    else % okay to process
        numValid = numValid + 1;
        tmpBoxes = [tmpBoxes cell2mat(detectorResults.bboxes{kk})];  %#ok<*AGROW> 
        labelData{numValid} = categorical(cellstr(allLabelData{kk}));
        scoreData{numValid} = allScoreData{kk};
    end
end

resultTable = table(transpose(tmpBoxes), ...
    transpose(scoreData), transpose(labelData));
[ap,recall,precision] = evaluateDetectionPrecision(resultTable, blds);
end

