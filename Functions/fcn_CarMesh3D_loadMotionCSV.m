function motion = fcn_CarMesh3D_loadMotionCSV(fileName, options)
% fcn_CarMesh3D_loadMotionCSV
% Reads a vehicle motion from a CSV file (for example, the output of a
% vehicle dynamics simulation) and converts it into everything
% fcn_CarMesh3D_plotVehicle needs at each time step: the pose of the
% ground (unsprung) frame, the body (sprung mass) roll, pitch, and heave
% relative to it, wheel spin and lift, front-wheel steer angles, and the
% light states.
%
% THE COLUMNS. The file has one row per time step and a header row of
% column names. Columns are found by NAME, so their order does not matter
% and any column except X, Y, and yaw may be left out. The usual order
% (the order fcn_CarMesh3D_saveMotionCSV writes) is:
%
%    #  Name            Units  Meaning (default if the column is missing)
%    1  time            s      Time (or give SampleTime)
%    2  X               m      Global X of the rear-axle center, on the ground
%    3  Y               m      Global Y of the rear-axle center, on the ground
%    4  Z               m      Sprung-mass displacement up from its static
%                              equilibrium (ride height); 0 at equilibrium (0)
%    5  roll            rad    Sprung-mass roll, + right side down (0)
%    6  pitch           rad    Sprung-mass pitch, + nose down (0)
%    7  yaw             rad    Heading, + counterclockwise from +X
%    8  U               m/s    Body-fixed forward speed (from the path)
%    9  V               m/s    Body-fixed lateral speed (not used)
%   10  W               m/s    Body-fixed vertical speed (not used)
%   11  roll_rate       rad/s  (not used)
%   12  pitch_rate      rad/s  (not used)
%   13  yaw_rate        rad/s  Used with U for steering, if no steer column
%   14  wheelSpeed_FL   rad/s  Tire 1 spin rate, + rolling forward
%   15  wheelSpeed_RL   rad/s  Tire 2
%   16  wheelSpeed_RR   rad/s  Tire 3
%   17  wheelSpeed_FR   rad/s  Tire 4   (all four: from U / tire radius)
%   18  wheelLift_FL    m      Tire 1 height above the road (0)
%   19  wheelLift_RL    m      Tire 2 (0)
%   20  wheelLift_RR    m      Tire 3 (0)
%   21  wheelLift_FR    m      Tire 4 (0)
%   22  roadRoll        rad    Ground tilt under the vehicle, about X (0)
%   23  roadPitch       rad    Ground tilt under the vehicle, about Y (0)
%   24  steer_FL        rad    Front-left road-wheel angle, + left
%   25  steer_FR        rad    Front-right road-wheel angle, + left
%                              (both: see "Steering" below)
%   26  headlights      -      0 off, 1 low, 2 high (0)
%   27  indicator       -      0 off, 1 left, 2 right, 3 hazard (0)
%   28  brakeLight      -      0 off, 1 on, 2 strong (0)
%   29  reverseLight    -      0 off, 1 on (0)
%   30  runningLights   -      0 off, 1 on (0)
%
% Tires are numbered by quadrant (ISO 8855, viewed from above): 1 front
% left, 2 rear left, 3 rear right, 4 front right. The names carry the
% position (_FL, _RL, _RR, _FR) so the numbering cannot be mixed up;
% w1, w2, w3, w4 are also accepted for the four wheel speeds.
%
% Other accepted columns: roadZ (m, ground height under the rear axle,
% default 0), steerAngle (rad, one centerline "bicycle" angle),
% steeringWheelAngle (rad, divided by SteeringRatio), and wheelAngle_FL,
% _RL, _RR, _FR (rad, wheel rotation angles, used instead of integrating
% the wheel speeds). Any other column is read and ignored.
%
% UNITS are SI with angles in radians. A name ending in _deg is in
% degrees (or degrees per second), for example yaw_deg or steer_FL_deg,
% and a wheel speed ending in _rpm is in revolutions per minute; both are
% converted. Names are matched ignoring upper and lower case and
% underscores, so roll_rate, Roll_Rate, and rollRate are the same column.
% Use names that are valid MATLAB and Python variable names (letters,
% digits, and underscores, starting with a letter), as all names here are.
%
% LIGHTS ARE INPUTS. Every light comes from its own column; none is
% worked out from the motion. (A car coasting downhill may brake while
% speeding up, and a car rolling back down a hill is not in reverse.)
%
% HOW THE COLUMNS ARE USED.
%   Pose (ground frame): [X Y roadZ roadRoll roadPitch yaw]. The wheels
%     sit in this frame, on the ground.
%   Body: BodyHeave = Z, BodyRoll = roll - roadRoll, BodyPitch = pitch -
%     roadPitch (the body angles relative to the ground under it; exact
%     for flat ground, and a close approximation for gentle slopes).
%   Wheel spin: wheelAngle_* if given, otherwise the integral of
%     wheelSpeed_* over time, otherwise distance traveled / tire radius.
%   Steering, in this order of preference: steer_FL and steer_FR;
%     steerAngle; steeringWheelAngle / SteeringRatio; or, if there is no
%     steering column, the path's curvature (yaw_rate / U, or the change
%     in yaw per meter traveled). A single angle is split into left and
%     right angles with fcn_CarMesh3D_calcAckermannSteering.
%   Lights: indicator becomes blinking TurnLeft / TurnRight (on for half
%     of BlinkPeriod, starting on when switched on); brakeLight 1 or 2
%     becomes Tail='brake'; reverseLight 1 becomes Backup; the tail
%     lights are 'on' when the headlights or running lights are on. A
%     missing light column means that light is off.
%
% FORMAT:
%
%       motion = fcn_CarMesh3D_loadMotionCSV(fileName,...
%           (VehicleSpec=vehicleSpec), (SampleTime=dt),...
%           (ColumnNames=names), (SteeringRatio=ratio),...
%           (BlinkPeriod=T), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      fileName: the CSV file to read; or the motion already in memory:
%      a table (its variable names are the column names), or a matrix of
%      numbers (one column per quantity, named by ColumnNames, or in the
%      usual column order if ColumnNames is not given). A table or
%      matrix is read the same way as a file, so a program that reads a
%      growing file itself (only the new rows) can hand the rows over
%      without writing a file.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      VehicleSpec: a spec from fcn_CarMesh3D_fillVehicleSpec or
%      fcn_CarMesh3D_loadVehicleSpec, for the wheelbase, front track, and
%      tire diameter. Default is the 'genericSedan' preset.
%      (For a table or matrix, ColumnNames names the columns of a matrix,
%      and is not used for a table.)
%
%      SampleTime: the time step, in seconds, for files with no time
%      column. Default [] (the file must then have a time column).
%
%      ColumnNames: a cell array of column names, for files with NO
%      header row (the first line is numbers). Default is the usual order
%      above. For example, for a file of [X Y Z roll pitch yaw U V W
%      roll_rate pitch_rate yaw_rate w1 w2 w3 w4], use
%      ColumnNames={'X','Y','Z','roll','pitch','yaw','U','V','W',...
%      'roll_rate','pitch_rate','yaw_rate','w1','w2','w3','w4'} and give
%      SampleTime.
%
%      SteeringRatio: steering-wheel angle / road-wheel angle, used only
%      with a steeringWheelAngle column. Default 15.
%
%      BlinkPeriod: the turn signal on-off period, in seconds. Default 0.8.
%
%      FigNum: a figure number to plot the path, speed, steering, and body
%      motion. If empty or omitted, no plot is made. If set to -1, input
%      checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      motion: a structure with one row per time step (K rows):
%           Time (K x 1)
%           Pose (K x 6): [x y z roll pitch yaw] of the ground frame
%           BodyRoll, BodyPitch, BodyHeave (K x 1): the body relative to
%               the ground frame
%           Speed (K x 1, U), Distance (K x 1)
%           SteerAngle (K x 2): [FL FR] road-wheel angles
%           SteerSource: which column the steering came from
%           WheelSpin (K x 4), WheelLift (K x 4): in CarMesh3D's
%               [FL FR RL RR] order, ready for fcn_CarMesh3D_plotVehicle
%           LightStates (K x 1 structure array): ready for
%               fcn_CarMesh3D_plotVehicle's LightStates
%           Data: every column read, by its usual name, in SI units
%           ColumnsUsed, ColumnsIgnored: the column names as written in
%               the file
%           FileName, Path ('csv')
%      Use row k with fcn_CarMesh3D_plotVehicle:
%           Pose=motion.Pose(k,:), WheelSpin=motion.WheelSpin(k,:),
%           SteerAngle=motion.SteerAngle(k,:), WheelLift=motion.WheelLift(k,:),
%           BodyRoll=motion.BodyRoll(k), BodyPitch=motion.BodyPitch(k),
%           BodyHeave=motion.BodyHeave(k), LightStates=motion.LightStates(k)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_fillVehicleSpec (only for the default spec)
%      fcn_CarMesh3D_calcAckermannSteering
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_loadMotionCSV.m for a full test
%       suite, and fcn_CarMesh3D_saveMotionCSV to write a file.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadMotionCSV
%   % * Wrote the code originally (drafted with Claude)
%   % * Rate columns renamed roll_rate, pitch_rate, yaw_rate; brake and
%   %   reverse lights are now inputs only (removed AutoLights and
%   %   BrakeDeceleration)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadMotionCSV
%   % * Wheel spin from speed uses each axle's own tire radius
%   %   % (VehicleSpec.TireDiameterRear for the rear wheels)
%   % * Reads a table, or a matrix of numbers (with ColumnNames), as well
%   %   % as a file (asked for by AnimateCar3D's live watcher)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_loadMotionCSV
%   % * Several vehicles in one file (an id column)
%   % * Resample to a fixed frame rate for animation



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    fileName
    options.VehicleSpec = []         % For wheelbase, track, tire diameter
    options.SampleTime = []          % Time step [s] for files with no time column
    options.ColumnNames = []         % Column names for files with no header row
    options.SteeringRatio = 15       % Steering-wheel angle / road-wheel angle
    options.BlinkPeriod = 0.8        % Turn signal period [s]
    options.FigNum = []              % Figure to plot into; [] for no plot, -1 for fast mode
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

        % Check the fileName input: a file, a table, or a matrix of numbers
        if istable(fileName)
            if width(fileName) < 3
                error('A motion table needs at least the X, Y, and yaw columns');
            end
        elseif isnumeric(fileName)
            if ~ismatrix(fileName) || size(fileName,2) < 3
                error('A motion matrix needs one column per quantity (at least X, Y, and yaw)');
            end
        elseif ~(ischar(fileName) || isstring(fileName)) || ~isfile(fileName)
            error('File not found: %s', char(string(fileName)));
        end

        % Check the numeric options
        if ~isempty(options.SampleTime) && (~isnumeric(options.SampleTime) || ~isscalar(options.SampleTime) || options.SampleTime<=0)
            error('SampleTime must be empty or a positive number of seconds');
        end
        numericNames = {'SteeringRatio','BlinkPeriod'};
        for ith_name = 1:length(numericNames)
            thisValue = options.(numericNames{ith_name});
            if ~isnumeric(thisValue) || ~isscalar(thisValue) || ~(thisValue>0)
                error('%s must be a positive number', numericNames{ith_name});
            end
        end

        % Check the ColumnNames input
        if ~isempty(options.ColumnNames) && ~(iscellstr(options.ColumnNames) || isstring(options.ColumnNames)) %#ok<ISCLSTR>
            error('ColumnNames must be a cell array of column names');
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

%%%%
% Read the numbers and the column names
if istable(fileName)
    [dataMatrix, rawNames] = fcn_INTERNAL_readTable(fileName);
    fileName = '(table)';
elseif isnumeric(fileName)
    [dataMatrix, rawNames] = fcn_INTERNAL_readMatrix(double(fileName), options.ColumnNames);
    fileName = '(numbers)';
else
    fileName = char(fileName);
    [dataMatrix, rawNames] = fcn_INTERNAL_readFile(fileName, options.ColumnNames);
end
Nrows = size(dataMatrix,1);
if Nrows < 2
    error('The file %s has fewer than 2 rows of data', fileName);
end

%%%%
% Match each column to a usual name, and convert its units to SI
[knownNames, angleNames] = fcn_INTERNAL_knownColumns;
data = struct;
columnsUsed = {};
columnsIgnored = {};
for ith_column = 1:length(rawNames)
    [usualName, unitScale] = fcn_INTERNAL_matchColumn(rawNames{ith_column}, knownNames, angleNames);
    if isempty(usualName)
        columnsIgnored{end+1} = rawNames{ith_column}; %#ok<AGROW>
    else
        data.(usualName) = dataMatrix(:,ith_column)*unitScale;
        columnsUsed{end+1} = rawNames{ith_column}; %#ok<AGROW>
    end
end
has = @(name) isfield(data, name);
getColumn = @(name, defaultValue) fcn_INTERNAL_getColumn(data, name, defaultValue, Nrows);

%%%%
% Time
if has('time')
    timeValues = data.time;
elseif ~isempty(options.SampleTime)
    timeValues = (0:Nrows-1)'*options.SampleTime;
    data.time = timeValues;
else
    error('The file has no time column; give SampleTime');
end

%%%%
% Required pose columns
missingNames = {'X','Y','yaw'};
missingNames = missingNames(~cellfun(has, missingNames));
if ~isempty(missingNames)
    error('The file is missing required column(s): %s', strjoin(missingNames,', '));
end
xValues = data.X;
yValues = data.Y;
yawValues = unwrap(data.yaw);

%%%%
% Vehicle dimensions
vehicleSpec = options.VehicleSpec;
if isempty(vehicleSpec)
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
end
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
% Ground (unsprung) frame and body (sprung mass) motion
roadRoll = getColumn('roadRoll',0);
roadPitch = getColumn('roadPitch',0);
poseValues = [xValues, yValues, getColumn('roadZ',0), roadRoll, roadPitch, yawValues];
bodyHeave = getColumn('Z',0);
bodyRoll = getColumn('roll',0) - roadRoll;
bodyPitch = getColumn('pitch',0) - roadPitch;

%%%%
% Speed and distance
if has('U')
    speedValues = data.U;
else
    % Path speed along the heading (negative when backing up)
    speedValues = gradient(xValues,timeValues).*cos(yawValues) + gradient(yValues,timeValues).*sin(yawValues);
end
distanceValues = cumtrapz(timeValues, speedValues);

%%%%
% Wheel spin and lift. The file is in quadrant order (1 FL, 2 RL, 3 RR,
% 4 FR); CarMesh3D uses [FL FR RL RR].
quadrantToCarMesh = [1 4 2 3]; % CarMesh3D wheel i is file tire quadrantToCarMesh(i)
wheelSuffixes = {'FL','RL','RR','FR'};
angleColumns = strcat('wheelAngle_', wheelSuffixes);
speedColumns = strcat('wheelSpeed_', wheelSuffixes);
liftColumns = strcat('wheelLift_', wheelSuffixes);
if all(cellfun(has, angleColumns))
    wheelQuadrant = cell2mat(cellfun(@(name) data.(name), angleColumns, 'UniformOutput', false));
elseif all(cellfun(has, speedColumns))
    wheelQuadrant = cumtrapz(timeValues, cell2mat(cellfun(@(name) data.(name), speedColumns, 'UniformOutput', false)));
else
    wheelQuadrant = distanceValues./[tireRadius tireRadiusRear tireRadiusRear tireRadius];   % (quadrant order: FL RL RR FR)
end
wheelSpin = wheelQuadrant(:, quadrantToCarMesh);
liftQuadrant = cell2mat(cellfun(@(name) getColumn(name,0), liftColumns, 'UniformOutput', false));
wheelLift = liftQuadrant(:, quadrantToCarMesh);

%%%%
% Steering: [FL FR] road-wheel angles
if has('steer_FL') && has('steer_FR')
    steerValues = [data.steer_FL data.steer_FR];
    steerSource = 'steer_FL and steer_FR';
else
    if has('steerAngle')
        bicycleSteer = data.steerAngle;
        steerSource = 'steerAngle';
    elseif has('steeringWheelAngle')
        bicycleSteer = data.steeringWheelAngle/options.SteeringRatio;
        steerSource = 'steeringWheelAngle / SteeringRatio';
    else
        % From the path: curvature = yaw rate / speed, or the change in
        % yaw per meter traveled
        if has('yaw_rate') && has('U')
            curvature = data.yaw_rate./speedValues;
            steerSource = 'path curvature (yaw_rate / U)';
        else
            curvature = gradient(yawValues)./gradient(distanceValues);
            steerSource = 'path curvature (change in yaw per meter)';
        end
        curvature(~isfinite(curvature) | abs(speedValues) < 0.1) = 0;
        bicycleSteer = atan(wheelbase*curvature);
    end
    bicycleSteer = max(min(bicycleSteer, deg2rad(60)), -deg2rad(60));
    steerValues = fcn_CarMesh3D_calcAckermannSteering(bicycleSteer, wheelbase, frontTrack, FigNum=-1);
end

%%%%
% Lights
headlightCodes = round(getColumn('headlights',0));
indicatorCodes = round(getColumn('indicator',0));
runningCodes = round(getColumn('runningLights',0));
% Brake and reverse lights are inputs, never worked out from the motion
brakeCodes = round(getColumn('brakeLight',0));
reverseCodes = round(getColumn('reverseLight',0));
lightStates = fcn_INTERNAL_lightStates(timeValues, headlightCodes, indicatorCodes, brakeCodes, reverseCodes, runningCodes, options.BlinkPeriod);

%%%%
% Output
motion = struct;
motion.Time = timeValues;
motion.Pose = poseValues;
motion.BodyRoll = bodyRoll;
motion.BodyPitch = bodyPitch;
motion.BodyHeave = bodyHeave;
motion.Speed = speedValues;
motion.Distance = distanceValues;
motion.SteerAngle = steerValues;
motion.SteerSource = steerSource;
motion.WheelSpin = wheelSpin;
motion.WheelLift = wheelLift;
motion.LightStates = lightStates;
motion.Data = data;
motion.ColumnsUsed = columnsUsed;
motion.ColumnsIgnored = columnsIgnored;
motion.FileName = fileName;
motion.Path = 'csv';

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
    tiledlayout(2,2);

    nexttile;
    plot(motion.Pose(:,1), motion.Pose(:,2), 'b-', 'LineWidth', 1.5);
    hold on;
    plot(motion.Pose(1,1), motion.Pose(1,2), 'go', 'MarkerFaceColor','g');
    axis equal; grid on;
    xlabel('X [m]'); ylabel('Y [m]');
    [~, shortName, extension] = fileparts(fileName);
    title(sprintf('Path: %s%s', shortName, extension), 'Interpreter','none');

    nexttile;
    plot(motion.Time, motion.Speed, 'LineWidth', 1.5);
    grid on; xlabel('Time [s]'); ylabel('U [m/s]'); title('Forward speed');

    nexttile;
    plot(motion.Time, rad2deg(motion.SteerAngle), 'LineWidth', 1.5);
    grid on; xlabel('Time [s]'); ylabel('Steer angle [deg]');
    legend({'FL','FR'},'Location','best');
    title(sprintf('Steering (from %s)', motion.SteerSource), 'Interpreter','none');

    nexttile;
    yyaxis left;
    plot(motion.Time, rad2deg([motion.BodyRoll motion.BodyPitch]), 'LineWidth', 1.5);
    ylabel('Body angle [deg]');
    yyaxis right;
    plot(motion.Time, 100*motion.BodyHeave, 'LineWidth', 1.5);
    ylabel('Body heave [cm]');
    grid on; xlabel('Time [s]');
    legend({'roll','pitch','heave'},'Location','best');
    title('Body motion relative to the ground');
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

%% fcn_INTERNAL_readFile
function [dataMatrix, rawNames] = fcn_INTERNAL_readFile(fileName, columnNames)
% Reads a CSV file with or without a header row
fileID = fopen(fileName,'r');
firstLine = '';
while ischar(firstLine) && isempty(strtrim(firstLine))
    firstLine = fgetl(fileID);
end
fclose(fileID);
if ~ischar(firstLine)
    error('The file %s is empty', fileName);
end
flagHeader = any(isletter(regexprep(firstLine,'[eE][+-]?\d','')));
if flagHeader
    dataTable = readtable(fileName, 'VariableNamingRule','preserve', 'FileType','text', 'Delimiter',',');
    [dataMatrix, rawNames] = fcn_INTERNAL_readTable(dataTable);
else
    dataMatrix = readmatrix(fileName, 'FileType','text', 'Delimiter',',');
    [dataMatrix, rawNames] = fcn_INTERNAL_readMatrix(dataMatrix, columnNames);
end
end % Ends fcn_INTERNAL_readFile

%% fcn_INTERNAL_readTable
function [dataMatrix, rawNames] = fcn_INTERNAL_readTable(dataTable)
% The numbers and names of a table's columns (columns that are not
% numbers are left as NaN)
rawNames = dataTable.Properties.VariableNames;
dataMatrix = nan(height(dataTable), length(rawNames));
for ith_column = 1:length(rawNames)
    thisColumn = dataTable.(rawNames{ith_column});
    if (isnumeric(thisColumn) || islogical(thisColumn)) && size(thisColumn,2)==1
        dataMatrix(:,ith_column) = double(thisColumn);
    end
end
end % Ends fcn_INTERNAL_readTable

%% fcn_INTERNAL_readMatrix
function [dataMatrix, rawNames] = fcn_INTERNAL_readMatrix(dataMatrix, columnNames)
% Names for a matrix's columns: ColumnNames, or the usual order
if isempty(columnNames)
    columnNames = fcn_INTERNAL_usualColumns;
end
columnNames = cellstr(columnNames);
if length(columnNames) < size(dataMatrix,2)
    error('The data have %d columns but only %d ColumnNames', size(dataMatrix,2), length(columnNames));
end
rawNames = columnNames(1:size(dataMatrix,2));
end % Ends fcn_INTERNAL_readMatrix

%% fcn_INTERNAL_usualColumns
function usualNames = fcn_INTERNAL_usualColumns
% The usual column names, in the usual order
usualNames = {'time','X','Y','Z','roll','pitch','yaw','U','V','W', ...
    'roll_rate','pitch_rate','yaw_rate', ...
    'wheelSpeed_FL','wheelSpeed_RL','wheelSpeed_RR','wheelSpeed_FR', ...
    'wheelLift_FL','wheelLift_RL','wheelLift_RR','wheelLift_FR', ...
    'roadRoll','roadPitch','steer_FL','steer_FR', ...
    'headlights','indicator','brakeLight','reverseLight','runningLights'};
end % Ends fcn_INTERNAL_usualColumns

%% fcn_INTERNAL_knownColumns
function [knownNames, angleNames] = fcn_INTERNAL_knownColumns
% Every column name this function uses, and which of them are angles or
% angle rates (so a _deg ending converts them)
knownNames = [fcn_INTERNAL_usualColumns, {'roadZ','steerAngle','steeringWheelAngle', ...
    'wheelAngle_FL','wheelAngle_RL','wheelAngle_RR','wheelAngle_FR'}];
angleNames = {'roll','pitch','yaw','roll_rate','pitch_rate','yaw_rate', ...
    'wheelSpeed_FL','wheelSpeed_RL','wheelSpeed_RR','wheelSpeed_FR', ...
    'roadRoll','roadPitch','steer_FL','steer_FR','steerAngle','steeringWheelAngle', ...
    'wheelAngle_FL','wheelAngle_RL','wheelAngle_RR','wheelAngle_FR'};
end % Ends fcn_INTERNAL_knownColumns

%% fcn_INTERNAL_matchColumn
function [usualName, unitScale] = fcn_INTERNAL_matchColumn(rawName, knownNames, angleNames)
% The usual name of a column (or '' if unknown), and the factor that
% converts it to SI units
usualName = '';
unitScale = 1;
thisName = strtrim(char(rawName));
flagDegrees = false;
flagRPM = false;
if ~isempty(regexpi(thisName,'[_ ]deg$','once'))
    flagDegrees = true;
    thisName = regexprep(thisName,'[_ ]deg$','','ignorecase');
elseif ~isempty(regexpi(thisName,'[_ ]rpm$','once'))
    flagRPM = true;
    thisName = regexprep(thisName,'[_ ]rpm$','','ignorecase');
end
squash = @(name) lower(regexprep(char(name),'[^A-Za-z0-9]',''));
key = squash(thisName);
aliases = {'w1','wheelSpeed_FL'; 'w2','wheelSpeed_RL'; 'w3','wheelSpeed_RR'; 'w4','wheelSpeed_FR'; 't','time'};
aliasIndex = find(strcmp(key, aliases(:,1)), 1);
if ~isempty(aliasIndex)
    usualName = aliases{aliasIndex,2};
else
    knownIndex = find(strcmp(key, cellfun(squash, knownNames, 'UniformOutput', false)), 1);
    if isempty(knownIndex)
        return;
    end
    usualName = knownNames{knownIndex};
end
if flagDegrees
    if ~any(strcmp(usualName, angleNames))
        error('Column %s ends in _deg, but %s is not an angle', char(rawName), usualName);
    end
    unitScale = pi/180;
elseif flagRPM
    if ~startsWith(usualName,'wheelSpeed')
        error('Column %s ends in _rpm, but only wheel speeds can be in rpm', char(rawName));
    end
    unitScale = 2*pi/60;
end
end % Ends fcn_INTERNAL_matchColumn

%% fcn_INTERNAL_getColumn
function values = fcn_INTERNAL_getColumn(data, name, defaultValue, Nrows)
% A column, or a column of the default value if it is missing
if isfield(data, name)
    values = data.(name);
    values(isnan(values)) = defaultValue;
else
    values = defaultValue*ones(Nrows,1);
end
end % Ends fcn_INTERNAL_getColumn

%% fcn_INTERNAL_lightStates
function lightStates = fcn_INTERNAL_lightStates(timeValues, headlightCodes, indicatorCodes, brakeCodes, reverseCodes, runningCodes, blinkPeriod)
% Converts the light columns into one LightStates structure per row.
% Turn signals blink, starting "on" whenever the indicator changes.
headlightNames = {'off','low','high'};
Nrows = length(timeValues);
lightStates = repmat(struct('Headlights','off','TurnLeft',false,'TurnRight',false, ...
    'Running',false,'Tail','off','Backup',false), Nrows, 1);
switchTime = timeValues(1);
for ith_row = 1:Nrows
    if ith_row>1 && indicatorCodes(ith_row)~=indicatorCodes(ith_row-1)
        switchTime = timeValues(ith_row);
    end
    blinkOn = mod(timeValues(ith_row) - switchTime, blinkPeriod) < blinkPeriod/2;
    headlightCode = min(max(headlightCodes(ith_row),0),2);
    lightStates(ith_row).Headlights = headlightNames{headlightCode+1};
    lightStates(ith_row).TurnLeft = blinkOn && any(indicatorCodes(ith_row)==[1 3]);
    lightStates(ith_row).TurnRight = blinkOn && any(indicatorCodes(ith_row)==[2 3]);
    lightStates(ith_row).Running = runningCodes(ith_row) > 0;
    if brakeCodes(ith_row) > 0
        lightStates(ith_row).Tail = 'brake';
    elseif headlightCode > 0 || runningCodes(ith_row) > 0
        lightStates(ith_row).Tail = 'on';
    end
    lightStates(ith_row).Backup = reverseCodes(ith_row) > 0;
end
end % Ends fcn_INTERNAL_lightStates
