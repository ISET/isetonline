function [bboxes, scores, labels] = doYOLO(img)
%DOYOLO Summary of this function goes here
%   Detailed explanation goes here
persistent ourDetector;
detectorType = "tiny-yolov4-coco";
if isempty(ourDetector)
    ourDetector = yolov4ObjectDetector(detectorType);
end

[bboxes, scores, labels] = ourDetector.detect(img);

end

