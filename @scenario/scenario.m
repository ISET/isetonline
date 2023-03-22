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
        -- Recipe to PBRT to Scene/EXR to sensorImages
        -- ISET Scene to OI using optics and/or Flare
        -- OI to SensorImage using a sensor
        -- (When appropriate) Store sensorImage in ISETdb
        -- (When appropriate) Create metadata.json for ISETOnline

        EXAMPLE:
            useScenario = scenario(); % can also set params in create call
            useScenario.scenarioName = 'SomethingNew';
            useScenario.sourceProject = 'Ford';
            useScenario.sourceType = 'autoscenesiset';
            useScenario.sourceScenario = 'nighttime';
            loadedScenes = useScenario.loadData;
            fprintf('Loaded: %d scenes. First Scene:\n', numel(loadedScenes));
            disp(loadedScenes{1});
            useScenario.save(); % writes to /data/scenarios
            % useScenario.writeToDB(); % Not implemented yet

        Initial Hypothetical Use Case (DJC):
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

        % This is probably wrong, I think we need to load data in the
        % appropriate "slot"
        sourceData; % data loaded for processing by .loadData
        filteredData; % filtered for scenario, etc. in Matlab

        scenarioInput;
        lightingParameters;
        
        sensors; % set of sensors to use for capturing
        lenses; % lenses to use for capturing

        % We keep track of data at whichever stages of the workflow are
        % needed, don't know how to set up sub-fields here so just make 
        % a parent?
        data;
    end

    methods(Static)
        function scenarioObject = loadFromFile(fileName)
            if ~isfile(fileName)
                % Look in data/scenarios by default
                fileName = fullfile(olDirGet('scenarios'),[fileName '.mat']);
            end
            scenarioParent = load(fileName,'obj');
            scenarioObject = scenarioParent.obj;
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
            addParameter(p,'lightingparameters',[]);

            parse(p,varargin{:});

            obj.scenarioName = p.Results.scenarioname;
            obj.sourceProject = p.Results.sourceproject;

            % SourceType is the type of data we start with
            % It is used to specify the isetdb collection we query
            obj.sourceType = p.Results.sourcetype;
            obj.sourceScenario = p.Results.sourcescenario;
            obj.lightingParameters = p.Results.lightingparameters;

            % Initialize data to null -- rough cut of categories
            obj.data.scenesRecipe = [];
            obj.data.scenesEXR = [];
            obj.data.scenesPBRT = [];
            obj.data.scenesISET = [];
            obj.data.sensorImages = [];
            obj.data.imagesTrained = [];
            
        end

        function filteredData = loadData(obj)
            % ScenarioSourceType
            switch obj.sourceType
                case 'autoscenesrecipe'
                    obj.sourceCollection = 'autoScenesRecipe';
                    resultsField = 'scenesRecipe';
                case 'autoscenespbrt'
                    obj.sourceCollection = 'autoScenesPBRT';
                    resultsField = 'scenesPBRT';
                case 'autoscenesiset'
                    obj.sourceCollection = 'autoScenesISET';
                    resultsField = 'scenesISET';
                case 'autoscenesexr'
                    obj.sourceCollection = 'autoScenesEXR';
                    resultsField = 'scenesEXR';
                case 'sensorimages'
                    obj.sourceCollection = 'sensorImages';
                    resultsField = 'sensorImages';
            end

            % Open a conection to the database and query for the desired
            % data
            ourDB = isetdb();
            if ~isempty(obj.sourceProject)
                queryString = sprintf("{""project"": ""%s""}", obj.sourceProject);
            else
                queryString = '';
            end
            % leave original source data here, 'cuz ?
            obj.sourceData = ourDB.docFind(obj.sourceCollection, queryString);
            obj = setfield(obj.data, resultsField, obj.sourceData);

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

        % Start with a (Blender-generated) .mat recipe and create
        % a pbrt version. 
        function recipeToPBRT(obj)
            % Or we could just read it, let the user edit it, and write it
            % If we have lighting or other attributes, might need to
            % generate several of these
        end

        function pbrtToISET(obj)
            % Starting with one or more pbrt recipes, create a scene
            % or if needed a combined scene using some form of weighting
            % scene(s) = piRender(...)
            % piSceneAdd(scene(s))
        end

        function sceneAnalyze(obj)
            % If we can, calculate ground truth and closest target
            % only needed if we aren't starting with pre-run scenes
        end

        function createSensorImages(obj)
            % This is where we render the iset scene through one or 
            % more optics and sensors

            % Right now we run YOLO at the same time
        end

        function evaluatePreTrained(obj)
            % room to evaluate sensors, etc. via mAP
        end

        function train(obj)
            % TBD
        end

        function evaluateTrained(obj)
            % see how well the training did
        end 

        function print(obj)
            %PRINT See what we hae
            disp(obj)
        end

        % Save to Scenarios Folder (at least by default
        function save(obj)   
            save(fullfile(olDirGet('scenarios'),[obj.scenarioName '.mat']),'obj');
        end

    end
end

