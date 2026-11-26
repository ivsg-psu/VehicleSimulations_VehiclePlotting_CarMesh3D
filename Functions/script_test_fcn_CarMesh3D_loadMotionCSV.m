% script_test_fcn_CarMesh3D_loadMotionCSV.m
% Tests fcn_CarMesh3D_loadMotionCSV
% Reads vehicle motions from CSV files in the CarMesh3D column convention,
% with and without headers, in other units, and with missing columns.

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadMotionCSV
%   % * First write of the code (drafted with Claude)
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadMotionCSV
%   % * Renamed from script_CarMesh3D_loadMotionCSV: test scripts are named
%   %   % script_test_fcn_<Repo>_<name>
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadMotionCSV
%   % * Tests a table and a matrix in place of a file, and different rear
%   %   % tires

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadMotionCSV
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

%% DEMO case: Write a figure eight with lights, then read it back
figNum = 10001;
titleString = sprintf('DEMO case: Write a figure eight with lights, then read it back');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

% A motion made in MATLAB, written in the CSV convention, then read back.
% A dynamics simulation would write the same columns.
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
trajectory = fcn_CarMesh3D_fillTrajectory(Path='figureEight', Radius=12, Speed=8, Duration=10, ...
    VehicleSpec=vehicleSpec, FigNum=-1);
K = length(trajectory.Time);
lights = struct('headlights',1, 'indicator',[ones(round(K/2),1); 2*ones(K-round(K/2),1)]);
csvFile = fullfile(tempdir,'CarMesh3D_testFigureEight.csv');
fcn_CarMesh3D_saveMotionCSV(csvFile, trajectory, Lights=lights);

