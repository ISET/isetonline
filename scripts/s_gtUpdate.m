% Update Ground Truth in DB Documents for the Ford scenes
%
% Written to allow updates/fixes when ground truth
% calculations are changed.

% D.Cardinal, Stanford University, 2023
% builds on Zhenyi & Devesh's scenes and renders

% Can optionally recreate the ground truth in our EXR scenes
% or just update our sensor images or some other collection
gtRecreate = false;
if gtRecreate
    projectName = 'Ford'; % we currently use folders per project
    projectFolder = fullfile(iaFileDataRoot('local', true), projectName);
    EXRFolder = fullfile(projectFolder, 'SceneEXRs');

    % Not sure we want to rely on this indefinitely
    sceneFolder =  fullfile(projectFolder, 'SceneMetadata');
    infoFolder = fullfile(projectFolder, 'additionalInfo');

    % Store in our collection of rendered auto scenes (.EXR files)
    % and in sensorImages
    useCollection{1} = 'autoScenesEXR';
    useCollection{2} = 'sensorImages';
else
    % we already have gt in autoScenesEXR, but we want to 
    % update sensorImages based on it
    useCollection{1} = 'sensorImages';
end

ourDB = isetdb();

% Retrieve all of our scenes
ourScenes = ourDB.docFind('autoScenesEXR',[]);

for ii = 1:numel(ourScenes)
    
    if gtRecreate
        % we recalculate the ground truth right from the .exr files
        instanceFile = fullfile(EXRFolder, sprintf('%s_instanceID.exr', ourScenes(ii).sceneID));
        additionalFile = fullfile(infoFolder, sprintf('%s.txt', ourScenes(ii).sceneID));

        [GTObjects, closestTarget] = olGetGroundTruth([], 'instanceFile', instanceFile, ...
            'additionalFile', additionalFile);
    % Store whatever ground truth we can calculate
    ourScenes{ii}.GTObject = GTObjects;
    ourScenes{ii}.closestTarget = closestTarget;
    else
        % We already have ground truth in our SceneEXR
    end

    % now update the document in the DB
    ourDB.gtUpdate(useCollection, ourScenes(ii));
    fprintf("Processed scene #: %d\n", ii);
end

