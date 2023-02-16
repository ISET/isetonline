function [ap, precision, recall] = ol_apCompute(sensorImages, varargin)
%OL_APCOMPUTE Compute Average Precision for one or more sensorImages

% Extract one or more sensorImages to get GTObjects and YOLO
% Example .sceneID: 1112154540
%         .sensorname: MTV9V024-RGB
%         .GTObjects (Table with entries for each object)
%             Each cell: (.label, .bbox2d, .catId, .distance)
%         .YOLOData (.bboxes, .scores, .labels) -- arrays of matching size

% The case we've tested is filtering for the class of the closest target
% in the image ground truth. We then compare that to the bounding box
% images of the same class that our found by our detector (currently
% YOLOv4). If there are none or there is no overlap, we score it as a 0.

% Otherwise we calculate IoU and compare it to a threshold.
% When finished you can use the ploting code below to plot precision and
% recall and show the Average Precision for that class.

%{
% Test code:
ourDB = isetdb(); 
dbTable = 'sensorImages';
filter = 'closestTarget.label';
target = 'truck';
queryString = sprintf("{""closestTarget.label"": ""%s""}", target);
sensorImages = ourDB.docFind(dbTable, queryString);

% for debugging we can limit how many images to save time
sensorImages = sensorImages(1:4);

% Rely on Matlab to do most of the heavy-lifting math
[ap, precision, recall] = ol_apCompute(sensorImages, 'class','truck');

% Visualize the results
figure;
plot(recall, precision);
grid on
title(sprintf('AP for class %s = %.1f', target, ap))

%}

% D. Cardinal, Stanford University, 2023

p = inputParser();

% If we only want a single class
addParameter(p, 'class', '');
addParameter(p, 'distancerange', []);

varargin = ieParamFormat(varargin);
p.parse(varargin{:});

if ~isempty(p.Results.class)
    ourClass = p.Results.class;
    singleClass = true;
else
    singleClass = false;
end

% FOR DEBUGGING
%sensorImages = sensorImages(1:10);

% Allocate a table to store image detection results, one per row
if singleClass
    resultTable = table('Size',[numel(sensorImages) 2],'VariableTypes',{'cell','cell'});
else
    resultTable = table('Size',[numel(sensorImages) 3],'VariableTypes',{'cell','cell','cell'});
end

% ii is image iterator
% jj is GTObjects iterator
% kk is YOLO  iterator

% clear out old data
ourScoreData = [];
ourLabelData = [];

% filter for distance range if needed
if ~isempty(p.Results.distancerange)
    filteredImages = arrayfun(@(x) (x.closestTarget.distance > p.Results.distancerange(1)), sensorImages);
    filteredImages = arrayfun(@(x) (x.closestTarget.distance < p.Results.distancerange(2)), filteredImages);    
else
    filteredImages = sensorImages;
end

