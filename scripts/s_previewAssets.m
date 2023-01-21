% Get a look at our PBRT assets by browsing thumbnails
%

assetCollection = 'assetsPBRT';

ourDB = isetdb();

assets = ourDB.find(assetCollection);

% array of thumbnails
images = {};

for ii = 1:numel(assets)
    if ~isempty(assets.thumbnail) % we've found a thumbnail to display
        images(end+1) = {assets.thumbnail}; %#ok<SAGROW> 
    end
end

thumbnails = imageDatastore(images);
imageBrowser(thumbnails);

