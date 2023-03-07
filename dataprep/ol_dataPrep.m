% ol_dataPrep takes Scenes & produces a ready-to-view website
% for ISETOnline. It's roughly composed of these four steps:
%
% 1) Image (via oi, sensor, ip) folders of ISET Scene objects
% 2) Analyze (retrieve ground truth, use YOLO for detection)
% 3) Export images for use in ISETOnline
% 4) Update sensorImages collection in isetdb().
%
% Supports  scenes generated
% using PBRT & re-processed for multiple illuminants. The
% output is designed to be used by ISETOnline
%
% It does several things that could be separated:
% * Reads ISET scenes
% * computes an Optical Image (OI)
%   (currently using shift-invariant optics, with focal
%    length adjusted for the size of our auto sensors)
% * creates sensorImages for each chosen sensor
%   (currently AE, burst, and bracket for each)
% * runs YOLO on each version of a sensorImage
% * writes to metadata.json
% * writes supporting files to web folders
% * (if useDB == true) writes to sensorImage collection in ISETdb.
%
%
% D. Cardinal, Stanford University, 2022
%

%% Currently we process one scenario at a time

% Need to decide if we want to allow multiple/all
projectName = 'Ford';
% Currently we have 3 lighting scenarios
%scenarioName = 'nighttime';
%scenarioName = 'nighttime_No_Streetlamps';
scenarioName = 'daytime_20_500'; % day with 20*sky, 500 ml

%% Set output folder

% This is the place where our Web app expects to find web-accessible
% Data files when running our dev environment locally. For production
% use, it, along with the static "build" folder need to be copied over
% to the web server
outputFolder = fullfile(onlineRootPath,'simcam','public');
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

% Need to make db optional, as not everyone will be set up for it.
useDB = true;

% We processed synthetic scenes that have been rendered through a pinhole by PBRT
% If we're using a database, typically it is the ISET default
if useDB
    ourDB = isetdb();
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

%% Start assembling metadata
% The Metadata Array is the non-image portion of those, which
% is small enough to be kept in a single file & used for filtering
if ~useDB
    imageMetadataArray = [];
end

% prior to using lenses we use default optics, but need to change
% the focal length (I think) to match the sensor size + FOV.
oiDefault = oiCreate('shift invariant');

% both our auto sensors are about 4.55mm x 2.97mm
% That is a 1.5 aspect ratio, but our scenes are 1.77 (1920/1080)
% So that + resolution mean that our YOLO data won't match GT Data
% But this should be calculated for each size sensor if we add more
oiDefault = oiSet(oiDefault, 'focal length', .006);

% 'local' for iaFileDataRoot allows for local 'test' copies of file data
datasetFolder = fullfile(iaFileDataRoot('local',true),projectName);

% Where the rendered EXR files live -- this is the
% same for all scenarios as it is the input data
EXRFolder = fullfile(datasetFolder, 'SceneEXRs');

% scenes are actually synthetic and have already been rendered
% typically using makeScenesFromRenders.m
sceneFolder = fullfile(datasetFolder, 'SceneISET', scenarioName);

% These are the composite scene files made by mixing
% illumination sources and showing through a pinhole
sceneFileEntries = dir(fullfile(sceneFolder,'*.mat'));

% for DEBUG: Limit how many scenes we use for testing to speed things up
sceneNumberLimit = 3000;
numScenes = min(sceneNumberLimit, numel(sceneFileEntries));

sceneFileNames = '';
jj = 1;
for ii = 1:numScenes
    sceneFileNames{jj} = fullfile(sceneFileEntries(ii).folder, sceneFileEntries(ii).name);
    jj = jj+1;
end

% our scenes are typically rendered from project recipes into
% ISETCam scene objects (stored in .mat files)

