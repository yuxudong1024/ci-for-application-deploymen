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
    % plan("displayCoverage").Dependencies = "test";
    % plan("copyTestReports").Dependencies = "test";
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

function deployWebAppTask(~,archiveName,destination)
    arguments
        ~ 
        archiveName = "TravelingSalesman";
        destination = "\\mathworks\inside\labs\matlab\mwa\TravelingSalesman";
    end
    % Build web app and deploy to web app server
    wasResults = compiler.build.webAppArchive(fullfile(currentProject().RootFolder, ...
        "source","TravelingSalesman.mlapp"), "ArchiveName", archiveName);
    % Only Copy the application when it is not running on GitHub
    disp(wasResults)
    if (getenv('GITHUB_REPOSITORY') == "")
        [status,message] = copyfile(wasResults.Files{1}, destination);
        if (~status)
            error(message);
        end
        disp(destination + "\" + archiveName);
    end
end

function deployMPSArchiveTask(~,archiveName,destination)
    % Build production server archive and deploy to production server
    arguments
        ~ 
        archiveName = "shortestTrip";
        destination = "\\mathworks\inside\labs\matlab\mps";
    end
    mpsResults = compiler.build.productionServerArchive(fullfile(currentProject().RootFolder, ...
        "source","shortestTrip.m"), "ArchiveName", archiveName);
    disp(mpsResults)
    if (getenv('GITHUB_REPOSITORY') == "")
        [status,message] = copyfile(mpsResults.Files{1}, destination);
        if (~status)
            error(message);
        end
    disp(destination + "\" + archiveName);
    end
end

function deployFrontendTask(~, archiveName, server, outputFolder)
    % Deploy index.html with given apiEndpoint to outputFolder
    arguments
        ~ 
        archiveName = "shortestTrip";
        server = "`";
        outputFolder = "public";
    end
    apiEndpoint = server + "/" + archiveName + "/shortestTrip";
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
    disp(outputFilePath);
end