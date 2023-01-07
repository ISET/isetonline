% Render & Export objects for use in "oi2sensor" / ISETOnline
%
% Currently supports either pre-computed OIs, or scenes generated
% using PBRT & re-processed for multiple illuminants. These
% are designed to be used by ISETOnline
%
% Optionally can store in a mongoDB set of collections, in addition
% to the file system
%
% D. Cardinal, Stanford University, 2022
%

%% TBFixed: We wind up with COCO annotations for full 1080p
%  But images that are smaller. Need to sort that out
%%

% NOTE: Currently we create each sensor with the ISETCam resolution,
%       but that is not the same as the actual resolution of the products

%% Set output folder
% I'm not sure where we want the data to go ultimately.
% As it will wind up in the website and/or a db
% We don't want it in our path or github (it wouldn't fit)

% This is the place where our Web app expects to find web-accessible
% Data files when running our dev environment locally. For production
% use, it, along with the static "build" folder need to be copied over.
outputFolder = fullfile(onlineRootPath,'simcam','public');
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

% Need to make db optional, as not everyone will be set up for it.
useDB = true; % false;

% We can either process pre-computed optical images
% or synthetic scenes that have been rendered through a pinhole by PBRT
% that Zhenyi is having Denesh render
usePreComputedOI = false;

% Port number seems to wander a bit:)

if useDB
    portNumber = 49154; % this changes, need to figure out why
    ourDB = db('dbServer','seedling','dbPort',portNumber);
    % If we are also using Mongo create our collections first!
    ourDB.createSchema;
else
    ourDB = []; % don't save to a database
end


% Our webserver pulls metadata from a private folder
privateDataFolder = fullfile(onlineRootPath,'simcam','src','data');
if ~isfolder(privateDataFolder)
    mkdir(privateDataFolder);
end

% For performance we might want to have a "metadata only" update option
% in the case where we are adding new information to our metadata.json
% but not re-rendering the actual sensor images. TBD

%% Export sensor(s)
% Provide data for sensors so people can work with it on their own
sensorFiles = exportSensors(outputFolder, privateDataFolder, ourDB);

%% Export Lenses
exportLenses(outputFolder, privateDataFolder, ourDB)

%% ... Eventually see if we can modify illumination ...
% And potentially download information about it?
% Or maybe this all comes in the variants on the recipes?

%% Copy/Export OIs
%  OIs include complex numbers, which are not directly-accessible
%  in standard JSON. They also become extremely large as JSON (or BSON)
%  files. So for now, seems best to simply export the .mat files.
%  We do that in the loop below as we render each one.

% The Metadata Array is the non-image portion of those, which
% is small enough to be kept in a single file & used for filtering
imageMetadataArray = [];

% We can either start with pre-computed optical images that
% have been through lenses, or synthetic scenes through a pinhole
% that we'll render through "another" pinhole for now
if usePreComputedOI
    % For now we have the OI folder in our Matlab path
    % As we add a large number we might want to enumerate a data folder
    % Or even get them from a database
    oiFiles = {'oi_001.mat', 'oi_002.mat',  ...
        'oi_003.mat', 'oi_004.mat', 'oi_005.mat', 'oi_006.mat'};