% Currently we can't use parfor without database because we concatenate onto
% imagemetadataarray on all threads...
for ii = 1:numScenes

    % If we use parfor, each thread needs a db connection
    threadDB = idb();
    %threadDB = ourDB;

    ourScene = load(sceneFileNames{ii}, 'scene');
    ourScene = ourScene.scene; % we get a nested variable for some reason

    % This is where the scene ID is available
    fName = erase(sceneFileEntries(ii).name,'.mat');
    sceneID = fName;

    % Preserve size for later use in resizing
    ourScene.metadata.sceneSize = sceneGet(ourScene,'size');
    ourScene.metadata.sceneID = sceneID;
    ourScene.metadata.scenario = scenarioName;

    % In our case we render the scene through our default
    % (shift-invariant) optics so that we have an OI to work with
    oiComputed = oiCompute(ourScene, oiDefault);

    % Get rid of the oi border so we match the original
    % scene for better viewing & ground truth matching
    oiComputed = oiCrop(oiComputed,'border');
    oiComputed.metadata.sceneID = sceneID;
    oiComputed.metadata.scenario = scenarioName;

    % Ground Truth is the same for all versions of a scene,
    % although perhaps for previewing we'll want to use the scenario lights
    ipGTName = [sceneID '-GT.png'];
    ipOIName = [sceneID '-OI.png'];

    % "Local" is our ISET filepath, not the website path
    ipLocalGT = fullfile(outputFolder,'images',ipGTName);
    ipLocalOI = fullfile(outputFolder,'images',ipOIName);

    %% If possible, get GT from the databaase!
    if useDB % get ground truth from the Auto Scene in ISETdb

        % this code sometimes has parse errors so use a try block
        try
            [GTObjects, closestTarget] = threadDB.gtGetFromScene('auto',sceneID);
            ourScene.metadata.GTObject = GTObjects;
            ourScene.metadata.closestTarget = closestTarget;

            % we need an image to annotate
            % -3 says don't show, 2.2 is a gamma value
            img_for_GT = oiShowImage(oiComputed, -3, 2.2);

            annotatedImage = annotateImageWithObjects(img_for_GT, GTObjects);
            img_GT = annotatedImage;
        catch
            annotatedImage = img_for_GT;
            img_GT = oiShowImage(oiComputed, -3, 2.2);
            ourScene.metadata.closestTarget = [];
            warning("gtGet failed on %s", sceneID);
        end
    else % we need to calculate ground truth "by hand"

        % Use GT & get back annotated image
        % pass it a native resolution image so the bounding boxes
        % match the scene locations
        if exist('instanceFile', 'var') && ~isempty(instanceFile)
            % Use HDR for render given the DR of many scenes
            img_for_GT = oiShowImage(oiComputed, -3, 2.2);

            % ol_gtCompute currently calculates and then
            % creates an annotated image. For the DB case
            % we just need an annotated image, though
            [img_GT, GTObjects] = ol_gtCompute(ourScene, img_for_GT,'instanceFile',instanceFile, ...
                'additionalFile',additionalFile);

        end
    end

    % Write out the GT image as a nice "visual" of the scene
    % or nothing if the image is empty for some reason
    if ~isempty(img_for_GT)
        imwrite(imageCropBorder(img_for_GT), ipLocalOI);
    else
        fprintf("Empty GT image: %s\n", img_for_GT);
    end

    % Add ground truth to output metadata
    if ~isempty(GTObjects) && isfield(GTObjects,'label')
        GTStruct = GTObjects; % already a struct
        uniqueObjects = unique({GTStruct(1,:).label});
        ourScene.metadata.Stats.uniqueLabels = convertCharsToStrings(uniqueObjects);
        distanceValues = [GTStruct(1,:).distance];
        ourScene.metadata.Stats.minDistance = min(distanceValues,[],'all');
        oiComputed.metadata.Stats.uniqueLabels = convertCharsToStrings(uniqueObjects);
        oiComputed.metadata.Stats.minDistance = min(distanceValues,[],'all');
    else
        ourScene.metadata.Stats.uniqueLabels = 'none';
        ourScene.metadata.Stats.minDistance = '1000000'; % found nothing
        oiComputed.metadata.Stats.uniqueLabels = 'none';
        oiComputed.metadata.Stats.minDistance = '1000000'; % found nothing
    end

    % Write out our GT annotated image
    imwrite(imageCropBorder(img_GT), ipLocalGT);

    % Unlike other previews, this one is generic to the scene
    % but we've already built an oi, so save it there also
    ourScene.metadata.web.GTName = ipGTName;
    ourScene.metadata.web.OIName = ipOIName;
    ourScene.metadata.GTObjects = GTObjects;
    ourScene.metadata.closestTarget = closestTarget;

    oiComputed.metadata.web.GTName = ipGTName;
    oiComputed.metadata.web.OIName = ipOIName;
    oiComputed.metadata.GTObjects = GTObjects;
    oiComputed.metadata.closestTarget = closestTarget;

    % Pre-compute sensor images
    % Start by giving them a folder
    if ~isfolder(fullfile(outputFolder,'images'))
        mkdir(fullfile(outputFolder,'images'))
    end

    % Our base OI
    oi = oiComputed;

    % baseMetadata should be generic info to add to per-image data
    % once we figure out what that is
    baseMetadata = '';

    % LOOP THROUGH THE SENSORS HERE
    imageMetadata = processSensors(oi, sensorFiles, outputFolder, ...
        baseMetadata, threadDB);

    % Not all sensorimages will have the same
    % metadata fields, so we need to put them in a cell struct
    % ImageMetaData is actually an array (per sensor)

    % if we are threaded, we can't use this
    % and if we have a db, we don't need it
    if ~useDB

        % Can't even have this here if we want parfor
        %    for jj=1:numel(imageMetadata)
        %        imageMetadataArray{end+1} = imageMetadata(jj);
        %    end
    end
