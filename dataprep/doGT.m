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
% Fix that we're not getting 
if ~isempty(GTData)
    scores = ones(size(GTData));
    annotatedImage = img;
    for ii = 1:numel(GTData)
        % now build annotated image to return
        annotatedImage = insertObjectAnnotation(annotatedImage,'Rectangle', ...
        GTData(ii).bbox2d,GTData(ii).label);
    end
else
    annotatedImage = img;
end
end
