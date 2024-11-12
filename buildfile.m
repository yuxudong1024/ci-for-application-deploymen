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
    
    % Make the "archive" task the default task in the plan
    plan.DefaultTasks = "test";
    
    % Dependencies
    plan("displayCoverage").Dependencies = "test";
end

function displayCoverageTask(~)
    % Display coverage
    s = load("code-coverage/coverage.mat");
    disp(s.coverage);
end

function deployMPSArchiveTask(~,destination)
    % Build and deploy CTF
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
    % Build and deploy CTF
    wasResults = compiler.build.webAppArchive(fullfile(currentProject().RootFolder, ...
        "source","TravelingSalesman.mlapp"));
    disp(wasResults.Files{1});
    [status,message] = copyfile(wasResults.Files{1}, destination);
    if (~status)
        error(message);
    end
end