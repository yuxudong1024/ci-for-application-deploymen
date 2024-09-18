classdef tWaveApp < matlab.uitest.TestCase

    properties
        App
    end % properties

    methods (TestClassSetup)
        function createApp(testCase)
            % Add a smoke test to check the app actually works
            fatalAssertWarningFree(testCase, @createAndDestroy)

            function createAndDestroy
                app = waveApp;
                oc = onCleanup(@() delete(app));
            end % function createAndDestroy

            % Ok, it works, create the acutal app and attach a teardown
            testCase.App = waveApp;
            addTeardown(testCase, @delete, testCase.App);

        end % function createApp
    end % methods (TestClassSetup)
    
    methods (Test)
        function tPlotLength(testCase)

            % choose frequency and damping and press the add button
            choose(testCase, testCase.App.FrequencyKnob, 10);
            choose(testCase, testCase.App.DampingKnob, 2);           
            
            % Check that the line is plotted correctly
            verifyLength(testCase, testCase.App.UIAxes.Children, 1);
            t = testCase.App.UIAxes.Children(1).XData;
            yData = testCase.App.UIAxes.Children(1).YData;
            verifyLength(testCase, yData, length(t));
        end

        function tCorrectPlot(testCase)

            % choose frequency and damping and press the add button
            choose(testCase, testCase.App.FrequencyKnob, 10);
            choose(testCase, testCase.App.DampingKnob, 2);           
            
            % Check that the line is plotted correctly
            verifyLength(testCase, testCase.App.UIAxes.Children, 1);
            t = testCase.App.UIAxes.Children(1).XData;
            yData = testCase.App.UIAxes.Children(1).YData;
            frequency = testCase.App.FrequencyKnob.Value;
            damping = testCase.App.DampingKnob.Value;
            yDataExp = cos(frequency*t).*exp(-damping*t);
            verifyEqual(testCase, yData, yDataExp, RelTol=100*eps);
        end
    end
end % classdef