classdef scenario < handle
    %SCENARIO Specific set of experimental conditions
    %   Draws on our database of scenes and images
    %{

        We have a library of Recipes, currently created in Blender
        as ISET3d @recipe objects stored in .mat files. 

        Scenarios can flow from there, or start later in the pipeling.

        The first (optional) customization step is edits to the @recipe.
        For example, changing the camera position.

        There is an (optional) step where light sources are 
        differentiated so that each @recipe becomes several.

        The resulting recipes are written using piWrite() to .pbrt 'scenes'

        They can then be rendered into EXR files that represent
        the radiance from the now-modified original @recipe.

        These .EXR files can be turned into ISET scenes. If light sources or 
        other aspects have been broken out, they can either be recombined
        using the EXR renders, or having each rendered into a scene and
        using piSceneAdd().

        The original scenario is "nighttime"

        Conceptually, scenarios can include one or more of the following:
        -- Recipe to .EXR  or ISET3d Scene using PBRT-v4
        -- EXR Scene to ISET Scene using weights
        (Does this turn into an @experiment at this point?)
        -- ISET Scene to OI using optics and/or Flare
        -- OI to SensorImage using a sensor
        -- (When appropriate) Store sensorImage in ISETdb
        -- (When appropriate) Create metadata.json for ISETOnline

        EXAMPLE:
            useScenario = scenario();
            useScenario.scenarioName = 'SomethingNew';
            useScenario.sourceProject = 'Ford';
            useScenario.sourceType = 'autoscenesiset';
            useScenario.sourceScenario = 'nighttime';
            loadedScenes = useScenario.loadData;
            fprintf('Loaded: %d scenes. First Scene:\n', numel(loadedScenes));
            disp(loadedScenes{1});
            useScenario.save(); % writes to /data/scenarios
            % useScenario.writeToDB(); % Not implemented yet

        Initial Example Use Case (DJC):
        Create Scenario to Experiment with flare on some of our Auto scenes:
        -- Start with our AutoSceneISET scenes (or a sub-set)
        -- oiCompute with optics (generic or lens)
        -- piFlareApply calc
        -- combine irradiance using weights (say .96 & .04, for example)
        -- render through sensor(s)
        -- Do something interesting with the results:)

    %}

    % D.Cardinal, Stanford University, 2023

    properties
        scenarioName;
        sourceProject;
        sourceType;
        sourceCollection; % set when data is loaded

        sourceScenario; % set to limit source data to an existing scenario
        sourceData; % data loaded for processing by .loadData
        filteredData; % filtered for scenario, etc. in Matlab

        scenarioInput;
        scenarioParameters;
    end

    methods(Static)
        function createFromFile(fileName)
            % There should be a way to do this without
            % specifying every attribute.

            % Look in data/scenarios by default
        end
    end

    methods
        function obj = scenario(varargin)
            %SCENARIO Construct an instance of this class
            p = inputParser;
            varargin = ieParamFormat(varargin);
            addParameter(p,'scenarioname','defaultScenario');
            addParameter(p,'sourceproject',''); % e.g. Ford
            addParameter(p,'sourcetype','autoscenesiset',@ischar);
            addParameter(p,'sourcescenario',''); % allow just 1 for now
            addParameter(p,'scenarioparameters',[]);

            parse(p,varargin{:});

            obj.scenarioName = p.Results.scenarioname;
            obj.sourceProject = p.Results.sourceproject;

            % SourceType is the type of data we start with
            % It is used to specify the isetdb collection we query
            obj.sourceType = p.Results.sourcetype;
            obj.sourceScenario = p.Results.sourcescenario;
            obj.scenarioParameters = p.Results.scenarioparameters;

        end

        function filteredData = loadData(obj)
            % ScenarioSourceType
            switch obj.sourceType
                case 'autoscenesrecipe'
                    obj.sourceCollection = 'autoScenesRecipe';
                    fprintf("Start with an ISET recipe -- usually from Blender");
                case 'autoscenespbrt'
                    fprintf("Start with a prbrt exported version iset scene");
                    obj.sourceCollection = 'autoScenesPBRT';
                case 'autoscenesiset'
                    fprintf("Start with an iset scene");
                    obj.sourceCollection = 'autoScenesISET';
                case 'autoscenesexr'
                    fprintf("Start with an exr scene");
                    obj.sourceCollection = 'autoScenesEXR';
            end
            ourDB = isetdb();
            if ~isempty(obj.sourceProject)
                queryString = sprintf("{""project"": ""%s""}", obj.sourceProject);
            else
                queryString = '';
            end
            obj.sourceData = ourDB.docFind(obj.sourceCollection, queryString);
            fprintf("Found %d images\n",numel(obj.sourceData));

            %% Filtering by scenario
            if ~isempty(obj.sourceScenario)
                filteredIndex = cellfun(@(x) matches(x.scenario, obj.sourceScenario), obj.sourceData);
                obj.filteredData = obj.sourceData(filteredIndex);
            else
                obj.filteredData = obj.sourceData;
            end
            fprintf("Filtered %d images\n",numel(obj.filteredData));
            filteredData = obj.filteredData;

        end

        function print(obj)
            %PRINT See what we hae
            disp(obj)
        end

        % Save to Scenarios Folder (at least by default
        function save(obj)   
            jsonObj = jsonencode(obj);
            jsonwrite(fullfile(olDirGet('scenarios'),[obj.scenarioName '.json']),jsonObj);
        end

    end
end

