% script_test_fcn_CarMesh3D_fillTrajectory.m
% Tests fcn_CarMesh3D_fillTrajectory
% Makes vehicle motions: pose, wheel spin (with slip), and steering.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillTrajectory
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillTrajectory
%   % * Renamed from script_CarMesh3D_fillTrajectory: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fillTrajectory
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

%% DEMO case: A circle at constant speed
figNum = 10001;
titleString = sprintf('DEMO case: A circle at constant speed');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

trajectory = fcn_CarMesh3D_fillTrajectory(Path='circle', Radius=15, Speed=10, Duration=12, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(trajectory));

% Check variable sizes
K = length(trajectory.Time);
assert(isequal(size(trajectory.Pose),[K 3]));
assert(isequal(size(trajectory.WheelSpin),[K 4]));
assert(isequal(size(trajectory.SteerAngle),[K 2]));
assert(isequal(size(trajectory.BicycleSteerAngle),[K 1]));

% Check variable values
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
% On a circle, curvature is 1/R and steer is atan(wheelbase/R)
middle = round(K/2);
assert(abs(trajectory.Curvature(middle) - 1/15) < 0.002);
assert(abs(trajectory.BicycleSteerAngle(middle) - atan(vehicleSpec.Wheelbase/15)) < 0.005);
% Ackermann: the left (inside) tire steers more than the right (outside)
assert(abs(trajectory.SteerAngle(middle,1) - atan(vehicleSpec.Wheelbase/(15 - vehicleSpec.TrackFront/2))) < 0.005);
assert(abs(trajectory.SteerAngle(middle,2) - atan(vehicleSpec.Wheelbase/(15 + vehicleSpec.TrackFront/2))) < 0.005);
% Every point is about R from the center (0, R)
radii = vecnorm(trajectory.Pose(:,1:2) - [0 15], 2, 2);
assert(max(abs(radii - 15)) < 0.01);
% Wheels roll: spin = distance / tire radius
assert(max(abs(trajectory.WheelSpin(end,:) - trajectory.Distance(end)/(vehicleSpec.TireDiameter/2))) < 1e-6);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: Peel out from rest, then lock the wheels to stop
figNum = 10002;
titleString = sprintf('DEMO case: Peel out from rest, then lock the wheels to stop');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

Duration = 6;
dt = 1/20;
timeValues = (0:dt:Duration)';
speedValues = min(3*timeValues, 6).*(timeValues<4) + max(6 - 6*(timeValues-4), 0).*(timeValues>=4);
slip = zeros(length(timeValues),4);
slip(timeValues<1.5, 1:2) = 2;     % Front wheels spin 3x too fast while launching (front-wheel drive)
slip(timeValues>=4, :) = -1;       % All wheels locked while braking
trajectory = fcn_CarMesh3D_fillTrajectory(Path='straight', Speed=speedValues, Duration=Duration, SampleTime=dt, ...
    WheelSlip=slip, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Peel-out: front wheels have turned more than rear wheels
assert(trajectory.WheelSpin(end,1) > trajectory.WheelSpin(end,3));
% Lock-up: no wheel turns after t = 4 s
locked = trajectory.Time>=4;
assert(max(max(abs(diff(trajectory.WheelSpin(locked,:))))) < 1e-12);

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

%% TEST case: Every path type runs, and reverse drives backward
figNum = 20001;
titleString = sprintf('TEST case: Every path type runs, and reverse drives backward');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

pathNames = {'straight','circle','figureEight','laneChange'};
for ith_path = 1:length(pathNames)
    trajectory = fcn_CarMesh3D_fillTrajectory(Path=pathNames{ith_path}, Duration=5);
    assert(all(isfinite(trajectory.Pose(:))));
    assert(abs(trajectory.Pose(1,3)) < 0.05); % Starts heading along +X
end
trajectory = fcn_CarMesh3D_fillTrajectory(Path='waypoints', Waypoints=[0 0; 20 0; 20 20], Speed=5, Duration=6);
assert(all(isfinite(trajectory.Pose(:))));
% Reverse: x goes down, wheels turn backward
trajectory = fcn_CarMesh3D_fillTrajectory(Path='straight', Speed=-2, Duration=3);
assert(trajectory.Pose(end,1) < -5.9);
assert(all(trajectory.WheelSpin(end,:) < 0));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Lane change ends one lane over, steering left then right
figNum = 20002;
titleString = sprintf('TEST case: Lane change ends one lane over, steering left then right');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

trajectory = fcn_CarMesh3D_fillTrajectory(Path='laneChange', LaneOffset=3.5, Speed=15, Duration=5);
assert(abs(trajectory.Pose(end,2) - 3.5) < 0.01);
assert(max(trajectory.SteerAngle,[],'all') > 0 && min(trajectory.SteerAngle,[],'all') < 0);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: StartPose moves and turns the path
figNum = 20003;
titleString = sprintf('TEST case: StartPose moves and turns the path');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

trajectory = fcn_CarMesh3D_fillTrajectory(Path='straight', Speed=10, Duration=1, StartPose=[5 -3 pi/2]);
assert(max(abs(trajectory.Pose(1,:) - [5 -3 pi/2])) < 1e-9);
assert(abs(trajectory.Pose(end,1) - 5) < 1e-6 && abs(trajectory.Pose(end,2) - 7) < 1e-6);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Speed as a function of time
figNum = 20004;
titleString = sprintf('TEST case: Speed as a function of time');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

trajectory = fcn_CarMesh3D_fillTrajectory(Speed=@(t) 2*t, Duration=5);
assert(abs(trajectory.Distance(end) - 25) < 1e-6); % Integral of 2t from 0 to 5

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

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

%% FAST mode, empty figNum
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); close(figNum);

