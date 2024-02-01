ourDB = idb();
isetScenes = ourDB.connection.find('ISETScenesPBRT');
autoScenes = ourDB.connection.find('autoScenesPBRT');

isetScenes(:).sceneID
%autoScenes(:).sceneID
