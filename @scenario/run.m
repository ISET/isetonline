function result = run(obj)
% Run a specific scenario on a set of scenes
switch obj.sourceType
    case 'isetscene'
        result = makeScenesFromRenders(obj.scenarioInput, ...
            obj.lightingParameters{:});
end
end
