% Simple script to create DB Documents for the
% our ISET Assets from the ISET3d repo 

% D.Cardinal, Stanford University, 2024

projectName = 'ISET3d'; % we currently use folders per project

%% Assume our scenes are in folders under
% /acorn/data/iset/iset3d-repo/data/assets, and have the same name as their pbrt file

% Enumerate scenes:

pcDataRoot = 'y:\'; % place your local version here
linuxDataRoot = '/acorn/';
macDataRoot = '/Volumes'; % SOMETHING like this
if ispc
    dataRoot = pcDataRoot;
else
    dataRoot = linuxDataRoot;
end

assetsRelativePath = 'data/iset/iset3d-repo/data/assets';
assetsLocalParentFolder = fullfile(dataRoot, assetsRelativePath);
assetsParentFolder = fullfile(dataRoot, assetsRelativePath);
assetFolders = dir(assetsParentFolder);

assetMATFiles = {};

for ii=1:numel(assetFolders)
    if assetFolders(ii).name(1)~='.'
       
        % so check for a asset files with the same name
        % Can't use fullfile as works backwards on Windows
        % (or use pathToLinux after it)
        assetMATFile = [fixPath(assetFolders(ii).folder) '/' assetFolders(ii).name];
        
        % now we have one to import
        assetMATFiles{end+1} = assetMATFile; %#ok<SAGROW>

    end
end

%{ 
% Bring back this second level scan later for character asset support
for ii=1:numel(assetFolders)
    if assetFolders(ii).isdir && assetFolders(ii).name(1)~='.'
        % we have what we hope is a scene folder
        assetPath = fullfile(assetFolders(ii).folder, assetFolders(ii).name);

        % so check for a pbrt file with the same name
        assetMATFile = fullfile(assetPath,[assetFolders(ii).name '.mat']);
        if exist(assetMATFile,'file')
            % now we have one to import
            assetRecipeFiles{end+1} = assetMATFile; %#ok<SAGROW>
        else
            fprintf("Mal-formed asset %s found\n", assetFolders(ii).name);
            % skipping
        end
    else
        % skip
    end
end
%}

% Store in our collection of ISET3d scenes (.pbrt files)
assetCollection = 'ISETAssets';

% open the default ISET database
ourDB = isetdb();

% create ISET scene collections if needed
try
    createCollection(ourDB.connection,assetCollection);
catch
end

for ii = 1:numel(assetMATFiles)

    % clear these
    ourAsset.fileName = fixPath(assetMATFiles{ii});

    % get the scene id if needed
    [~, n, e] = fileparts(assetMATFiles{ii});
    ourAsset.assetID = n;

    % Project-specific metadata
    ourAsset.project = "ISET3d";
    ourAsset.creator = "Various";
    ourAsset.assetSource = "ISET3d Repo";
    ourAsset.assetFile = fixPath(assetMATFiles{ii});

    % First store the original @recipe info
    ourDB.store(ourAsset, 'collection', assetCollection);

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
