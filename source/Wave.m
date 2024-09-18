classdef Wave
    %DAMPEDOSCILLATION 
    
    properties (SetAccess = private)
        Frequency (:,1) {mustBeNumeric, mustBeReal}
        Damping (:,1) {mustBeNumeric, mustBeReal}
    end
    
    methods
        function obj = Wave(Frequency, Damping)
            %WAVE Construct an instance of this class
            obj.Frequency = Frequency;
            obj.Damping = Damping;
        end
        
        function y = calculateSignal(obj, t)
            arguments
                obj Wave
                t (1,:) {mustBeNumeric, mustBeReal}
            end
            %CALCULATESIGNAL Calculate time domain signal
            y = cos(obj.Frequency*t).*exp(-obj.Damping*t);
        end
    end
end

