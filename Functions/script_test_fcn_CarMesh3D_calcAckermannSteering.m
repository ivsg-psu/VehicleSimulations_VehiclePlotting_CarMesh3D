% script_test_fcn_CarMesh3D_calcAckermannSteering.m
% Tests fcn_CarMesh3D_calcAckermannSteering
% Calculates the steer angles of the inside and outside front tires so
% both turn about the same turn center (Ackermann steering).

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_calcAckermannSteering
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_calcAckermannSteering
%   % * Renamed from script_CarMesh3D_calcAckermannSteering: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_calcAckermannSteering
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

%% DEMO case: A 2013 Prius steering 20 degrees to the left
figNum = 10001;
titleString = sprintf('DEMO case: A 2013 Prius steering 20 degrees to the left');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

priusFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four', FigNum=-1);
specFile = priusFiles.ParametersFile;
vehicleSpec = fcn_CarMesh3D_loadVehicleSpec(specFile, FigNum=-1);
wheelbase = vehicleSpec.Wheelbase;
track = vehicleSpec.TrackFront;
bicycleSteerAngle = deg2rad(20);

[steerAngles, insideOutsideAngles, turnRadius] = fcn_CarMesh3D_calcAckermannSteering(...
    bicycleSteerAngle, wheelbase, track, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');
fprintf(1,'   Left (inside) tire: %.2f deg, right (outside) tire: %.2f deg, turn radius %.2f m\n', ...
    rad2deg(steerAngles), turnRadius);

% Check variable types
assert(isnumeric(steerAngles));
assert(isnumeric(insideOutsideAngles));
assert(isnumeric(turnRadius));

% Check variable sizes
assert(isequal(size(steerAngles),[1 2]));
assert(isequal(size(insideOutsideAngles),[1 2]));
assert(isequal(size(turnRadius),[1 1]));

% Check variable values
% Left turn: the left tire is inside and steers more; the bicycle angle
% lies between the two
assert(steerAngles(1) > bicycleSteerAngle && bicycleSteerAngle > steerAngles(2));
assert(isequal(insideOutsideAngles, steerAngles));
% The textbook formulas: R = WB/tan(delta), atan(WB/(R -/+ T/2))
assert(abs(turnRadius - wheelbase/tan(bicycleSteerAngle)) < 1e-12);
assert(abs(steerAngles(1) - atan(wheelbase/(turnRadius - track/2))) < 1e-12);
assert(abs(steerAngles(2) - atan(wheelbase/(turnRadius + track/2))) < 1e-12);
% Each front tire points at right angles to the line from the turn center
lineLeft  = [wheelbase,  track/2 - turnRadius];
lineRight = [wheelbase, -track/2 - turnRadius];
assert(abs(dot(lineLeft,  [cos(steerAngles(1)) sin(steerAngles(1))])) < 1e-12);
assert(abs(dot(lineRight, [cos(steerAngles(2)) sin(steerAngles(2))])) < 1e-12);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: A sweep of steer angles, left and right
figNum = 10002;
titleString = sprintf('DEMO case: A sweep of steer angles, left and right');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

bicycleSteerAngles = deg2rad(linspace(-35, 35, 71))';
[steerAngles, insideOutsideAngles, turnRadius] = fcn_CarMesh3D_calcAckermannSteering(...
    bicycleSteerAngles, wheelbase, track, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable sizes
K = length(bicycleSteerAngles);
assert(isequal(size(steerAngles),[K 2]));
assert(isequal(size(insideOutsideAngles),[K 2]));
assert(isequal(size(turnRadius),[K 1]));

% Check variable values
% A right turn is the mirror image of a left turn
assert(max(abs(steerAngles - (-fliplr(flipud(steerAngles)))),[],'all') < 1e-12, 'mirror symmetry');
% The inside tire always steers at least as much as the outside tire
assert(all(abs(insideOutsideAngles(:,1)) >= abs(insideOutsideAngles(:,2))));
% Signs follow the turn direction; straight ahead gives zero and Inf
assert(all(sign(steerAngles(:,1))==sign(bicycleSteerAngles)));
straightRow = find(bicycleSteerAngles==0);
assert(isequal(steerAngles(straightRow,:),[0 0]) && isinf(turnRadius(straightRow)));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% DEMO case: Partial Ackermann (half) and parallel steering
figNum = 10003;
titleString = sprintf('DEMO case: Partial Ackermann (half) and parallel steering');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

fullAngles = fcn_CarMesh3D_calcAckermannSteering(deg2rad(25), wheelbase, track);
halfAngles = fcn_CarMesh3D_calcAckermannSteering(deg2rad(25), wheelbase, track, AckermannFraction=0.5, FigNum=figNum);
parallelAngles = fcn_CarMesh3D_calcAckermannSteering(deg2rad(25), wheelbase, track, AckermannFraction=0);
sgtitle(titleString, 'Interpreter','none');

% Check variable values
assert(isequal(parallelAngles, deg2rad([25 25])));
assert(max(abs(halfAngles - (fullAngles + parallelAngles)/2),[],'all') < 1e-12);

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

%% TEST case: A very tight turn (inside tire past 90 degrees)
figNum = 20001;
titleString = sprintf('TEST case: A very tight turn (inside tire past 90 degrees)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

% Turn center between the rear tires, closer to the left one
bicycleSteerAngle = atan(wheelbase/(0.25*track));
[steerAngles, ~, turnRadius] = fcn_CarMesh3D_calcAckermannSteering(...
    bicycleSteerAngle, wheelbase, track, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable values
assert(steerAngles(1) > pi/2 && steerAngles(1) < pi);
assert(abs(turnRadius - 0.25*track) < 1e-12);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Steer angles from a path curvature
figNum = 20002;
titleString = sprintf('TEST case: Steer angles from a path curvature');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

% A 10 m radius circle to the right
curvature = -1/10;
steerAngles = fcn_CarMesh3D_calcAckermannSteering(atan(wheelbase*curvature), wheelbase, track, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable values: right turn, right tire inside, on radius 10 - T/2
assert(all(steerAngles < 0));
assert(abs(steerAngles(2) + atan(wheelbase/(10 - track/2))) < 1e-12);
assert(abs(steerAngles(1) + atan(wheelbase/(10 + track/2))) < 1e-12);

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

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); close(figNum);

steerAngles = fcn_CarMesh3D_calcAckermannSteering(deg2rad(10), wheelbase, track, FigNum=[]);

% Check variable values
assert(steerAngles(1) > steerAngles(2));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Basic fast mode - FigNum of -1 skips the input checks
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

steerAnglesFast = fcn_CarMesh3D_calcAckermannSteering(deg2rad(10), wheelbase, track, FigNum=-1);

% Check variable values: same answer as the checked version
assert(isequal(steerAnglesFast, steerAngles));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
figure(figNum); close(figNum);

Niterations = 1000;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_calcAckermannSteering(deg2rad(10), wheelbase, track, FigNum=[]);
end
slow_time = toc;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_calcAckermannSteering(deg2rad(10), wheelbase, track, FigNum=-1);
end
fast_time = toc;
fprintf(1,'   %d calls: %.4f s with checks, %.4f s in fast mode\n', Niterations, slow_time, fast_time);

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

%% FAIL case: Negative wheelbase
if 1==0
    fcn_CarMesh3D_calcAckermannSteering(0.1, -2.7, 1.5);
end

%% FAIL case: Steer angle given in degrees by mistake (over 90)
if 1==0
    fcn_CarMesh3D_calcAckermannSteering(120, 2.7, 1.5);
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
