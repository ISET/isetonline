function [occluded, truncated,bbox2d, segmentation, area] = piAnnotationGet(scene_mesh,index,offset)
% Read the annotation from the COCO data set
%
% NOTE:  Requires the coco api to be installed on your computer
%
% See also
%
%
%{
% To compile the coco code MatlabAPI, do this:

% 1. Download cocoapi from here:
  % https://github.com/cocodataset/cocoapi.git

% 2. Change into the MatlabApi directory and run

  mex('CFLAGS=\$CFLAGS -Wall -std=c99','-largeArrayDims',...
  'private/maskApiMex.c','../common/maskApi.c',...
  '-I../common/','-outdir','private');

%}

%% Check for cocoapi
if ~isa(MaskApi,'MaskApi'), error('cocoapi must be on your path'); end

%% Set up the counters
occluded  = 0;
truncated = 0;
bbox2d    = [];

% No idea
if offset==0
    indicator = (scene_mesh == index);
else
    indicator = ((scene_mesh <= (index+offset)) & (scene_mesh>=(index-offset)));
end

xSpread  = sum(indicator);
xIndices = find(xSpread > 0);
ySpread  = sum(indicator,2);
yIndices = find(ySpread > 0);

if isempty(xIndices) || isempty(yIndices)
    segmentation = [0 1920 0 1080];
else
    bbox2d.xmin = min(xIndices);
    bbox2d.xmax = max(xIndices);
    bbox2d.ymin = min(yIndices);
    bbox2d.ymax = max(yIndices);

    % For now just try and use the Bounding Box as the Segmentation
    segmentation = [bbox2d.xmin bbox2d.xmax bbox2d.ymin bbox2d.ymax];

end

% Set up the bounding box and determine size
w = size(scene_mesh,2);
h = size(scene_mesh,1);


area = w * h;

% Occlusions
ccomp = bwconncomp(indicator);
if ccomp.NumObjects > 1
    occluded = 1;
else
    occluded = 0;
end

% Truncations
if ~isempty(bbox2d)
    if (bbox2d.xmin == 1 || bbox2d.ymin == 1 || ...
            bbox2d.xmax == w || bbox2d.ymax == h)
        truncated = 1;
    else
        truncated = 0;
    end
end

end