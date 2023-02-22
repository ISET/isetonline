% Simple script to create DB Documents for the
% Scenes (@recipe .MAT files) that have been rendered into
% lighting specific .EXR files.
%
% At some point when we also have other recipe customizations
% like camera position, we can extend this
%
% Recipes for the Ford project were created using multiple
% different light sources for each scene. So we have several
% recipe files for each scene, but they are independent recipes.

% D.Cardinal, Stanford University, 2023
% builds on Zhenyi's recipes

projectName = 'Ford'; % we currently use folders per project
projectFolder = fullfile(iaFileDataRoot('local', true), projectName);
sceneRecipeFolder =  fullfile(projectFolder, 'SceneRecipes');

% These are the recipes from the scenes exported from Blender
sceneMetadataFiles = dir(fullfile(sceneRecipeFolder,'*.mat'));

% For this project, recipes are stored as <ID>_<lighting>.pbrt
% with <ID> being one of the numbered scenes reference in a .mat file

% In this case, instead of a single recipe per scene, there
% are several, reflecting the components of the lighting
sceneSuffixes = {'skymap', 'otherlights', 'headlights', ...
    'streetlights'};

% Store in our collection of rendered auto scenes (.EXR files)
pbrtCollection = 'autoScenesPBRT';
recipeCollection = 'autoScenesRecipes';

% open the default ISET database
ourDB = isetdb();

% create auto recipes collections if needed
try
    createCollection(ourDB.connection,recipeCollection);
catch
end
try
    createCollection(ourDB.connection,recipeCollection);
catch
end

for ii = 1:numel(sceneMetadataFiles)

    p = sceneMetadataFiles(ii).folder;
    ne = sceneMetadataFiles(ii).name;
    [~, n, e] = fileparts(sceneMetadataFiles(ii).name);

    % Project-specific metadata
    ourRecipe.project = "Ford Motor Company";
    ourRecipe.creator = "Zhenyi Liu";
    ourRecipe.sceneSource = "Blender";
    ourRecipe.sceneID = n;

    % First store the original @recipe info
    ourDB.store(ourRecipe, 'collection', recipeCollection);

    for jj = 1:numel(sceneSuffixes)

        recipeFile = fullfile(p,[n '_' sceneSuffixes{jj} '.pbrt']);
        if isfile(recipeFile)

            % Scene specific metadata
            ourRecipe.lightingType = sceneSuffixes{jj};
            ourRecipe.fileName = recipeFile;

            ourDB.store(ourRecipe, 'collection', pbrtCollection);
        end
    end
end

