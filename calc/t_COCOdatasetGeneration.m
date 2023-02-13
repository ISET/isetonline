%%
% mex('CFLAGS=\$CFLAGS -Wall -std=c99','-largeArrayDims',...
%     'private/maskApiMex.c','../common/maskApi.c',...
%     '-I../common/','-outdir','private');
% coco annotation categories: https://tech.amikelive.com/node-718/what-object-categories-labels-are-in-coco-dataset/comment-page-1/
ieInit;

%% Info
info.description = 'Stanford Night time Scene Dataset';
info.url = '';
info.version = '1.0';
info.year = 2022;
info.contributor = 'Zhenyi Liu';
info.data_created = datestr(now,26);
data.info = info;
%% licenses 
% No licenses
data.licenses = [];
%% Categories
catNames = ["person", "deer", "car", "bus", "truck", "bicycle", "motorcycle"];
catIds   = [0, 91, 2, 5, 7, 1, 3];
dataDict = dictionary(catNames, catIds);
categories{1} = struct('supercategory','person','id',dataDict("person"),'name','person');
categories{2} = struct('supercategory','animal','id',dataDict("deer"),'name','deer');
categories{3} = struct('supercategory','vehicle','id',dataDict("car"),'name','car');
categories{4} = struct('supercategory','vehicle','id',dataDict("bus"),'name','bus');
categories{5} = struct('supercategory','vehicle','id',dataDict("truck"),'name','truck');
categories{6} = struct('supercategory','vehicle','id',dataDict("bicycle"),'name','bicycle');
categories{7} = struct('supercategory','vehicle','id',dataDict("motorcycle"),'name','motorcycle');

data.categories = categories;

%% TMP debug
datasetRoot = 'Y:\data\iset\isetauto';
useDataRoot = 'c:\iset\isetonline\coco-annotator\datasets\auto\';
% on Mux
%datasetRoot = '/acorn/data/iset/isetauto/';

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
%     imwrite(uint16(instanceMap), sprintf('%s/segmentation/%s.png',datasetFolder,imageID));
    %     instanceMap = imread(sprintf('%s/segmentation/%s.png',datasetFolder,imageID));
    objectslist = readlines(fullfile(datasetRoot,sprintf('dataset/nighttime/additionalInfo/%s.txt',imageID)));
    objectslist = objectslist(5:end);
    %     scene = piEXR2ISET(sprintf('/Users/zhenyi/Desktop/renderings/%s.exr',imageID),'label','radiance');
    %     scene = piAIdenoise(scene);
    %     save(sprintf('/Users/zhenyi/Desktop/renderings/%s.mat',imageID),"scene");
%     load(sprintf('%s/renderings/%s.mat',datasetFolder,imageID));
%     scene_circle = add_flare(scene, 48, 0);
%     oi = piOICreate(scene.data.photons,'meanilluminance',2);
%     ip = piRadiance2RGB(oi,'etime',1/30);
%     radiance = ipGet(ip,'srgb');
%     %     figure;imshow(radiance);
%     imwrite(radiance, sprintf('%s/rgb/%s.png',datasetFolder,imageID));
% 
%     scene_fl = add_flare(scene, 8, 1);
%     oi = piOICreate(scene_fl.data.photons,'meanilluminance',5);
%     ip = piRadiance2RGB(oi,'etime',1/30);
%     radiance_flare = ipGet(ip,'srgb');
%     %     figure;imshow(radiance_flare);
%     imwrite(radiance_flare, sprintf('%s/rgb_flare/%s.png',datasetFolder,imageID));

%     depth = piReadEXR(instanceMapFile, 'data type','zdepth');
    %     radiance = imread(sprintf('%s/rgb/%s.png',datasetFolder,imageID));
    %     depth    = imread(sprintf('%s/depth/%s.png',datasetFolder, imageID));
%     figure(1);
%     subplot(2,2,1);
%     imshow(radiance);title('sRGB');
%     ax1 = subplot(2,2,2);
%     imagesc(depth);colormap(ax1,"gray");title('Depth');axis off
%     set(gca, 'Visible', 'off');
%     ax2=subplot(2,2,3);
%     imagesc(instanceMap);colormap(ax2,"colorcube");axis off;title('Pixel Label');
%     subplot(2,2,4);
%     imshow(radiance);title('Bounding Box');

    [h,w,~] = size(instanceMap);
%     Annotation_coco = [];
    for ii = 1:numel(objectslist)
        name = objectslist{ii};
        name = erase(name,{'ObjectInstance ', '"', '_m'});
        %     fprintf(seg_FID, '%d %s \n',ii, name);
        if contains(lower(name), {'car'})
            label = 'vehicle';
            catId = dataDict('car');
%             r = 0.1; g= 0.5; b = 0.1;
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
%             Id = 9;
%             r = 1; g= 0.1; b = 0.1;
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
%         rectangle('Position',pos,'EdgeColor',[r g b],'LineWidth',1);
%         tex=text(bbox2d.xmin+2.5,bbox2d.ymin-8,label);
%         tex.Color = [1 1 1];
%         tex.BackgroundColor = [r g b];
%         tex.FontSize = 12;
        if area == 0
            fprintf('No target found in %s.\n',imageID);
            continue;
        end
        annotations{nBox} = struct('segmentation',[segmentation],'area',area,'iscrowd',0,...
            'image_id',str2double(imageID),'bbox',pos,'category_id',catId,'id',0,'ignore',0);
        fprintf('Class %s, instanceID: %d \n', label, ii);
        nBox = nBox+1;
    end
%     truesize;
    %%

    imgName = sprintf('%d.png',str2double(imageID));

    images{nImage} = struct('file_name',imgName,'height',h,'width',w,'id',str2double(imageID));

    % write files out
%     save(fullfile(datasetFolder, sprintf('%s_image.mat',imageID)),'Image_coco');
%     save(fullfile(datasetFolder, sprintf('%s_anno.mat',imageID)), 'Annotation_coco');

%     imgFilePath  = fullfile(datasetFolder,'rgb',imgName);
%     imwrite(radiance,imgFilePath);

%     imwrite(uint16(instanceMap),fullfile(datasetFolder,'segmentation',imgName));
%     imwrite(uint16(depth),fullfile(datasetFolder,'depth',imgName));
%     outputFolder = sceneData.recipe.get('outputdir');
%     movefile(fullfile(outputFolder,'renderings/*.exr'),fullfile(datasetFolder,'rendered/'));
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

