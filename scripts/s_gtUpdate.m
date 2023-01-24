% Update Ground Truth in DB Documents for the Ford scenes
% 
% Written to allow updates/fixes when ground truth
% calculations are changed.

% Specifically we had a bug in the initial target distance
% calculations previously

% D.Cardinal, Stanford University, 2023
% builds on Zhenyi & Devesh's scenes and renders

projectName = 'Ford'; % we currently use folders per project
projectFolder = fullfile(iaFileDataRoot('local', true), projectName); 
EXRFolder = fullfile(projectFolder, 'SceneEXRs');

% Not sure we want to rely on this indefinitely
sceneFolder =  fullfile(projectFolder, 'SceneMetadata');
infoFolder = fullfile(projectFolder, 'additionalInfo');

% Store in our collection of rendered auto scenes (.EXR files)
useCollection = 'autoScenesEXR';

ourDB = isetdb();

% Retrieve all of our scenes
ourScenes = ourDB.find(useCollection);

for ii = 1:numel(ourScenes)

    % Update dataset folder to new layout, if needed
    %sceneMeta.datasetFolder = fullfile(projectFolder, 'SceneEXRs');

    instanceFile = fullfile(EXRFolder, sprintf('%s_instanceID.exr', ourScenes(ii).imageID));
    additionalFile = fullfile(infoFolder, sprintf("%s.txt", ourScenes(ii).imageID));

    GTObjects = olGetGroundTruth([], 'instanceFile', instanceFile, ...
        'additionalFile', additionalFile);

    % Store whatever ground truth we can calculate
    GTObject = GTObjects;
    ourScenes(ii).GTObject = GTObject;

    % now update the document in the DB
    ourDB.gtUpdate(ourScenes(ii), 'collection', useCollection);

end

