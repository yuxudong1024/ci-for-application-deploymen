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
    plan.DefaultTasks = ["check" "test" "displayCoverage" "deployFrontend" "deployMPSArchive" "deployWebApp" "integrationTest"];
    
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
        [status, message] = mkdir(codeCoverageFolder);
        assert(status==1, message);
    end
    testReportFolder = fullfile(outputFolder,"test-reports");
    if ~exist(testReportFolder, 'dir')
        [status, message] = mkdir(testReportFolder);
        assert(status==1, message);
    end
    copyfile("code-coverage", codeCoverageFolder);
    copyfile("test-reports", testReportFolder);
end

function displayCoverageTask(~)
    % Display test coverage
    s = load(fullfile("code-coverage", "coverage.mat"));
    disp(s.coverage);
end

function deployWebAppTask(~,archiveName,destination)
    % Build web app and deploy to web app server
    arguments
        ~ 
        archiveName = "TravelingSalesman";
        destination = "\\mathworks\inside\labs\matlab\mwa\TravelingSalesman";
    end
    wasResults = compiler.build.webAppArchive(fullfile(currentProject().RootFolder, ...
        "source","TravelingSalesman.mlapp"), "ArchiveName", archiveName);
    [status,message] = copyfile(wasResults.Files{1}, destination);
    if (~status)
        error(message);
    end
    disp(destination + "\" + archiveName);
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
    [status,message] = copyfile(mpsResults.Files{1}, destination);
    if (~status)
        error(message);
    end
    disp(destination + "\" + archiveName);
end

function deployFrontendTask(~, archiveName, server, outputFolder)
    % Deploy index.html with given apiEndpoint to outputFolder
    arguments
        ~ 
        archiveName = "shortestTrip";
        server = "https://ipws-mps.mathworks.com";
        outputFolder = "public";
    end
    apiEndpoint = server + "/" + archiveName + "/shortestTrip";
    fileContent = fileread(fullfile("source","index_template.html"));

    if ~exist(outputFolder, 'dir')
        [status, message] = mkdir(outputFolder);
        assert(status==1, message);
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

function publishAppDiffToMainTask(~, outputFolder)
    % Publish difference of TravelingSalesman app to status in main branch
    arguments
        ~
        outputFolder = "visdiff";
    end
    if ~exist(outputFolder, 'dir')
        [status, message] = mkdir(outputFolder);
        assert(status==1, message);
    end

    appFile = fullfile("source","TravelingSalesman.mlapp");
    report = publishDiffToMain(appFile, outputFolder);
    disp(report);
end

function report = publishDiffToMain(fileName, outputFolder)
    [~, name, ext] = fileparts(fileName);
    mainFile = fullfile(outputFolder, name + "_main" + ext);    
    % Replace seperators to work with git and create main file name
    fileName = strrep(fileName, '\', '/');
    mainFile = strrep(mainFile, '\', '/');
    % Build git command to get file from main
    gitFetchMainCommand = "git fetch origin main:refs/remotes/origin/main";   
    [status, result] = system(gitFetchMainCommand);
    assert(status==0, result);
    gitSaveMainCommand = sprintf('git --no-pager show origin/main:%s > %s', fileName, mainFile);    
    [status, result] = system(gitSaveMainCommand);
    assert(status==0, result);
    comp = visdiff(mainFile, fileName);
    report = publish(comp,'Format','html','OutputFolder',outputFolder);
    delete(mainFile);
end