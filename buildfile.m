function plan = buildfile
    import matlab.buildtool.tasks.CodeIssuesTask
    import matlab.buildtool.tasks.TestTask
    import matlab.buildtool.io.FileCollection
    
    % Create a plan from task functions
    plan = buildplan(localfunctions);
    
    % Add a task to identify code issues
    plan("check") = CodeIssuesTask;
    
    % Add a task to run tests
    plan("test") = TestTask(SourceFiles=FileCollection.fromPaths("source"), ...
        TestResults=["test-reports/junit.xml","test-reports/junit.html"], ...
        CodeCoverageResults=["code-coverage/cobertura-coverage.xml", ...
            "code-coverage/cobertura-coverage.html", "code-coverage/coverage.mat"], ...
        Tag=["Unit","App"]);
    
    plan("integrationTest") = TestTask(Tag="Integration");
    
    % Make the "test" task the default task in the plan
    plan.DefaultTasks = "test";
    
    % Dependencies
    plan("displayCoverage").Dependencies = "test";
    plan("copyTestReports").Dependencies = "test";
end

function copyTestReportsTask(~, outputFolder)
    % Copy test reports to outputFolder
    arguments
        ~ 
        outputFolder = "public";
    end
    codeCoverageFolder = fullfile(outputFolder,"code-coverage");
    if ~exist(codeCoverageFolder, 'dir')
        mkdir(codeCoverageFolder);
    end
    testReportFolder = fullfile(outputFolder,"test-reports");
    if ~exist(testReportFolder, 'dir')
        mkdir(testReportFolder);
    end
    copyfile("code-coverage", codeCoverageFolder);
    copyfile("test-reports", testReportFolder);
end

function displayCoverageTask(~)
    % Display coverage
    s = load(fullfile("code-coverage", "coverage.mat"));
    disp(s.coverage);
end

function deployMPSArchiveTask(~,destination)
    % Build production server archive and deploy to production server
    arguments
        ~ 
        destination = "\\mathworks\inside\labs\matlab\mps";
    end
    mpsResults = compiler.build.productionServerArchive(fullfile(currentProject().RootFolder, ...
        "source","shortestTrip.m"), "ArchiveName", "shortestTrip");
    disp(mpsResults.Files{1});
    [status,message] = copyfile(mpsResults.Files{1}, destination);
    if (~status)
        error(message);
    end
end

function deployWebAppTask(~,destination)
    arguments
        ~ 
        destination = "\\mathworks\inside\labs\matlab\mwa";
    end
    % Build web app and deploy to web app server
    wasResults = compiler.build.webAppArchive(fullfile(currentProject().RootFolder, ...
        "source","TravelingSalesman.mlapp"));
    disp(wasResults.Files{1});
    [status,message] = copyfile(wasResults.Files{1}, destination);
    if (~status)
        error(message);
    end
end

function deployFrontendTask(~, apiEndpoint, outputFolder)
    % Deploy index.html with given apiEndpoint to outputFolder
    arguments
        ~ 
        apiEndpoint = "https://ipws-mps.mathworks.com/shortestTrip/shortestTrip";
        outputFolder = "public";
    end
    fileContent = fileread(fullfile("source","index_template.html"));

    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    outputFilePath = fullfile(outputFolder,"index.html");

    % Replace the placeholder with the actual API endpoint
    updatedContent = strrep(fileContent, '__API_ENDPOINT__', apiEndpoint);

    % Write the updated content to a new file
    fileID = fopen(outputFilePath, 'w');
    if fileID == -1
        error('Failed to open file: %s', outputFilePath);
    end
    fwrite(fileID, updatedContent, 'char');
    fclose(fileID);
end