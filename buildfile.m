function plan = buildfile
    import matlab.buildtool.*;
    import matlab.buildtool.tasks.*;

    % Create a plan from task functions
    plan = buildplan(localfunctions);
    
    % Define default tasks
    plan.DefaultTasks = ["check" "test" "buildWebApp" "buildMPSArchive"];

    % Enable cleaning derived build outputs
    plan("clean") = CleanTask;

    % Add a task to identify code issues
    plan("check") = CodeIssuesTask;

    outputFolder = "public";
    plan("createOutDir").Outputs = outputFolder;
    
    % Add a task to run tests
    plan("test:run") = TestTask(SourceFiles="source", ...
        Tag=["Unit","App"], ...
        TestResults=[ ...
            fullfile(outputFolder,"test-reports","junit.xml"), ...
            fullfile(outputFolder,"test-reports","test-results.html"), ...
            fullfile(outputFolder,"test-reports","test-results.mat")], ...
        CodeCoverageResults=[ ...
            fullfile(outputFolder,"code-coverage","cobertura-coverage.xml"), ...
            fullfile(outputFolder,"code-coverage","coverage.html"), ...
            fullfile(outputFolder,"code-coverage","coverage.mat")]);

    plan("test:badges:results") = Task(Actions=@processTestResults,...
        Inputs=plan("test:run").TestResults(3), ...
        Outputs=fullfile(outputFolder,"testBadge.svg"));

    plan("test:badges:coverage") = Task(Actions=@processCoverageResults,...
        Inputs=plan("test:run").CodeCoverageResults(3), ...
        Outputs=[...
            fullfile(outputFolder,"code-coverage","standalone.html"), ...
            fullfile(outputFolder,"coverageBadge.svg")]);
    plan("test").Description = "Run all tests and generate test and coverage reports and badges";

    % Add build and deploy tasks   
    plan("buildWebApp").Inputs = "source/TravelingSalesman.mlapp";
    plan("buildWebApp").Outputs = ["deploy/webapp/TravelingSalesman" ...
        "deploy/webapp/TravelingSalesman/TravelingSalesman.ctf"];

    plan("deployWebApp").Inputs = plan("buildWebApp").Outputs(2);
    plan("deployWebApp").Outputs = plan("buildWebApp").Outputs(1) ...
        .transform(@(p) fullfile(p,"webAppDeployment.mat"));
    
    plan("buildMPSArchive").Inputs = "source/shortestTrip.m";
    plan("buildMPSArchive").Outputs = "deploy/mpsArchive/shortestTrip.ctf";

    plan("deployMPSArchive").Inputs = plan("buildMPSArchive").Outputs;
    plan("deployMPSArchive").Outputs = "deploy/mpsArchive/shortestTripDeployment.mat";

    plan("deployFrontend").Inputs = [plan("deployMPSArchive").Outputs, plan("createOutDir").Outputs];
    plan("deployFrontend").Outputs = fullfile(outputFolder,"index.html");
    
    plan("integrationTest").Inputs = ["test/tShortestTripIntegration.m", plan("deployMPSArchive").Outputs];

end

function createOutDirTask(context)
    % Create output folder for build reports
    outputFolder = context.Task.Outputs.paths;
    if ~exist(outputFolder, 'dir')
        [status, message] = mkdir(outputFolder);
        assert(status==1, message);
    end
end

function processTestResults(context)
    testResults = load(context.Task.Inputs.paths);
    testResults = testResults.result;
    disp(testResults);
    generateTestBadge(testResults, context.Task.Outputs.paths);  
end

function processCoverageResults(context)
    coverageResults = load(context.Task.Inputs.paths);
    coverageResults = coverageResults.coverage;
    disp(coverageResults);
    [~] = generateStandaloneReport(coverageResults, context.Task.Outputs(1).paths); % Suppress opening of report by assigning to [~]
    generateCoverageBadge(coverageResults, context.Task.Outputs(2).paths);    
end

function buildWebAppTask(context)
    % Build web app
    mlappFile = context.Task.Inputs.paths;
    outputDir = context.Task.Outputs(1).paths;
    [~, archiveName] = fileparts(context.Task.Outputs(2).paths);
    results = compiler.build.webAppArchive(mlappFile, ArchiveName=archiveName, OutputDir=outputDir);
    disp(results);
end

