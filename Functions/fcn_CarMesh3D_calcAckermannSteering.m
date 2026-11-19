function [steerAngles, insideOutsideAngles, turnRadius] = fcn_CarMesh3D_calcAckermannSteering(bicycleSteerAngle, wheelbase, track, options)
% fcn_CarMesh3D_calcAckermannSteering
% Calculates the steer angle of each front tire, left and right, so that
% the two front tires turn about the same point as the rest of the
% vehicle (Ackermann steering).
%
% WHY: In a turn, every wheel rolls on a circle around one shared turn
% center, which lies on the line through the rear axle. The inside front
% tire is closer to that center, so it rolls on a smaller circle and must
% steer MORE than the outside tire. If both front tires steered the same
% amount (parallel steering), one of them would have to slide sideways.
%
% THE GEOMETRY (top view, front of the vehicle at the top, turning left
% about the turn center C, which lies on the line of the rear axle):
%
%                  left            right
%                   o--------------o     front axle (x = wheelbase)
%                   |              |
%                   |              |
%     C . . . . . . o------o-------o     rear axle (x = 0)
%     |<- R - T/2 ->|      |
%     |<-------- R ------->|  R = turn radius of the rear axle center
%                             T = front track (spacing of the front tires)
%
% Each front tire must point at right angles to the line from C to that
% tire, which gives:
%
%       turn radius     R            = wheelbase / tan(delta)
%       inside tire     deltaInside  = atan( wheelbase / (R - T/2) )
%       outside tire    deltaOutside = atan( wheelbase / (R + T/2) )
%
% where delta is the "bicycle" steer angle: the angle of a single
% imaginary front tire on the vehicle's centerline (as in the kinematic
% bicycle model, where delta = atan(wheelbase * pathCurvature)). The
% bicycle angle always lies between the inside and outside angles. The
% code uses an equivalent atan2 form of these formulas, which also works
% when driving straight (R is infinite) and in very tight turns, where
% the inside tire steers past 90 degrees.
%
% Real vehicles often use only part of the full Ackermann difference. The
% AckermannFraction option blends between parallel steering (0) and full
% Ackermann steering (1, the default).
%
% FORMAT:
%
%       [steerAngles, insideOutsideAngles, turnRadius] = ...
%           fcn_CarMesh3D_calcAckermannSteering(bicycleSteerAngle,...
%           wheelbase, track, (AckermannFraction=fraction),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      bicycleSteerAngle: the steer angle of an imaginary single front
%      tire on the centerline, in radians, as a scalar or a K x 1 vector
%      (one per time step). Positive steers left (ISO 8855). From a path
%      curvature, use bicycleSteerAngle = atan(wheelbase * curvature).
%
%      wheelbase: the distance from the rear axle to the front axle, in
%      meters (vehicleSpec.Wheelbase).
%
%      track: the distance between the centers of the two front tires, in
%      meters (vehicleSpec.TrackFront).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      AckermannFraction: how much of the Ackermann difference to use:
%           1    full Ackermann (default): no tire slides sideways
%           0    parallel steering: both tires steer the bicycle angle
%           0.5  half way between
%      Values below 0 give "anti-Ackermann" steering (the outside tire
%      steers more), which some race cars use.
%
%      FigNum: a figure number to draw a top view of the steering
%      geometry (for the sample with the largest steer angle) and, for a
%      vector input, a plot of the tire angles against the bicycle angle.
%      If empty or omitted, no plot is made. If set to -1, input checking
%      is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      steerAngles: K x 2 steer angles [left right] of the front tires,
%      in radians. This is the [FL FR] order used by the SteerAngle
%      option of fcn_CarMesh3D_plotVehicle, so row k can be passed
%      directly: SteerAngle=steerAngles(k,:).
%
%      insideOutsideAngles: K x 2 steer angles [inside outside], in
%      radians. In a left turn the inside tire is the left one; in a
%      right turn it is the right one. When driving straight, both are 0.
%
%      turnRadius: K x 1 signed turn radius of the rear axle center, in
%      meters. Positive for left turns, negative for right turns, Inf
%      when driving straight.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       % A 2013 Prius steering for a 20 degree bicycle angle
%       vehicleSpec = fcn_CarMesh3D_loadVehicleSpec('Data/2013_Toyota_Prius_Four/vehicleParameters_2013_Toyota_Prius_Four.mat');
%       steerAngles = fcn_CarMesh3D_calcAckermannSteering(deg2rad(20),...
%           vehicleSpec.Wheelbase, vehicleSpec.TrackFront, FigNum=1);
%       rad2deg(steerAngles)   % [left right], left (inside) is larger
%
%       See the script: script_CarMesh3D_calcAckermannSteering.m for a
%       full test suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_calcAckermannSteering
%   % * Wrote the code originally (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_calcAckermannSteering
%   % * Consider rear-wheel and four-wheel steering



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    bicycleSteerAngle
    wheelbase
    track
    options.AckermannFraction = 1   % 1 full Ackermann, 0 parallel steering
    options.FigNum = []             % Figure to plot into; [] for no plot, -1 for fast mode
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

        % Check the bicycleSteerAngle input
        if ~isnumeric(bicycleSteerAngle) || ~isvector(bicycleSteerAngle) || any(~isfinite(bicycleSteerAngle))
            error('bicycleSteerAngle must be a finite scalar or vector of angles, in radians');
        end
        if any(abs(bicycleSteerAngle) >= pi/2)
            error('bicycleSteerAngle must be between -pi/2 and pi/2 radians (-90 to 90 degrees)');
        end

        % Check the wheelbase and track inputs
        if ~isnumeric(wheelbase) || ~isscalar(wheelbase) || ~(wheelbase>0)
            error('wheelbase must be a positive number of meters');
        end
        if ~isnumeric(track) || ~isscalar(track) || ~(track>0)
            error('track must be a positive number of meters');
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

% Work with a column of bicycle steer angles
delta = bicycleSteerAngle(:);
halfTrack = track/2;

%%%%
% Full Ackermann angles. Each front tire points at right angles to the
% line from the turn center to that tire. Written with atan2 (multiplying
% the top and bottom of wheelbase/(R -/+ T/2) by sin(delta)) so that it
% works for every angle, including straight driving (delta = 0).
%       left tire  (y = +T/2):  atan( wheelbase / (R - T/2) )
%       right tire (y = -T/2):  atan( wheelbase / (R + T/2) )
% with R = wheelbase/tan(delta).
fullLeft  = atan2(wheelbase*sin(delta), wheelbase*cos(delta) - halfTrack*sin(delta));
fullRight = atan2(wheelbase*sin(delta), wheelbase*cos(delta) + halfTrack*sin(delta));

%%%%
% Blend with parallel steering (both tires at the bicycle angle)
fraction = options.AckermannFraction;
steerLeft  = delta + fraction*(fullLeft  - delta);
steerRight = delta + fraction*(fullRight - delta);
steerAngles = [steerLeft steerRight];

%%%%
% Inside and outside tires: in a left turn (delta > 0) the left tire is
% inside; in a right turn the right tire is inside.
flagLeftTurn = delta >= 0;
insideOutsideAngles = zeros(length(delta),2);
insideOutsideAngles(flagLeftTurn,:)  = [steerLeft(flagLeftTurn)  steerRight(flagLeftTurn)];
insideOutsideAngles(~flagLeftTurn,:) = [steerRight(~flagLeftTurn) steerLeft(~flagLeftTurn)];

%%%%
% Turn radius of the rear axle center (Inf when driving straight)
turnRadius = wheelbase./tan(delta);
turnRadius(delta==0) = Inf;

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
    flagVector = length(delta) > 1;
    if flagVector
        tiledlayout(1,2);
        nexttile;
    end

    % Top view of the geometry, for the largest steer angle (a left turn
    % if left and right turns are equally large)
    showIndex = find(abs(delta)==max(abs(delta)) & delta>=0, 1);
    if isempty(showIndex)
        [~, showIndex] = max(abs(delta));
    end
    fcn_INTERNAL_drawGeometry(delta(showIndex), steerAngles(showIndex,:), turnRadius(showIndex), wheelbase, track, fraction);

    if flagVector
        % The tire angles against the bicycle angle
        nexttile;
        [sortedDelta, sortOrder] = sort(delta);
        plot(rad2deg(sortedDelta), rad2deg(steerAngles(sortOrder,1)), 'b-', 'LineWidth', 1.5, 'DisplayName','left tire');
        hold on;
        plot(rad2deg(sortedDelta), rad2deg(steerAngles(sortOrder,2)), 'r-', 'LineWidth', 1.5, 'DisplayName','right tire');
        plot(rad2deg(sortedDelta), rad2deg(sortedDelta), 'k--', 'DisplayName','bicycle angle (parallel steering)');
        grid on; axis equal;
        xlabel('Bicycle steer angle [deg]');
        ylabel('Tire steer angle [deg]');
        legend('Location','northwest');
        title('Left and right tire angles');
    end
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

%% fcn_INTERNAL_drawGeometry
function fcn_INTERNAL_drawGeometry(delta, steerPair, turnRadius, wheelbase, track, fraction)
% Draws the vehicle from above: axles, tires (as thick lines along their
% rolling direction), the turn center, and the lines from the turn
% center to each tire. With full Ackermann steering, each front tire is
% at right angles to its line.
halfTrack = track/2;
tireLength = 0.25*wheelbase;
hold on;

% Axles and the centerline
plot([0 0], [-halfTrack halfTrack], 'k-', 'LineWidth', 2);
plot([wheelbase wheelbase], [-halfTrack halfTrack], 'k-', 'LineWidth', 2);
plot([0 wheelbase], [0 0], 'k:', 'LineWidth', 1);

% Tires: [x y steer]
tires = [wheelbase  halfTrack steerPair(1);
         wheelbase -halfTrack steerPair(2);
         0          halfTrack 0;
         0         -halfTrack 0];
tireColors = [0 0 1; 1 0 0; 0.3 0.3 0.3; 0.3 0.3 0.3];
for ith_tire = 1:4
    direction = 0.5*tireLength*[cos(tires(ith_tire,3)) sin(tires(ith_tire,3))];
    plot(tires(ith_tire,1) + [-1 1]*direction(1), tires(ith_tire,2) + [-1 1]*direction(2), ...
        '-', 'Color', tireColors(ith_tire,:), 'LineWidth', 6);
end

% The bicycle (centerline) front tire
direction = 0.5*tireLength*[cos(delta) sin(delta)];
plot(wheelbase + [-1 1]*direction(1), [-1 1]*direction(2), '-', 'Color', [0.6 0.6 0.6], 'LineWidth', 3);

% Turn center and lines to each tire (only if it fits on the plot)
plotLimit = 3*wheelbase;
if isfinite(turnRadius) && abs(turnRadius) < plotLimit
    plot(0, turnRadius, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 7);
    text(0, turnRadius, '  turn center', 'VerticalAlignment', 'bottom');
    for ith_tire = 1:4
        plot([0 tires(ith_tire,1)], [turnRadius tires(ith_tire,2)], 'k--', 'LineWidth', 0.75);
    end
    plot([0 wheelbase], [turnRadius 0], '--', 'Color', [0.6 0.6 0.6], 'LineWidth', 0.75);
    yRange = sort([turnRadius 0]) + [-1.5 1.5]*halfTrack;
else
    yRange = [-1 1]*max(1.5*track, 0.6*wheelbase);
end

% Angle labels
text(wheelbase + 0.6*tireLength, halfTrack, sprintf('left %.1f%s', rad2deg(steerPair(1)), char(176)), 'Color', [0 0 1]);
text(wheelbase + 0.6*tireLength, -halfTrack, sprintf('right %.1f%s', rad2deg(steerPair(2)), char(176)), 'Color', [1 0 0]);

axis equal; grid on;
xlim([-0.6*tireLength - 0.2*wheelbase, wheelbase + 2.2*tireLength + 0.3*wheelbase]);
ylim(yRange);
xlabel('X (forward) [m]'); ylabel('Y (left) [m]');
title(sprintf('Bicycle angle %.1f%s, Ackermann fraction %.2g', rad2deg(delta), char(176), fraction));
end % Ends fcn_INTERNAL_drawGeometry
