function result = olStorePhotos(folderpath, varargin)
%OLSTOREPHOTOS Store info about a folder of photos in isetdb()

%{ 
% Examples:
   olStorePhotos('/acorn/data/iset/source_images/pixel4a/night_images/20230225', 'type', 'OpenCamera');
   olStorePhotos('/acorn/data/iset/source_images/pixel4a/night_images/20221106', 'type', 'OpenCamera');
   olStorePhotos('/acorn/data/iset/source_images/pixel4a/night_images/20221113', 'type', 'OpenCamera');
   olStorePhotos('/acorn/data/iset/source_images/pixel4a/night_images/20221119', 'type', 'OpenCamera');
   olStorePhotos('/acorn/data/iset/source_images/pixel4a/night_images/20221120', 'type', 'OpenCamera');

%}

% D. Cardinal, Stanford University, 2023

p = inputParser;

p.addParameter('type','');
p.addParameter('note','');

p.parse(varargin{:});

if ~isfolder(folderpath)
    warning("Folder %s doesn't exist. \n", folderpath);
    result = -1; return;
end

photoType = p.Results.type;
photoNote = p.Results.note;

ourDB = isetdb();
photoCollection = 'photosCaptured';

% Assume we have a 'root' image name in the folder, with one or more
% suffixes denoting versions of the photo. That might include a 'raw'
% version (typically .dng, or .cr<x> or .n<x>) and a processed version like
% a .jpg and/or .tif(f)

% Not sure if we should give each option its own field or stash them in a
% "derivations" list?

% We also want to get the meta data for the photos, and put that in the
% database. It's going to vary, so for starters I think we'll just do it
% "free-form" and not worry too much.

% Matlab can pull some metadata from processed files
% but I think we need dcraw() for many others

switch photoType
    case {'OpenCamera'} % Has both .dng and .jpg
        % iterate folder and find .dng images
        % get metadata
        % then also add jpeg (.jpg) images
        % store with path & maybe folder name(s) as metadata

        % in isetdb, records are Documents
        photoDoc.note = photoNote;
        photoDoc.type = photoType;

        rawFiles = dir(fullfile(folderpath,'*.dng'));
        % This gives us bits we have to assemble
        for ii = 1: numel(rawFiles)
            rawFile = fullfile(rawFiles(ii).folder, rawFiles(ii).name);

            try
                % Some files may be corrupted, so need try/catch
            photoDoc.rawData = imfinfo(rawFile);

            [p, n, ~ ] = fileparts(rawFile);
            jpegFile = fullfile(p, [n '.jpg']);
            photoDoc.jpegData = imfinfo(jpegFile);

            photoDoc.rawFile = rawFile;
            photoDoc.jpegFile = jpegFile;

            ourDB.store(photoDoc,"collection",photoCollection);
            catch MEX
                warning(MEX.identifier, "%s", MEX.message);
            end

        end

end


end

