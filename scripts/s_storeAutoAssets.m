% Store the PBRT version of the assets created for isetauto
% Fairly fixed function for now.
%
% Eventually should also store ISET assets, etc.
%
ourDB = isetdb();
assetDir = fullfile(iaFileDataRoot('local',true),'PBRT_Assets');

assetFolders = dir(assetDir);

for ii = 1:numel(assetFolders)
    assetSubFolder = fullfile(assetFolders(ii).folder, assetFolders(ii).name);
    % check to see if it is a real asset folder
    if isfolder(assetSubFolder) && ~isequal(assetFolders(ii).name(1), '.')
        ourDB.assetStore(assetSubFolder);
    end
end
