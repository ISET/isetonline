% Simple script to create DB Documents for the
% our ISET Scenes in the ISET3d repo

% D.Cardinal, Stanford University, 2024

projectName = 'ISET3d'; % we currently use folders per project

%% Assume our scenes are in folders under
% /acorn/data/iset/iset3d-repo/data/scenes, and have the same name as their pbrt file

% Enumerate scenes:

pcDataRoot = 'y:\'; % place your local version here
linuxDataRoot = '/acorn/';
macDataRoot = '/Volumes'; % SOMETHING like this
if ispc
    dataRoot = pcDataRoot;
else
    dataRoot = linuxDataRoot;
end

sceneRelativePath = 'data/iset/pbrt-v4-scenes';
sceneLocalParentFolder = fullfile(dataRoot, sceneRelativePath);
sceneParentFolder = fullfile(dataRoot, sceneRelativePath);
sceneFolders = dir(sceneParentFolder);

sceneRecipeFiles = {};
for ii=1:numel(sceneFolders)
    if sceneFolders(ii).isdir && sceneFolders(ii).name(1)~='.'
        % we have what we hope is a scene folder
        scenePath = fullfile(sceneFolders(ii).folder, sceneFolders(ii).name);

        % so check for a pbrt file with the same name
        scenePBRTFiles = dir(fullfile(scenePath,'*.pbrt'));
        for jj = 1:numel(scenePBRTFiles)
            if ~isequal(scenePBRTFiles(jj).name,'materials.pbrt') ...
                    & ~isequal(scenePBRTFiles(jj).name,'geometry.pbrt')
                % now we have one to import
                sceneRecipeFiles{end+1} = ...
                    fullfile(scenePBRTFiles(jj).folder, scenePBRTFiles(jj).name); %#ok<SAGROW>
            end
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
    ourRecipe.fileName = fixPath(sceneRecipeFiles{ii});

    % get the scene id if needed
    [~, n, e] = fileparts(sceneRecipeFiles{ii});
    ourRecipe.sceneID = n;

    % Project-specific metadata
    ourRecipe.project = "ISET3d";
    ourRecipe.creator = "Various";
    ourRecipe.sceneSource = "ISET3d Repo";
    ourRecipe.recipeFile = fixPath(sceneRecipeFiles{ii});

    % First store the original @recipe info
    ourDB.store(ourRecipe, 'collection', pbrtCollection);

end

function newPath = fixPath(oldPath)

% Eventually improve how we pass these in:
pcDataRoot = 'y:\'; % place your local version here
linuxDataRoot = '/acorn/';
macDataRoot = '/Volumes'; % SOMETHING like this

if ispc
    % swap pcDataRoot to linuxDataRoot
    newPath = strrep(oldPath, pcDataRoot, linuxDataRoot);
    newPath = dockerWrapper.pathToLinux(newPath);
else
    newPath = oldPath;
end

end
