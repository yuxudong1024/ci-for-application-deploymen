classdef tTravelingSalesmanApp < matlab.uitest.TestCase

    properties (TestParameter)
        nCities = {1,2,3,4,50,100,150,200};
    end

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
    
    methods (Test, ParameterCombination = 'sequential')
        function tGeneratedCities(testCase,nCities)
            % choose number of cities and press the generate button
            testCase.type(testCase.App.Spinner,nCities);
            testCase.press(testCase.App.GenerateButton);  
            
            % Check that the number of cities is correct
            verifyLength(testCase, testCase.App.UIAxes.Children, 1);
            xData = testCase.App.UIAxes.Children(1).XData;
            yData = testCase.App.UIAxes.Children(1).YData;
            verifyLength(testCase, xData, nCities);
            verifyLength(testCase, yData, nCities);
        end

        function tPlottedPath(testCase,nCities)
            % choose number of cities and press the generate button
            testCase.type(testCase.App.Spinner,nCities);
            testCase.press(testCase.App.GenerateButton);

            % Get plotted city positions
            xDataOrig = testCase.App.UIAxes.Children(1).XData;
            yDataOrig = testCase.App.UIAxes.Children(1).YData;

            % Press the solve button
            testCase.press(testCase.App.SolveButton);

            % Check that the plotted path contains the same cities
            verifyLength(testCase, testCase.App.UIAxes.Children, 1);
            xData = testCase.App.UIAxes.Children(1).XData;
            yData = testCase.App.UIAxes.Children(1).YData;
            verifyLength(testCase,xData,nCities+1);
            verifyLength(testCase,yData,nCities+1);
            verifyTrue(testCase,all(ismember(xDataOrig,xData)));
            verifyTrue(testCase,all(ismember(xData,xDataOrig)));
            verifyTrue(testCase,all(ismember(yDataOrig,yData)));
            verifyTrue(testCase,all(ismember(yData,yDataOrig)));
            verifyEqual(testCase,xData(nCities+1),xData(1));
            verifyEqual(testCase,yData(nCities+1),yData(1));
        end
    end
end % classdef