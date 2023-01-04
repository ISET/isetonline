function [annotatedImage, bboxes, scores, labels] = doGT(img, options)
%DOGT Get Ground Truth for image

arguments
    img = [];
    options.additionalFile = '';
    options.instanceFile = '';
end

GTData = olGetGroundTruth('addtionalFile',options.additionalFile, ...
    'instanceFile',options.instanceFile);

% Currently, GTData has a separate entry for each object
% That is different from our YOLO detector that returns a list of boxes &
% labels, so we convert formats here

% first check to see if we got data back
% not sure why we don't always get something
if ~isempty(GTData)
    bboxes = GTData(1:end).bbox2d;
    labels = GTData(1:end).label;
    scores = ones(size(GTData));

    % now build annotated image to return
    annotatedImage = insertObjectAnnotation(img,'Rectangle',bboxes,labels);
else
    annotatedImage = img;
end
end
