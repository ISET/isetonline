% Simple script to create DB Documents for the Ford scenes
% 
% Currently saves obvious metadata
% Adding ability to save GTObjects

projectName = 'Ford'; % we currently use folders per project
projectFolder = fullfile(iaFileDataRoot('local', true), projectName); 
sceneFolder =  fullfile(projectFolder, 'SceneMetadata');
sceneDataFiles = dir(fullfile(sceneFolder,'*.mat'));

EXRFolder = fullfile(projectFolder, 'SceneEXRs');
infoFolder = fullfile(projectFolder, 'additionalInfo');

useCollection = 'autoScenes';

ourDB = db.ISETdb();

% create auto collection if needed
try
    createCollection(ourDB.connection,useCollection);
catch
end

for ii = 1:numel(sceneDataFiles)
    load(fullfile(sceneDataFiles(ii).folder, ...
        sceneDataFiles(ii).name)); % get sceneMeta struct
    sceneMeta.project = "Ford Motor Company";
    sceneMeta.creator = "Zhenyi Liu";
    sceneMeta.sceneSource = "Blender";

    % Update dataset folder to new layout
    sceneMeta.datasetFolder = EXRFolder;

    % in theory we can get the ground truth from the original
    % .exr files. Do we need these .mat files?
    instanceFile = fullfile(EXRFolder, ...
            sprintf('%s_instanceID.exr', imageID));
    additionalFile = fullfile(infoFolder, ...
            sprintf('%s.txt',imageID));

    GTObjects = olGetGroundTruth([], 'instanceFile', instanceFile, ...
        'additionalFile', additionalFile);

    % Store whatever ground truth we can calculate
    sceneMeta.GTObject = GTObjects;

    % instance and depth maps are too large as currently stored
    sceneMeta.instanceMap = [];
    sceneMeta.depthMap = [];
    ourDB.store(sceneMeta, 'collection', useCollection);
end

