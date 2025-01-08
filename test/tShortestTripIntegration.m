classdef tShortestTripIntegration < matlab.unittest.TestCase
    properties
        ServerUrl = "https://ipws-mps.mathworks.com";
        ArchiveName = "shortestTrip";
    end

    methods (TestClassSetup)
        function setProperties(testCase)
            if (~isempty(getenv("MPS_ARCHIVE_NAME")))
                testCase.ArchiveName = getenv("MPS_ARCHIVE_NAME");
            end
            if (~isempty(getenv("MPS_URL")))
                testCase.ServerUrl = getenv("MPS_URL");
            end
        end
    end

    methods(Test, TestTags = {'Integration'})

        function prodServerIntegrationTest(testCase)
            x = [1,1,2,2];
            y = [1,2,2,1];
            url = testCase.ServerUrl + "/" + testCase.ArchiveName + "/shortestTrip";
            disp(url);
            data = mps.json.encoderequest({x,y});
            options = weboptions("MediaType","application/json","Timeout",300);
            response = webwrite(url, data, options);
            trip = reshape(response.lhs,1,[]);
            testCase.verifyEqual(trip,1:4);
        end
    end

end