% Simple script to create DB Documents for the
% our ISET Scenes in the ISET3d repo 

% D.Cardinal, Stanford University, 2024

projectName = 'ISET3d'; % we currently use folders per project

%% Assume our scenes are in folders under
% /acorn/data/iset/iset3d-repo/data/scenes, and have the same name as their pbrt file

% Enumerate scenes:
sceneParentFolder = '/acorn/data/iset/iset3d-repo/data/scenes';
sceneFolders = dir(sceneParentFolder);

sceneRecipeFiles = {};
for ii=1:numel(sceneFolders)
    if sceneFolders(ii).isdir && sceneFolders(ii).name(1)~='.'
        % we have what we hope is a scene folder
        scenePath = fullfile(sceneFolders(ii).folder, sceneFolders(ii).name);

        % so check for a pbrt file with the same name
        scenePBRTFile = fullfile(scenePath,[sceneFolders(ii).name '.pbrt']);
        if exist(scenePBRTFile,'file')
            % now we have one to import
            sceneRecipeFiles{end+1} = scenePBRTFile; %#ok<SAGROW>
        else
            fprintf("Mal-formed scene %s found\n", sceneFolders(ii).name);
            % skipping
        end
    else
        % skip
    end
end


% Store in our collection of ISET3d scenes (.pbrt files)
pbrtCollection = 'ISETScenesPBRT';

% open the default ISET database
ourDB = isetdb();

% create ISET scene collections if needed
try
    createCollection(ourDB.connection,pbrtCollection);
catch
end

for ii = 1:numel(sceneRecipeFiles)

    % clear these
    ourRecipe.fileName = sceneRecipeFiles{ii};

    % get the scene id if needed
    p = sceneRecipeFiles{ii}.folder;
    ne = sceneRecipeFiles{ii}.name;
    [~, n, e] = fileparts(sceneRecipeFiles{ii}.name);

    % Project-specific metadata
    ourRecipe.project = "ISET3d";
    ourRecipe.creator = "Various";
    ourRecipe.sceneSource = "ISET3d Repo";
    ourRecipe.sceneID = n;
    ourRecipe.recipeFile = sceneRecipeFiles{ii};

    % First store the original @recipe info
    ourDB.store(ourRecipe, 'collection', recipeCollection);

end


