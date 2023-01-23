% Get a look at our PBRT assets by browsing thumbnails
%

assetCollection = 'assetsPBRT';

ourDB = isetdb();

assets = ourDB.find(assetCollection);

% array of thumbnails
images = {};

for ii = 1:numel(assets)
    if ~isempty(assets(ii).thumbnail) && isfile(assets(ii).thumbnail)% we've found a thumbnail to display
        images(end+1) = {assets(ii).thumbnail}; %#ok<SAGROW> 
    else
        images(end+1) = zeros(300,300,3); %#ok<SAGROW> 
    end
end

thumbnails = imageDatastore(images);
imageBrowser(thumbnails);

