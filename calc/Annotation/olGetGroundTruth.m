function [GTObjects, closestTarget] = olGetGroundTruth(scene, varargin)
%OLGETGROUNDTRUTH Retrieve GT info from rendered scenes
% Or from EXR renders that have enough information
%   D. Cardinal, Stanford University, 12/2022

% Currently needs the _instanceID.exr file, and
%   the instanceid.txt file
%   (the dataset param file would be nice, but hopefully we
%    can get that data included in our .mat file

% Also assumes we only care about certain classes & know their IDs

% instanceFile is the EXR file with instanceId channel
%   that has a map of object instances to pixels
% additionalFile is a text file with the list of objects in the scene

p = inputParser;
addParameter(p,'instanceFile','',@ischar);
addParameter(p,'additionalFile','',@ischar);
addParameter(p,'offset',0,@isnumeric); 

p.parse(varargin{:});

options = p.Results;

GTObjects = []; % make sure we return a value

%% Set Categories that we support currently (out of the 80 or so total)
%    One reason not to support them all is some like tree & rock
%    would "just get in the way"
catNames = ["person", "deer", "car", "bus", "truck", "bicycle", "motorbike"];
% These categories are 1 less than in the paper, but maybe
% that is how they've been coded in the Blender exported scenes?
% paper catIDs
catIDs   = [0, 91, 2, 5, 7, 1, 3];
dataDict = dictionary(catNames, catIDs);

instanceMap = piReadEXR(options.instanceFile, 'data type','instanceId');

%% Read in our entire list of rendered objects
% First four lines are text metadata, so clip to start at line 5
headerLines = 4;
objectslist = readlines(options.additionalFile);
objectslist = objectslist((headerLines+1):end);

% We want to calculate the closest target for use with AP calculation
closestTarget.label = '';
closestTarget.distance = 1000000;
closestTarget.bbox = [];

%% Iterate on objects, filtering for the ones we want
%  and then building annotations


% Calculate this once to save time
imageEXR = replace(options.instanceFile,'instanceID','skymap');
% try reading all depth channels at once
useDepthMap = piReadEXR(imageEXR, 'dataType','alldepth');

% For objects that we actually want
foundObjects = 0;
% Allow an offset for headerlines
for ii = 1:numel(objectslist)

    name = objectslist{ii};
    % get rid of text we don't want
    name = erase(name,{'ObjectInstance ', '"', '_m'});
    %     fprintf(seg_FID, '%d %s \n',ii, name);
    numPlusName = split(name, ' ');

    if numel(numPlusName) <2
        continue;
    end
    objectIndex = str2num(numPlusName{1});
    objectName = numPlusName{2};
    % Consolidate some categories, as needed
    % fprintf("Found: %s\n", name);
    if contains(lower(objectName), {'car'})
        label = 'car';
        catId = dataDict('car');
    elseif contains(lower(objectName),'deer')
        label = 'deer';
        catId = dataDict('deer');
    elseif contains(lower(objectName),{'person','pedestrian'})
        label = 'person';
        catId = dataDict('person');
    elseif contains(lower(objectName), 'bus')
        label = 'bus';
        catId = dataDict('bus');
    elseif contains(lower(objectName), 'truck')
        label = 'truck';
        catId = dataDict('truck');
    elseif contains(lower(objectName), {'bicycle','bike', 'biker', 'cyclist'})
        label = 'bicycle';
        catId = dataDict('bicycle');
        % alternates + one allowance for possible mis-spelling
    elseif contains(lower(objectName), {'motorcycle','motorbike', 'otorbike'})
        label = 'motorbike';
        catId = dataDict('motorbike');
    else % We can add other categories here as needed
        continue;
    end

    % There is a weird offset needed here
    [occluded, ~, bbox2d, segmentation, area] = piAnnotationGet(instanceMap,objectIndex,options.offset);
    if isempty(bbox2d)
        continue
    end % no location or hidden

    % Convert bbox format as needed (x, y, width, height)
    pos = [bbox2d.xmin bbox2d.ymin ...
        bbox2d.xmax-bbox2d.xmin ...
        bbox2d.ymax-bbox2d.ymin];

    % check for minimum and maximum object size
    if pos(3)<10 || pos(4)<10
        continue
    end
    if pos(4)>500 && pos(3)>1000
        continue
    end
    if area <= 0 % Not sure how this can happen if we have height & width
        continue
    end
    foundObjects = foundObjects + 1;
    % Build our object data structure
    GTObjects(foundObjects).label = label;
    GTObjects(foundObjects).bbox2d = pos;
    GTObjects(foundObjects).catId = catId;

    % Also Compute the distance to the object.
    % Currently we use its minimum distance
    GTObjects(foundObjects).distance = min(useDepthMap(instanceMap == ii),[],"all");
    
    % NOTE: To calculate AP, we want to have the closest target object
    %       along with distance and bounding box. 
    if GTObjects(foundObjects).distance < closestTarget.distance
        % only say we're closer if we have a real distance
        if GTObjects(foundObjects).distance > 1
            closestTarget.distance = GTObjects(foundObjects).distance;
            closestTarget.label = label;
            closestTarget.bbox = pos;
            closestTarget.name = name;
        end
    end

end



end


