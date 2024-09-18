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
    CodeCoverageResults="code-coverage/report.html");

% Make the "archive" task the default task in the plan
plan.DefaultTasks = "test";