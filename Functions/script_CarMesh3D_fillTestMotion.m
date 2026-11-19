% script_CarMesh3D_fillTestMotion.m
% Tests fcn_CarMesh3D_fillTestMotion
% The standard test motion, which uses every motion input in short,
% labeled segments (lights, body, steering, wheels).

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_fillTestMotion
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_fillTestMotion
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

%% DEMO case: The standard test motion for a generic sedan
figNum = 10001;
titleString = sprintf('DEMO case: The standard test motion for a generic sedan');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
csvFile = fullfile(tempdir,'CarMesh3D_testMotion.csv');
testMotion = fcn_CarMesh3D_fillTestMotion(vehicleSpec, CSVFile=csvFile, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(testMotion));
assert(iscell(testMotion.Caption));

% Check variable sizes
K = length(testMotion.Time);
assert(isequal(size(testMotion.Caption),[K 1]));
assert(isequal(size(testMotion.WheelSpin),[K 4]));
assert(length(testMotion.Segments)==4);

% Check variable values
assert(isequal({testMotion.Segments.Name}, {'lights','body','steering','wheels'}));
assert(isfile(csvFile) && strcmp(testMotion.CSVFile, csvFile));
% Lights: each light appears, alone, in the lights segment
inLights = testMotion.Time <= testMotion.Segments(1).EndTime;
lightStates = testMotion.LightStates(inLights);
assert(any(strcmp({lightStates.Headlights},'high')) && any([lightStates.TurnLeft]) && any([lightStates.Backup]));
assert(any(strcmp({lightStates.Tail},'brake')));
% Body: roll reaches 5 degrees; each tire is lifted at some time
assert(abs(max(testMotion.BodyRoll) - deg2rad(5)) < deg2rad(0.1));
assert(all(max(testMotion.WheelLift,[],1) > 0.07));
% Steering: near full lock, inside tire steers more
assert(max(testMotion.SteerAngle(:,1)) > max(testMotion.SteerAngle(:,2)));
assert(max(rad2deg(testMotion.SteerAngle(:))) > 30);
% Wheels: locked during hard braking (spin does not change), and the
% front tires spin faster than the rear during the peel-out
% (wheel speeds are written as rates and integrated back, so the first
% and last two rows of the locked span are blurred slightly; check the rest)
lockedRows = find(contains(testMotion.Caption, 'locked'));
lockedRows = lockedRows(3:end-2);
assert(max(abs(diff(testMotion.WheelSpin(lockedRows,:))),[],'all') < 1e-6);
peelRows = contains(testMotion.Caption, 'peel-out');
assert(all(diff(testMotion.WheelSpin(peelRows,1)) >= diff(testMotion.WheelSpin(peelRows,3))));
% The vehicle ends where it started its steering turns: heading back to 0
assert(abs(testMotion.Pose(end,6)) < deg2rad(1));

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

%% TEST case: A longer vehicle turns on a wider circle
figNum = 20001;
titleString = sprintf('TEST case: A longer vehicle turns on a wider circle');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vanSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSUV', FigNum=-1);
vanMotion = fcn_CarMesh3D_fillTestMotion(vanSpec, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable values: the turn radius is 1.5 wheelbases, so the
% centerline steer angle at full turn is the same for both vehicles
bicycleSedan = atan(vehicleSpec.Wheelbase/(1.5*vehicleSpec.Wheelbase));
assert(abs(max(atan(mean(tan(vanMotion.SteerAngle),2))) - bicycleSedan) < deg2rad(3));
assert(isempty(vanMotion.CSVFile));

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
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

fastMotion = fcn_CarMesh3D_fillTestMotion(vehicleSpec, FigNum=-1);
assert(isequal(fastMotion.Pose, testMotion.Pose));

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

%% FAIL case: Not a vehicle spec
if 1==0
    fcn_CarMesh3D_fillTestMotion(struct('Length',4));
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
