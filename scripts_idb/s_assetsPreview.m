% Get a look at our PBRT assets by browsing thumbnails
%
% See the Dashlane account for how to set up Matlab preferences for
% isetonline data base when on campus.  This is not yet working for
% off-campus computers.
%

assetCollection = 'assetsPBRT';

ourDB = isetdb();

assets = ourDB.connection.find(assetCollection);

% array of thumbnails
images = {};

% NOTE: Currently this relies on having file system
%       access to the thumbnail files, which is possible
%       over WebDAV for local and VPN

for ii = 1:numel(assets)
    if ~isempty(assets(ii).thumbnail) && isfile(assets(ii).thumbnail)% we've found a thumbnail to display
        images(end+1) = {assets(ii).thumbnail}; %#ok<SAGROW> 
    else
        % no image available -- should show a blank placeholder if possible
    end
end

thumbnails = imageDatastore(images);
imageBrowser(thumbnails);

