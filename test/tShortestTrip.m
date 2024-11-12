classdef tShortestTrip < matlab.unittest.TestCase & matlabtest.compiler.TestCase
        
    properties (TestParameter)
        nCities = {1,2,3,4,50,100,150,200};
    end

    methods(Test, TestTags = {'Equivalence'})

        function prodServerEquivalenceTest(testCase)
            func = fullfile(currentProject().RootFolder,"source","shortestTrip.m");
            buildOpts = compiler.build.ProductionServerArchiveOptions(func);
            buildOpts.ArchiveName = "TravelingSalesman";
            buildResults = build(testCase,buildOpts);
            executionResults = execute(testCase,buildResults,{[1,1,2,2],[1,2,2,1]});
            verifyExecutionMatchesMATLAB(testCase,executionResults);
        end
    end

    methods(Test, TestTags = {'Integration'})

        function prodServerIntegrationTest(testCase)
            x = [1,1,2,2];
            y = [1,2,2,1];
            url = 'https://ipws-mps.mathworks.com/shortestTrip/shortestTrip';
            data = mps.json.encoderequest({x,y});
            options = weboptions("MediaType","application/json");
            response = webwrite(url, data, options);
            trip = reshape(response.lhs,1,[]);
            testCase.verifyEqual(trip,1:4);
        end
    end

    methods(Test, TestTags = {'Unit'})
        function testFourCities(testCase)
            x = [1,1,2,2];
            y = [1,2,2,1];
            testCase.verifyEqual(shortestTrip(x,y),1:4);
        end
    end

    methods(Test, ParameterCombination = 'sequential', TestTags = {'Unit'})

        function testAllCitiesVisitedOnce(testCase,nCities)
            rng("default");
            x=rand(nCities,1);
            y=rand(nCities,1);
            trip = shortestTrip(x,y);
            testCase.verifyEqual(sort(trip),1:nCities);
        end

        function testCorrectOrder(testCase,nCities)
            rng("default");
            x=rand(nCities,1);
            y=rand(nCities,1);
            trip = shortestTrip(x,y);
            testCase.verifyEqual(trip(1),1);
            if (nCities>3)
                testCase.verifyTrue(trip(2)<trip(nCities));
            end
        end
    end    
end