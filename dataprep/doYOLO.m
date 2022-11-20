function [annotatedImage, bboxes, scores, labels] = doYOLO(img)
%DOYOLO Summary of this function goes here
%   Detailed explanation goes here
persistent ourDetector;
detectorType = "tiny-yolov4-coco";
if isempty(ourDetector)
    ourDetector = yolov4ObjectDetector(detectorType);
end

[bboxes, scores, labels] = detect(ourDetector, img);

% now build annotated image to return
annotatedImage = insertObjectAnnotation(img,'Rectangle',bboxes,labels);

end

