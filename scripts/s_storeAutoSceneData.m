% Simple script to create DB Documents for the Ford scenes
% 
% Currently only saves obvious metadata
% Ideally would correlate the annotation files and
% save easier to use versions of targets / GT

sceneFolder = fullfile(iaFileDataRoot(), 'Ford', 'sceneMetadata');
sceneDataFiles = dir(fullfile(sceneFolder,'*.mat'));

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

    % instance and depth maps are too large as currently stored
    sceneMeta.instanceMap = [];
    sceneMeta.depthMap = [];
    ourDB.store(sceneMeta, 'collection', useCollection);
end

