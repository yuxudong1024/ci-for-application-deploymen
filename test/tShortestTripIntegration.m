classdef tShortestTripIntegration < matlab.unittest.TestCase
    properties(TestParameter)
        serverUrl = {"https://ipws-mps.mathworks.com"};
        archiveName = {"shortestTrip"};
    end

    methods(Test, TestTags = {'Integration'})

        function prodServerIntegrationTest(testCase, serverUrl, archiveName)
            x = [1,1,2,2];
            y = [1,2,2,1];
            if (getenv('GITHUB_REPOSITORY') ~= "")
               url = "http://edison.mathworks-workshop.com:9900/shortestTrip/shortestTrip";
            else
               url = serverUrl + "/" + archiveName + "/shortestTrip";   
            end
            disp(url);
            data = mps.json.encoderequest({x,y});
            options = weboptions("MediaType","application/json","Timeout",300);
            response = webwrite(url, data, options);
            trip = reshape(response.lhs,1,[]);
            testCase.verifyEqual(trip,1:4);
        end
    end

end