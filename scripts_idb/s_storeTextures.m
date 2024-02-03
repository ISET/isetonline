% Store our Texture resources
%
% Requires that we run it on a system that can access
% the textures folder under Resources
%
ourDB = isetdb();
textureCollectionName = 'textures';

textureDir = fullfile(olFileDataRoot('type','Resources'),'textures');

textureFiles = dir(textureDir);

for ii = 1:numel(textureFiles)
    textureFileName = fullfile(textureFiles(ii).folder, textureFiles(ii).name);

    if ~isequal(textureFiles(ii).name(1), '.')
        textureStruct.Name = textureFiles(ii).name;
        textureStruct.location = textureFileName;
        ourDB.store(textureStruct,"collection",textureCollectionName);

    end
end
