% Simple script to create DB Documents for the
% our ISET Scenes in the ISET3d repo 

% D.Cardinal, Stanford University, 2024

projectName = 'ISET3d'; % we currently use folders per project

%% Assume our scenes are in folders under
% /data/scenes, and have the same name as their pbrt file

% Enumerate scenes:
sceneParentFolder = piDirGet('scenes');
sceneFolders = dir(sceneParentFolder);

for ii=1:numel(sceneFolders)
    if isfolder(sceneFolders(ii)) && sceneFolders(ii).name(1)~='.'
        % we have what we hope is a scene folder
        scenePath = fullfile(sceneFolders(ii).folder, sceneFolders(ii.name));

        % so check for a pbrt file with the same name
        if exists(xxx,'file')
            % now we have one to import
        else
            fprintf("Mal-formed scene %s found\n", xxx);
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
    ourRecipe.fileName = '';
    if isfield(ourRecipe, '_id')
        ourRecipe = rmfield(ourRecipe,'_id');
    end
    p = sceneRecipeFiles(ii).folder;
    ne = sceneRecipeFiles(ii).name;
    [~, n, e] = fileparts(sceneRecipeFiles(ii).name);

    % Project-specific metadata
    ourRecipe.project = "ISET3d";
    ourRecipe.creator = "Various";
    ourRecipe.sceneSource = "ISET3d Repo";
    ourRecipe.sceneID = n;
    ourRecipe.recipeFile = fullfile(sceneRecipeFiles(ii).folder, ...
        sceneRecipeFiles(ii).name);

    % First store the original @recipe info
    ourDB.store(ourRecipe, 'collection', recipeCollection);

    for jj = 1:numel(sceneSuffixes)

        recipeFile = fullfile(p,[n '_' sceneSuffixes{jj} '.pbrt']);
        if isfile(recipeFile)

            if isfield(ourRecipe, '_id')
                ourRecipe = rmfield(ourRecipe,'_id');
            end
            % Scene specific metadata
            ourRecipe.lightingType = sceneSuffixes{jj};
            ourRecipe.fileName = recipeFile;

            ourDB.store(ourRecipe, 'collection', pbrtCollection);
        end
    end
end