else
    oiDefault = oiCreate('shift invariant');

    % Here is where we look for our scenes
    % TMP HACK with hard-coded paths
    if ispc
        % Live Root:
        % datasetRoot = 'Y:\data\iset\isetauto';
        % Test Root:
        iaDataRoot = 'v:\data\iset\isetauto';
        datasetRoot = fullfile(iaDataRoot, 'dataset');
        % example instance file
        % V:\data\iset\isetauto\Deveshs_assets\ISETScene_011_renderings\
        sceneSet = 'nighttime_006';
        instanceSet = 'ISETScene_006';
        % Rendering folder has the .mat files for the Scenes that can be summed
        datasetFolder = fullfile(iaDataRoot,'Deveshs_assets',[instanceSet '_renderings']);

    else
        % on Mux
        datasetRoot = '/acorn/data/iset/isetauto/';
        sceneSet = 'nighttime_006';
        % needs to be set:
        datasetFolder = '';

    end
    sceneFolder = fullfile(datasetRoot, 'skymap_scale10', sceneSet);
    infoFolder = fullfile(datasetRoot,'nighttime','additionalInfo');

    % These are the composite scene files made by mixing
    % illumination sources and showing through a pinhole
    sceneFileEntries = dir(fullfile(sceneFolder,'*.mat'));

    % Limit how many scenes we use for testing to speed things up
    sceneNumberLimit = 3;
    numScenes = min(sceneNumberLimit, numel(sceneFileEntries));

    sceneFileNames = '';
    jj = 1;
    for ii = 1:numScenes
        sceneFileNames{jj} = fullfile(sceneFileEntries(ii).folder, sceneFileEntries(ii).name);
        jj = jj+1;
    end

    % This is where the scene ID is available
    fName = erase(sceneFileEntries(ii).name,'.mat');
    imageID = fName;

    % Now we'll make oi's by iterating through our scenes
    oiFiles = {};

    % our scenes are pre-rendered .exr files for various illuminants
    % that have been combined into ISETcam scenes for evaluation
    % Good place to try parfor
    for ii = 1:numScenes
        ourScene = load(sceneFileNames{ii}, 'scene');
        % Preserve size for later use in resizing
        ourScene.metadata.sceneSize = sceneGet(ourScene,'size');
        ourScene.metadata.sceneID = fName; % best we can do for now
        % In our case we render the scene through our default 
        % (shift-invariant) optics so that we have an OI to work with

        oiComputed{ii} = oiCompute(ourScene.scene, oiDefault); %#ok<SAGROW>

        % Get rid of the oi border for better viewing
        oiComputed{ii} = oiCrop(oiComputed{ii},'border'); %#ok<SAGROW>
        oiComputed{ii}.metadata.sceneID = fName; % best we can do for now

    end

end

% Either way we now have a set of optical images that we can
% Loop through and render them with our sensors
% and with whatever variants (burst, bracket, ...) we want
if ~isfolder(fullfile(outputFolder,'oi'))
    mkdir(fullfile(outputFolder,'oi'))
end

% Pre-compute sensor images
% Start by giving them a folder
if ~isfolder(fullfile(outputFolder,'images'))
    mkdir(fullfile(outputFolder,'images'))
end

if usePreComputedOI
    for ii = 1:numel(oiFiles)
        [~, fName, fSuffix] = fileparts(oiFiles{ii});
        oiDataFile = fullfile(outputFolder,'oi',[fName fSuffix]);

        % For now only copy if we don't have it already
        % Might need to change if we have updated versions
        if ~isfile(oiDataFile)
            % NOTE: This is where oi gets set!
            load(oiFiles{ii}); % assume OIs are on our path
            copyfile(which(oiFiles{ii}), oiDataFile);
        else
            load(oiDataFile);
        end

        % specify the files needed to extract Ground Truth
        infoFiles.instanceFile = '';
        infoFiles.additionalFile = '';

        % LOOP THROUGH THE SENSORS HERE
        % we use basemetadata for other render case, but not here?
        imageMetadata = processSensors(oi, sensorFiles, outputFolder, '', infoFiles, ourDB);
        imageMetadataArray = [imageMetadataArray imageMetadata];
    end
else
    % Originally we looped through oiFiles,
    % but for metric scenes we will generate them
    % from the .mat Scene objects created from .exr files
    for ii = 1:numel(oiComputed)
        % This is where the scene ID is available
        fName = erase(sceneFileEntries(ii).name,'.mat');
        imageID = fName;

        oi = oiComputed{ii};

        % baseMetadata should be generic info to add to per-image data
        % once we figure out what that is
        baseMetadata = '';

        % specify the files needed to extract Ground Truth
        % Example:
        % V:\data\iset\isetauto\Deveshs_assets\ISETScene_011_renderings\
        infoFiles.instanceFile = fullfile(datasetFolder, ...
            sprintf('%s_instanceID.exr', imageID));
        infoFiles.additionalFile = fullfile(infoFolder, ...
            sprintf('%s.txt',imageID));

        % LOOP THROUGH THE SENSORS HERE
        imageMetadata = processSensors(oi, sensorFiles, outputFolder, ...
            baseMetadata, infoFiles, ourDB);

        % Not all sensorimages will have the same
        % metadata fields, so we need to put them in a cell struct

        imageMetadataArray{ii} = imageMetadata;
    end
