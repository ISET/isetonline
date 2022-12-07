function [foo] = olGetGroundTruth(options)
%OLGETGROUNDTRUE Retrieve GT info from rendered scenes
%   D. Cardinal, Stanford University, 12/2022

% Currently needs the _instanceID.exr file, and
%   the instanceid.txt file

% Also assumes we only care about certain classes & know their IDs

arguments
    options.instanceFile = '';
    options.addtionalFile = '';
    % others?
end

%% Categories
catNames = ["person", "deer", "car", "bus", "truck", "bicycle", "motorcycle"];
catIds   = [0, 91, 2, 5, 7, 1, 3];
dataDict = dictionary(catNames, catIds);

instanceMap = piReadEXR(instanceFile, 'data type','instanceId');

%% Read in our entire list of rendered objects
% First four lines are text metadata, so clip to start at line 5
objectslist = readlines(fullfile(datasetRoot,sprintf('dataset/nighttime/additionalInfo/%s.txt',imageID)));
objectslist = objectslist(5:end);

%% Iterate on objects, filtering for the ones we want
%  and then building annotations
for ii = 1:numel(objectslist)
    name = objectslist{ii};
    % get rid of text we don't want
    name = erase(name,{'ObjectInstance ', '"', '_m'});
    %     fprintf(seg_FID, '%d %s \n',ii, name);

    % These are category tweaks from Zhenyi
    % I don't know if they are to correct past issues or are still needed
    if contains(lower(name), {'car'})
        label = 'vehicle';
        catId = dataDict('car');
    elseif contains(lower(name),'deer')
        label = 'Deer';
        catId = dataDict('deer');
    elseif contains(lower(name),['person','pedestrian'])
        label = 'Person';
        catId = dataDict('person');
    elseif contains(lower(name), 'bus')
        label = 'vehicle';
        catId = dataDict('bus');
    elseif contains(lower(name), 'truck')
        label = 'vehicle';
        catId = dataDict('truck');
    elseif contains(lower(name), ['bicycle','bike'])
        label = 'vehicle';
        catId = dataDict('bicycle');
        % is it really motorbicycle??
    elseif contains(lower(name), ['motorbicycle','motorbike'])
        label = 'vehicle';
        catId = dataDict('motorbicycle');
    else % WE NEED TO ADD OUR OTHER CATEGORIES HERE!
        continue;
    end
    [occluded, ~, bbox2d, segmentation, area] = piAnnotationGet(instanceMap,ii,0);
    if isempty(bbox2d), continue;end
    pos = [bbox2d.xmin bbox2d.ymin ...
        bbox2d.xmax-bbox2d.xmin ...
        bbox2d.ymax-bbox2d.ymin];
    if pos(3)<10 || pos(4)<10
        continue
    end
    if pos(4)<500 && pos(3)>960
        continue
    end
    if area == 0
        fprintf('No target found in %s.\n',imageID);
        continue;
    end
    %{
    % This is the COCO generation code from Zhenyi's original
    annotations{nBox} = struct('segmentation',[segmentation],'area',area,'iscrowd',0,...
        'image_id',str2double(imageID),'bbox',pos,'category_id',catId,'id',0,'ignore',0);
    fprintf('Class %s, instanceID: %d \n', label, ii);
    nBox = nBox+1;
    %}

% CONVERSION STOPPED HERE< REST NEEDS WORK
    imgName = sprintf('%d.png',str2double(imageID));

    images{nImage} = struct('file_name',imgName,'height',h,'width',w,'id',str2double(imageID));
    nImage = nImage + 1;
end

%%
%{
% Since we aren't doing COCO, we might not need this?
anno_uniqueID = randperm(100000,numel(annotations));
for nn = 1:numel(annotations)
    annotations{nn}.id = anno_uniqueID(nn);
end
data.images = images;
data.annotations = annotations;

clk = tic;
annFile = fullfile(outputFolder, 'annotations.json');
jsonwrite(annFile, data);
%}

% Instead we want to return our JSON structure to our caller
% So that they can embed it into an output file
% and create an annotated version (unless we return that also)

% Have to set contents of data
return GTdata

end