end

% To use 
% Added support for incremental updates, by pulling all the
% imageMetadata out of the sensorimage collection
% NOTE: This assumes that all the needed preview files are still
%       in place in public/images.

% TBD: As we grow, might want to put each scenario in its own
%      metdata file, and load them all into the Web UI
if useDB
    ourDB.collectionToFile('sensorImages', fullfile(privateDataFolder,'metadata.json'));
else
    jsonwrite(fullfile(privateDataFolder,'metadata.json'), imageMetadataArray);
end


%% --------------- SUPPORT FUNCTIONS START HERE --------------------
%% For each OI process through all the sensors we have
function imageMetadata = processSensors(oi, sensorFiles, outputFolder, baseMetadata, ourDB)

% To force (or not) recreation of sensor images
useDBCache = false;
imageMetadata = baseMetadata;

% Kind of lame as our test OIs don't really have good metadata
% So we pick the leading characters which are the unique ID so far
if ~isstrprop(oi.name(1),'alpha')
    fName = oi.name(1:10); % root scene name in our initial test data
else
    fName = oi.name;
end

% need this to create unique sensor image files
scenarioName = oi.metadata.scenario;

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
    % shutter time is an issue. We don't know it yet, but at least 0
    % means some type of AE

    % for debug
    %sensor.name = 'MTV9V024-RGB'
    %oi.metadata.sceneID = '1112154540'

    % check if we already have a sensorimage for this scene and sensor
    % If so, then skip re-creating it
    %% NB Need more fields: project & scenario in key
    keyQuery = sprintf("{""sceneID"": ""%s"", ""sensorname"" : ""%s"", ""scenario"" : ""%s""}", ...
        oi.metadata.sceneID, sensor.name, scenarioName);
    if ourDB.exists('sensorImages', keyQuery) && useDBCache
        continue;
    end

    %% Oops -- This alters sensor rows & cols
    % Which means subsequent .size doesn't equal sensor size
    % But this is helpful in making all the images display in a similar way
    if ~isequaln(oiGet(oi,'focalLength'),NaN())
        hFOV = oiGet(oi,'hfov');
        sensor = sensorSetSizeToFOV(sensor,hFOV,oi);
    end

    %% Now we have an OI + Sensor

    % Default Auto-Exposure breaks with oncoming headlights, etc.
    % Experimenting with others
    aeMethod = 'mean';
    aeLevels = .5;
    %aeMethod = 'specular';
    %aeLevels = .8;
    aeTime = autoExposure(oi,sensor, aeLevels, aeMethod);
    % aeTime varies in its low order bits when re-run
    % since we use time values as keys we need to round
    aeTime = round(aeTime,5);
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
    sensor_ae.metadata.web.sensorBaselineFileName = [sName '-Baseline.json'];

    % Our actual capture won't be the same as the native sensor resolution
    sensor_ae.metadata.imgSize = sensorGet(sensor_ae,'size');

    % merge metadata from the OI with our own
    sensor_ae.metadata = appendStruct(sensor_ae.metadata, oi.metadata);
    jsonwrite(fullfile(outputFolder,'sensors',[sName '-Baseline.json']), sensor_ae);

    sensor_ae = sensorCompute(sensor_ae,oi);
    sensor_burst = sensorCompute(sensor_burst,oiBurst);
    sensor_bracket = sensorCompute(sensor_bracket,oi);

    % Save the preview images
    % We use the fullfile for local write
    % and just the filename for web use
    % May need to get fancier with #frames in filename!

    baseFileName = [fName '-' scenarioName '-' sName];
    ipJPEGName = [baseFileName '.jpg'];
    ipJPEGName_burst = [baseFileName '-burst.jpg'];
    ipJPEGName_bracket = [baseFileName '-bracket.jpg'];
    ipThumbnailName = [baseFileName '-thumbnail.jpg'];

    % "Local" is our ISET filepath, not the website path
    ipLocalJPEG = fullfile(outputFolder,'images',ipJPEGName);
    ipLocalJPEG_burst = fullfile(outputFolder,'images',ipJPEGName_burst);
    ipLocalJPEG_bracket = fullfile(outputFolder,'images',ipJPEGName_bracket);
    ipLocalThumbnail = fullfile(outputFolder,'images',ipThumbnailName);

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

    % save an RGB JPEG default IP for use with YOLO
    % We may save a cropped version later for better display
    outputFile = ipSaveImage(ip_ae, ipLocalJPEG, false, false);
    burstFile = ipSaveImage(ip_burst, ipLocalJPEG_burst, false, false);
    bracketFile = ipSaveImage(ip_bracket, ipLocalJPEG_bracket, false, false);

    % prepare for doing yolo in batch after db updates
    sensor_ae.metadata.YOLO.aeFileName = outputFile;
    sensor_ae.metadata.YOLO.burstFileName = burstFile;
    sensor_ae.metadata.YOLO.bracketFileName = bracketFile;
    sensor_ae.metadata.YOLO.imgSize = sensorGet(sensor_ae,'size');

    % Set filenames for output YOLO image files here
    % We also want to save a YOLO-annotated version of each
    ipYOLOName = [baseFileName '-YOLO.jpg'];
    ipYOLOName_burst = [baseFileName 'YOLO-burst.jpg'];
    ipYOLOName_bracket = [baseFileName 'YOLO-bracket.jpg'];

    %{
    % "Local" is our ISET filepath, not the website path
    ipLocalYOLO = fullfile(outputFolder,'images',ipYOLOName);
    ipLocalYOLO_burst = fullfile(outputFolder,'images',ipYOLOName_burst);
    ipLocalYOLO_bracket = fullfile(outputFolder,'images',ipYOLOName_bracket);
    %}
    processYOLO(sensor_ae, outputFolder, baseFileName);

    % save a cropped version of our RGB JPEG using our default IP so we can show a preview
    ipSaveImage(ip_ae, ipLocalJPEG, false, false, 'cropborder', true);
    ipSaveImage(ip_burst, ipLocalJPEG_burst, false, false, 'cropborder', true);
    ipSaveImage(ip_bracket, ipLocalJPEG_bracket, false, false, 'cropborder', true);

    % Generate a quick thumbnail
    thumbnail = imread(ipLocalJPEG);
    thumbnail = imresize(thumbnail, [128 128]);
    imwrite(imageCropBorder(thumbnail), ipLocalThumbnail);

    % We need to save the relative paths for the website to use
    sensor_ae.metadata.web.jpegName = ipJPEGName;
    sensor_ae.metadata.web.YOLOName = ipYOLOName;
    sensor_ae.metadata.web.thumbnailName = ipThumbnailName;

    % we also have bracket & burst (& others)
    % how do we want to store / note them?
    sensor_ae.metadata.web.burstJPEGName = ipJPEGName_burst;
    sensor_ae.metadata.web.burstYOLOName = ipYOLOName_burst;
    sensor_ae.metadata.web.bracketJPEGName = ipJPEGName_bracket;
    sensor_ae.metadata.web.bracketYOLOName = ipYOLOName_bracket;

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
    sensorDataFile = [baseFileName '.json'];
    sensor_ae.metadata.sensorRawFile = sensorDataFile;
    jsonwrite(fullfile(outputFolder,'images', sensorDataFile), sensor_ae);

    % mongo doesn't manage docs > 16MB, so sensor data doesn't fit,
    % but it can manage our metadata
    if ~isempty(ourDB)
        % .store won't update an existing document
        ourDB.store(sensor_ae.metadata,"collection","sensorImages");
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