end

% We can write metadata as one file to make it faster to read
% Since it is only read by our code, we place it in the code folder tree
% instead of the public data folder
% imageMetaDataArray is a cell Array, so we wind up with a sort of empty
% top level right now??
jsonwrite(fullfile(privateDataFolder,'metadata.json'), imageMetadataArray);

%% --------------- SUPPORT FUNCTIONS START HERE --------------------
%% For each OI process through all the sensors we have
function imageMetadata = processSensors(oi, sensorFiles, outputFolder, baseMetadata, infoFiles, ourDB)

imageMetadata = baseMetadata;

% Kind of lame as our test OIs don't really have good metadata
% So we pick the leading characters which are the unique ID so far
if ~isstrprop(oi.name(1),'alpha')
    fName = oi.name(1:10); % root scene name in our initial test data
else
    fName = oi.name;
end

% experiment with camera motion
% for now each shift adds oi data to the oi
% for expediency we're doing this once per OI, although ideally
% we'd recalc for each sensor.

oiBurst = oi;
% Turn off camera motion for now, as it is confusing people:)
% Pick a large amount for testing
%oiBurst = oiCameraMotion(oiBurst, 'amount', ...
%    {[0 .05], [0 .1], [0 .15], [0 .2]});

% Loop through our sensors: (ideally with parfor)
% But that may have issues
for iii = 1:numel(sensorFiles)
    % parfor wants us to assign load to a variable
    sensorWrapper = load(sensorFiles{iii},'sensor'); % assume they are on our path
    sensor = sensorWrapper.sensor;
    % prep for changing suffix to json
    [~, sName, ~] = fileparts(sensorFiles{iii});

    % NOTE to self DJC:
    % This is a little complicated, as we often have a narrow FOV
    % scene (front-facing auto camera), but a wider FOV sensor.
    % We want to keep pixel size the same, but cropping isn't
    % ideal
    if ~isequaln(oiGet(oi,'focalLength'),NaN())
        hFOV = oiGet(oi,'hfov');
        sensor = sensorSetSizeToFOV(sensor,hFOV,oi);
    end

    %% Now we have an OI + Sensor
    % so at this point we should have a notion/function
    % of what variants we want for that "sensorimage"

    % Default Auto-Exposure breaks with oncoming headlights, etc.
    % Experimenting with others
    aeMethod = 'mean';
    aeLevels = .5;
    %aeMethod = 'specular';
    %aeLevels = .8;
    aeTime = autoExposure(oi,sensor, aeLevels, aeMethod);
    aeMethod = 'hdr';
    % Un-used, for now
    %aeHDRTime  = autoExposure(oi,sensor,aeLevels,aeMethod,'numframes',7);

    % Now derive bracket & burst times:
    % These are hacked for now to get things working.
    % Then we can wire them up more elegantly
    % For static images with no fancy AI,
    % I think a "mini-HDR" is actually equivalent
    % to doing simple burst calculations
    burstFrames = 3;
    burstTimes = repelem(aeTime/burstFrames, burstFrames);

    bracketStops = 3; % for now
    bracketTimes = [aeTime/(3*bracketStops), ...
        aeTime, aeTime * (3*bracketStops)];

    sensor_ae = sensorSet(sensor,'exp time',aeTime);
    sensor_burst = sensorSet(sensor,'exp time',burstTimes);
    sensor_burst = sensorSet(sensor_burst, 'exposure method', 'burst');
    sensor_bracket = sensorSet(sensor,'exp time',bracketTimes);

    % Here is where we have sensor(s) that have our modified
    % defaults, but have not processed an OI,
    % so we want to write them out for use in our Sensor Editor
    sensor_ae.metadata = baseMetadata; % initialize with generic value
    sensor_ae.metadata.sensorBaselineFileName = [sName '-Baseline.json'];

    % Get the sceneID
    sensor_ae.metadata.sceneID = oi.metadata.sceneID; % snag original scene ID
    jsonwrite(fullfile(outputFolder,'sensors',[sName '-Baseline.json']), sensor_ae);

    % See how long this takes in case we want
    % to allow users to do it in real-time on our server
    tic;
    % This is where we need to sync up resolution
    % We are going to annotate the sensor output
    % But the sensors have differing resolutions
    % So we will need to resize before we analyze
    sensor_ae = sensorCompute(sensor_ae,oi);

    sensor_burst = sensorCompute(sensor_burst,oiBurst);
    sensor_bracket = sensorCompute(sensor_bracket,oi);
    toc;

    % Here we save the preview images
    % We use the fullfile for local write
    % and just the filename for web use
    % May need to get fancier with #frames in filename!
    ipJPEGName = [fName '-' sName '.jpg'];
    ipJPEGName_burst = [fName '-' sName '-burst.jpg'];
    ipJPEGName_bracket = [fName '-' sName '-bracket.jpg'];
    ipThumbnailName = [fName '-' sName '-thumbnail.jpg'];

    % "Local" is our ISET filepath, not the website path
    ipLocalJPEG = fullfile(outputFolder,'images',ipJPEGName);
    ipLocalJPEG_burst = fullfile(outputFolder,'images',ipJPEGName_burst);
    ipLocalJPEG_bracket = fullfile(outputFolder,'images',ipJPEGName_bracket);
    ipLocalThumbnail = fullfile(outputFolder,'images',ipThumbnailName);

    % Do the same for our Ground Truth filenames
    % QUESTION: It makes sense to do YOLO on the sensor-rendered image
    %   but Ground Truth is based on the original PBRT render
    %   so if we use it, then try to show it over a sensor-rendered image
    %   then will it all line up? Or do we just show a single GT vesion?

    ipGTName = [fName '-' sName '-GT.jpg'];
    ipGTName_burst = [fName '-' sName 'GT-burst.jpg'];
    ipGTName_bracket = [fName '-' sName 'GT-bracket.jpg'];

    % "Local" is our ISET filepath, not the website path
    ipLocalGT = fullfile(outputFolder,'images',ipGTName);
    ipLocalGT_burst = fullfile(outputFolder,'images',ipGTName_burst);
    ipLocalGT_bracket = fullfile(outputFolder,'images',ipGTName_bracket);

    % Do the same for our YOLO version filenames
    ipYOLOName = [fName '-' sName '-YOLO.jpg'];
    ipYOLOName_burst = [fName '-' sName 'YOLO-burst.jpg'];
    ipYOLOName_bracket = [fName '-' sName 'YOLO-bracket.jpg'];

    % "Local" is our ISET filepath, not the website path
    ipLocalYOLO = fullfile(outputFolder,'images',ipYOLOName);
    ipLocalYOLO_burst = fullfile(outputFolder,'images',ipYOLOName_burst);
    ipLocalYOLO_bracket = fullfile(outputFolder,'images',ipYOLOName_bracket);

    % Create a default IP so we can see some baseline image
    ip_ae = ipCreate('ourIP',sensor_ae);
    % For RCCC we need to set the IP differently
    if contains(sensor_ae.name, 'RCCC')
        ip_ae.demosaic.method = 'analog rccc'; end
    ip_ae = ipCompute(ip_ae, sensor_ae);

    % This is where we'd add sensor shift/rotate
    % to mimic camera motion for burst and bracket
    % We can't currently mimic motion during a frame
    % without re-computing the OI
    jigglePixels = 10;
    sensor_burst = sensorJiggle(sensor_burst, jigglePixels);
    sensor_burst.metadata.jiggle = jigglePixels;

    ip_burst = ipCreate('ourIP',sensor_burst);
    if isequal(sensor_burst.name, 'AR0132AT-RCCC')
        ip_burst.demosaic.method = 'analog rccc'; end
    ip_burst = ipCompute(ip_burst, sensor_burst);

    ip_bracket = ipCreate('ourIP',sensor_bracket);
    if isequal(sensor_bracket.name, 'AR0132AT-RCCC')
        ip_bracket.demosaic.method = 'analog rccc'; end
    ip_bracket = ipCompute(ip_bracket, sensor_bracket);

    % save an RGB JPEG using our default IP so we can show a preview
    outputFile = ipSaveImage(ip_ae, ipLocalJPEG);
    burstFile = ipSaveImage(ip_burst, ipLocalJPEG_burst);
    bracketFile = ipSaveImage(ip_bracket, ipLocalJPEG_bracket);

    % We also want to save a GT-annotated version of each!
    % "doGT" will run detector, but need to make it integrate bboxes
    % Generate images to use for GT, with size matching scene
    img_for_GT = imread(outputFile);

    img_for_GT_burst = imread(burstFile);

    img_for_GT_bracket = imread(bracketFile);

    % Sometimes we are not getting sceneSize
    if ~isempty(ip_ae.metadata) && isfield(ip_ae.metadata, 'sceneSize')
        sceneRez = ip_ae.metadata.sceneSize;
        imresize(img_for_GT, sceneRez);
        imresize(img_for_GT_burst, sceneRez);
        imresize(img_for_GT_bracket, sceneRez);
        
    end

    % Use GT & get back annotated image
    if ~isempty(infoFiles.instanceFile)
        img_GT = doGT(img_for_GT,'instanceFile',infoFiles.instanceFile, ...
            'additionalFile',infoFiles.additionalFile);
        img_GT_burst = doGT(img_for_GT_burst,'instanceFile',infoFiles.instanceFile, ...
            'additionalFile',infoFiles.additionalFile);
        img_GT_bracket = doGT(img_for_GT_bracket,'instanceFile',infoFiles.instanceFile, ...
            'additionalFile',infoFiles.additionalFile);

        % Write out our GT annotated image
        imwrite(img_GT, ipLocalGT);
        imwrite(img_GT_burst, ipLocalGT_burst);
        imwrite(img_GT_bracket, ipLocalGT_bracket);
    end
    % We also want to save a YOLO-annotated version of each!
    % doYOLO will run detector, but need to make it integrate bboxes
    % Generate images to use for YOLO
    img_for_YOLO = imread(outputFile);
    img_for_YOLO_burst = imread(burstFile);
    img_for_YOLO_bracket = imread(bracketFile);

    % Use YOLO & get back annotated image
    % FIGURE OUT HOW TO WRITE OUT YOLO DATA
    [img_YOLO, bboxes, scores, labels] = doYOLO(img_for_YOLO);

    % yoloJSON needs to be fixed for parfor, and
    % we're not currently using it, so comment out
    %yoloJSON.bboxes = bboxes;
    %yoloJSON.scores = scores;
    %yoloJSON.labels = labels;

    % Don't know if we need to write these version out separately?
    [img_YOLO_burst, bboxes, scores, labels] = doYOLO(img_for_YOLO_burst);
    [img_YOLO_bracket, bboxes, scores, labels] = doYOLO(img_for_YOLO_bracket);

    % Write out our annotated image
    imwrite(img_YOLO, ipLocalYOLO);
    imwrite(img_YOLO_burst, ipLocalYOLO_burst);
    imwrite(img_YOLO_bracket, ipLocalYOLO_bracket);

    % we could also save without an IP if we want
    %sensorSaveImage(sensor, sensorJPEG  ,'rgb');

    % Generate a quick thumbnail
    thumbnail = imread(ipLocalJPEG);
    thumbnail = imresize(thumbnail, [128 128]);
    imwrite(thumbnail, ipLocalThumbnail);

    % We need to save the relative paths for the website to use
    sensor_ae.metadata.jpegName = ipJPEGName;
    sensor_ae.metadata.GTName = ipGTName;
    sensor_ae.metadata.YOLOName = ipYOLOName;
    sensor_ae.metadata.thumbnailName = ipThumbnailName;

    % we also have bracket & burst (& others)
    % how do we want to store / note them?
    sensor_ae.metadata.burstJPEGName = ipJPEGName_burst;
    sensor_ae.metadata.burstGTName = ipGTName_burst;
    sensor_ae.metadata.burstYOLOName = ipYOLOName_burst;
    sensor_ae.metadata.bracketJPEGName = ipJPEGName_bracket;
    sensor_ae.metadata.bracketGTName = ipGTName_bracket;
    sensor_ae.metadata.bracketYOLOName = ipYOLOName_bracket;

    % Stash exposure time for reference
    sensor_ae.metadata.exposureTime = aeTime;
    sensor_ae.metadata.aeMethod = aeMethod;

    % Save OI & Original sensor file names
    % for runtime compute

    %%%% fSuffix not defined -- set to '.mat' for now
    sensor_ae.metadata.oiFile = [fName '.mat'];
    sensor_ae.metadata.sensorFile = sName;

    % Start stashing pixel information
    sensor_ae.metadata.pixel = sensor_ae.pixel;

    % we might eventually get illumination
    sensor_ae.metadata.illumination = '';

    % We don't want the full lensfile path
    if isfield(sensor_ae.metadata,'opticsname')
        [~, lName, ~] = fileparts(sensor_ae.metadata.opticsname);
        sensor_ae.metadata.opticsname = lName;
    end

    % Write out the 'raw' voltage file
    % Need to add support for bracket & burst
    sensorDataFile = [fName '-' sName '.json'];
    sensor_ae.metadata.sensorRawFile = sensorDataFile;
    jsonwrite(fullfile(outputFolder,'images', sensorDataFile), sensor_ae);

    % mongo doesn't manage docs > 16MB, so sensor data doesn't fit,
    % but it can manage our metadata
    if ~isempty(ourDB)
        ourDB.store(sensor_ae.metadata,"collection","sensorimage");
    end

    % We ONLY write out the metadata in the main .json
    % file to keep it of reasonable size
    % NOTE: Currently we re-write the entire file
    % Each time so dataPrep needs to run a complete batch
    % We might want to add an "Update" option that only
    % adds and updates?

    % Need to accumulate all sensor data
    imageMetadata = [imageMetadata sensor_ae.metadata]; %#ok<AGROW> 

