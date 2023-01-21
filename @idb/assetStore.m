function result = assetStore(obj, assetFolder)
%ASSETSTORE Store pointers to folder of PBRT assets in the database
%   If available, also stores a thumbnail for previewing
%
% Example:
%
%  assetStore('v:\data\iset\isetauto\PBRT_Assets\car');
%

assetStruct = [];

if ~isfolder(assetFolder)
    warning("Asset folder: %s does not exist", assetFolder);
    result = -1;
    return;
else
    potentialAssets = dir(assetFolder);
    for ii = 1:numel(potentialAssets)
        % identify sub-folders, as these are likely assets
        if isfolder(potentialAssets(ii))
            % we probably have an asset
            assetStruct.folder = potentialAssets(ii).folder;
            assetStruct.name = potentialAssets(ii).name;
            if isfile(fullfile(assetFolder, [potentialAssets(ii).name '.png']))
                assetStruct.thumbnail = ...
                    fullfile(assetFolder, [potentialAssets(ii).name '.png']);
            else
                assetStruct.thumbnail = [];
            end
        end
    end

end

