function fileName = fcn_CarMesh3D_saveMotionCSV(fileName, motion, options)
% fcn_CarMesh3D_saveMotionCSV
% Writes a vehicle motion to a CSV file in the CarMesh3D column
% convention, which fcn_CarMesh3D_loadMotionCSV reads. Use it to see an
% example of the convention, to save a motion made with
% fcn_CarMesh3D_fillTrajectory, or as a template for writing the same
% columns from a vehicle dynamics simulation.
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
% All 30 usual columns are written, in the usual order, in SI units and
% radians. A roadZ column is added at the end if the ground height is not
% zero. Wheel speeds are written as rates (the time derivative of the
% wheel spin angles).
%
% FORMAT:
%
%       fileName = fcn_CarMesh3D_saveMotionCSV(fileName, motion,...
%           (BodyRoll=roll), (BodyPitch=pitch), (BodyHeave=heave),...
%           (WheelLift=lift), (Lights=lights), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      fileName: the .csv file to write (it is replaced if it exists).
%
%      motion: a motion structure with Time, Pose (K x 3 [x y yaw] or
%      K x 6 [x y z roll pitch yaw] of the ground frame), and optionally
%      Speed, WheelSpin (K x 4, [FL FR RL RR]), SteerAngle (K x 1 or
%      K x 2 [FL FR]), BodyRoll, BodyPitch, BodyHeave, and WheelLift
%      (K x 4, [FL FR RL RR]). The output of fcn_CarMesh3D_fillTrajectory
%      or fcn_CarMesh3D_loadMotionCSV works.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      BodyRoll, BodyPitch, BodyHeave: K x 1 body motion relative to the
%      ground frame (radians, radians, meters), used instead of the
%      motion's own fields. Default [] (use the motion's fields, or 0).
%
%      WheelLift: K x 4 wheel lift [FL FR RL RR] in meters. Default [].
%
%      Lights: a structure of light columns, each a scalar or K x 1:
%      headlights (0/1/2), indicator (0/1/2/3), brakeLight (0/1/2),
%      reverseLight (0/1), runningLights (0/1). Missing fields are 0.
%
%      FigNum: if set to -1, input checking is skipped (fast mode).
%
% OUTPUTS:
%
%      fileName: the file that was written.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       trajectory = fcn_CarMesh3D_fillTrajectory(Path='circle', Duration=5);
%       fcn_CarMesh3D_saveMotionCSV('circle.csv', trajectory, ...
%           Lights=struct('headlights',1,'indicator',1));
%       motion = fcn_CarMesh3D_loadMotionCSV('circle.csv');
%
%       See the script: script_CarMesh3D_saveMotionCSV.m for a full test
%       suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_saveMotionCSV
%   % * Wrote the code originally (drafted with Claude)
%   % * Rate columns renamed roll_rate, pitch_rate, yaw_rate

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_saveMotionCSV
%   % * Option to write only some columns



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    fileName
    motion
    options.BodyRoll = []     % K x 1 [rad]; [] to use motion.BodyRoll or 0
    options.BodyPitch = []    % K x 1 [rad]
    options.BodyHeave = []    % K x 1 [m]
    options.WheelLift = []    % K x 4 [m], [FL FR RL RR]
    options.Lights = struct   % Light columns (scalars or K x 1)
    options.FigNum = []       % -1 for fast mode (no input checks)
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

        % Check the fileName input
        if ~(ischar(fileName) || isstring(fileName))
            error('fileName must be a character string');
        end

        % Check the motion input
        if ~isstruct(motion) || ~isfield(motion,'Time') || ~isfield(motion,'Pose')
            error('motion must be a structure with Time and Pose (for example, from fcn_CarMesh3D_fillTrajectory)');
        end
        Ncheck = length(motion.Time);
        if ~any(size(motion.Pose,2)==[3 6]) || size(motion.Pose,1)~=Ncheck
            error('motion.Pose must be K x 3 [x y yaw] or K x 6 [x y z roll pitch yaw], with K = length(motion.Time)');
        end

        % Check the optional columns
        optionNames = {'BodyRoll','BodyPitch','BodyHeave'};
        for ith_name = 1:3
            thisValue = options.(optionNames{ith_name});
            if ~isempty(thisValue) && numel(thisValue)~=Ncheck
                error('%s must have one value per time step (%d)', optionNames{ith_name}, Ncheck);
            end
        end
        if ~isempty(options.WheelLift) && ~isequal(size(options.WheelLift),[Ncheck 4])
            error('WheelLift must be K x 4 [FL FR RL RR]');
        end
        if ~isstruct(options.Lights)
            error('Lights must be a structure of light columns');
        end
    end
end

% (This function writes a file; it makes no plot of its own)

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

timeValues = motion.Time(:);
Nrows = length(timeValues);
column = @(values) fcn_INTERNAL_column(values, Nrows);

