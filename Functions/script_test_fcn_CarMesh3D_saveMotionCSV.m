% script_test_fcn_CarMesh3D_saveMotionCSV.m
% Tests fcn_CarMesh3D_saveMotionCSV
% Writes vehicle motions to CSV files in the CarMesh3D column convention.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_saveMotionCSV
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_saveMotionCSV
%   % * Renamed from script_CarMesh3D_saveMotionCSV: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_saveMotionCSV
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

%% DEMO case: Write a circle drive to a CSV file
figNum = 10001;
titleString = sprintf('DEMO case: Write a circle drive to a CSV file');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

trajectory = fcn_CarMesh3D_fillTrajectory(Path='circle', Radius=15, Speed=10, Duration=5, FigNum=-1);
K = length(trajectory.Time);
csvFile = fullfile(tempdir,'CarMesh3D_testCircle.csv');
writtenFile = fcn_CarMesh3D_saveMotionCSV(csvFile, trajectory, Lights=struct('headlights',2,'runningLights',1));

% Show the first rows, as a spreadsheet would
csvData = readtable(writtenFile, 'VariableNamingRule','preserve');
disp(csvData(1:3,1:8));
plot(csvData.X, csvData.Y, 'b-', 'LineWidth', 1.5); axis equal; grid on;
xlabel('X [m]'); ylabel('Y [m]');
title(titleString, 'Interpreter','none');

% Check variable types
assert(ischar(writtenFile) && isfile(writtenFile));

% Check variable sizes: one row per time step, the 30 usual columns
assert(height(csvData)==K);
assert(width(csvData)==30);

% Check variable values
expectedNames = {'time','X','Y','Z','roll','pitch','yaw','U','V','W','roll_rate','pitch_rate','yaw_rate', ...
    'wheelSpeed_FL','wheelSpeed_RL','wheelSpeed_RR','wheelSpeed_FR', ...
    'wheelLift_FL','wheelLift_RL','wheelLift_RR','wheelLift_FR','roadRoll','roadPitch','steer_FL','steer_FR', ...
    'headlights','indicator','brakeLight','reverseLight','runningLights'};
assert(isequal(csvData.Properties.VariableNames, expectedNames));
assert(max(abs(csvData.U - 10)) < 1e-9);
assert(abs(median(csvData.yaw_rate) - 10/15) < 1e-3);    % speed / radius
assert(all(csvData.headlights==2) && all(csvData.runningLights==1));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_    ___ __ _ ___  ___  ___
%    | |/ _ \/ __| __|  / __/ _` / __|/ _ \/ __|
%    | |  __/\__ \ |_  | (_| (_| \__ \  __/\__ \
%    |_|\___||___/\__|  \___\__,_|___/\___||___/
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: Body motion, road height, and wheel lift are written
figNum = 20001;
titleString = sprintf('TEST case: Body motion, road height, and wheel lift are written');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

trajectory = fcn_CarMesh3D_fillTrajectory(Path='straight', Speed=5, Duration=2, FigNum=-1);
K = length(trajectory.Time);
motionIn = struct('Time',trajectory.Time, ...
    'Pose',[trajectory.Pose(:,1:2), 0.5*ones(K,1), 0.01*ones(K,1), zeros(K,1), trajectory.Pose(:,3)]);
liftValues = zeros(K,4); liftValues(:,2) = 0.05;      % CarMesh3D wheel 2 is FR
csvFile = fullfile(tempdir,'CarMesh3D_testBody.csv');
fcn_CarMesh3D_saveMotionCSV(csvFile, motionIn, BodyRoll=0.04*ones(K,1), BodyHeave=0.02*ones(K,1), WheelLift=liftValues);
csvData = readtable(csvFile, 'VariableNamingRule','preserve');
plot(csvData.time, [csvData.roll csvData.Z], 'LineWidth', 1.5); grid on;
title(titleString, 'Interpreter','none');

% Check variable values: roll is written in the global sense (body + road)
assert(max(abs(csvData.roll - 0.05)) < 1e-12);
assert(max(abs(csvData.roadRoll - 0.01)) < 1e-12);
assert(max(abs(csvData.Z - 0.02)) < 1e-12);
assert(max(abs(csvData.wheelLift_FR - 0.05)) < 1e-12 && max(abs(csvData.wheelLift_RL)) < 1e-12);
% A road height that is not zero adds a roadZ column at the end
assert(strcmp(csvData.Properties.VariableNames{end},'roadZ'));

% Read back: the same body and wheel motion
motion = fcn_CarMesh3D_loadMotionCSV(csvFile, FigNum=-1);
assert(max(abs(motion.BodyRoll - 0.04)) < 1e-12);
assert(max(abs(motion.WheelLift(:,2) - 0.05)) < 1e-12);
assert(max(abs(motion.Pose(:,3) - 0.5)) < 1e-12);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ______        _     __  __           _        _______        _
% |  ____|      | |   |  \/  |         | |      |__   __|      | |
% | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
% |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
% | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
% |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

close all;
fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% Basic fast mode - FigNum of -1 skips the input checks
figNum = 80002;
titleString = sprintf('Basic fast mode - FigNum of -1 skips the input checks');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

fcn_CarMesh3D_saveMotionCSV(csvFile, motionIn, FigNum=-1);
assert(isfile(csvFile));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: A motion with no Pose
if 1==0
    fcn_CarMesh3D_saveMotionCSV(fullfile(tempdir,'bad.csv'), struct('Time',(0:3)'));
end

%% FAIL case: A light column of the wrong length
if 1==0
    fcn_CarMesh3D_saveMotionCSV(fullfile(tempdir,'bad.csv'), struct('Time',(0:3)','Pose',zeros(4,3)), ...
        Lights=struct('headlights',[1 2]));
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
