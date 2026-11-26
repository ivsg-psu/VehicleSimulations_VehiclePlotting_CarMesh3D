function [cameraPosition, cameraTarget] = fcn_CarMesh3D_updateCamera(cameraSettings, vehiclePose, options)
% fcn_CarMesh3D_updateCamera
% Points the camera of an axes for one animation frame, from camera
% settings (fcn_CarMesh3D_fillCameraSettings) and the vehicle's pose.
% Call it once per frame, after moving the vehicle:
%
%       cameraSettings = fcn_CarMesh3D_fillCameraSettings(Mode='chase');
%       for k = 1:N
%           fcn_CarMesh3D_plotVehicle(mesh, Pose=pose(k,:), PlotHandles=h, FigNum=-1);
%           fcn_CarMesh3D_updateCamera(cameraSettings, pose(k,:), Time=t(k), ...
%               AxesHandle=h.Axes, FigNum=-1);
%           drawnow;
%       end
%
% Vehicle-frame points are turned into world points with the pose:
%       worldPoint = [x y z] + R(yaw) * vehiclePoint
% (z from a six-value pose, so the camera rides with the vehicle on a
% hilly road; FlagFollowHeight=false keeps z = 0), or, with FollowPitch, also
% tilted with the vehicle's pitch: [x y z] + R(yaw) * R(pitch) * vehiclePoint
% and for an orbit, the camera position is first turned about the
% vehicle's vertical axis by OrbitRate * Time.
%
% The camera uses perspective projection, and the axes limits are left
% fixed (set them once to cover the whole scene) so the camera can move
% freely without the axes rescaling.
%
% FORMAT:
%
%       [cameraPosition, cameraTarget] = fcn_CarMesh3D_updateCamera(...
%           cameraSettings, vehiclePose,...
%           (Time=t), (AxesHandle=axesHandle),...
%           (FlagFollowHeight=flag), (FlagFollowPitch=flag),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      cameraSettings: from fcn_CarMesh3D_fillCameraSettings.
%
%      vehiclePose: [x y yaw] or [x y z roll pitch yaw] of the vehicle
%      (the same pose given to fcn_CarMesh3D_plotVehicle). x, y, yaw,
%      and (from a six-value pose) z place the camera; pitch tilts it
%      with FollowPitch.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Time: the animation time, in seconds, for orbiting cameras.
%      Default is 0.
%
%      AxesHandle: the axes to point. Default is the current axes.
%
%      FlagFollowHeight: true (default) to raise the camera with the pose's z
%      (a six-value pose), so it stays above the vehicle on hills; false
%      for the old behavior (z = 0).
%
%      FlagFollowPitch: true to tilt the camera with the pose's pitch (a
%      six-value pose; positive pitch is nose down), so the road ahead
%      stays level in the picture on a grade. Default false (the camera
%      stays level).
%
%      FigNum: if set to -1, input checking is skipped (fast mode, for
%      animation loops). Otherwise not used; the camera is always set.
%
% OUTPUTS:
%
%      cameraPosition, cameraTarget: the world coordinates used.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_test_fcn_CarMesh3D_updateCamera.m for a full test
%       suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_updateCamera
%   % * Wrote the code originally (drafted with Claude)
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_updateCamera
%   % * Follows the vehicle's height (FollowHeight, default true) and,
%   %   % optionally, its pitch (FollowPitch), for hilly roads (asked for
%   %   % by AnimateCar3D)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_updateCamera
%   % * Add a smoothing option (camera lags behind the vehicle)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    cameraSettings
    vehiclePose
    options.Time = 0          % seconds, for orbiting cameras
    options.AxesHandle = []   % axes to point; [] for the current axes
    options.FlagFollowHeight = true % raise the camera with the pose's z
    options.FlagFollowPitch = false % tilt the camera with the pose's pitch
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

        % Check the cameraSettings input
        requiredFields = {'Position','PositionFrame','Target','TargetFrame','FieldOfView','OrbitRate','UpVector'};
        if ~isstruct(cameraSettings) || ~all(isfield(cameraSettings, requiredFields))
            error('cameraSettings must come from fcn_CarMesh3D_fillCameraSettings');
        end

        % Check the vehiclePose input
        if ~isnumeric(vehiclePose) || ~any(numel(vehiclePose)==[3 6]) || any(~isfinite(vehiclePose))
            error('vehiclePose must be [x y yaw] or [x y z roll pitch yaw]');
        end

        % Check the Time input
        if ~isnumeric(options.Time) || ~isscalar(options.Time) || ~isfinite(options.Time)
            error('Time must be a finite number of seconds');
        end

        % Check the AxesHandle input
        if ~isempty(options.AxesHandle) && ~isgraphics(options.AxesHandle,'axes')
            error('AxesHandle must be a valid axes');
        end
    end
end

% (This function changes a camera; it makes no plot of its own)

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

% Vehicle position, height, heading, and pitch
vehiclePose = vehiclePose(:)';
vehicleZ = 0;
vehiclePitch = 0;
if numel(vehiclePose)==6
    if options.FlagFollowHeight
        vehicleZ = vehiclePose(3);
    end
    if options.FlagFollowPitch
        vehiclePitch = vehiclePose(5);
    end
    vehiclePose = vehiclePose([1 2 6]);
end
yaw = vehiclePose(3);
rotationYaw = [cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1];
% (pitch: about the vehicle's Y axis, positive nose down)
rotationPitch = [cos(vehiclePitch) 0 sin(vehiclePitch); 0 1 0; -sin(vehiclePitch) 0 cos(vehiclePitch)];
rotationYaw = rotationYaw*rotationPitch;
origin = [vehiclePose(1:2) vehicleZ];

% Camera position, in world coordinates
cameraPosition = cameraSettings.Position(:);
if strcmp(cameraSettings.PositionFrame,'vehicle')
    orbitAngle = cameraSettings.OrbitRate*options.Time;
    if orbitAngle~=0
        % Orbit around the vehicle's vertical axis through the target
        pivot = cameraSettings.Target(:);
        rotationOrbit = [cos(orbitAngle) -sin(orbitAngle) 0; sin(orbitAngle) cos(orbitAngle) 0; 0 0 1];
        cameraPosition = pivot + rotationOrbit*(cameraPosition - pivot);
    end
    cameraPosition = (rotationYaw*cameraPosition)' + origin;
else
    cameraPosition = cameraPosition';
end

% Camera target, in world coordinates
cameraTarget = cameraSettings.Target(:);
if strcmp(cameraSettings.TargetFrame,'vehicle')
    cameraTarget = (rotationYaw*cameraTarget)' + origin;
else
    cameraTarget = cameraTarget';
end

% The up direction: tilted with the vehicle's pitch, if following it
cameraUpVector = cameraSettings.UpVector;
if vehiclePitch~=0
    cameraUpVector = (rotationYaw*cameraUpVector(:))';
end

% Point the axes camera
axesHandle = options.AxesHandle;
if isempty(axesHandle)
    axesHandle = gca;
end
set(axesHandle, ...
    'Projection','perspective', ...
    'CameraPosition',cameraPosition, ...
    'CameraTarget',cameraTarget, ...
    'CameraUpVector',cameraUpVector, ...
    'CameraViewAngle',cameraSettings.FieldOfView);

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
% (No plot: the camera of the axes was changed above)

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


