% Get a look at our ISET textures by browsing
%
% See the Dashlane account for how to set up Matlab preferences for
% isetonline data base when on campus.  This is not yet working for
% off-campus computers.
%

textureCollection = 'textures';
thumbnailSize = [256 256];
thumbnailFiles = {};

textureResourceDir = fullfile(olFileDataRoot('type', 'Resources'), 'textures');
thumbnailDir = 'thumbnails';

ourDB = isetdb();

textures = ourDB.docFind(textureCollection, []);

if ~isfolder(fullfile(textureResourceDir, thumbnailDir))
    mkdir(fullfile(textureResourceDir, thumbnailDir));
end

for ii = 1:numel(textures)
    if ~isempty(textures(ii).location)
        try
            [p, n, e] = fileparts(textures(ii).location);

            % if we already have a thumbnail, use it
            thumbnailLocation = fullfile(textureResourceDir, ...
                    thumbnailDir, [n '-thumb.png']);
            if isfile(thumbnailLocation)
                thumbnailFiles{end+1} = thumbnailLocation;
                continue
            end
            if isequal(e, '.exr')
                % Only reads RGB HDR images currently, not hyperspectral
                tmpImage = exrread(textures(ii).location);
            else
                 tmpImage = imread(textures(ii).location); %#ok<SAGROW> 
            end
            thumbnailImage = imresize(tmpImage, thumbnailSize);
            imwrite(thumbnailImage, thumbnailLocation); %#ok<SAGROW> 
            thumbnailFiles{end+1} = thumbnailLocation;
        catch err
            % .exr files aren't directly rea
            warning("unable to load texture: %s\n", textures(ii).Name);
        end
    else
        % no image available -- should show a blank placeholder if possible
    end
end

thumbDatastore = imageDatastore(thumbnailFiles);
imageBrowser(thumbDatastore);