end
end
% Export lenses to fils for our users
function exportLenses(~, ~, ourDB)
lensRoot = isetRootPath;
lensFiles = lensC.list('quiet', true, 'lensRoot', lensRoot);
lensCount = numel(lensFiles);

for ii = 1:lensCount
    lensFileName = lensFiles(ii).name;
    % Get the full path to load
    lensFile = fullfile(lensFiles(ii).folder, lensFileName);
    ourLens = jsonread(lensFile);
    if ~isempty(ourDB); ourDB.store(ourLens, 'collection','lens'); end
end
end

function sensorFiles = exportSensors(outputFolder, privateDataFolder, ourDB)
% 'ar0132atSensorRGBW.mat',     'NikonD100Sensor.mat'
sensorFiles = {'MT9V024SensorRGB.mat', 'imx363.mat',...
    'ar0132atSensorrgb.mat', 'ar0132atSensorRCCC.mat'};

% Currently we want to keep a copy of sensors in /public for user
% download, and one is src/data for us to use for the UI as needed
if ~isfolder(fullfile(outputFolder,'sensors'))
    mkdir(fullfile(outputFolder,'sensors'));
end
if ~isfolder(fullfile(privateDataFolder,'sensors'))
    mkdir(fullfile(privateDataFolder,'sensors'));
end

% Write parameters for each sensor as a separate JSON file
% For those who want to do other calculations
for ii = 1:numel(sensorFiles)
    load(sensorFiles{ii}); % assume they are on our path
    % change suffix to json
    [~, sName, fSuffix] = fileparts(sensorFiles{ii});
    sFileName = fullfile(outputFolder,'sensors',[sName '.json']);

    % stash the name so we can load it into the web ui
    sensor.sensorFileName = [sName '.json'];
    jsonwrite(fullfile(outputFolder,'sensors',[sName '.json']), sensor);
    jsonwrite(fullfile(privateDataFolder,'sensors',[sName '.json']), sensor);

    % We want to write these to the sensor database also
    if ~isempty(ourDB); ourDB.store(sensor, 'collection','sensor'); end

end

end
