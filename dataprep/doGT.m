function [annotatedImage, bboxes, scores, labels] = doGT(img, varargin)
%DOGT Get Ground Truth for image

p = inputParser;

addParameter(p, 'additionalfile', '', @isfile);
addParameter(p, 'instancefile', '', @isfile);

varargin = ieParamFormat(varargin);
p.parse(varargin{:});

% Make sure we set values for probably un-used results
bboxes = [];
scores = [];

GTData = olGetGroundTruth('addtionalFile',p.Results.additionalfile, ...
    'instanceFile',p.Results.instancefile);

if ~isempty(GTData)
    uniqueObjects = unique({GTData(:).label});
    labels = convertCharsToStrings(uniqueObjects);
else
    labels = [];
end
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
