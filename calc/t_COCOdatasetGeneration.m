%%
% Updated version of the COCO-based dataset generator
% written by Zhenyi for the Ford project

ieInit;

%% Info
info.description = 'Stanford ISET Scene Dataset';
info.url = '';
info.version = '1.0';
info.year = 2023;
info.contributor = 'Wandell Lab & Zhenyi Liu';
info.data_created = datestr(now,26);
data.info = info;
%% licenses 
% No licenses
data.licenses = [];
%% Categories

% List of categories that we consider interesting as subjects
catNames = ["person", "deer", "car", "bus", "truck", "bicycle", "motorcycle"];

% Their IDs in COCO
catIds   = [0, 91, 2, 5, 7, 1, 3];
dataDict = dictionary(catNames, catIds);

% Map general "supercategory" to our specific categories
categories{1} = struct('supercategory','person','id',dataDict("person"),'name','person');
categories{2} = struct('supercategory','animal','id',dataDict("deer"),'name','deer');
categories{3} = struct('supercategory','vehicle','id',dataDict("car"),'name','car');
categories{4} = struct('supercategory','vehicle','id',dataDict("bus"),'name','bus');
categories{5} = struct('supercategory','vehicle','id',dataDict("truck"),'name','truck');
categories{6} = struct('supercategory','vehicle','id',dataDict("bicycle"),'name','bicycle');
categories{7} = struct('supercategory','vehicle','id',dataDict("motorcycle"),'name','motorcycle');

data.categories = categories;

%% TMP debug
%datasetRoot = 'Y:\data\iset\isetauto';
%useDataRoot = 'c:\iset\isetonline\coco-annotator\datasets\auto\';
% on Mux or Orange
datasetRoot = '/acorn/data/iset/isetauto/';

% need to process all folders eventually
datasetFolder = fullfile(datasetRoot,'Deveshs_assets/ISETScene_003_renderings');

sceneNames = dir([datasetFolder,'/*_instanceID.exr']);

outputFolder = useDataRoot;

if ~exist(outputFolder, 'dir'), mkdir(outputFolder);end
% imageID = '20220328T155503';
nBox=1;
nImage = 1;
annotations={};
%%
for ss = 1:numel(sceneNames)

    imageID = erase(sceneNames(ss).name,'_instanceID.exr');
    instanceMapFile = fullfile(datasetFolder, [imageID, '_instanceID.exr']);
    instanceMap = piReadEXR(instanceMapFile, 'data type','instanceId');
    objectslist = readlines(fullfile(datasetRoot,sprintf('dataset/nighttime/additionalInfo/%s.txt',imageID)));
    objectslist = objectslist(5:end);

    [h,w,~] = size(instanceMap);
%     Annotation_coco = [];
    for ii = 1:numel(objectslist)
        name = objectslist{ii};
        name = erase(name,{'ObjectInstance ', '"', '_m'});
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
        elseif contains(lower(name), ['motorcycle','motorbike'])
            label = 'vehicle';
            catId = dataDict('motorcycle');
        else
            continue;
        end
        [occluded, truncated, bbox2d, segmentation, area] = piAnnotationGet(instanceMap,ii,0);
        if isempty(bbox2d), continue;end
        pos = [bbox2d.xmin bbox2d.ymin ...
            bbox2d.xmax-bbox2d.xmin ...
            bbox2d.ymax-bbox2d.ymin];

        % if object < 10x10, ignore
        if pos(3)<10 || pos(4)<10
            continue
        end

        % Not sure what this accomplishes, maybe meant something different?
        if pos(4)<500 && pos(3)>960
            continue
        end
        if area == 0
            fprintf('No target found in %s.\n',imageID);
            continue;
        end
        annotations{nBox} = struct('segmentation',[segmentation],'area',area,'iscrowd',0,...
            'image_id',str2double(imageID),'bbox',pos,'category_id',catId,'id',0,'ignore',0);
        fprintf('Class %s, instanceID: %d \n', label, ii);
        nBox = nBox+1;
    end
    %%

    imgName = sprintf('%d.png',str2double(imageID));

    images{nImage} = struct('file_name',imgName,'height',h,'width',w,'id',str2double(imageID));

    nImage = nImage + 1;
end

%%
anno_uniqueID = randperm(100000,numel(annotations));
for nn = 1:numel(annotations)
    annotations{nn}.id = anno_uniqueID(nn);
end

data.images = images;
data.annotations = annotations;

clk = tic;
annFile = fullfile(outputFolder, 'annotations.json');
jsonwrite(annFile, data);