trajectory = fcn_CarMesh3D_fillTrajectory(Path='figureEight', FigNum=[]);
assert(isstruct(trajectory));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% FAST mode, figNum=-1
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

trajectory = fcn_CarMesh3D_fillTrajectory(Path='figureEight', FigNum=-1);
assert(isstruct(trajectory));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of normal mode versus fast mode
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum);
close(figNum);

% (no setup needed)

Niterations = 20;

% Normal mode
tic;
for ith_test = 1:Niterations
    trajectory = fcn_CarMesh3D_fillTrajectory(Path='figureEight', FigNum=[]);
end
slow_method = toc;

% Fast mode, FigNum=-1
tic;
for ith_test = 1:Niterations
    trajectory = fcn_CarMesh3D_fillTrajectory(Path='figureEight', FigNum=-1);
end
fast_method = toc;

% Input checks turned off by environment variable. The code reads these
% variables only when both are set. Save the user's settings and restore
% them afterward, even if a call errors.
old_check_inputs = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
old_do_debug     = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS","0");
setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG","0");
try
    tic;
    for ith_test = 1:Niterations
        trajectory = fcn_CarMesh3D_fillTrajectory(Path='figureEight', FigNum=[]);
    end
    env_method = toc;
catch ME
    setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS",old_check_inputs);
    setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG",old_do_debug);
    rethrow(ME);
end
setenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS",old_check_inputs);
setenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG",old_do_debug);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

% Plot results as bar chart
figure(373737);
clf;
hold on;

barLabels = {'Normal mode','Checks off (environment variable)','Fast mode (FigNum=-1)'};
X = categorical(barLabels);
X = reordercats(X,barLabels); % Forces bars to appear in this exact order, not alphabetized
Y = [slow_method env_method fast_method]*1000/Niterations;
bar(X,Y)
ylabel('Execution time (Milliseconds)')
title('fcn_CarMesh3D_fillTrajectory: time per call','Interpreter','none');
fprintf(1,'Average time per call (ms): normal %.3f, checks off by environment variable %.3f, fast mode %.3f\n',Y(1),Y(2),Y(3));

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

%% FAIL case: Unknown path
if 1==0
    trajectory = fcn_CarMesh3D_fillTrajectory(Path='spiral');
end

%% FAIL case: Waypoints path without waypoints
if 1==0
    trajectory = fcn_CarMesh3D_fillTrajectory(Path='waypoints');
end

%% FAIL case: Speed vector of the wrong length
if 1==0
    trajectory = fcn_CarMesh3D_fillTrajectory(Speed=[1 2 3], Duration=10);
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
