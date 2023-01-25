classdef scenario < handle
    %SCENARIO Specific set of experimental conditions
    %   Draws on our database of scenes and assets
    
    properties
        Property1
    end
    
    methods
        function obj = scenario(varargin)
            %SCENARIO Construct an instance of this class

            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

