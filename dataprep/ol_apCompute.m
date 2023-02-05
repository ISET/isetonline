function [ap, precision, recall] = ol_apCompute(GTObjects, detectorResults)
%OL_APCOMPUTE Compute Average Precision for one or more sensorImages

% Start with 1 GT & 1 YOLOv4

% Extract one or more sensorImages to get GTObjects and YOLO
% Example .sceneID: 1112154540
%         .sensorname: MTV9V024-RGB  
%         .GTObjects (Table with entries for each object)
%             Each cell: (.label, .bbox2d, .catId, .distance) 
%         .YOLOData (.bboxes, .scores, .labels) -- arrays of matching size

%{
ourDB = isetdb(); 
dbTable = 'sensorImages';
sceneID = '1112154540';
queryString = sprintf("{""sceneID"": ""%s""}", sceneID);
sensorImages = ourDB.docFind(dbTable, queryString);

GTObjects = sensorImages(:).GTObjects;
YOLOData = sensorImages(:).YOLOData; % gets bboxes, scores, labels

[ap, precision, recall] = ol_apCompute(GTObjects, YOLOData);

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
%{
 WEB EXAMPLE:
boxes = cell(10,2); %number of images x 2=(coordinates of box , labels)
% fill boxes :
for i=1:10
n = randi(3); % number of box in i-th image, it maybe diffrenent so i consider it
boxes{i,1} = rand(n,4); % nx4 each row coordinate of a box
boxes{i,2} = string(randi(2,n,1)); % here i create n label for every image between 2 possible labels
end

% Convert to table
boxes = cell2table(boxes,'VariableNames',{'Boxes','Labels'}); 

blds = boxLabelDatastore(boxes)
%}

boxes = cell(numel(GTObjects, 2));

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
GTBoxes = transpose(GTBoxes);
GTLabels = string(GTLabels);

bboxes = [bboxesCell(:)];
blds = boxLabelDatastore(GTTable);
evaluateDetectionPrecision(YOLOData, blds)
end

