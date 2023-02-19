function [ap, precision, recall] = ol_apCompute(sensorImages, varargin)
%OL_APCOMPUTE Compute Average Precision for one or more sensorImages

% Extract one or more sensorImages to get GTObjects and YOLO
% Scale & crop YOLO data from sensor size to scene size and aspect ratio

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
target = 'car';
queryString = sprintf("{""closestTarget.label"": ""%s""}", target);
sensorImages = ourDB.docFind(dbTable, queryString);

% Rely on Matlab to do most of the heavy-lifting math
[ap, precision, recall] = ol_apCompute(sensorImages, 'class',target);

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
    error("ol_apCompute requires a class name");
end

% FOR DEBUGGING
%sensorImages = sensorImages(1:10);

% ii is image iterator
% jj is GTObjects iterator
% kk is YOLO  iterator

% clear out old data
ourScoreData = [];
ourLabelData = [];

% filter for distance range if needed
if ~isempty(p.Results.distancerange)
    minIndices = arrayfun(@(x) (x.closestTarget.distance > p.Results.distancerange(1)), sensorImages);
    filteredImages = sensorImages(minIndices);
    maxIndices = arrayfun(@(x) (x.closestTarget.distance < p.Results.distancerange(2)), filteredImages);
    filteredImages = filteredImages(maxIndices);
else
    filteredImages = sensorImages;
end

% Allocate a table to store image detection results, one per row
resultTable = table('Size',[numel(filteredImages) 2],'VariableTypes',{'double','cell'});

GTTable = table('Size', [numel(filteredImages) 2], 'VariableTypes',{'cell', 'cell'});

imgIndex = 0;
Results = {};
for ii = 1:numel(filteredImages)

    % YOLO is in sensor pixels, we need to scale to match scene pixels
    % This routine has been troublesome because of varying aspect ratios
    % in addition to resolution, so a place to look if there are issues
    detectorResults = scaleDetectorResults(filteredImages(ii));

    %fprintf("Processing image %s\n", sensorImages(ii).scenename);
    % cT has label, bbox, distance, name
    GTObjects = filteredImages(ii).closestTarget;
    if  matches(GTObjects(:).label, ourClass) == true
        % we have an image that includes our class
        imgIndex = imgIndex + 1;
    else
        % increments ii, but not imgIndex
        continue
    end

    GTStruct = GTObjects;
    GTBoxes = [];
    GTLabels = {};

    % First process the ground truth objects
    % For singleClass case we only use the closestObject
    for jj = 1:numel(GTObjects)

        % This gets us a 2 x N matrix of boxes
        tmpBox = GTStruct(jj).bbox;
        GTBoxes= [GTBoxes; [tmpBox{:}]]; %#ok<*AGROW> 

        tmpLabel = GTStruct(jj).label;
        % fprintf("jj is: %d\n",jj);
        GTLabels{jj} = tmpLabel;
    end

    % Now we have a matrix of boxes & labels
    GTLabels = transpose(string(GTLabels));

    GTBoxes = double(GTBoxes);
    GTTable{imgIndex,1} = {GTBoxes};
    GTTable{imgIndex,2} = {GTLabels};

    % Now we need to massage our detector results from their DB layout
    % (multiclass needs cells with categoricals, to match Ground Truth)
    % HOWEVER, if we have "found" something with a different class
    %          then the call fails, so we need to weed those out. Sigh.
    %
    % For singleClass we need to find the closest match YOLO object
    % and _only_ compare it. We pick the one with max Overlap

    % Match Label -- returns indices of YOLO results for our class
    maxOverlap = 0; % default

    % Find any YOLO results that match the class we are looking for
    matchingElements = matches(detectorResults.labels, ourClass);

    if numel(matchingElements) == 0
        % This if case can be good for debugging, if there is an issue
        % with the YOLO detectors results
        % We don't have a match at all
        fprintf("No match in image: %s\n", filteredImages(ii).sceneID);
    else

        % Get the bounding boxes and scores for the matching elements
        % using the scaled detector results
        matchingBoxes = detectorResults.bboxes(matchingElements);
        matchingScores = detectorResults.scores(matchingElements);

        % Now pick best fit of the matching elements, by
        % finding the largest overlap we can
        for ll = 1:numel(matchingBoxes)

            % Calculate IoU for ground truth & detected
            tmpOverlap = bboxOverlapRatio(cell2mat(matchingBoxes{ll}), ...
                cell2mat(tmpBox));
            if tmpOverlap > maxOverlap
                try
                    % bestBox and bestScore get the best fit we have
                    bestBox = matchingBoxes{ll};
                    bestScore = matchingScores(ll);
                    maxOverlap = tmpOverlap;
                catch err
                    % failed to parse the box, so no score
                    fprintf("Error %s on boxes\n", err.message);
                end
            end
        end
    end

    % we may have what we need. GTStruct is the closestTarget
    % and bestBox and bestScore are the closest we have

    % We found something
    if maxOverlap > 0
        % Increment the valid image count
        try
            if isequal(class(bestScore), 'double')
                scoreData = {bestScore};
            else
                scoreData = bestScore(1);
            end
            BBoxes(imgIndex) = {cell2mat(bestBox)};
            Results(imgIndex) = scoreData;
        catch
            % pause
            Results(imgIndex) = {[0]};
            BBoxes(imgIndex) = {[]};
        end
    else
        Results(imgIndex) = {[0]};
        % Maybe an empty bbox works, but this one should get a 0 anyway
        BBoxes(imgIndex) = {[]}; % Not sure what to put here?
    end

