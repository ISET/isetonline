% Simple script to create DB Documents for the Ford scenes
% 
%  EXR version creates db entries for the original rendered EXR files
%  ISET version creates entries for a specific set of lighting conditions
%       that have been combined into a full ISET scene object

% Currently saves obvious metadata
% Along with GTObjects (Ground Truth as calculated from the .exr files)
% [GT can also be derived from earlier metadata on objects, but
%  that hasn't been implemented here]

% D.Cardinal, Stanford University, 2023
% builds on Zhenyi & Devesh's scenes and renders

projectName = 'Ford'; % we currently use folders per project
projectFolder = fullfile(iaFileDataRoot('local', true), projectName); 
EXRFolder = fullfile(projectFolder, 'SceneEXRs');

% Not sure we want to rely on this indefinitely
sceneFolder =  fullfile(projectFolder, 'SceneMetadata');
infoFolder = fullfile(projectFolder, 'additionalInfo');

sceneDataFiles = dir(fullfile(sceneFolder,'*.mat'));

% Store in our collection of rendered auto scenes (.EXR files)
useCollection = 'autoScenesISET';

ourDB = isetdb();

% create auto collection if needed
try
    createCollection(ourDB.connection,useCollection);
catch
end

for ii = 1:numel(sceneDataFiles)
    load(fullfile(sceneDataFiles(ii).folder, ...
        sceneDataFiles(ii).name)); % get sceneMeta struct
    % Hopefully the metadata is passed along here, not added
    sceneMeta.project = "Ford Motor Company";
    sceneMeta.creator = "Zhenyi Liu";
    sceneMeta.sceneSource = "Blender";

    % Update dataset folder to new layout
    sceneMeta.datasetFolder = fullfile(projectFolder, 'SceneEXRs');

    % in theory we can get the ground truth from the original
    % .exr files. Do we need these .mat files?
    instanceFile = fullfile(EXRFolder, ...
            sprintf('%s_instanceID.exr', sceneMeta.imageID));
    additionalFile = fullfile(infoFolder, ...
            sprintf('%s.txt',sceneMeta.imageID));

    GTObjects = olGetGroundTruth([], 'instanceFile', instanceFile, ...
        'additionalFile', additionalFile);

    % Store whatever ground truth we can calculate
    sceneMeta.GTObject = GTObjects;

    % instance and depth maps are too large as currently stored
    sceneMeta.instanceMap = [];
    sceneMeta.depthMap = [];
    ourDB.store(sceneMeta, 'collection', useCollection);
end

