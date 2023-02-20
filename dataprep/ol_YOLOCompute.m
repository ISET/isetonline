function [annotatedImages, YOLO_Objects] = ol_YOLOCompute(inputImages)
%ol_YOLOCompute Run YOLO object detector on an image(s)
%   Returns annotated image(s) and an array of found objects

persistent ourDetector;
detectorType = "csp-darknet53-coco"; %"tiny-yolov4-coco";
if isempty(ourDetector)
    ourDetector = yolov4ObjectDetector(detectorType);
end

[bboxes, scores, labels] = detect(ourDetector, inputImages);

YOLO_Objects.bboxes = bboxes;
YOLO_Objects.scores = scores;
YOLO_Objects.labels = labels;

% now build annotated image to return
for ii = 1:numel(YOLO_Objects.bboxes)
    annotatedImages(ii) = insertObjectAnnotation(img,'Rectangle', ...
        YOLO_Objects.bboxes(ii), YOLO_Objects.labels(ii));
end

end

