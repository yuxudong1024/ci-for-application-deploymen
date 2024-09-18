classdef tWave < matlab.unittest.TestCase
    
    properties (TestParameter)
        Frequency = {0, 10, 10};
        Damping = {0, 1, 10, 15};
    end

    methods (Test)

        function tCalculateMultipleWaveSignalsCorrectSize(testCase)
            t = linspace(0,1,10);
            w = Wave([1,3], [2,3]);
            y = calculateSignal(w, t);
            verifySize(testCase, y, [2, 10]);
        end
        
        function tCalculateConstantWaveSignal(testCase)
            t = linspace(0,1,100);
            w = Wave(0,0);
            y = calculateSignal(w, t);
            verifyEqual(testCase, y, ones(size(t)));
        end

    end

    methods (Test, ParameterCombination="exhaustive")

        function tCalculateWaveSignalCorrectSize(testCase, Frequency, Damping)
            t = linspace(0,1,10);
            w = Wave(Frequency, Damping);
            y = calculateSignal(w, t);
            verifySize(testCase, y, [1, 10]);
        end

        function tCalculateWaveSignal(testCase, Frequency, Damping)
            t = linspace(0,1,100);
            w = Wave(Frequency, Damping);
            y = calculateSignal(w, t);
            verifyEqual(testCase, y, cos(Frequency*t).*exp(-Damping*t));
        end
        
    end
end 