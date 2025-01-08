function plan = buildfile
    import matlab.buildtool.*;
    import matlab.buildtool.tasks.*;

    % Create a plan from task functions
    plan = buildplan(localfunctions);
    
    % Enable cleaning derived build outputs
    plan("clean") = CleanTask;

    % Add a task to identify code issues
    plan("check") = CodeIssuesTask;

    outputFolder = "public";
    plan("createOutDir").Outputs = outputFolder;
    
    % Add a task to run tests
    plan("test") = TestTask(SourceFiles="source", ...
        TestResults=[ ...
            fullfile(outputFolder,"test-reports","junit.xml"), ...
            fullfile(outputFolder,"test-reports","junit.html"), ...
            fullfile(outputFolder,"test-reports","junit.mat")], ...
        CodeCoverageResults=[ ...
            fullfile(outputFolder,"code-coverage","cobertura-coverage.xml"), ...
            fullfile(outputFolder,"code-coverage","cobertura-coverage.html"), ...
            fullfile(outputFolder,"code-coverage","coverage.mat")], ...
        Tag="Unit");
    plan("test").Inputs = plan("createOutDir").Outputs;
    plan("test").Actions(end+1) = @processTestResults;
    plan("test").Actions(end+1) = @processCoverageResults;

    plan("buildWebApp").Inputs = "source/*.mlapp";
    plan("buildWebApp").Outputs = arrayfun(@webAppArchive, plan("buildWebApp").Inputs.paths);

    plan("deployWebApp").Inputs = plan("buildWebApp").Outputs;
    
    plan("buildMPSArchive").Inputs = "source/shortestTrip.m";
    plan("buildMPSArchive").Outputs = "shortestTripProductionServerArchive/shortestTrip.ctf";

    plan("deployMPSArchive").Inputs = plan("buildMPSArchive").Outputs;
    plan("deployMPSArchive").Outputs = "shortestTripProductionServerArchive/shortestTripDeployment.mat";

    plan("deployFrontend").Inputs = plan("deployMPSArchive").Outputs;
    plan("deployFrontend").Outputs = fullfile(outputFolder,"index.html");
    
    plan("integrationTest").Inputs = plan("deployMPSArchive").Outputs;

    % Dependencies
    plan("test").Dependencies = "createOutDir";
    plan("deployWebApp").Dependencies = "buildWebApp";
    plan("deployMPSArchive").Dependencies = "buildMPSArchive";
    plan("deployFrontend").Dependencies = ["createOutDir", "deployMPSArchive"];
    plan("integrationTest").Dependencies = "deployMPSArchive";

    % Define default tasks
    plan.DefaultTasks = ["check" "test"];
end

function archive=webAppArchive(mlappFile)
    [~,name] = fileparts(mlappFile);
    archive = name + "WebAppArchive/" + name + ".ctf";
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
    outputFolder = context.Task.Inputs.paths;
    testResults = load(fullfile(outputFolder,"test-reports","junit.mat"));
    testResults = testResults.result;
    disp(testResults);
    generateTestBadge(testResults, fullfile(outputFolder, "testBadge.svg"));  
end

function processCoverageResults(context)
    outputFolder = context.Task.Inputs.paths;
    coverageResults = load(fullfile(outputFolder,"code-coverage", "coverage.mat"));
    coverageResults = coverageResults.coverage;
    disp(coverageResults);
    generateStandaloneReport(coverageResults,fullfile(outputFolder,"code-coverage","standalone.html"));
    generateCoverageBadge(coverageResults, fullfile(outputFolder, "coverageBadge.svg"));    
end

function buildWebAppTask(context)
    % Build web app
    mlappFile = context.Task.Inputs.paths;
    webAppArchive = context.Task.Outputs.paths;
    for i=1:length(mlappFile)
        [outputDir,archiveName]=fileparts(webAppArchive(i));
        compiler.build.webAppArchive(mlappFile(i), ...
            "ArchiveName",archiveName,"OutputDir",outputDir);
    end
end

function deployWebAppTask(context,archiveSuffix,destination)
    % Deploy web app to web app server
    arguments
        context 
        archiveSuffix = "";
        destination = "\\mathworks\inside\labs\matlab\mwa\TravelingSalesman";
    end
    webAppArchive = context.Task.Inputs.paths;
    for i=1:length(webAppArchive)
        ctfFile=fullfile(currentProject().RootFolder,webAppArchive(i));
        [~,name,ext]=fileparts(webAppArchive(i));
        [status,message] = copyfile(ctfFile, destination + "\" + name + archiveSuffix(i) + ext);
        if (~status)
            error(message);
        end
    end
end

function buildMPSArchiveTask(context)
    % Build production server archive
    functionFile = context.Task.Inputs.paths;
    mpsArchive = context.Task.Outputs.paths;
    [outputDir,archiveName]=fileparts(mpsArchive);
    compiler.build.productionServerArchive(functionFile, ...
        "ArchiveName",archiveName,"OutputDir",outputDir);
end

function deployMPSArchiveTask(context,archiveName,destination,serverUrl)
    % Build production server archive and deploy to production server
    arguments
        context
        archiveName = "shortestTrip";
        destination = "\\mathworks\inside\labs\matlab\mps";
        serverUrl = "https://ipws-mps.mathworks.com";
    end
    mpsResults = compiler.build.productionServerArchive(fullfile(currentProject().RootFolder, ...
        "source","shortestTrip.m"), "ArchiveName", archiveName);
    [status,message] = copyfile(mpsResults.Files{1}, destination + "\" + archiveName);
    if (~status)
        error(message);
    end
    disp(destination + "\" + archiveName);
    save(context.Task.Outputs.paths,"archiveName","serverUrl");
end

function integrationTestTask(context)
    % Run integration tests
    s = load(context.Task.Inputs.paths);
    setenv("MPS_ARCHIVE_NAME", s.archiveName);
    setenv("MPS_SERVER_URL", s.serverUrl);
    results = runtests("tShortestTripIntegration.m");
    assertSuccess(results);
end

function deployFrontendTask(context)
    % Deploy index.html with given apiEndpoint to outputFolder
    s = load(context.Task.Inputs.paths);
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