% script_test_fcn_CarMesh3D_browseVehicles.m
% Tests fcn_CarMesh3D_browseVehicles
% The vehicle browser: a menu of the finished vehicles with their quality
% scores. The menu itself waits for typed choices, so these tests build
% it with Interactive=false and run each menu line's commands the way the
% DebugTools menu does (sprintf, then eval).
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_browseVehicles
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_browseVehicles
%   % * (fill in items here)


%% Set up the workspace
close all


%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: The menu of finished vehicles (built, not opened)
figNum = 10001;
titleString = sprintf('DEMO case: The menu of finished vehicles (built, not opened)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[vehicleTable, selections] = fcn_CarMesh3D_browseVehicles(Interactive=false, FigNum=figNum);

% Check variable types
assert(istable(vehicleTable) && isstruct(selections));

% Check variable sizes: one line per vehicle, then (v), (t), (q)
Nvehicles = height(vehicleTable);
assert(Nvehicles>=1 && numel(selections)==Nvehicles+3);

% Check variable values: numbered vehicle lines first, then the commands;
% each vehicle line shows its score
assert(isequal({selections(1:Nvehicles).MenuChar}, cellstr(string(1:Nvehicles))));
assert(isequal({selections(end-2:end).MenuChar}, {'v','t','q'}));
assert(strcmp(selections(1).AssignmentString,'CarMesh3D_vehicleBrowser'));
assert(all(contains({selections(1:Nvehicles).Text}, 'score')));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_
%    | |/ _ \/ __| __|
%    | |  __/\__ \ |_
%    |_|\___||___/\__|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: Sorted by score, best first
figNum = 20001;
titleString = sprintf('TEST case: Sorted by score, best first');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

vehicleTable = fcn_CarMesh3D_browseVehicles(SortBy='score', Interactive=false);
scores = vehicleTable.Score(~isnan(vehicleTable.Score));
assert(issorted(scores,'descend'));
nameTable = fcn_CarMesh3D_browseVehicles(SortBy='name', Interactive=false);
assert(issorted(nameTable.Name));

%% TEST case: Choosing a vehicle shows it and marks it viewed
figNum = 20101;
titleString = sprintf('TEST case: Choosing a vehicle shows it and marks it viewed');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[vehicleTable, selections] = fcn_CarMesh3D_browseVehicles(ViewFigNum=figNum, Interactive=false);
priusLine = find(vehicleTable.ID=="2013_Toyota_Prius_Four");
answers = cell(numel(selections),1);
previousView = getenv('CARMESH3D_BROWSER_VIEW');
setenv('CARMESH3D_BROWSER_VIEW','both');
answers =fcn_INTERNAL_runMenuLineWithAnswers(selections(priusLine).FunctionSubmission{1}, answers);
assert(strcmp(answers{priusLine},'viewed'));
assert(isgraphics(figure(figNum)) && isgraphics(figure(figNum+1)));

%% TEST case: The view choice and the table commands run
figNum = 20201;
titleString = sprintf('TEST case: The view choice and the table commands run');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[~, selections] = fcn_CarMesh3D_browseVehicles(ViewFigNum=figNum, Interactive=false);
tableCommands = selections(end-1).FunctionSubmission;
fcn_INTERNAL_runMenuLine(tableCommands{1});                    % (prints the table)
setenv('CARMESH3D_BROWSER_VIEW','materials');
answers = fcn_INTERNAL_runMenuLineWithAnswers(selections(1).FunctionSubmission{1}, cell(numel(selections),1));
assert(strcmp(answers{1},'viewed') && isgraphics(figure(figNum)));
flag_exitMain = fcn_INTERNAL_runQuit(selections(end).FunctionSubmission);
assert(flag_exitMain==1);
setenv('CARMESH3D_BROWSER_VIEW', previousView);

%% TEST case: A Data folder path with backslashes reaches the commands intact
figNum = 20301;
titleString = sprintf('TEST case: A Data folder path with backslashes reaches the commands intact');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

dataFolder = fullfile(fileparts(fileparts(which('fcn_CarMesh3D_browseVehicles'))), 'Data');
[~, selections] = fcn_CarMesh3D_browseVehicles(DataFolder=dataFolder, Interactive=false);
commandAsRun = sprintf(selections(1).FunctionSubmission{1});
assert(contains(commandAsRun, ['DataFolder=''' dataFolder '''']));

%% Fast Mode Tests



%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
vehicleTable = fcn_CarMesh3D_browseVehicles(Interactive=false, FigNum=[]);
assert(istable(vehicleTable));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
vehicleTable = fcn_CarMesh3D_browseVehicles(Interactive=false, FigNum=-1);
assert(istable(vehicleTable));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: An unknown sort order
if 1==0
    fcn_CarMesh3D_browseVehicles(SortBy='color', Interactive=false);
end

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_runMenuLine
function fcn_INTERNAL_runMenuLine(commandToEval)
% Runs one menu command as fcn_DebugTools_menuManageSelections does
answers = cell(100,1); %#ok<NASGU>
eval(sprintf(commandToEval));
end % Ends fcn_INTERNAL_runMenuLine

%% fcn_INTERNAL_runMenuLineWithAnswers
function answers = fcn_INTERNAL_runMenuLineWithAnswers(commandToEval, answers)
% Runs one menu command, as the menu does, and returns the answers
eval(sprintf(commandToEval));
end % Ends fcn_INTERNAL_runMenuLineWithAnswers

%% fcn_INTERNAL_runQuit
function flag_exitMain = fcn_INTERNAL_runQuit(commandToEval)
% Runs the quit command, as the menu does
flag_exitMain = 0;
eval(sprintf(commandToEval));
end % Ends fcn_INTERNAL_runQuit
