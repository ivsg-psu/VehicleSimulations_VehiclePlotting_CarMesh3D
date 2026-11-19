function trajectory = fcn_CarMesh3D_fillTrajectory(options)
% fcn_CarMesh3D_fillTrajectory
% Makes a vehicle motion for animation: where the vehicle is (pose),
% how far each wheel has rolled (wheel spin), and how far the front wheels
% are steered, at every time step. The vehicle follows a path at a given
% speed. The pose is the position of the REAR AXLE center and the heading
% (yaw), which is the frame used by fcn_CarMesh3D_fitMeshToSpec, so the
% steering angle follows exactly from the path's curvature with the
% kinematic bicycle model:
%
%       bicycleSteerAngle = atan(wheelbase * curvature)
%
% The left and right front tires then steer by different amounts
% (Ackermann steering: the inside tire steers more), calculated by
% fcn_CarMesh3D_calcAckermannSteering.
%
% Wheel spin is the distance traveled divided by the tire radius, times
% (1 + slip). Slip makes wheels lock up or spin faster than the ground:
%       WheelSlip =  0   rolling (no slip, the default)
%       WheelSlip = -1   locked (the wheel does not turn, it skids)
%       WheelSlip =  2   peeling out (the wheel turns 3 times too fast)
% Slip can be different for each wheel and can change over time.
%
% FORMAT:
%
%       trajectory = fcn_CarMesh3D_fillTrajectory(...
%           (Path=pathName), (Waypoints=xy),...
%           (Speed=speed), (Duration=seconds), (SampleTime=dt),...
%           (Radius=R), (LaneOffset=offset), (StartPose=[x y yaw]),...
%           (VehicleSpec=vehicleSpec), (WheelSlip=slip),...
%           (AckermannFraction=fraction), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Path: the shape of the path, starting at the origin heading along
%      +X (then moved to StartPose):
%           'straight'    a straight line (default)
%           'circle'      a counterclockwise circle of radius Radius
%           'figureEight' a figure eight, Radius wide on each loop
%           'laneChange'  straight, with a smooth sideways step of
%                         LaneOffset (positive = to the left)
%           'waypoints'   straight lines through the points in Waypoints
%
%      Waypoints: an N x 2 list of [x y] points, for Path='waypoints'.
%
%      Speed: the speed along the path, in m/s. A scalar (constant
%      speed), a vector with one value per time step, or a function of
%      time, such as @(t) min(2*t, 10) for accelerating from rest.
%      Negative speed drives backward along the path. Default is 10.
%
%      Duration: the length of the motion, in seconds. Default is 10.
%
%      SampleTime: the time step, in seconds. Default is 1/20 (20 frames
%      per second).
%
%      Radius: the radius for 'circle', and the loop size for
%      'figureEight', in meters. Default is 15.
%
%      LaneOffset: the sideways step for 'laneChange', in meters. Default
%      is 3.5 (one lane, to the left).
%
%      StartPose: [x y yaw] where the path starts (yaw in radians).
%      Default is [0 0 0].
%
%      VehicleSpec: a spec from fcn_CarMesh3D_fillVehicleSpec or
%      fcn_CarMesh3D_loadVehicleSpec, for the wheelbase and tire
%      diameter, and the front track (for Ackermann steering). Default is
%      the 'genericSedan' preset.
%
%      WheelSlip: slip for each wheel, as a scalar (all wheels), a 1 x 4
%      vector [FL FR RL RR], or a K x 4 matrix (one row per time step).
%      Default is 0.
%
%      AckermannFraction: how much Ackermann steering to use, passed to
%      fcn_CarMesh3D_calcAckermannSteering: 1 for full Ackermann (the
%      default), 0 for parallel steering (both tires at the bicycle
%      angle).
%
%      FigNum: a figure number to plot the path, speed, steering, and
%      wheel spin. If empty or omitted, no plot is made. If set to -1,
%      input checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      trajectory: a structure with one row per time step:
%           Time (K x 1), Pose (K x 3: [x y yaw] of the rear axle),
%           Speed (K x 1), Distance (K x 1, along the path),
%           Curvature (K x 1, 1/m),
%           SteerAngle (K x 2, rad, [FL FR], with Ackermann steering),
%           BicycleSteerAngle (K x 1, rad, one centerline tire),
%           WheelSpin (K x 4, rad, [FL FR RL RR]), WheelSlip (K x 4)
%      Use row k with fcn_CarMesh3D_plotVehicle:
%           Pose=trajectory.Pose(k,:), WheelSpin=trajectory.WheelSpin(k,:),
%           SteerAngle=trajectory.SteerAngle(k,:)
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_fillVehicleSpec (only for the default spec)
%      fcn_CarMesh3D_calcAckermannSteering
%
% EXAMPLES:
%
%       See the script: script_CarMesh3D_fillTrajectory.m for a full test
%       suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillTrajectory
%   % * Wrote the code originally (drafted with Claude)
%   % * Added Ackermann steering: SteerAngle is now K x 2 [FL FR], from
%   %   fcn_CarMesh3D_calcAckermannSteering. The single centerline angle
%   %   is kept as BicycleSteerAngle. Added AckermannFraction option.

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillTrajectory
%   % * (Body roll and pitch come from other repos; pass them to
%   %   fcn_CarMesh3D_plotVehicle as BodyRoll, BodyPitch, BodyHeave)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.Path = 'straight'      % 'straight','circle','figureEight','laneChange','waypoints'
    options.Waypoints = []         % N x 2 [x y] points for Path='waypoints'
    options.Speed = 10             % m/s: scalar, K x 1 vector, or function of time
    options.Duration = 10          % seconds
    options.SampleTime = 1/20      % seconds
    options.Radius = 15            % meters (circle, figure eight)
    options.LaneOffset = 3.5       % meters (lane change), positive to the left
    options.StartPose = [0 0 0]    % [x y yaw] of the path start
    options.VehicleSpec = []       % For wheelbase and tire diameter
    options.WheelSlip = 0          % Scalar, 1 x 4, or K x 4
    options.AckermannFraction = 1  % 1 full Ackermann, 0 parallel steering
    options.FigNum = []            % Figure to plot into; [] for no plot, -1 for fast mode
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

        % Check the Path input
        pathNames = {'straight','circle','figureEight','laneChange','waypoints'};
        if ~any(strcmpi(char(options.Path), pathNames))
            error('Path must be one of: %s', strjoin(pathNames,', '));
        end
        if strcmpi(char(options.Path),'waypoints')
            if ~isnumeric(options.Waypoints) || size(options.Waypoints,2)~=2 || size(options.Waypoints,1)<2
                error('Path ''waypoints'' needs Waypoints, an N x 2 list of at least 2 [x y] points');
            end
        end

        % Check the timing inputs
        if ~isnumeric(options.Duration) || ~isscalar(options.Duration) || options.Duration<=0
            error('Duration must be a positive number of seconds');
        end
        if ~isnumeric(options.SampleTime) || ~isscalar(options.SampleTime) || options.SampleTime<=0
            error('SampleTime must be a positive number of seconds');
        end

        % Check the Speed input
        if ~(isnumeric(options.Speed) || isa(options.Speed,'function_handle'))
            error('Speed must be a number, a vector (one value per time step), or a function of time');
        end

        % Check the size inputs
        if ~isnumeric(options.Radius) || ~isscalar(options.Radius) || options.Radius<=0
            error('Radius must be a positive number of meters');
        end
        if ~isnumeric(options.StartPose) || numel(options.StartPose)~=3
            error('StartPose must be [x y yaw]');
        end

        % Check the WheelSlip input
        if ~isnumeric(options.WheelSlip) || ~(isscalar(options.WheelSlip) || isequal(size(options.WheelSlip),[1 4]) || size(options.WheelSlip,2)==4)
            error('WheelSlip must be a scalar, a 1 x 4 vector, or a K x 4 matrix');
        end

        % Check the AckermannFraction input
        if ~isnumeric(options.AckermannFraction) || ~isscalar(options.AckermannFraction) || ~isfinite(options.AckermannFraction)
            error('AckermannFraction must be a finite number (1 full Ackermann, 0 parallel steering)');
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
% Vehicle dimensions
vehicleSpec = options.VehicleSpec;
if isempty(vehicleSpec)
    vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
end
wheelbase = vehicleSpec.Wheelbase;
tireRadius = vehicleSpec.TireDiameter/2;
frontTrack = vehicleSpec.TrackFront;
if isempty(frontTrack)
    % No track given: estimate it from the overall width
    frontTrack = 0.85*vehicleSpec.OverallWidth;
end

%%%%
% Time and speed
timeValues = (0:options.SampleTime:options.Duration)';
Ntimes = length(timeValues);
if isa(options.Speed,'function_handle')
    speedValues = arrayfun(options.Speed, timeValues);
elseif isscalar(options.Speed)
    speedValues = options.Speed*ones(Ntimes,1);
else
    if numel(options.Speed)~=Ntimes
        error('A Speed vector must have one value per time step (%d values)', Ntimes);
    end
    speedValues = options.Speed(:);
end
distanceValues = cumtrapz(timeValues, speedValues); % Signed distance along the path

%%%%
% A dense polyline of the path, long enough for the distance traveled
pathLengthNeeded = max(abs(distanceValues)) + 1;
pathXY = fcn_INTERNAL_pathPolyline(char(options.Path), pathLengthNeeded, options);

% Arc length along the polyline; repeat closed paths (circle, figure
% eight) so the vehicle can go around more than once
segmentLengths = vecnorm(diff(pathXY),2,2);
keep = [true; segmentLengths>1e-9];
pathXY = pathXY(keep,:);
arcLength = [0; cumsum(vecnorm(diff(pathXY),2,2))];
flagClosed = any(strcmpi(char(options.Path),{'circle','figureEight'}));

if flagClosed
    loopLength = arcLength(end);
    sampleDistance = mod(distanceValues, loopLength);
else
    sampleDistance = distanceValues;
end

% Positions, by linear interpolation (extrapolate past the ends)
positionX = interp1(arcLength, pathXY(:,1), sampleDistance, 'linear', 'extrap');
positionY = interp1(arcLength, pathXY(:,2), sampleDistance, 'linear', 'extrap');

% Heading and curvature from a finely sampled copy of the path
headingAtArc = unwrap(atan2(gradient(pathXY(:,2)), gradient(pathXY(:,1))));
curvatureAtArc = gradient(headingAtArc)./max(gradient(arcLength), eps);
curvatureAtArc = movmean(curvatureAtArc, 5);
headingValues = interp1(arcLength, headingAtArc, sampleDistance, 'linear', 'extrap');
curvatureValues = interp1(arcLength, curvatureAtArc, sampleDistance, 'linear', 'extrap');

% Make the heading continuous over repeated loops
headingValues = unwrap(headingValues);

%%%%
% Move to the start pose
startPose = options.StartPose(:)';
rotation = [cos(startPose(3)) -sin(startPose(3)); sin(startPose(3)) cos(startPose(3))];
movedXY = [positionX positionY]*rotation' + startPose(1:2);
poseValues = [movedXY, headingValues + startPose(3)];

%%%%
% Steering (kinematic bicycle model, rear axle on the path), then the
% left and right tire angles (Ackermann steering)
bicycleSteerValues = atan(wheelbase*curvatureValues);
steerValues = fcn_CarMesh3D_calcAckermannSteering(bicycleSteerValues, wheelbase, frontTrack, ...
    AckermannFraction=options.AckermannFraction, FigNum=-1);

%%%%
% Wheel spin: integrate (1 + slip) * speed / radius
slipValues = options.WheelSlip;
if isscalar(slipValues)
    slipValues = repmat(slipValues, Ntimes, 4);
elseif size(slipValues,1)==1
    slipValues = repmat(slipValues, Ntimes, 1);
elseif size(slipValues,1)~=Ntimes
    error('A K x 4 WheelSlip must have one row per time step (%d rows)', Ntimes);
end
spinRates = (1 + slipValues).*speedValues/tireRadius;
wheelSpinValues = cumtrapz(timeValues, spinRates);

trajectory = struct;
trajectory.Time = timeValues;
trajectory.Pose = poseValues;
trajectory.Speed = speedValues;
trajectory.Distance = distanceValues;
trajectory.Curvature = curvatureValues;
trajectory.SteerAngle = steerValues;
trajectory.BicycleSteerAngle = bicycleSteerValues;
trajectory.WheelSpin = wheelSpinValues;
trajectory.WheelSlip = slipValues;
trajectory.Path = char(options.Path);

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
    plot(trajectory.Pose(:,1), trajectory.Pose(:,2), 'b-', 'LineWidth', 1.5);
    hold on;
    plot(trajectory.Pose(1,1), trajectory.Pose(1,2), 'go', 'MarkerFaceColor','g', 'DisplayName','start');
    axis equal; grid on;
    xlabel('X [m]'); ylabel('Y [m]');
    title(sprintf('Path: %s', trajectory.Path));

    nexttile;
    plot(trajectory.Time, trajectory.Speed, 'LineWidth', 1.5);
    grid on; xlabel('Time [s]'); ylabel('Speed [m/s]'); title('Speed');

    nexttile;
    plot(trajectory.Time, rad2deg(trajectory.SteerAngle(:,1)), 'b-', 'LineWidth', 1.5);
    hold on;
    plot(trajectory.Time, rad2deg(trajectory.SteerAngle(:,2)), 'r-', 'LineWidth', 1.5);
    plot(trajectory.Time, rad2deg(trajectory.BicycleSteerAngle), 'k--', 'LineWidth', 1);
    grid on; xlabel('Time [s]'); ylabel('Steer angle [deg]');
    legend({'left (FL)','right (FR)','bicycle'},'Location','best');
    title('Front wheel steer angles');

    nexttile;
    plot(trajectory.Time, trajectory.WheelSpin/(2*pi), 'LineWidth', 1.5);
    grid on; xlabel('Time [s]'); ylabel('Wheel turns');
    legend({'FL','FR','RL','RR'},'Location','northwest');
    title('Wheel rotation');
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

%% fcn_INTERNAL_pathPolyline
function pathXY = fcn_INTERNAL_pathPolyline(pathName, lengthNeeded, options)
% A dense [x y] polyline of the path, starting at the origin heading +X
pointSpacing = 0.05; % meters
switch lower(pathName)
    case 'straight'
        s = (0:pointSpacing:max(lengthNeeded,1))';
        pathXY = [s, zeros(size(s))];
    case 'circle'
        R = options.Radius;
        theta = linspace(0, 2*pi, max(200, ceil(2*pi*R/pointSpacing)))';
        pathXY = [R*sin(theta), R*(1 - cos(theta))];
    case 'figureeight'
        % Two loops: left loop first, then right loop
        R = options.Radius;
        theta = linspace(0, 2*pi, max(400, ceil(4*pi*R/pointSpacing)))';
        pathXY = [2*R*sin(theta), R*sin(2*theta)];
        % Rotate so the start heads along +X
        startHeading = atan2(pathXY(2,2)-pathXY(1,2), pathXY(2,1)-pathXY(1,1));
        rotation = [cos(-startHeading) -sin(-startHeading); sin(-startHeading) cos(-startHeading)];
        pathXY = pathXY*rotation';
    case 'lanechange'
        % Straight, then a smooth (cosine) step over 30 m, then straight
        s = (0:pointSpacing:max(lengthNeeded,60))';
        stepStart = 15;
        stepLength = 30;
        fraction = min(max((s - stepStart)/stepLength, 0), 1);
        pathXY = [s, options.LaneOffset*(1 - cos(pi*fraction))/2];
    otherwise % 'waypoints'
        waypoints = options.Waypoints;
        segmentLengths = vecnorm(diff(waypoints),2,2);
        arc = [0; cumsum(segmentLengths)];
        s = (0:pointSpacing:arc(end))';
        % Waypoints are used where they are (StartPose then moves them)
        pathXY = [interp1(arc, waypoints(:,1), s), interp1(arc, waypoints(:,2), s)];
end
end % Ends fcn_INTERNAL_pathPolyline
