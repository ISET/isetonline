function show(obj, dbCollection)
%SHOW Display table of documents in a collection

% NOTE: Matlab doesn't have a native 'list collections'
%       command (sadly), so for now user has to pick
%       one

%{
% Examples:
ourDB = idb();
ourDB.show('scenes');

ourDB = idb();
ourDB.show('lenses');
%}

foundDocuments = [];

% We split into cases to allow for custom pretty-printing
% by document type over time
switch dbCollection
    case 'scenes'
        foundDocuments = obj.connection.find('ISETScenesPBRT');
    case 'assets'
        foundDocuments = obj.connection.find('assets');
    case 'lenses'
        
        foundLenses = obj.connection.find('lenses');
        % In this case we get a cell array
        foundDocuments = [cellfun(@(x) x.name, foundLenses, 'UniformOutput',false)];

    case 'textures'
        foundDocuments = obj.connection.find('textures');
    case 'auto_scenes'
        foundDocuments = obj.connection.find('autoScenesPBRT');
    otherwise % should try to 'list' here
        foundDocuments = obj.connection.find(dbCollection);
end

% stop if we didn't find anything
if isempty(foundDocuments)
    fprintf("Empty or non-existent collection\n");
    return
end


%% Common pretty-printing

% Some objects (like ISET scenes) return a simple Struct Array
% But other objects (like lenses) are more complex, so Matlab
% returns them in a cell array with each element being the 
% structure for one of the objects
if iscell(foundDocuments)
    documentTable = cell2table(foundDocuments);
else
    % Drop _id column
    foundDocuments = rmfield(foundDocuments,'_id');
    documentTable = struct2table(foundDocuments);
end


%% Now we show the collection to the user
ourFigure = uifigure('Name', ['Showing: ' dbCollection],...
    'Position',[200 200 800 450]);

ourUITable = uitable(ourFigure, "Data",documentTable, ...
    'Position',[20 20 800 400]);
drawnow

end