%%%%
% Ground frame
if size(motion.Pose,2)==3
    groundPose = [motion.Pose(:,1:2), zeros(Nrows,3), motion.Pose(:,3)];
else
    groundPose = motion.Pose;
end
xValues = groundPose(:,1);
yValues = groundPose(:,2);
roadZ = groundPose(:,3);
roadRoll = groundPose(:,4);
roadPitch = groundPose(:,5);
yawValues = unwrap(groundPose(:,6));

%%%%
% Body motion relative to the ground frame
bodyRoll = fcn_INTERNAL_pick(options.BodyRoll, motion, 'BodyRoll', Nrows);
bodyPitch = fcn_INTERNAL_pick(options.BodyPitch, motion, 'BodyPitch', Nrows);
bodyHeave = fcn_INTERNAL_pick(options.BodyHeave, motion, 'BodyHeave', Nrows);
rollValues = bodyRoll + roadRoll;
pitchValues = bodyPitch + roadPitch;

%%%%
% Speeds and rates
if isfield(motion,'Speed') && ~isempty(motion.Speed)
    speedValues = motion.Speed(:);
else
    speedValues = gradient(xValues,timeValues).*cos(yawValues) + gradient(yValues,timeValues).*sin(yawValues);
end

%%%%
% Wheels, in the file's quadrant order (1 FL, 2 RL, 3 RR, 4 FR) from
% CarMesh3D's [FL FR RL RR]
carMeshToQuadrant = [1 3 4 2]; % File tire j is CarMesh3D wheel carMeshToQuadrant(j)
if isfield(motion,'WheelSpin') && ~isempty(motion.WheelSpin)
    wheelSpeeds = zeros(Nrows,4);
    for ith_wheel = 1:4
        wheelSpeeds(:,ith_wheel) = gradient(motion.WheelSpin(:,ith_wheel), timeValues);
    end
else
    wheelSpeeds = zeros(Nrows,4);
end
wheelSpeeds = wheelSpeeds(:, carMeshToQuadrant);
wheelLift = options.WheelLift;
if isempty(wheelLift)
    if isfield(motion,'WheelLift') && ~isempty(motion.WheelLift)
        wheelLift = motion.WheelLift;
    else
        wheelLift = zeros(Nrows,4);
    end
end
wheelLift = wheelLift(:, carMeshToQuadrant);

%%%%
% Steering
steerValues = zeros(Nrows,2);
if isfield(motion,'SteerAngle') && ~isempty(motion.SteerAngle)
    if size(motion.SteerAngle,2)==1
        steerValues = repmat(motion.SteerAngle(:),1,2);
    else
        steerValues = motion.SteerAngle;
    end
end

%%%%
% Lights
lights = options.Lights;
lightNames = {'headlights','indicator','brakeLight','reverseLight','runningLights'};
lightColumns = zeros(Nrows, length(lightNames));
for ith_light = 1:length(lightNames)
    if isfield(lights, lightNames{ith_light})
        lightColumns(:,ith_light) = column(lights.(lightNames{ith_light}));
    end
end

%%%%
% All columns, in the usual order
allColumns = [timeValues, xValues, yValues, bodyHeave, rollValues, pitchValues, yawValues, ...
    speedValues, zeros(Nrows,2), ...
    gradient(rollValues,timeValues), gradient(pitchValues,timeValues), gradient(yawValues,timeValues), ...
    wheelSpeeds, wheelLift, roadRoll, roadPitch, steerValues, lightColumns];
columnNames = fcn_INTERNAL_usualColumns;
if any(roadZ~=0)
    allColumns = [allColumns, roadZ];
    columnNames = [columnNames, {'roadZ'}];
end

%%%%
% Write: a header row, then one row per time step
fileName = char(fileName);
fileID = fopen(fileName,'w');
if fileID < 0
    error('Could not open %s for writing', fileName);
end
fprintf(fileID, '%s\n', strjoin(columnNames, ','));
rowFormat = [strjoin(repmat({'%.10g'},1,length(columnNames)), ','), '\n'];
fprintf(fileID, rowFormat, allColumns');
fclose(fileID);

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
% (No plot)

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

%% fcn_INTERNAL_column
function values = fcn_INTERNAL_column(values, Nrows)
% A scalar becomes a column of Nrows; a vector becomes a column
values = double(values(:));
if isscalar(values)
    values = repmat(values, Nrows, 1);
elseif length(values)~=Nrows
    error('A light column must be a scalar or have one value per time step (%d)', Nrows);
end
end % Ends fcn_INTERNAL_column

%% fcn_INTERNAL_pick
function values = fcn_INTERNAL_pick(optionValue, motion, fieldName, Nrows)
% The option if given, else the motion's field, else zeros
if ~isempty(optionValue)
    values = optionValue(:);
elseif isfield(motion, fieldName) && ~isempty(motion.(fieldName))
    values = motion.(fieldName)(:);
else
    values = zeros(Nrows,1);
end
end % Ends fcn_INTERNAL_pick
