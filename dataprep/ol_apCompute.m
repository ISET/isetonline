function [ap, precision, recall] = ol_apCompute(sensorImages, varargin)
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

[ap, precision, recall] = ol_apCompute(sensorImages, 'class','truck');

%}

% D. Cardinal, Stanford University, 2023

p = inputParser();

% If we only want a single class
addParameter(p, 'class', '');

varargin = ieParamFormat(varargin);
p.parse(varargin{:});

if ~isempty(p.Results.class)
    ourClass = p.Results.class;
    singleClass = true;
else
    singleClass = false;
end

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

% Allocate a table to store image detection results, one per row
if singleClass
    resultTable = table('Size',[numel(sensorImages) 2],'VariableTypes',{'cell','cell'});
else
    resultTable = table('Size',[numel(sensorImages) 3],'VariableTypes',{'cell','cell','cell'});
end

GTTable = table('Size', [numel(sensorImages) 2], 'VariableTypes',{'cell', 'cell'});

% number of sensor images that have matching classes
numValid = 0;

resultTable = table();

% ii is image iterator
% numValid is how many images have useful data
% jj is GTObjects iterator
% kk is YOLO  iterator

    % clear out old data
    tmpBoxes = {};
    labelData = [];
    scoreData = {};
    ourScoreData = [];
    ourLabelData = [];


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
        % and _only_ compare it
        % We have bboxes, but not distances, so maybe pick class
        % and highest score?

        % Match Label
        % Pick Smallest Distance
        % Put that element in the all**

        % Match Label
        matchingElements = matches(detectorResults.labels, ourClass);

        % Now pick smallest distance


        allLabelData = detectorResults.labels;
        allScoreData = detectorResults.scores;

        foo = 1; % bogus statement
    else
        allLabelData = detectorResults.labels;
        allScoreData = detectorResults.scores;
    end

    tmpBoxes = [];


    % Assume not valid as we might have no boxes
    imgValid = false;
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

                    imgValid = true;
                catch
                    fprintf("failed processing image %s\n", sensorImages(ii).scenename);
                    imgValid = false;
                    continue;
                end
            end
        end

    % If the image has 1 or more targets worth processing
    % (?? We might miss the case where YOLO detects nothing?)
    if imgValid
        % Increment the valid image count
        numValid = numValid + 1;
        try
            scoreData = ourScoreData(numValid);
            labelData = {ourLabelData(numValid)};
            BBoxes(numValid) = {tmpBoxes};
            Results(numValid) = {transpose(scoreData)};
            Labels(numValid) = transpose(labelData);
        catch
            % pause
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

