% Simple script to create DB Documents for scenarios
% (ISET scenes) generated from .EXR scenes
% 
% Currently saves obvious metadata
% TBD: Check how much we get "for free" and how much we can/should
%      look up in the database -- maybe better not to multi-store?

% D.Cardinal, Stanford University, 2023
% builds on Zhenyi & Devesh's scenes and renders

projectName = 'Ford'; % we currently use folders per project
scenarioName = 'nighttime'; % default for now, need to make a parameter

projectFolder = fullfile(iaFileDataRoot('local', true), projectName); 
EXRFolder = fullfile(projectFolder, 'SceneEXRs');
sceneFolder =  fullfile(projectFolder, 'SceneISET', scenarioName);
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

    % start with scene metadata
    sceneMeta = scene.metadata;
    sceneMeta.project = "Ford";
    sceneMeta.creator = "Zhenyi Liu";
    sceneMeta.sceneSource = "Blender";
    sceneMeta.imageID = scene.name;
    sceneMeta.scenario = scenarioName;

    % maintain the lighting parameters, which currently
    % are the only items we change between experiments
    if ~isempty(scene.metadata.lightingParams)
        sceneMeta.lightingParams = scene.metadata.lightingParams;
    end

    % Update dataset folder to new layout
    sceneMeta.datasetFolder = EXRFolder;

    % Maybe try to copy over the GTObjects from the original scene
    % or leave it to a db query to find them?

    % instance and depth maps are too large as currently stored
    sceneMeta.instanceMap = [];
    sceneMeta.depthMap = [];
    ourDB.store(sceneMeta, 'collection', useCollection);
end

