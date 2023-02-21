classdef scenario < handle
    %SCENARIO Specific set of experimental conditions
    %   Draws on our database of scenes and assets
    %{

        We have a library of Recipes, currently created in Blender
        as ISET3d @recipe objects. Scenarios flow from there.

        The first (optional) customization step is edits to the @recipe.
        For example, changing the camera position.

        There is an (optional) step where light sources are 
        differentiated so that each @recipe becomes several.

        The resulting recipes are written using piWrite() to .pbrt

        They can then be rendered into EXR files that represent
        the radiance from the now-modified original @recipe.

        These .EXR files can be turned into ISET scenes, either each
        alone, or for example using a set of
        weights on each of the light sources.

        The original scenario is "nighttime"

        Conceptually, scenarios can include one or more of the following:
        -- Recipe to EXR Scene using PBRT-v4
        -- EXR Scene to ISET Scene using weights
        (Does this turn into an @experiment at this point?)
        -- ISET Scene to OI using optics and/or Flare
        -- OI to SensorImage using a sensor
        -- (When appropriate) Store sensorImage in ISETdb
        -- (When appropriate) Create metadata.json for ISETOnline

        Initial Use Case (DJC):
        @Scenario or @Experiment?
        Experiment with flare on some of our Auto scenes:
        -- Start with our AutoSceneISET scenes (or a sub-set)
        -- oiCompute with optics (generic or lens)
        -- piFlareApply calc
        -- combine irradiance using weights (say .96 & .04, for example)
        -- render through sensor(s)
        -- Do something interesting with the results:)

    %}
    properties
        scenarioName;
        scenarioProject;
        scenarioType;
        scenarioInput;
        scenarioParameters;
    end

    methods
        function obj = scenario(varargin)
            %SCENARIO Construct an instance of this class
            p = inputParser;
            varargin = ieParamFormat(varargin);
            addParameter(p,'scenarioname','defaultScenario');
            addParameter(p,'scenarioproject','ISET');
            addParameter(p,'scenariotype','isetscene',@ischar);
            addParameter(p,'scenarioinput',[]);
            addParameter(p,'scenarioparameters',[]);

            parse(p,varargin{:});

            obj.scenarioName = p.Results.scenarioname;
            obj.scenarioProject = p.Results.scenarioproject;
            obj.scenarioType = p.Results.scenariotype;
            obj.scenarioInput = p.Results.scenarioinput;
            obj.scenarioParameters = p.Results.scenarioparameters;

            switch obj.scenarioType
                case 'isetscene'
                    fprintf("Start with an iset scene");
                case 'exrscene'
                    fprintf("Start with an exr scene");

            end

        end


        function print(obj)
            %PRINT See what we hae
            obj
        end
    end
end

