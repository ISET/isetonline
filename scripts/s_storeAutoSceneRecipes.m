% Simple script to create DB Documents for the Ford scene recipes
%
% Recipes for the Ford project were created using multiple
% different light sources for each scene. So we have several
% recipe files for each scene, but they are independent recipes.

% D.Cardinal, Stanford University, 2023
% builds on Zhenyi's recipes

projectName = 'Ford'; % we currently use folders per project
projectFolder = fullfile(iaFileDataRoot('local', true), projectName);
sceneRecipeFolder =  fullfile(projectFolder, 'SceneRecipes');

% These files have some information, but aren't strictly necessary
% for storing the recipes
sceneMetadataFiles = dir(fullfile(sceneRecipeFolder,'*.mat'));

% For this project, recipes are stored as <ID>_<lighting>.pbrt
% with <ID> being one of the numbered scenes reference in a .mat file

% In this case, instead of a single recipe per scene, there
% are several, reflecting the components of the lighting
sceneSuffixes = {'skymap', 'otherlights', 'headlights', ...
    'streetlights'};

% Store in our collection of rendered auto scenes (.EXR files)
useCollection = 'autoScenesRecipes';

% open the default ISET database
ourDB = isetdb();

% create auto recipes collection if needed
try
    createCollection(ourDB.connection,useCollection);
catch
end

for ii = 1:numel(sceneMetadataFiles)

    p = sceneMetadataFiles(ii).folder;
    ne = sceneMetadataFiles(ii).name;
    [~, n, e] = fileparts(sceneMetadataFiles(ii).name);

    for jj = 1:numel(sceneSuffixes)

        recipeFile = fullfile(p,[n '_' sceneSuffixes{jj} '.pbrt']);
        if isfile(recipeFile)
            ourRecipe = [];

            % Project-specific metadata
            ourRecipe.project = "Ford Motor Company";
            ourRecipe.creator = "Zhenyi Liu";
            ourRecipe.sceneSource = "Blender";

            % Scene specific metadata
            ourRecipe.sceneID = n;
            ourRecipe.lightingType = sceneSuffixes{jj};
            ourRecipe.fileName = recipeFile;

            ourDB.store(ourRecipe, 'collection', useCollection);
        end
    end
end

