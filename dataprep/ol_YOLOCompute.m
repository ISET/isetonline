function [annotatedImage, YOLO_Objects] = ol_YOLOCompute(img)
%ol_YOLOCompute Run YOLO object detector on an image
%   Returns annotated image and an array of found objects

% For threading, I think we may need to instantiate a new detector
% each time we are called
ourDetector = [];
%persistent ourDetector;
detectorType = "csp-darknet53-coco"; %"tiny-yolov4-coco";
if isempty(ourDetector)
    ourDetector = yolov4ObjectDetector(detectorType);
end

try
    [bboxes, scores, labels] = detect(ourDetector, img);

    YOLO_Objects.bboxes = bboxes;
    YOLO_Objects.scores = scores;
    YOLO_Objects.labels = labels;

    % now build annotated image to return
    annotatedImage = insertObjectAnnotation(img,'Rectangle',bboxes,labels);

catch
    % sometimes the detector errors. Maybe with a null image?
    YOLO_Objects.bboxes = [];
    YOLO_Objects.scores = [];
    YOLO_Objects.labels = [];
    blankimage = ones(200,200,3);
    blankimage(:,:,3) = 0;
    annotatedImage = blankimage;
end

end

