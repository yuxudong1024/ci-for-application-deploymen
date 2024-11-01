classdef tTravelingSalesmanApp < matlab.uitest.TestCase

    properties
        App
    end % properties

    methods (TestClassSetup)
        function createApp(testCase)
            % Add a smoke test to check the app actually works
            fatalAssertWarningFree(testCase, @createAndDestroy)

            function createAndDestroy
                app = TravelingSalesman;
                oc = onCleanup(@() delete(app));
            end % function createAndDestroy

            % Ok, it works, create the acutal app and attach a teardown
            testCase.App = TravelingSalesman;
            addTeardown(testCase, @delete, testCase.App);

        end % function createApp
    end % methods (TestClassSetup)
    
    methods (Test)
        function tPlotLength(testCase)
            nCities = 10;
            % choose frequency and damping and press the add button
            testCase.type(testCase.App.Spinner,nCities);
            testCase.press(testCase.App.GenerateButton);          
            
            % Check that the line is plotted correctly
            verifyLength(testCase, testCase.App.UIAxes.Children, 1);
            xData = testCase.App.UIAxes.Children(1).XData;
            yData = testCase.App.UIAxes.Children(1).YData;
            verifyLength(testCase, xData, nCities);
            verifyLength(testCase, yData, nCities);
        end
    end
end % classdef