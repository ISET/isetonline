% Get a look at our PBRT assets by browsing thumbnails
%
% See the Dashlane account for how to set up Matlab preferences for
% isetonline data base when on campus.  This is not yet working for
% off-campus computers.
%

assetCollection = 'assetsPBRT';

ourDB = isetdb();

assets = ourDB.find(assetCollection);

% array of thumbnails
images = {};

for ii = 1:numel(assets)
    if ~isempty(assets(ii).thumbnail) % we've found a thumbnail to display
        images(end+1) = {assets(ii).thumbnail}; %#ok<SAGROW> 
    end
end

thumbnails = imageDatastore(images);
imageBrowser(thumbnails);