function deployWebAppTask(context,env,user,serverUrl,deployFolder)
    % Deploy web app to web app server
    arguments
        context 
        env = "DEV";
        user = string(getUsername).replace({'/','\'},"_");
        serverUrl = "https://ipws-webapps.mathworks.com/webapps/home/";
        deployFolder = "//mathworks/inside/labs/matlab/mwa/TravelingSalesman";
    end
    deployFolder = deployFolder + "-" + env;
    webAppArchive = fullfile(context.Plan.RootFolder, context.Task.Inputs.paths);
    [~,archiveName,ext]=fileparts(webAppArchive);
    archiveName = archiveName + user + ext;
    targetFile = fullfile(deployFolder, archiveName);
    [status,message] = copyfile(webAppArchive, targetFile, 'f');
    disp(targetFile);
    disp(serverUrl);
    assert(status==1, message);
    save(context.Task.Outputs.paths,"archiveName","serverUrl","deployFolder");
end

function buildMPSArchiveTask(context)
    % Build production server archive
    functionFile = context.Task.Inputs.paths;
    mpsArchive = context.Task.Outputs.paths;
    [outputDir,archiveName]=fileparts(mpsArchive);
    compiler.build.productionServerArchive(functionFile, ...
        "ArchiveName",archiveName,"OutputDir",outputDir);
end

function deployMPSArchiveTask(context,archiveName,serverUrl,deployFolder)
    % Build production server archive and deploy to production server
    arguments
        context
        archiveName = "shortestTripDev";
        serverUrl = "https://ipws-mps.mathworks.com";
        deployFolder = "//mathworks/inside/labs/matlab/mps";
    end
    targetFile = fullfile(deployFolder, archiveName + ".ctf");
    [status,message] = copyfile(fullfile(currentProject().RootFolder,context.Task.Inputs.paths), targetFile);
    disp(targetFile);
    disp(serverUrl);
    assert(status==1, message);
    save(context.Task.Outputs.paths,"archiveName","serverUrl","deployFolder");
end

function integrationTestTask(context)
    % Run integration test for deployed MPS archive
    import matlab.unittest.*;    
    import matlab.unittest.parameters.*;
    
    % Run integration tests
    s = load(context.Task.Inputs(2).paths);
    integrationTests = context.Task.Inputs(1).paths;
    suite = TestSuite.fromFile(integrationTests,...
        ExternalParameters=Parameter.fromData(...
            "serverUrl",{s.serverUrl}, ...
            "archiveName",{s.archiveName}));
    runner = testrunner;
    results = runner.run(suite);
    assertSuccess(results);
end

function deployFrontendTask(context)
    % Deploy index.html with given apiEndpoint to outputFolder
    s = load(context.Task.Inputs(1).paths);
    apiEndpoint = s.serverUrl + "/" + s.archiveName + "/shortestTrip";
    fileContent = fileread(fullfile("source","index_template.html"));
    outputFilePath = context.Task.Outputs.paths;

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

function publishAppDiffToMainTask(~, visDiffFolder)
    % Publish difference of TravelingSalesman app to status in main branch
    arguments
        ~
        visDiffFolder = "visdiff";
    end
    if ~exist(visDiffFolder, 'dir')
        [status, message] = mkdir(visDiffFolder);
        assert(status==1, message);
    end

    appFile = fullfile("source","TravelingSalesman.mlapp");
    report = publishDiffToMain(appFile, visDiffFolder);
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

function generateTestBadge(results,badgeFile)
    % See https://shields.io/badges/static-badge
    numPassed = sum([results.Passed]);
    numFailed = sum([results.Failed]);
    numIncomplete = sum([results.Incomplete]);
    color = "brightgreen";
    if (numIncomplete>0)
        color = "orange";
    end
    if (numFailed>0)
        color = "red";
    end
    badgeContent = sprintf("%s-%i/%i-%s", ...
        "Unit%20Test", numPassed, numPassed + numFailed + numIncomplete, color);
    websave(badgeFile, sprintf("%s/%s", "https://img.shields.io/badge", badgeContent));
end

function generateCoverageBadge(results,badgeFile)
    % See https://shields.io/badges/static-badge
    statementCov = sum(coverageSummary(results,"statement"));
    percentage = 100*statementCov(1)/statementCov(2);
    color = "brightgreen";
    if (percentage < 75)
        color = 'red';
    elseif (percentage < 80)
        color = 'orange';
    elseif (percentage < 85)
        color = 'yellow';
    elseif (percentage < 90)
        color = 'yellowgreen';
    elseif (percentage < 95)
        color = 'green';
    end

    badgeContent = sprintf("%s-%.2f%%25-%s", ...
        "Coverage", percentage, color);
    url = sprintf("%s/%s", "https://img.shields.io/badge", badgeContent);
    websave(badgeFile, url);
end

function user = getUsername
user = "UNKNOWN";
[result, output] = system("whoami");
if result ==0
    user = upper(strip(output));
else
    disp("Could not find username. Using user ""UNKNOWN"". Output:")
    disp(output)
end
end