end

% Builds a box data store now that we have all the GT needed
blds = boxLabelDatastore(GTTable);

% Now build resultTable
Results = transpose(Results);
BBoxes = transpose(BBoxes);

resultTable = table(BBoxes,Results);

useThreshold = .5; % default is .5
[ap,recall,precision] = evaluateDetectionPrecision(resultTable, blds, useThreshold);
end

%% -----------------------------------------------------------
% Start supporting functions here

function detectorResults = scaleDetectorResults(sensorImage)
% We need to scale YOLOData to match ther resolution of the GT Scene
% and the aspect ratio, since the YOLOdata was captured in a sensor image
% that has the sensor resolution and aspect ratio.
ourDB = isetdb();
dbTable = 'sensors';

% Find the sensor so we can get its size
sensorName = sensorImage.sensorname;

queryString = sprintf("{""name"": ""%s""}", sensorName);
sensor = ourDB.docFind(dbTable, queryString);
sceneSize = sensorImage.sceneSize;

detectorResults = sensorImage.YOLOData; % gets bboxes, scores, labels

% Scale to [width height] multiplier
sensorSize = double([sensor.rows sensor.cols]);
% sceneSize is in  rows, columns
scaleRatioVertical = double(sceneSize{1}) / double(sensorSize(1));
scaleRatioHorizontal = double(sceneSize{2}) / double(sensorSize(2));

% Now figure out crop factor adjustment as needed
sensorAspect = double((sensorSize(1) / sensorSize(2)));
sceneAspect = double(sceneSize{1}) / double(sceneSize{2});

% Handle the case where the top and bottom are padded because our sensor
% is "more square" than our 1080p scenes. If we had massively horizontal
% sensors we'd need to do the equivalent for left & right
if sensorAspect > sceneAspect % sensor "taller" than scene
    simSensorHeight = sensorSize(1) * scaleRatioHorizontal;

    % Establish how far to offset the sensor YOLO data so that the top
    % left corner matches (0,0) in the scene ground truth
    vOffset = double(sceneSize{1} - simSensorHeight) / 2;
else
    % should handle the other case eventually
    vOffset = 0;
end

% Scale any and all bounding boxes we have been given
% If we only have one bbox we have to handle it differently, apparently

% Current assumption is that the sensor is more square than the scene, so
% when it captures the OI of the scene, there is banding at top and bottom,
% and that the resulting image needs to be scaled according to the
% horizontal difference in resolution (adjusted for the padding)

% NB This seems to be working well for the MT Auto sensor, but with odd
%    effects for the AP sensor
if numel(detectorResults.scores) == 1
    try
        % bboxes are:
        %columns (from left), rows (from top), width, height
        tmpBoxes{1}{1} = double(detectorResults.bboxes{1}) * scaleRatioHorizontal;
        tmpBoxes{1}{2} = double(detectorResults.bboxes{2}) * scaleRatioHorizontal + vOffset;
        tmpBoxes{1}{3} = double(detectorResults.bboxes{3}) * scaleRatioHorizontal;
        tmpBoxes{1}{4} = double(detectorResults.bboxes{4}) * scaleRatioHorizontal;
        detectorResults.bboxes = tmpBoxes;
    catch err
        fprintf('ERROR: %s\n', err.message);
    end
else
    for qq = 1:numel(detectorResults.bboxes)
        try
            %fprintf("Sensor: %s \n", sensorName)
            %celldisp(detectorResults.bboxes{qq}, "Original")
            detectorResults.bboxes{qq}{1} = double(detectorResults.bboxes{qq}{1}) * scaleRatioHorizontal;
            detectorResults.bboxes{qq}{2} = double(detectorResults.bboxes{qq}{2})  * scaleRatioHorizontal +vOffset;
            detectorResults.bboxes{qq}{3} = double(detectorResults.bboxes{qq}{3}) * scaleRatioHorizontal;
            detectorResults.bboxes{qq}{4} = double(detectorResults.bboxes{qq}{4}) * scaleRatioHorizontal;
            %celldisp(detectorResults.bboxes{qq}, "Scaled")
        catch err
            fprintf('ERROR: %s\n', err.message);
        end
    end
end

end



