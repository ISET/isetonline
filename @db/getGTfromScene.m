function GTObjects = getGTfromScene(obj, sceneType, sceneID)
%GETGTFROMSCENE retrieve Ground truth from a scene in the database
% Currently supports auto scenes rendered for the Ford project
%
% Input:
%   Scenetype -- 'auto'
%   SceneID   -- <ID of the desired scene>
%
% Output:
%   GTObject structure
%
% Example:
%{
   ourDB = db.ISETdb();
   GTObject = ourDB.getGTfromScene('auto', '1112153442');
%}
% D.Cardinal, Stanford University, 2023

% Assume our db is open & query
if ~isopen(obj.connection)
    return;
end

% We only support auto scenes for now
switch sceneType
    case 'auto'
        dbTable = 'autoScenesEXR';
        % sceneIDs are unique for auto scenes
        queryString = sprintf("{""sceneID"": ""%s""}", sceneID);
        ourScene = obj.find(dbTable, 'query', queryString);
        if ~isempty(ourScene) && isfield(ourScene,'GTObject')
            GTObjects = ourScene.GTObject;
        else
            GTObjects = [];
        end
    case other
        warning("Scene Type %s not supported", sceneType);
        GTObjects = [];
end


end

