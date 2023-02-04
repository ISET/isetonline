function result = run(obj)
% Run a specific scenario on a set of scenes
switch obj.scenarioType
    case 'isetscene'
        result = makeScenesFromRenders(obj.scenarioInput, ...
            obj.scenarioParameters{:});
end
end
