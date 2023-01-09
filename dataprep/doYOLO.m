function [annotatedImage, YOLO_Objects] = doYOLO(img)
%DOYOLO Run YOLO object detector on an image
%   Returns annotated image and an array of found objects

persistent ourDetector;
detectorType = "csp-darknet53-coco"; %"tiny-yolov4-coco";
if isempty(ourDetector)
    ourDetector = yolov4ObjectDetector(detectorType);
end

[bboxes, scores, labels] = detect(ourDetector, img);

YOLO_Objects.bboxes = bboxes;
YOLO_Objects.scores = scores;
YOLO_Objects.labels = labels;

% now build annotated image to return
annotatedImage = insertObjectAnnotation(img,'Rectangle',bboxes,labels);

end

