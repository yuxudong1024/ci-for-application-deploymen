classdef tShortestTripEquivalence < matlabtest.compiler.TestCase
        
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
end