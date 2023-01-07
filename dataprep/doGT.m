function [annotatedImage, bboxes, scores, labels] = doGT(img, varargin)
%DOGT Get Ground Truth for image

% Can we have a function that processes the options argument so that
% the strings (e.g., 'additionalFile') could also be sent in as
% 'additional File' or 'additional file'.  THis would be like
%
%   varargin = ieParamFormat(varargin);
%
% Type checking.  BW needs education on that.

% Can we have a function that processes the options argument so that
% the strings (e.g., 'additionalFile') could also be sent in as
% 'additional File' or 'additional file'.  THis would be like
%
%   varargin = ieParamFormat(varargin);
%
% Type checking.  BW needs education on that.

p = inputParser;

addParameter(p, 'additionalFile', '', @isfile);
addParameter(p, 'instanceFile', '', @isfile);

p.parse(varargin{:});

options = p.Results;


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
