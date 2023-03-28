% Store the PBRT version of the assets created for isetauto
% Fairly fixed function for now.
%
% Currently doesn't store meshes or textures or skymaps in with
% the other assets. Easy enough to do, but need to decide if they
% should be separate collections or just "types"
%
% Eventually should also store other ISET assets, etc.
%
ourDB = isetdb();
assetDir = fullfile(iaFileDataRoot('type','PBRT_assets'));

assetFolders = dir(assetDir);

for ii = 1:numel(assetFolders)
    assetSubFolder = fullfile(assetFolders(ii).folder, assetFolders(ii).name);
    % check to see if it is a real asset folder
    if isfolder(assetSubFolder) && ~isequal(assetFolders(ii).name(1), '.')
        ourDB.assetStore(assetSubFolder);
    end
end
