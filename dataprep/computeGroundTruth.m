function [annotatedImage, GTObjects] = computeGroundTruth(scene, img, varargin)
%%computeGroundTruth Get Ground Truth for image
% Relies on COCO-style annotation files, as used currently in ISETAuto
% Returns both Ground Truth Data and a labeled version of the input image

p = inputParser;

addParameter(p, 'additionalfile', '', @isfile);
addParameter(p, 'instancefile', '', @isfile);

varargin = ieParamFormat(varargin);
p.parse(varargin{:});

% Make sure we set default empty values
bboxes = [];
scores = [];
labels = [];
distances = [];

GTObjects = olGetGroundTruth(scene, 'additionalFile',p.Results.additionalfile, ...
    'instanceFile',p.Results.instancefile);

% Currently, GTObjects has a separate entry for each object
% That is different from our YOLO detector that returns a list of boxes &
% labels, so we convert formats here

% first check to see if we got data back
% and if so, annotate our image 
if ~isempty(GTObjects)
    annotatedImage = img;
    for ii = 1:numel(GTObjects)
        % now build annotated image to return
        annotatedImage = insertObjectAnnotation(annotatedImage,'Rectangle', ...
        GTObjects(ii).bbox2d,GTObjects(ii).label);
    end
else
    annotatedImage = img;
end
end