motion = fcn_CarMesh3D_loadMotionCSV(csvFile, VehicleSpec=vehicleSpec, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(isstruct(motion));
assert(isstruct(motion.Signals));

% Check variable sizes
assert(isequal(size(motion.Pose),[K 6]));
assert(isequal(size(motion.WheelSpin),[K 4]));
assert(isequal(size(motion.SteerAngle),[K 2]));
assert(isequal(size(motion.Signals),[K 1]));

% Check variable values: the motion comes back
assert(max(abs(motion.Pose(:,[1 2 6]) - trajectory.Pose),[],'all') < 1e-6);
assert(max(abs(motion.SteerAngle - trajectory.SteerAngle),[],'all') < 1e-8);
assert(strcmp(motion.SteerSource,'steer_FL and steer_FR'));
% Wheel spin is written as rates and integrated back: close, not exact
assert(max(abs(motion.WheelSpin - trajectory.WheelSpin),[],'all') < 0.05);
% Lights: low beams; the left signal blinks, then the right
assert(all([motion.Signals.LowBeam]) && ~any([motion.Signals.HighBeam]));
assert(motion.Signals(1).TurnLeft && ~motion.Signals(1).TurnRight);
assert(any(~[motion.Signals(1:round(K/2)).TurnLeft]));   % it blinks
assert(motion.Signals(end-1).TurnRight || motion.Signals(end).TurnRight || any([motion.Signals(round(K/2)+1:end).TurnRight]));

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

%% TEST case: A file with no header, in the IVSG 16-column order
figNum = 20001;
titleString = sprintf('TEST case: A file with no header, in the IVSG 16-column order');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

% [X Y Z roll pitch yaw U V W roll_rate pitch_rate yaw_rate w1 w2 w3 w4],
% no time column: straight at 10 m/s, with a bump in Z, and each wheel
% spinning at a different (made-up) rate so the wheel order can be checked
dt = 0.1;
K = 51;
timeValues = (0:K-1)'*dt;
Zvalues = 0.02*sin(timeValues);
legacyData = [10*timeValues, zeros(K,1), Zvalues, zeros(K,3), 10*ones(K,1), zeros(K,5), ...
    1*ones(K,1), 2*ones(K,1), 3*ones(K,1), 4*ones(K,1)];
csvFile = fullfile(tempdir,'CarMesh3D_testLegacy.csv');
writematrix(legacyData, csvFile);
legacyNames = {'X','Y','Z','roll','pitch','yaw','U','V','W','roll_rate','pitch_rate','yaw_rate','w1','w2','w3','w4'};
motion = fcn_CarMesh3D_loadMotionCSV(csvFile, ColumnNames=legacyNames, SampleTime=dt, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable values
assert(max(abs(motion.Time - timeValues)) < 1e-12);
assert(max(abs(motion.BodyHeave - Zvalues)) < 1e-12);
assert(contains(motion.SteerSource,'yaw_rate / U'));
assert(max(abs(motion.SteerAngle),[],'all') < 1e-12);
% Tire quadrants 1 FL, 2 RL, 3 RR, 4 FR become CarMesh3D's [FL FR RL RR]
endSpin = motion.WheelSpin(end,:);
assert(max(abs(endSpin - [1 4 2 3]*timeValues(end))) < 1e-9);
% No brake lights at steady speed; no backup lights going forward
assert(~any([motion.Signals.Brake]) && ~any([motion.Signals.Backup]));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Degrees, rpm, and other name spellings
figNum = 20002;
titleString = sprintf('TEST case: Degrees, rpm, and other name spellings');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

csvFile = fullfile(tempdir,'CarMesh3D_testUnits.csv');
fcn_INTERNAL_writeText(csvFile, { ...
    'Time,X,Y,Yaw_deg,steerAngle_deg,Roll_Rate,w1_rpm,w2_rpm,w3_rpm,w4_rpm,driverName', ...
    '0,0,0,90,10,0,60,60,60,60,1', ...
    '1,0,5,90,10,0,60,60,60,60,1', ...
    '2,0,10,90,10,0,60,60,60,60,1'});
motion = fcn_CarMesh3D_loadMotionCSV(csvFile, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable values
assert(max(abs(motion.Pose(:,6) - pi/2)) < 1e-12);            % 90 degrees
assert(abs(motion.WheelSpin(end,1) - 2*pi*2) < 1e-9);          % 60 rpm for 2 s = 2 turns
% One centerline angle becomes Ackermann left and right angles
assert(strcmp(motion.SteerSource,'steerAngle'));
assert(motion.SteerAngle(1,1) > deg2rad(10) && motion.SteerAngle(1,2) < deg2rad(10));
assert(any(strcmp(motion.ColumnsIgnored,'driverName')));
% Speed from the path: 5 m/s forward (heading +Y)
assert(max(abs(motion.Speed - 5)) < 1e-9);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Brake and backup lights come only from their columns; signals blink
figNum = 20003;
titleString = sprintf('TEST case: Brake and backup lights come only from their columns; signals blink');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

dt = 0.1;
timeValues = (0:dt:6)';
% Speeding up downhill WITH the brakes on (0-2 s), then rolling backward
% down a hill in neutral, with NO backup lights (4-6 s): the lights must
% follow their columns, not the motion
speedValues = 5 + 2*timeValues.*(timeValues<2) + 4*(timeValues>=2) - 3*(timeValues-2).*(timeValues>=2);
K = length(timeValues);
indicatorValues = 1*(timeValues < 2);            % Left signal for the first 2 s
brakeValues = 1*(timeValues < 2);                % Brakes on while speeding up
reverseValues = zeros(K,1);                      % Never in reverse
csvFile = fullfile(tempdir,'CarMesh3D_testLights.csv');
fcn_CarMesh3D_saveMotionCSV(csvFile, struct('Time',timeValues,'Pose',[cumtrapz(timeValues,speedValues) zeros(K,2)],'Speed',speedValues), ...
    Lights=struct('indicator',indicatorValues,'brakeLight',brakeValues,'reverseLight',reverseValues));
motion = fcn_CarMesh3D_loadMotionCSV(csvFile, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable values
signals = motion.Signals;
% Brakes on while speeding up; off while slowing (no brake column value)
assert(signals(find(timeValues>=1,1)).Brake);
assert(~signals(find(timeValues>=3,1)).Brake);
% Rolling backward (U < 0 after about 5 s) without reverse: no backup lights
assert(motion.Speed(end) < 0 && ~any([signals.Backup]));
% A file with no light columns has every light off
csvData = readtable(csvFile);
csvData.brakeLight = []; csvData.reverseLight = []; csvData.indicator = [];
writetable(csvData, csvFile);
motionNoLights = fcn_CarMesh3D_loadMotionCSV(csvFile, FigNum=-1);
assert(~any([motionNoLights.Signals.Brake]) && ~any([motionNoLights.Signals.Backup]));
% Blinking: on at 0 s, off at 0.5 s, on again at 0.8 s; off after 2 s
assert(signals(1).TurnLeft && ~signals(6).TurnLeft && signals(9).TurnLeft);
assert(~any([signals(timeValues>2.05).TurnLeft]));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Road tilt, body motion, and wheel lift
figNum = 20004;
titleString = sprintf('TEST case: Road tilt, body motion, and wheel lift');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

csvFile = fullfile(tempdir,'CarMesh3D_testTilt.csv');
fcn_INTERNAL_writeText(csvFile, { ...
    'time,X,Y,yaw,Z,roll,pitch,roadRoll,roadPitch,wheelLift_FL,wheelLift_RL,wheelLift_RR,wheelLift_FR', ...
    '0,0,0,0,0.01,0.05,-0.02,0.02,0.01,0,0,0,0.1', ...
    '0.1,1,0,0,0.01,0.05,-0.02,0.02,0.01,0,0,0,0.1'});
motion = fcn_CarMesh3D_loadMotionCSV(csvFile, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable values: ground frame takes the road tilt; the body is
% relative to it; wheel lift goes to CarMesh3D wheel 2 (FR)
assert(max(abs(motion.Pose(1,4:5) - [0.02 0.01])) < 1e-12);
assert(abs(motion.BodyRoll(1) - 0.03) < 1e-12 && abs(motion.BodyPitch(1) + 0.03) < 1e-12);
assert(abs(motion.BodyHeave(1) - 0.01) < 1e-12);
assert(isequal(motion.WheelLift(1,:), [0 0.1 0 0]));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Steering from the steering-wheel angle
figNum = 20005;
titleString = sprintf('TEST case: Steering from the steering-wheel angle');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

csvFile = fullfile(tempdir,'CarMesh3D_testSteeringWheel.csv');
fcn_INTERNAL_writeText(csvFile, { ...
    'time,X,Y,yaw,steeringWheelAngle', ...
    '0,0,0,0,1.6', ...
    '0.1,1,0,0,1.6'});
motion = fcn_CarMesh3D_loadMotionCSV(csvFile, SteeringRatio=16, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable values: 1.6 rad / 16 = 0.1 rad centerline angle
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
expectedAngles = fcn_CarMesh3D_calcAckermannSteering(0.1, vehicleSpec.Wheelbase, vehicleSpec.TrackFront);
assert(max(abs(motion.SteerAngle(1,:) - expectedAngles)) < 1e-12);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: A table or a matrix of numbers, in place of a file; different rear tires
figNum = 20007;
titleString = sprintf('TEST case: A table or a matrix of numbers, in place of a file; different rear tires');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

trajectory = fcn_CarMesh3D_fillTrajectory(Path='figureEight', FigNum=-1);
tableFile = fullfile(tempdir,'CarMesh3D_testTable.csv');
fcn_CarMesh3D_saveMotionCSV(tableFile, trajectory);
fromFile = fcn_CarMesh3D_loadMotionCSV(tableFile);
motionTable = readtable(tableFile, 'VariableNamingRule','preserve');
fromTable = fcn_CarMesh3D_loadMotionCSV(motionTable);
assert(max(abs(fromTable.Pose - fromFile.Pose), [], 'all') < 1e-12 && strcmp(fromTable.FileName, '(table)'));
fromNumbers = fcn_CarMesh3D_loadMotionCSV(table2array(motionTable), ColumnNames=motionTable.Properties.VariableNames);
assert(max(abs(fromNumbers.Pose - fromFile.Pose), [], 'all') < 1e-12 && max(abs(fromNumbers.WheelSpin - fromFile.WheelSpin), [], 'all') < 1e-12);
% (wheel spin from speed: the larger rear tires turn slower)
noWheelColumns = motionTable(:, ~startsWith(motionTable.Properties.VariableNames, {'wheel','w1','w2','w3','w4'}));
staggeredSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', TireSize='225/40R18', TireSizeRear='275/40R19');
staggered = fcn_CarMesh3D_loadMotionCSV(noWheelColumns, VehicleSpec=staggeredSpec);
ratio = staggered.WheelSpin(end,3)/staggered.WheelSpin(end,1);                   % (RL over FL)
assert(abs(ratio - staggeredSpec.TireDiameter/staggeredSpec.TireDiameterRear) < 1e-9);
delete(tableFile);

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
titleString = sprintf('Basic example - NO FIGURE');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

motion = fcn_CarMesh3D_loadMotionCSV(csvFile, SteeringRatio=16, FigNum=[]);
assert(isstruct(motion));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Basic fast mode - FigNum of -1 skips the input checks
figNum = 80002;
titleString = sprintf('Basic fast mode - FigNum of -1 skips the input checks');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

motionFast = fcn_CarMesh3D_loadMotionCSV(csvFile, SteeringRatio=16, FigNum=-1);
assert(isequal(motionFast.SteerAngle, motion.SteerAngle));

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

%% FAIL case: The file has no yaw column
if 1==0
    fcn_INTERNAL_writeText(fullfile(tempdir,'bad.csv'), {'time,X,Y','0,0,0','1,1,0'});
    fcn_CarMesh3D_loadMotionCSV(fullfile(tempdir,'bad.csv'));
end

%% FAIL case: No time column and no SampleTime
if 1==0
    fcn_INTERNAL_writeText(fullfile(tempdir,'bad.csv'), {'X,Y,yaw','0,0,0','1,0,0'});
    fcn_CarMesh3D_loadMotionCSV(fullfile(tempdir,'bad.csv'));
end

%% FAIL case: _deg on a column that is not an angle
if 1==0
    fcn_INTERNAL_writeText(fullfile(tempdir,'bad.csv'), {'time,X_deg,Y,yaw','0,0,0,0','1,1,0,0'});
    fcn_CarMesh3D_loadMotionCSV(fullfile(tempdir,'bad.csv'));
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

%% fcn_INTERNAL_writeText
function fcn_INTERNAL_writeText(fileName, textLines)
% Writes lines of text to a file (to make small test CSV files by hand)
fileID = fopen(fileName,'w');
fprintf(fileID,'%s\n',textLines{:});
fclose(fileID);
end % Ends fcn_INTERNAL_writeText
