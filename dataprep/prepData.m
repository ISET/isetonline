% Render & Export objects for use in "oi2sensor" / oiOnline
%
% D. Cardinal, Stanford University, 2022
%
%% Set output folder
% I'm not sure where we want the data to go ultimately.
% As it will wind up in the website and/or a db
% We don't want it in our path or github (it wouldn't fit)
%

% This is the place where our Web app expects to find web-accessible
% Data files when running our dev environment locally. For production
% use, it, along with the static "build" folder need to be copied over.
outputFolder = fullfile(onlineRootPath,'simcam','public');
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

% Need to make db optional, as not everyone will be set up for it.
% Port number seems to wander a bit:)
ourDB = db('dbServer','seedling','dbPort',49211);

% If we are also using Mongo create our collections first!
ourDB.createSchema;

% Our webserver pulls metadata from a private folder
privateDataFolder = fullfile(onlineRootPath,'simcam','src','data');
if ~isfolder(privateDataFolder)
    mkdir(privateDataFolder);
end

% For performance we might want to have a "metadata only" update option
% in the case where we are adding new information to our metadata.json
% but not re-rendering the actual sensor images. TBD

%% Export sensor(s)
% Provide data for the sensors used so people can work with it on their own
sensorFiles = {'MT9V024SensorRGB.mat', 'imx363.mat',...
    'ar0132atSensorrgb.mat', ...
    'ar0132atSensorRGBW.mat', ...
    'ar0132atSensorRCCC.mat', ...
    'NikonD100Sensor.mat'};

if ~isfolder(fullfile(outputFolder,'sensors'))
    mkdir(fullfile(outputFolder,'sensors'))
end

% Write parameters for each sensor as a separate JSON file
% For those who want to do other calculations
for ii = 1:numel(sensorFiles)
    load(sensorFiles{ii}); % assume they are on our path
    % change suffix to json
    [~, sName, fSuffix] = fileparts(sensorFiles{ii});
    jSensor = jsonencode(sensor);
    sFileName = fullfile(outputFolder,'sensors',[sName '.json']);
    % Is there really not a simpler api?
    fid = fopen(sFileName,'w');
    fprintf(fid,'%s',jSensor);
    fclose(fid);
    jsonwrite(fullfile(outputFolder,'sensors',[sName '.json']), sensor);
    % We want to write these to the sensor database also
    ourDB.store(sensor, 'collection','sensor');

end

%% Export Lenses
%
lensRoot = isetRootPath;
lensFiles = lensC.list('quiet', true, 'lensRoot', lensRoot);

lensNames = {lensFiles.name};

lensCount = numel(lensFiles);

for ii = 1:lensCount
    lensFileName = lensFiles(ii).name;
    % Get the full path to load
    lensFile = fullfile(lensFiles(ii).folder, lensFileName);
    ourLens = jsonread(lensFile);
    ourDB.store(ourLens, 'collection','lens');
end

%% TBD Export "Scenes"
% Our scenes won't typically be ISET scenes.
% Instead they will be recipes usable by the
% Vistalab version of PBRT and by ISET3d.
% But we could export them for download

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

% For now we have the OI folder in our Matlab path
% As we add a large number we might want to enumerate a data folder
% Or even get them from a database

oiFiles = {'oi_001.mat', 'oi_002.mat', ...
    'oi_003.mat', 'oi_004.mat', 'oi_005.mat', 'oi_006.mat'};

% Loop through OIs and render them with our sensors
% and with whatever variants (burst, bracket, ...) we want
if ~isfolder(fullfile(outputFolder,'oi'))
    mkdir(fullfile(outputFolder,'oi'))
end

