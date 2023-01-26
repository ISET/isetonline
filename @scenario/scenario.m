classdef scenario < handle
    %SCENARIO Specific set of experimental conditions
    %   Draws on our database of scenes and assets
    %{
        Currently we have a database of EXR files that represent
        individual lighting components of rendered PBRT scenes.

        These are then turned into ISET Scenes using a set of
        weights on each of the light sources.

        Currently flare isn't calculated at that stage, but instead
        we use oiCompute with an optic + piFlareApply to get an OI.

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
        scenarioType;
        scenarioInput;
        scenarioParameters;
    end
    
    methods
        function obj = scenario(varargin)
            %SCENARIO Construct an instance of this class
            p = inputParser;
            varargin = ieParamFormat(varargin);
            addParameter(p,'scenariotype','isetscene',@ischar);
            addParameter(p,'scenarioinput',[]);
            addParameter(p,'scenarioparameters',[]);

            parse(p,varargin{:});

            obj.scenarioType = p.Results.scenariotype;
            obj.scenarioInput = p.Results.scenarioinput;
            obj.scenarioParameters = p.Results.scenarioparameters;

        switch p.Results.scenariotype
            case 'isetscene'
               fprintf("Start with an iset scene");
        end

        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

