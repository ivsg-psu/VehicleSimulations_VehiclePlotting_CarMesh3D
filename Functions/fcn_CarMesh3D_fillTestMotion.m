function testMotion = fcn_CarMesh3D_fillTestMotion(vehicleSpec, options)
% fcn_CarMesh3D_fillTestMotion
% Makes the STANDARD TEST MOTION: one motion that uses every motion input
% (see "Inputs" in the README), in short, labeled segments, so that a new
% vehicle can be checked the same way every time. The motion is written
% to a CSV file in the CarMesh3D column convention and then read back with
% fcn_CarMesh3D_loadMotionCSV, so the file reader is checked too.
%
% THE SEGMENTS (about 45 s in all):
%
%   1. lights    (parked, 10.8 s) Each light alone, 1.2 s each: all off,
%                low beams, high beams, running lights, left signal, right
%                signal, hazards, brake lights, backup lights.
%   2. body      (parked, 11 s) Smooth 1.1 s pulses, one input at a time:
%                roll +5 deg (right side down), roll -5 deg, pitch +3 deg
%                (nose down), pitch -3 deg, heave +5 cm, heave -5 cm, then
%                each tire lifted 8 cm in turn: FL, FR, RL, RR.
%   3. steering  (2 m/s) Straight, a 90 deg left turn, straight, a 90 deg
%                right turn, straight. The turn radius is 1.5 wheelbases
%                (near full lock). Low beams on; the left or right signal
%                is on during each turn. Front tires get Ackermann angles.
%   4. wheels    From rest: speed up to 8 m/s in 3 s with the front tires
%                spinning twice as fast as the road for the first 1.5 s
%                (peel-out), cruise 1 s, brake hard to a stop in 2 s with
%                all four tires locked (not turning) and strong brake
%                lights, wait, then back up at 2 m/s with backup lights.
%
% Every input is held at its "off" value outside its own segment, so each
% check shows one thing at a time.
%
% FORMAT:
%
%       testMotion = fcn_CarMesh3D_fillTestMotion(vehicleSpec,...
%           (SampleTime=dt), (CSVFile=fileName), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vehicleSpec: a CarMesh3D vehicle spec (fcn_CarMesh3D_loadVehicleSpec
%      or fcn_CarMesh3D_fillVehicleSpec). The wheelbase sets the turn
%      radius; the wheelbase and front track set the Ackermann angles; the
%      tire diameter sets the wheel speeds.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      SampleTime: the time step, in seconds. Default 1/12 (12 frames per
%      second, the rate of the check GIFs).
%
%      CSVFile: where to write the CSV file. Default [] writes it to a
%      temporary file (and deletes it after reading it back).
%
%      FigNum: a figure number to plot the inputs over time, with the
%      segments shaded. If empty or omitted, no plot is made. If set to
%      -1, input checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      testMotion: the motion as read back by fcn_CarMesh3D_loadMotionCSV
%      (Time, Pose, BodyRoll, BodyPitch, BodyHeave, Speed, SteerAngle,
%      WheelSpin, WheelLift, LightStates, Data, ...), plus:
%           Segments: a structure array with Name, StartTime, EndTime,
%               and Description for each segment
%           Caption: K x 1 cell array describing the inputs at each time
%               step (for captions in the check animations)
%           CSVFile: the file written ('' if it was temporary)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_calcAckermannSteering
%      fcn_CarMesh3D_saveMotionCSV
%      fcn_CarMesh3D_loadMotionCSV
%
% EXAMPLES:
%
%       vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan');
%       testMotion = fcn_CarMesh3D_fillTestMotion(vehicleSpec, FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_fillTestMotion.m for a full test
%       suite, and fcn_CarMesh3D_runVehicleChecks, which uses it.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillTestMotion
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillTestMotion
%   % * Wheel spin uses each axle's own tire radius
%   %   % (VehicleSpec.TireDiameterRear for the rear wheels)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillTestMotion
%   % * Road tilt (roadRoll, roadPitch) segment



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleSpec
    options.SampleTime = 1/12   % Time step [s]
    options.CSVFile = []        % CSV file to write; [] for a temporary file
    options.FigNum = []         % Figure to plot into; [] for no plot, -1 for fast mode
end

%% Debugging and Input checks

% Check if flag_max_speed set. This occurs if the FigNum option is given
% a value of -1, which is not a valid figure number.
flag_max_speed = 0; % The default. This runs code with all error checking
if isequal(options.FigNum,-1)
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 0; % Flag to perform input checking
    flag_max_speed = 1;
else
    % Check to see if we are externally setting debug mode to be "on"
    flag_do_debug = 0; % % % % Flag to plot the results for debugging
    flag_check_inputs = 1; % Flag to perform input checking
    MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
    MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG = getenv("MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG");
    if ~isempty(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS) && ~isempty(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG)
        flag_do_debug = str2double(MATLABFLAG_CARMESH3D_FLAG_DO_DEBUG);
        flag_check_inputs  = str2double(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS);
    end
end

% flag_do_debug = 1;

if flag_do_debug % If debugging is on, print on entry/exit to the function
    st = dbstack; %#ok<*UNRCH>
    fprintf(1,'STARTING function: %s, in file: %s\n',st(1).name,st(1).file);
    debug_figNum = 999978; %#ok<NASGU>
else
    debug_figNum = []; %#ok<NASGU>
end

%% check input arguments?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                   _
%  |_   _|                 | |
%    | |  _ __  _ __  _   _| |_ ___
%    | | | '_ \| '_ \| | | | __/ __|
%   _| |_| | | | |_) | |_| | |_\__ \
%  |_____|_| |_| .__/ \__,_|\__|___/
%              | |
%              |_|
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Inputs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above

        % Check the vehicleSpec input
        requiredFields = {'Wheelbase','TireDiameter','OverallWidth'};
        if ~isstruct(vehicleSpec) || ~all(isfield(vehicleSpec, requiredFields))
            error('vehicleSpec must be a CarMesh3D vehicle spec (with Wheelbase, TireDiameter, OverallWidth)');
        end

        % Check the SampleTime input
        if ~isnumeric(options.SampleTime) || ~isscalar(options.SampleTime) || ~(options.SampleTime>0) || options.SampleTime>0.5
            error('SampleTime must be a positive number of seconds, at most 0.5');
        end
    end
end

% Does user want to show the plots?
flag_do_plots = 0; % Default is to NOT show plots
if (0==flag_max_speed)
    temp = options.FigNum;
    if ~isempty(temp) % Did the user NOT give an empty figure number?
        figNum = temp;
        flag_do_plots = 1;
    end
end

%% Main code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   __  __       _
%  |  \/  |     (_)
%  | \  / | __ _ _ _ __
%  | |\/| |/ _` | | '_ \
%  | |  | | (_| | | | | |
%  |_|  |_|\__,_|_|_| |_|
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dt = options.SampleTime;
wheelbase = vehicleSpec.Wheelbase;
tireRadius = vehicleSpec.TireDiameter/2;
tireRadiusRear = tireRadius;                                      % (different front and rear tires?)
if isfield(vehicleSpec,'TireDiameterRear') && ~isempty(vehicleSpec.TireDiameterRear)
    tireRadiusRear = vehicleSpec.TireDiameterRear/2;
end
frontTrack = vehicleSpec.TrackFront;
if isempty(frontTrack)
    frontTrack = 0.85*vehicleSpec.OverallWidth;
end

%%%%
% Build the inputs segment by segment. Each segment fills rows of these
% columns; anything not set stays at its "off" value.
timeValues = zeros(0,1);
segments = struct('Name',{},'StartTime',{},'EndTime',{},'Description',{});
columns = struct('U',[],'curvature',[],'roll',[],'pitch',[],'heave',[],'lift',[], ...
    'spinFactor',[],'headlights',[],'indicator',[],'brakeLight',[],'reverseLight',[],'runningLights',[]);
captions = cell(0,1);

% --- 1. Lights, parked: each light alone for 1.2 s
lightSteps = {
    'all lights off',                   0 0 0 0 0;
    'low beams (headlights = 1)',       1 0 0 0 0;
    'high beams (headlights = 2)',      2 0 0 0 0;
    'running lights (runningLights = 1)', 0 0 0 0 1;
    'left signal (indicator = 1)',      0 1 0 0 0;
    'right signal (indicator = 2)',     0 2 0 0 0;
    'hazards (indicator = 3)',          0 3 0 0 0;
    'brake lights (brakeLight = 1)',    0 0 1 0 0;
    'backup lights (reverseLight = 1)', 0 0 0 1 0};
stepTime = 1.2;
for ith_step = 1:size(lightSteps,1)
    Nrows = round(stepTime/dt);
    [timeValues, columns, captions] = fcn_INTERNAL_addRows(timeValues, columns, captions, Nrows, dt, ...
        ['Lights: ' lightSteps{ith_step,1}], ...
        'headlights', lightSteps{ith_step,2}, 'indicator', lightSteps{ith_step,3}, ...
        'brakeLight', lightSteps{ith_step,4}, 'reverseLight', lightSteps{ith_step,5}, 'runningLights', lightSteps{ith_step,6});
end
segments(end+1) = fcn_INTERNAL_segment('lights', timeValues, 0, 'Each light alone, parked');

% --- 2. Body motion, parked: smooth pulses, one input at a time
segmentStart = numel(timeValues);
pulseTime = 1.1;
Npulse = round(pulseTime/dt);
pulseShape = sin(pi*((1:Npulse)'-0.5)/Npulse).^2;   % 0 -> 1 -> 0
bodySteps = {
    'roll +5 deg (right side down)', 'roll',  deg2rad(5),  0;
    'roll -5 deg (left side down)',  'roll',  -deg2rad(5), 0;
    'pitch +3 deg (nose down)',      'pitch', deg2rad(3),  0;
    'pitch -3 deg (nose up)',        'pitch', -deg2rad(3), 0;
    'heave +5 cm (body up)',         'heave', 0.05,        0;
    'heave -5 cm (body down)',       'heave', -0.05,       0;
    'front-left tire lifted 8 cm',   'lift',  0.08,        1;
    'front-right tire lifted 8 cm',  'lift',  0.08,        2;
    'rear-left tire lifted 8 cm',    'lift',  0.08,        3;
    'rear-right tire lifted 8 cm',   'lift',  0.08,        4};
for ith_step = 1:size(bodySteps,1)
    [timeValues, columns, captions] = fcn_INTERNAL_addRows(timeValues, columns, captions, Npulse, dt, ...
        ['Body: ' bodySteps{ith_step,1}]);
    rowRange = numel(timeValues)-Npulse+1:numel(timeValues);
    fieldName = bodySteps{ith_step,2};
    if strcmp(fieldName,'lift')
        % CarMesh3D wheel order [FL FR RL RR]
        columns.lift(rowRange, bodySteps{ith_step,4}) = bodySteps{ith_step,3}*pulseShape;
    else
        columns.(fieldName)(rowRange) = bodySteps{ith_step,3}*pulseShape;
    end
end
segments(end+1) = fcn_INTERNAL_segment('body', timeValues, segmentStart, 'Body roll, pitch, heave, and each tire lifted, parked');

% --- 3. Steering: 90 deg left and right turns at 2 m/s
segmentStart = numel(timeValues);
turnSpeed = 2;
turnRadius = 1.5*wheelbase;
turnTime = (pi/2*turnRadius)/turnSpeed;
rampTime = 0.5;
steerPlan = {   % caption, duration, curvature at end, indicator
    'Steering: straight',              1.0,                 0,            0;
    'Steering: turning left',          rampTime,            1/turnRadius, 1;
    'Steering: turning left',          turnTime - rampTime, 1/turnRadius, 1;
    'Steering: straightening',         rampTime,            0,            1;
    'Steering: straight',              1.0,                 0,            0;
    'Steering: turning right',         rampTime,            -1/turnRadius, 2;
    'Steering: turning right',         turnTime - rampTime, -1/turnRadius, 2;
    'Steering: straightening',         rampTime,            0,            2;
    'Steering: straight',              1.0,                 0,            0};
lastCurvature = 0;
for ith_step = 1:size(steerPlan,1)
    Nrows = max(1, round(steerPlan{ith_step,2}/dt));
    [timeValues, columns, captions] = fcn_INTERNAL_addRows(timeValues, columns, captions, Nrows, dt, ...
        steerPlan{ith_step,1}, 'U', turnSpeed, 'headlights', 1, 'indicator', steerPlan{ith_step,4});
    rowRange = numel(timeValues)-Nrows+1:numel(timeValues);
    columns.curvature(rowRange) = lastCurvature + (steerPlan{ith_step,3} - lastCurvature)*((1:Nrows)'/Nrows);
    lastCurvature = steerPlan{ith_step,3};
end
segments(end+1) = fcn_INTERNAL_segment('steering', timeValues, segmentStart, 'Left and right turns near full lock, at 2 m/s');

% --- 4. Wheels: peel-out, lock-up, reverse
segmentStart = numel(timeValues);
wheelPlan = {  % caption, duration, speed at end, front spin factor, rear spin factor, brakeLight, reverseLight
    'Wheels: peel-out (front tires spin 2x)', 1.5, 4,  2, 1, 0, 0;
    'Wheels: speeding up',                    1.5, 8,  1, 1, 0, 0;
    'Wheels: cruising',                       1.0, 8,  1, 1, 0, 0;
    'Wheels: locked, hard braking (brakeLight = 2)', 2.0, 0, 0, 0, 2, 0;
    'Wheels: stopped (brakeLight = 1)',       0.6, 0,  1, 1, 1, 0;
    'Wheels: backing up (reverseLight = 1)',  1.0, -2, 1, 1, 0, 1;
    'Wheels: backing up (reverseLight = 1)',  1.5, -2, 1, 1, 0, 1;
    'Wheels: stopping (reverseLight = 1)',    1.0, 0,  1, 1, 0, 1};
lastSpeed = 0;
for ith_step = 1:size(wheelPlan,1)
    Nrows = round(wheelPlan{ith_step,2}/dt);
    [timeValues, columns, captions] = fcn_INTERNAL_addRows(timeValues, columns, captions, Nrows, dt, ...
        wheelPlan{ith_step,1}, 'headlights', 1, 'brakeLight', wheelPlan{ith_step,6}, 'reverseLight', wheelPlan{ith_step,7});
    rowRange = numel(timeValues)-Nrows+1:numel(timeValues);
    columns.U(rowRange) = lastSpeed + (wheelPlan{ith_step,3} - lastSpeed)*((1:Nrows)'/Nrows);
    columns.spinFactor(rowRange,:) = repmat([wheelPlan{ith_step,4} wheelPlan{ith_step,4} wheelPlan{ith_step,5} wheelPlan{ith_step,5}], Nrows, 1);
    lastSpeed = wheelPlan{ith_step,3};
end
segments(end+1) = fcn_INTERNAL_segment('wheels', timeValues, segmentStart, 'Peel-out, locked-wheel braking, backing up');

%%%%
% Integrate the path from speed and curvature (rear-axle reference point)
K = numel(timeValues);
speedValues = columns.U;
yawValues = cumtrapz(timeValues, speedValues.*columns.curvature);
xValues = cumtrapz(timeValues, speedValues.*cos(yawValues));
yValues = cumtrapz(timeValues, speedValues.*sin(yawValues));

% Steering: one centerline angle from the curvature, then Ackermann
bicycleSteer = atan(wheelbase*columns.curvature);
steerAngles = fcn_CarMesh3D_calcAckermannSteering(bicycleSteer, wheelbase, frontTrack, FigNum=-1);

% Wheels: spin rate = factor x speed / radius, integrated to angles
wheelRates = columns.spinFactor.*(speedValues./[tireRadius tireRadius tireRadiusRear tireRadiusRear]);   % ([FL FR RL RR])
wheelSpin = cumtrapz(timeValues, wheelRates);

%%%%
% Write the CSV file, then read it back exactly as any motion file is read
csvFile = options.CSVFile;
flagTemporary = isempty(csvFile);
if flagTemporary
    csvFile = [tempname '.csv'];
end
motionToWrite = struct('Time',timeValues, 'Pose',[xValues yValues yawValues], 'Speed',speedValues, ...
    'WheelSpin',wheelSpin, 'SteerAngle',steerAngles);
lights = struct('headlights',columns.headlights, 'indicator',columns.indicator, ...
    'brakeLight',columns.brakeLight, 'reverseLight',columns.reverseLight, 'runningLights',columns.runningLights);
fcn_CarMesh3D_saveMotionCSV(csvFile, motionToWrite, BodyRoll=columns.roll, BodyPitch=columns.pitch, ...
    BodyHeave=columns.heave, WheelLift=columns.lift, Lights=lights, FigNum=-1);
testMotion = fcn_CarMesh3D_loadMotionCSV(csvFile, VehicleSpec=vehicleSpec, FigNum=-1);
if flagTemporary
    delete(csvFile);
    testMotion.CSVFile = '';
else
    testMotion.CSVFile = char(csvFile);
end
testMotion.Segments = segments;
testMotion.Caption = captions;
testMotion.Path = 'standard test motion';
assert(numel(testMotion.Time)==K);

%% Any debugging?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____       _
%  |  __ \     | |
%  | |  | | ___| |__  _   _  __ _
%  | |  | |/ _ \ '_ \| | | |/ _` |
%  | |__| |  __/ |_) | |_| | (_| |
%  |_____/ \___|_.__/ \__,_|\__, |
%                            __/ |
%                           |___/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if flag_do_plots
    figure(figNum);
    clf;
    tiledlayout(4,1,'TileSpacing','compact');
    segmentColors = [0.95 0.90 0.80; 0.85 0.92 0.97; 0.88 0.95 0.86; 0.95 0.87 0.92];
    plotSets = {
        'Speed U [m/s], steer [deg]', [testMotion.Speed, rad2deg(testMotion.SteerAngle)], {'U','steer FL','steer FR'};
        'Body: roll, pitch [deg], heave [cm]', [rad2deg([testMotion.BodyRoll testMotion.BodyPitch]), 100*testMotion.BodyHeave], {'roll','pitch','heave'};
        'Wheel lift [cm]', 100*testMotion.WheelLift, {'FL','FR','RL','RR'};
        'Light inputs', [testMotion.Data.headlights, testMotion.Data.indicator, testMotion.Data.brakeLight, ...
            testMotion.Data.reverseLight, testMotion.Data.runningLights], {'headlights','indicator','brakeLight','reverseLight','runningLights'}};
    for ith_plot = 1:size(plotSets,1)
        nexttile;
        hold on;
        values = plotSets{ith_plot,2};
        yRange = [min(values(:)) max(values(:))] + [-1 1];
        for ith_segment = 1:length(testMotion.Segments)
            thisSegment = testMotion.Segments(ith_segment);
            patch([thisSegment.StartTime thisSegment.EndTime thisSegment.EndTime thisSegment.StartTime], ...
                yRange([1 1 2 2]), segmentColors(ith_segment,:), 'EdgeColor','none', 'HandleVisibility','off');
            if 1==ith_plot
                text(mean([thisSegment.StartTime thisSegment.EndTime]), yRange(2), thisSegment.Name, ...
                    'HorizontalAlignment','center','VerticalAlignment','top','FontWeight','bold');
            end
        end
        plot(testMotion.Time, values, 'LineWidth', 1.2);
        ylim(yRange); grid on; box on;
        ylabel(plotSets{ith_plot,1});
        legend(plotSets{ith_plot,3}, 'Location','eastoutside');
    end
    xlabel('Time [s]');
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_addRows
function [timeValues, columns, captions] = fcn_INTERNAL_addRows(timeValues, columns, captions, Nrows, dt, captionText, varargin)
% Adds Nrows time steps, with every input at its "off" value except
% those given as name, value pairs
if isempty(timeValues)
    newTimes = (0:Nrows-1)'*dt;
else
    newTimes = timeValues(end) + (1:Nrows)'*dt;
end
timeValues = [timeValues; newTimes];
zeroColumn = zeros(Nrows,1);
newValues = struct('U',zeroColumn,'curvature',zeroColumn,'roll',zeroColumn,'pitch',zeroColumn, ...
    'heave',zeroColumn,'lift',zeros(Nrows,4),'spinFactor',ones(Nrows,4),'headlights',zeroColumn, ...
    'indicator',zeroColumn,'brakeLight',zeroColumn,'reverseLight',zeroColumn,'runningLights',zeroColumn);
for ith_pair = 1:2:length(varargin)
    newValues.(varargin{ith_pair}) = varargin{ith_pair+1}*ones(Nrows, size(newValues.(varargin{ith_pair}),2));
end
fieldNames = fieldnames(newValues);
for ith_field = 1:length(fieldNames)
    columns.(fieldNames{ith_field}) = [columns.(fieldNames{ith_field}); newValues.(fieldNames{ith_field})];
end
captions = [captions; repmat({captionText}, Nrows, 1)];
end % Ends fcn_INTERNAL_addRows

%% fcn_INTERNAL_segment
function segment = fcn_INTERNAL_segment(name, timeValues, startRow, description)
% One segment's name, start and end times, and description
segment = struct('Name',name, 'StartTime',timeValues(startRow+1), 'EndTime',timeValues(end), 'Description',description);
end % Ends fcn_INTERNAL_segment
