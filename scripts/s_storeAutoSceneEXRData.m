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
sceneEXRFolder =  fullfile(projectFolder, 'ScenesEXRs');
sceneEXRDataFiles = dir(fullfile(sceneFolder,'*.mat'));

% Store in our collection of rendered auto scenes (.EXR files)
useCollection = 'autoScenesEXR';

ourDB = isetdb();

% create auto collection if needed
try
    createCollection(ourDB.connection,useCollection);
catch
end

for ii = 1:numel(sceneDataFiles)
    load(fullfile(sceneEXRDataFiles(ii).folder, ...
        sceneEXRDataFiles(ii).name)); % get sceneMeta struct
    % Project-specific metadata
    sceneMeta.project = "Ford Motor Company";
    sceneMeta.creator = "Zhenyi Liu";
    sceneMeta.sceneSource = "Blender";

    % Update dataset folder to new layout
    sceneMeta.datasetFolder = sceneEXRFolder;

    % in theory we can get the ground truth from the original
    % .exr files. Do we need these .mat files?
    instanceFile = fullfile(sceneEXRFolder, ...
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

