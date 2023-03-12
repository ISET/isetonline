% Simple script to create DB Documents for the
% Test Scenes (.jpg or .png) used for Flare removal tests
%

% D.Cardinal, Stanford University, 2023

projectName = 'Ford'; % we currently use folders per project
projectFolder = fullfile(iaFileDataRoot(), projectName);

% folders for Pixel 4a and DENSE test scenes
pixel4aFolder =  fullfile(projectFolder, 'Flare_paper','test_set','dense');
denseFolder =  fullfile(projectFolder, 'Flare_paper', 'test_set','dense');

% There are both .jpg and .png but jpegs have the metadata
pixel4aFiles = dir(fullfile(pixel4aFolder,'*.jpg'));
denseFiles = dir(fullfile(denseFolder, '*.jpg'));

% Store in a collection of flare test scenes
flareCollection = 'TestScenes_Flare';

% open the default ISET database
ourDB = isetdb();

% create collection if needed
try
    createCollection(ourDB.connection,flareCollection);
catch
end

% Not sure if we need to process 4a & Dense files separatel?
flareTestFiles = [pixel4aFiles, denseFiles];

for ii = 1:numel(flareTestFiles)

    ourTestDoc.imagePath = flareTestFiles(ii);

    % Get whatever metadata we can out of the file
    ourTestDoc.metadata = imfinfo(flareTestFiles(ii));

    % Project-specific metadata
    ourTestDoc.project = "Ford";
    if contains(flareTestFiles(ii),'pixel')
        ourTestDoc.creator = "Brian Wandell";
    else
        ourTestDoc.creator = "DENSE Dataset";
    end

    % Store our document
    ourDB.store(ourTestDoc, 'collection', flareCollection);

end
