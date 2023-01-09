% Simple script to create DB Documents for the Ford scenes

if ispc
    sceneFolder = 'Y:\data\iset\isetauto\ISETRenderings_sceneMeta';
else
    % not implemented yet
    return
end

sceneDataFiles = dir(fullfile(sceneFolder,'*.mat'));

% open our database
portNumber = 49153; % this changes, need to figure out why
ourDB = db('dbServer','seedling','dbPort',portNumber);

useCollection = 'autoscenes';

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

