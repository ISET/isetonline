function [GTData] = olGetGroundTruth(varargin)
%OLGETGROUNDTRUE Retrieve GT info from rendered scenes
%   D. Cardinal, Stanford University, 12/2022

% Currently needs the _instanceID.exr file, and
%   the instanceid.txt file
%   (the dataset param file would be nice, but hopefully we
%    can get that data included in our .mat file

% Also assumes we only care about certain classes & know their IDs

% instanceFile is the EXR file with instanceId channel
%   that has a map of object instances to pixels
% additionalFile is a text file with the list of objects in the scene

% TBD: Allow passing in of depthmap, so we can compare to instance map
%      and get a depth number for each object of interest

p = inputParser;
addParameter(p,'instanceFile','',@ischar);
addParameter(p,'addtionalFile','',@ischar);
addParameter(p,'offset',0,@isnumeric); 

p.parse(varargin{:});

options = p.Results;


GTData = []; % make sure we return a value

%% Categories that we support currently (out of the 80 or so total)
%    One reason not to support them all is some like tree & rock
%    would "just get in the way"

catNames = ["person", "deer", "car", "bus", "truck", "bicycle", "motorcycle"];
catIds   = [0, 91, 2, 5, 7, 1, 3];
dataDict = dictionary(catNames, catIds);

instanceMap = piReadEXR(options.instanceFile, 'data type','instanceId');

%% Read in our entire list of rendered objects
% First four lines are text metadata, so clip to start at line 5
objectslist = readlines(options.addtionalFile);
objectslist = objectslist(5:end);

%% Iterate on objects, filtering for the ones we want
%  and then building annotations

% Some objects won't be written out, so start an index
objectIndex = 1;
for ii = 1:numel(objectslist)

    name = objectslist{ii};
    % get rid of text we don't want
    name = erase(name,{'ObjectInstance ', '"', '_m'});
    %     fprintf(seg_FID, '%d %s \n',ii, name);

    % These are category tweaks from Zhenyi
    % I don't know if they are to correct past issues or are still needed
    if contains(lower(name), {'car'})
        label = 'car';
        catId = dataDict('car');
    elseif contains(lower(name),'deer')
        label = 'deer';
        catId = dataDict('deer');
    elseif contains(lower(name),['person','pedestrian'])
        label = 'person';
        catId = dataDict('person');
    elseif contains(lower(name), 'bus')
        label = 'bus';
        catId = dataDict('bus');
    elseif contains(lower(name), 'truck')
        label = 'truck';
        catId = dataDict('truck');
    elseif contains(lower(name), ['bicycle','bike'])
        label = 'bicycle';
        catId = dataDict('bicycle');
        % is it really motorbicycle??
    elseif contains(lower(name), ['motorcycle','motorbike'])
        label = 'motorcycle';
        catId = dataDict('motorcycle');
    else % We can add other categories here as needed
        continue;
    end
    
    [occluded, ~, bbox2d, segmentation, area] = piAnnotationGet(instanceMap,ii,options.offset);
    if isempty(bbox2d), continue;end % no location

    % Convert bbox format as needed (x, y, width, height)
    pos = [bbox2d.xmin bbox2d.ymin ...
        bbox2d.xmax-bbox2d.xmin ...
        bbox2d.ymax-bbox2d.ymin];

    % check for minimum and maximum object size
    if pos(3)<10 || pos(4)<10
        continue
    end
    if pos(4)>500 && pos(3)>960
        continue
    end
    if area <= 0 % Not sure how this can happen if we have height & width
        continue
    end

    % Build our return JSON structure
    % detector version returns: annotated_images, bboxes, scores
    % but we have different info, of course
    GTData(objectIndex).label = label;
    GTData(objectIndex).bbox2d = pos;
    GTData(objectIndex).catId = catId;

    objectIndex = objectIndex + 1;

    %{
    % This is the COCO generation code from Zhenyi's original
    annotations{nBox} = struct('segmentation',[segmentation],'area',area,'iscrowd',0,...
        'image_id',str2double(imageID),'bbox',pos,'category_id',catId,'id',0,'ignore',0);
    fprintf('Class %s, instanceID: %d \n', label, ii);
    nBox = nBox+1;
    %}

end


end