for ii = 1:numel(filteredImages)

    % YOLO is in sensor pixels, we need to scale to match scene pixels
    detectorResults = scaleDetectorResults(filteredImages(ii));

    %fprintf("Processing image %s\n", sensorImages(ii).scenename);
    if singleClass
        % cT has label, bbox, distance, name
        GTObjects = filteredImages(ii).closestTarget;
    else
        % GTO has rows of: label, bbox2d, catID, distance
        GTObjects = filteredImages(ii).GTObjects;
    end

    if singleClass
        GTStruct = GTObjects;
    else
        GTStruct = [GTObjects{:}];
    end
    GTBoxes = [];
    GTLabels = {};

    % First process the ground truth objects
    % For singleClass case we only use the closestObject
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
    if ~singleClass
        GTTable(ii,1) = {GTBoxes};
        GTTable(ii,2) = {GTLabels};
    else
        GTTable{ii,1} = {GTBoxes};
        GTTable{ii,2} = {GTLabels};
    end

    % Now we need to massage our detector results from their DB layout
    % (multiclass needs cells with categoricals, to match Ground Truth)
    % HOWEVER, if we have "found" something with a different class
    %          then the call fails, so we need to weed those out. Sigh.
    %

    if singleClass
        % For singleClass we need to find the closest match YOLO object
        % and _only_ compare it. We pick the one with max Overlap

        % Match Label -- returns indices of YOLO results for our class
        matchingElements = matches(detectorResults.labels, ourClass);
        matchingBoxes = detectorResults.bboxes(matchingElements);
        matchingScores = detectorResults.scores(matchingElements);

        % Now pick best fit of the matching elements
        maxOverlap = 0; % default

        for ll = 1:numel(matchingBoxes)
            tmpOverlap = max(bboxOverlapRatio(cell2mat(matchingBoxes{ll}), ...
                cell2mat(tmpBox)));
            if tmpOverlap > maxOverlap
                maxOverlap = tmpOverlap;

                try
                % bestBox and bestScore get the best fit we have
                bestBox = matchingBoxes{ll};
                bestScore = matchingScores(ll);
                catch err
                    fprintf("Error %s on boxes\n", err.message);
                end
            end
        end

        % Now we have the best fit bounding box

    else
        % we need to work harder to do calcs: TBD!
        allLabelData = detectorResults.labels;
        allScoreData = detectorResults.scores;
    end

    tmpBoxes = [];


    % Assume valid unless we have cases to throw it away
    imgValid = true;
    numValid = ii;
    if singleClass
        % we may have what we need. GTStruct is the closestTarget
        % and bestBox and bestScore are the closest we have

        %if ~isempty(GTStruct)
        %    imgValid = true;
        %    numValid = numValid + 1;
        %end
        
        % We found something
        if maxOverlap > 0
            % Increment the valid image count
            try
                scoreData = bestScore;
                BBoxes(numValid) = {cell2mat(bestBox)};
                Results(numValid) = transpose(scoreData);
            catch
                % pause
                Results(numValid) = {[0]};
            end
        else
            Results(numValid) = {[0]};
            % Maybe an empty bbox works, but this one should get a 0 anyway
            BBoxes(numValid) = {[1 1 1 1]}; % Not sure what to put here?
        end
    else
        if ~isequal(class(allLabelData),'cell')
            allLabelData = {allLabelData}; % make into a cell
        end

        for kk = 1:numel(allLabelData)

            if max(matches(allLabelData{kk}, GTLabels)) == 0 % non-matched class
                % do nothing

            else % okay to process
                try
                    tmpBoxes = [tmpBoxes; cell2mat(detectorResults.bboxes{kk})];
                    % We want score & label to be cell arrays, like boxes
                    ourScoreData = [ourScoreData allScoreData{kk}]; %#ok<*AGROW>
                    ourLabelData = [ourLabelData; cellstr(allLabelData{kk})];

                    %imgValid = true;
                catch
                    fprintf("failed processing image %s\n", sensorImages(ii).scenename);
                    %imgValid = false;
                    % This is an issue as we've already added the GT to the
                    % blds?
                    continue;
                end
            end
        end
        % If the image has 1 or more targets worth processing
        % (?? We might miss the case where YOLO detects nothing?)
        if imgValid
            % We're now assuming all valid, so no need to increment here
            % Increment the valid image count
            % numValid = numValid + 1;
            try
                scoreData = ourScoreData(numValid);
                labelData = {ourLabelData(numValid)};
                BBoxes(numValid) = {tmpBoxes};
                if empty(scoreData)
                    Results(numValid) = {[0]};
                else
                    Results(numValid) = {transpose(scoreData)};
                end
                Labels(numValid) = transpose(labelData);
            catch
                % pause
            end
        end
    end

end

% Builds a box data store now that we have all the GT needed
blds = boxLabelDatastore(GTTable);

% Now build resultTable
Results = transpose(Results);
BBoxes = transpose(BBoxes);

if singleClass
    resultTable = table(BBoxes,Results);
else
    resultTable = table(BBoxes,Results,Labels);
end

useThreshold = .5; % default is .5
[ap,recall,precision] = evaluateDetectionPrecision(resultTable, blds, useThreshold);
end

%% -----------------------------------------------------------
% Start supporting functions here

function detectorResults = scaleDetectorResults(sensorImage)
% We need to scale YOLOData to match ther resolution of the GT Scene
ourDB = isetdb();
dbTable = 'sensors';

% Find the sensor so we can get its size
sensorName = sensorImage.sensorname;

queryString = sprintf("{""name"": ""%s""}", sensorName);
sensor = ourDB.docFind(dbTable, queryString);
sceneSize = sensorImage.sceneSize;

detectorResults = sensorImage.YOLOData; % gets bboxes, scores, labels

sensorSize = [sensor.rows sensor.cols];

scaleRatio = [double(sceneSize{1}) / double(sensorSize(1)), double(sceneSize{2}) / double(sensorSize(2))];

% If we only have one bbox we have to handle it differently, apparently
if numel(detectorResults.scores) == 1
    try
        tmpBoxes{1}{1} = double(detectorResults.bboxes{1}) * scaleRatio(2);
        tmpBoxes{1}{2} = double(detectorResults.bboxes{2}) * scaleRatio(1);
        tmpBoxes{1}{3} = double(detectorResults.bboxes{3}) * scaleRatio(2);
        tmpBoxes{1}{4} = double(detectorResults.bboxes{4}) * scaleRatio(2);
        detectorResults.bboxes = tmpBoxes;
    catch err
        fprintf('ERROR: %s\n', err.message);
    end
else
    for qq = 1:numel(detectorResults.bboxes)
        try
            detectorResults.bboxes{qq}{1} = double(detectorResults.bboxes{qq}{1}) * scaleRatio(2);
            detectorResults.bboxes{qq}{2} = double(detectorResults.bboxes{qq}{2}) * scaleRatio(1);
            detectorResults.bboxes{qq}{3} = double(detectorResults.bboxes{qq}{3}) * scaleRatio(2);
            detectorResults.bboxes{qq}{4} = double(detectorResults.bboxes{qq}{4}) * scaleRatio(2);
        catch err
            fprintf('ERROR: %s\n', err.message);
        end
    end
end

end



