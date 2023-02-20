function [annotatedImages, YOLO_Objects] = ol_YOLOCompute(inputImages)
%ol_YOLOCompute Run YOLO object detector on an image(s)
%   Returns annotated image(s) and an array of found objects

persistent ourDetector;
detectorType = "csp-darknet53-coco"; %"tiny-yolov4-coco";
if isempty(ourDetector)
    ourDetector = yolov4ObjectDetector(detectorType);
end

[bboxes, scores, labels] = detect(ourDetector, cell2mat(inputImages));

YOLO_Objects.bboxes = bboxes;
YOLO_Objects.scores = scores;
YOLO_Objects.labels = labels;

annotatedImages = {};
% now build annotated image to return
for ii = 1:numel(YOLO_Objects)
    try
    annotatedImage = insertObjectAnnotation(inputImages{ii},'Rectangle', ...
        YOLO_Objects(ii).bboxes, YOLO_Objects(ii).labels);
    annotatedImages{ii} = annotatedImage;
    catch
        fprintf('No YOLO data found to annotate');
        annotatedImages{ii} = inputImages{ii};
    end
end

end

