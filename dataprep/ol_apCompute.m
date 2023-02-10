function [ap, precision, recall] = ol_apCompute(sensorImages)
%OL_APCOMPUTE Compute Average Precision for one or more sensorImages

% Extract one or more sensorImages to get GTObjects and YOLO
% Example .sceneID: 1112154540
%         .sensorname: MTV9V024-RGB
%         .GTObjects (Table with entries for each object)
%             Each cell: (.label, .bbox2d, .catId, .distance)
%         .YOLOData (.bboxes, .scores, .labels) -- arrays of matching size

%{
% Test code:
ourDB = isetdb(); 
dbTable = 'sensorImages';
filter = 'closestTarget.label';
target = 'truck';
queryString = sprintf("{""closestTarget.label"": ""%s""}", target);
sensorImages = ourDB.docFind(dbTable, queryString);

[ap, precision, recall] = ol_apCompute(sensorImages);

%}

% D. Cardinal, Stanford University, 2023


%{
% We MAY need to scale YOLOData to match ther resolution of the GT Scene
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

%}

% Start with detecting a single class for now
singleClass = true;

% Allocate a table to store image detection results, one per row
if singleClass
    resultTable = table('Size',[numel(sensorImages) 2],'VariableTypes',{'cell','cell'});
else
    resultTable = table('Size',[numel(sensorImages) 3],'VariableTypes',{'cell','cell','cell'});
end

GTTable = table('Size', [numel(sensorImages) 2], 'VariableTypes',{'cell', 'cell'});

% number of sensor images that have matching classes
numValid = 0;

for ii = 1:numel(sensorImages)

    fprintf("Processing image %s\n", sensorImages(ii).scenename);
    if singleClass
        % cT has label, bbox, distance, name
        GTObjects = sensorImages(ii).closestTarget;
    else
        % GTO has rows of: label, bbox2d, catID, distance
        GTObjects = sensorImages(ii).GTObjects;
    end

    sceneSize = sensorImages(ii).sceneSize;
    detectorResults = sensorImages(ii).YOLOData;

    GTStruct = [GTObjects{:}];
    GTBoxes = [];
    GTLabels = {};
    for jj = 1:numel(GTObjects)

        % This gets us a 2 x N matrix of boxes
        if singleClass
            tmpBox = GTStruct(jj).bbox;
        else
            tmpBox = GTStruct(jj).bbox2d;
        end
        GTBoxes= [GTBoxes; [tmpBox{:}]];

        tmpLabel = GTStruct(jj).label;
        % fprintf("jj is: %d\n",jj);
        GTLabels{jj} = tmpLabel;
    end

    % Now we have a matrix of boxes & labels
    GTLabels = transpose(string(GTLabels));
    GTBoxes = double(GTBoxes);

    GTTable(ii,1) = {GTBoxes};
    GTTable(ii,2) = {GTLabels};

    % Now we need to massage our detector results from their DB layout
    % need cells with categoricals, to match Ground Truth
    % HOWEVER, if we have "found" something with a different class
    %          then the call fails, so we need to weed those out. Sigh.
    allLabelData = detectorResults.labels;
    allScoreData = detectorResults.scores;

    % clear out old data
    tmpBoxes = {};
    labelData = [];
    scoreData = {};

    % Assume not valid as we might have no boxes
    imgValid = false;
    if ~isequal(class(allLabelData),'cell')
        allLabelData = {allLabelData}; % make into a cell
    end
        scoreData{numValid+1} = {};
        ourScoreData = {};
        ourLabelData = [];
        for kk = 1:numel(allLabelData)

            if max(matches(allLabelData{kk}, GTLabels)) == 0 % non-matched class
                % do nothing

            else % okay to process
                try
                    tmpBoxes = [tmpBoxes; cell2mat(detectorResults.bboxes{kk})];
                    % We want score & label to be cell arrays, like boxes
                    ourScoreData = [ourScoreData allScoreData{kk}]; %#ok<*AGROW> 
                    ourLabelData = [ourLabelData; cellstr(allLabelData{kk})];

                    numValid = numValid + 1;
                    imgValid = true;
                catch
                    fprintf("failed processing image %s\n", sensorImages(ii).scenename);
                    imgValid = false;
                    continue;
                end
            end
        end
    if imgValid
        try
            scoreData = ourScoreData(numValid);
            labelData = {ourLabelData(numValid)};
            resultTable(ii,1) = {tmpBoxes};
            resultTable(ii,2) = {transpose(scoreData)};
            tmpLabel = transpose(labelData);
            resultTable(ii,3) = tmpLabel;
        catch
            % pause
        end
    end
end

% Buils a box data store now that we have all the GT needed
blds = boxLabelDatastore(GTTable);

useThreshold = .5; % default is .5
[ap,recall,precision] = evaluateDetectionPrecision(resultTable, blds, useThreshold);
end