%% Batch process object detection after images are calculated
function processYOLO(sensor_ae, outputFolder, baseFileName)

% We need to decide whether to pass the full images, or just
% the filenames (more efficient, but more coding)

% We want to iterate over the sensorImages we've been "given"
% All the file names should already be there, so we need go
% generate the YOLOData & annotated images for each of them.
% seems to need: sensor_ae, outputFolder, and baseFileName

% Either per sensorImage, or per sensorImage + capture?

% Try to set YOLO image files here
% We also want to save a YOLO-annotated version of each
ipYOLOName = [baseFileName '-YOLO.jpg'];
ipYOLOName_burst = [baseFileName 'YOLO-burst.jpg'];
ipYOLOName_bracket = [baseFileName 'YOLO-bracket.jpg'];

% "Local" is our ISET filepath, not the website path
ipLocalYOLO = fullfile(outputFolder,'images',ipYOLOName);
ipLocalYOLO_burst = fullfile(outputFolder,'images',ipYOLOName_burst);
ipLocalYOLO_bracket = fullfile(outputFolder,'images',ipYOLOName_bracket);

% Use YOLO & get back annotated image plus
% found objects. By themselves they don't offer distance,
% although they do give us a bounding box, from which it might
% be possible to compute distance.

% Generate images to use for YOLO
img_for_YOLO = imread(sensor_ae.metadata.YOLO.aeFileName);
img_for_YOLO_burst = imread(sensor_ae.metadata.YOLO.burstFileName);
img_for_YOLO_bracket = imread(sensor_ae.metadata.YOLO.bracketFileName);