for ii = 1:numel(oiFiles)

    [~, fName, fSuffix] = fileparts(oiFiles{ii});
    oiDataFile = fullfile(outputFolder,'oi',[fName fSuffix]);

    % For now only copy if we don't have it already
    % Might need to change if we have updated versions
    if ~isfile(oiDataFile)
        load(oiFiles{ii}); % assume OIs are on our pat
        copyfile(which(oiFiles{ii}), oiDataFile);
    else
        load(oiDataFile);
    end
    % Total hack to demonstrate how a lighting tag could work
    illumination = 'unknown';
    switch(fName)
        case 'oi_001'
            illumination = 'night';
        case 'oi_002'
            illumination = 'day';
        case 'oi_fog'
            illumination = 'fog';
    end
    % Pre-compute sensor images
    % Start by giving them a folder
    if ~isfolder(fullfile(outputFolder,'images'))
        mkdir(fullfile(outputFolder,'images'))
    end

    % experiment with camera motion
    % for now each shift adds oi data to the oi
    % for expediency we're doing this once per OI, although ideally
    % we'd recalc for each sensor.
    oiBurst = oi;

    % Pick a large amount for testing
    oiBurst = oiCameraMotion(oiBurst, 'amount', ...
        {[0 .05], [0 .1], [0 .15], [0 .2]});

    % Loop through our sensors:
    for iii = 1:numel(sensorFiles)
        load(sensorFiles{iii}); % assume they are on our path
        % prep for changing suffix to json
        [~, sName, ~] = fileparts(sensorFiles{iii});

        % At least for now, scale sensor
        % to match the FOV
        hFOV = oiGet(oi,'hfov');
        sensor = sensorSetSizeToFOV(sensor,hFOV,oi);

        %% Now we have an OI + Sensor
        % so at this point we should have a notion/function
        % of what variants we want for that "sensorimage"

        % Default Auto-Exposure breaks with oncoming headlights, etc.
        % So we're using Mean/.5 for now.
        % We also use some variants
        %aeMethod = 'mean';
        %aeMean = .5;
        aeMethod = 'specular';
        aeLevels = .8;
        aeTime = autoExposure(oi,sensor, aeLevels, aeMethod);
        aeMethod = 'hdr';
        aeHDRTime  = autoExposure(oi,sensor,aeLevels,aeMethod,'numframes',7);

        % Now derive bracket & burst times:
        % These are hacked for now to get things working.
        % Then we can wire them up more elegantly
        % For static images with no fancy AI,
        % I think a "mini-HDR" is actually equivalent
        % to doing simple burst calculations
        burstFrames = 5;
        burstTimes = repelem(aeTime/burstFrames, burstFrames);
        numFrames = 3; % should we allow for 3 or 5?

        bracketStops = 3; % for now
        bracketTimes = [aeTime/(3*bracketStops), ...
            aeTime, aeTime * (3*bracketStops)];

        sensor_ae = sensorSet(sensor,'exp time',aeTime);
        sensor_burst = sensorSet(sensor,'exp time',burstTimes);
        sensor_burst = sensorSet(sensor_burst, 'exposure method', 'burst');
        sensor_bracket = sensorSet(sensor,'exp time',bracketTimes);

        % See how long this takes in case we want
        % to allow users to do it in real-time on our server
        tic;
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

        % Create a default IP so we can see some baseline image
        % This could of course be tweaked
        ip_ae = ipCreate('ourIP',sensor_ae);
        % For RCCC we need to set the IP differently
        if isequal(sensor_ae.name, 'AR0132AT-RCCC')
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

        % we could also save without an IP if we want
        %sensorSaveImage(sensor, sensorJPEG  ,'rgb');

        % Generate a quick thumbnail
        thumbnail = imread(ipLocalJPEG);
        thumbnail = imresize(thumbnail, [128 128]);
        imwrite(thumbnail, ipLocalThumbnail);

        % We need to save the relative paths for the website to use
        sensor_ae.metadata.jpegName = ipJPEGName;
        sensor_ae.metadata.thumbnailName = ipThumbnailName;
        % we also have bracket & burst (& others)
        % how do we want to store / note them?
        sensor_ae.metadata.burstJPEGName = ipJPEGName_burst;
        sensor_ae.metadata.bracketJPEGName = ipJPEGName_bracket;

        sensor_ae.metadata.jpegName = ipJPEGName;
        sensor_ae.metadata.thumbnailName = ipThumbnailName;

        % Stash exposure time for reference
        sensor_ae.metadata.exposureTime = aeTime;
        sensor_ae.metadata.aeMethod = aeMethod;

        % Save OI & Raw sensor file locations
        sensor_ae.metadata.oiFile = [fName fSuffix];

        % Start stashing pixel information
        sensor_ae.metadata.pixel = sensor_ae.pixel;

        % WE ALSO WANT ILLUMINATION FROM THE OI
        % FOR NOW We've stuck in some simple examples
        sensor_ae.metadata.illumination = illumination;

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
        % by default use the assetDB
        ourDB.store(sensor_ae.metadata,"collection","sensor");

        % We ONLY write out the metadata in the main .json
        % file to keep it of reasonable size
        % NOTE: Currently we re-write the entire file
        % Each time so dataPrep needs to run a complete batch
        % We might want to add an "Update" option that only
        % adds and updates?
        imageMetadataArray = [imageMetadataArray sensor_ae.metadata];

    end

    % We can write metadata as one file -- but since it is only
    % read by our code, we place it in the code folder tree
    % instead of the public data folder
    jsonwrite(fullfile(privateDataFolder,'metadata.json'), imageMetadataArray);

end