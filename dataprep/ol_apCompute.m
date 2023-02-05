function [ap, precision, recall] = ol_apCompute(GTObjects, detectorResults)
%OL_APCOMPUTE Compute Average Precision for one or more sensorImages

% Start with 1 GT & 1 YOLOv4

% Extract one or more sensorImages to get GTObjects and YOLO
% Example .sceneID: 1112154540
%         .sensorname: MTV9V024-RGB  
%         .GTObjects (Table with entries for each object)
%             Each cell: (.label, .bbox2d, .catId, .distance) 
%         .YOLOData (.bboxes, .scores, .labels) -- arrays of matching size

% Example call from docs:
%         [ap, recall, precision] = evaluateDetectionPrecision(results, blds);
%         results might be .YOLOData since we got it from a detector?
%
%         We need to create a BoxLabelDataStore from the GTObjects
%

end