% When we are in batch/parallel mode, want to create an array here!

% NOTE: img_YOLO is now a cell array, so we can calculate in batch
[img_YOLO, YOLO_Objects] = ol_YOLOCompute({img_for_YOLO});
[img_YOLO_burst, YOLO_Objects_Burst] = ol_YOLOCompute({img_for_YOLO_burst});
[img_YOLO_bracket, YOLO_Objects_Bracket] = ol_YOLOCompute({img_for_YOLO_bracket});

sensor_ae.metadata.YOLOData = YOLO_Objects;
sensor_ae.metadata.YOLOData_Burst = YOLO_Objects_Burst;
sensor_ae.metadata.YOLOData_Bracket = YOLO_Objects_Bracket;

% Write out our annotated image
if isempty(img_YOLO)
    fprintf("No YOLO for Image: %s \n", oi.metadata.sceneID);
end
if ~isempty(img_YOLO{1})
    imwrite(imageCropBorder(img_YOLO{1}), ipLocalYOLO);
end
if ~isempty(img_YOLO_burst{1})
    imwrite(imageCropBorder(img_YOLO_burst{1}), ipLocalYOLO_burst);
end
if ~isempty(img_YOLO_bracket{1})
    imwrite(imageCropBorder(img_YOLO_bracket{1}), ipLocalYOLO_bracket);
end
% Once we go parallel, need to write out the database entry here!


end

%% Export lenses to JSON files for our users
function exportLenses(~, ~, ourDB)
lensRoot = isetRootPath;
lensFiles = lensC.list('quiet', true, 'lensRoot', lensRoot);
lensCount = numel(lensFiles);

for ii = 1:lensCount
    lensFileName = lensFiles(ii).name;
    % Get the full path to load
    lensFile = fullfile(lensFiles(ii).folder, lensFileName);
    ourLens = jsonread(lensFile);
    ourLens.fileName = lensFileName; % need this to create a unique key
    if ~isempty(ourDB); ourDB.store(ourLens, 'collection','lenses'); end
end
end

%% Export sensors to JSON files for our users
function sensorFiles = exportSensors(outputFolder, privateDataFolder, ourDB)
% 'ar0132atSensorRGBW.mat',     'NikonD100Sensor.mat'
sensorFiles = {'MT9V024SensorRGB.mat', ... % 'imx363.mat',...
    'ar0132atSensorRGB.mat'}; %, 'ar0132atSensorRCCC.mat'};

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
    if ~isfile(fullfile(outputFolder,'sensors',[sName '.json']))
        jsonwrite(fullfile(outputFolder,'sensors',[sName '.json']), sensor);
    end
    jsonwrite(fullfile(privateDataFolder,'sensors',[sName '.json']), sensor);

    % We want to write these to the sensor database also
    if ~isempty(ourDB); ourDB.store(sensor, 'collection','sensors'); end

end

end
