function cameraSettings = fcn_CarMesh3D_fillCameraSettings(options)
% fcn_CarMesh3D_fillCameraSettings
% Makes the settings for a camera that frames a vehicle. Every camera,
% however different it looks, is described by the same four things:
%
%   1. WHERE THE CAMERA SITS (Position), measured either in the world
%      (PositionFrame='world', it stays put) or in the vehicle's own
%      frame (PositionFrame='vehicle': X forward, Y left, Z up, origin
%      on the ground below the rear axle, so it rides along).
%   2. WHAT IT LOOKS AT (Target), also in 'world' or 'vehicle' frame.
%   3. HOW WIDE IT SEES (FieldOfView, in degrees). Small = zoomed in.
%   4. OPTIONALLY, AN ORBIT: OrbitRate (radians per second) turns a
%      vehicle-frame Position around the vehicle's vertical axis.
%
% The named modes below are just presets of those four things. Start
% from the mode closest to what you want, and change any setting:
%
%   Mode         Position (frame)            Target (frame)          FOV
%   'wideFixed'  [-35 -45 30]   (world)      [0 0 0]       (world)   35
%   'roadside'   [0 -8 1.5]     (world)      [1.35 0 0.7]  (vehicle) 40
%   'overhead'   [0 0 60]       (world)      [0 0 0]       (world)   40
%   'chase'      [-7 0 2.5]     (vehicle)    [4 0 1]       (vehicle) 50
%   'driver'     [1.5 0.37 1.15] (vehicle)   [20 0.37 0.9] (vehicle) 70
%   'roof'       [0.6 0 1.9]    (vehicle)    [12 0 0.4]    (vehicle) 65
%   'side'       [1.35 -7 1.2]  (vehicle)    [1.35 0 0.7]  (vehicle) 40
%   'kite'       [-14 0 10]     (vehicle)    [6 0 0]       (vehicle) 45
%   'orbit'      [-9 0 4]       (vehicle)    [1.35 0 0.7]  (vehicle) 45
%                (with OrbitRate 0.4 rad/s)
%
% A world-frame camera stays in one place (it can still turn to follow
% a vehicle-frame target, like a person at the roadside). A vehicle-frame
% camera moves with the vehicle, like a camera bolted to it or flown
% behind it. Vehicle-frame numbers assume a car about 4.5 m long; scale
% them for other vehicles.
%
% Use the settings each frame with fcn_CarMesh3D_updateCamera.
%
% FORMAT:
%
%       cameraSettings = fcn_CarMesh3D_fillCameraSettings(...
%           (Mode=modeName),...
%           (Position=[x y z]), (PositionFrame=frameName),...
%           (Target=[x y z]), (TargetFrame=frameName),...
%           (FieldOfView=degrees), (OrbitRate=radPerSec),...
%           (UpVector=[x y z]),...
%           (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Mode: one of the preset names above. Default is 'chase'.
%
%      Position, PositionFrame, Target, TargetFrame, FieldOfView,
%      OrbitRate: override the preset values (see above). Frames are
%      'world' or 'vehicle'.
%
%      UpVector: which way is "up" in the picture, in world coordinates.
%      Default is [0 0 1]. For a camera looking straight down (overhead),
%      [0 1 0] puts world +Y at the top of the picture.
%
%      FigNum: a figure number to draw a picture of the camera setup
%      (the camera, its target, and a car outline, seen from above and
%      from the side). If empty or omitted, no plot is made. If set to -1,
%      input checking is skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      cameraSettings: a structure with fields Mode, Position,
%      PositionFrame, Target, TargetFrame, FieldOfView, OrbitRate,
%      UpVector.
%
% DEPENDENCIES:
%
%      (none)
%
% EXAMPLES:
%
%       See the script: script_CarMesh3D_fillCameraSettings.m for a full test
%       suite.
%
% This function was written on 2026_11_19 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillCameraSettings
%   % * Wrote the code originally (drafted with Claude)

% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillCameraSettings
%   % * Driver camera moved forward (x 1.25 to 1.5 m), closer to the
%   %   windshield, so the dashboard and roof fill less of the view

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_fillCameraSettings
%   % * Add smoothing (lag) for chase cameras on twisty paths
%   % * Scale vehicle-frame presets by vehicle length



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.Mode = 'chase'        % Preset name (see help)
    options.Position = []         % [x y z] camera position
    options.PositionFrame = ''    % 'world' or 'vehicle'
    options.Target = []           % [x y z] point the camera looks at
    options.TargetFrame = ''      % 'world' or 'vehicle'
    options.FieldOfView = []      % degrees
    options.OrbitRate = []        % rad/s, turns a vehicle-frame position
    options.UpVector = []         % [x y z] in world coordinates
    options.FigNum = []           % Figure to plot into; [] for no plot, -1 for fast mode
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

        % Check the Mode input
        modeNames = {'wideFixed','roadside','overhead','chase','driver','roof','side','kite','orbit'};
        if ~any(strcmpi(char(options.Mode), modeNames))
            error('Mode must be one of: %s', strjoin(modeNames,', '));
        end

        % Check the point inputs
        pointNames = {'Position','Target','UpVector'};
        for ith_name = 1:length(pointNames)
            thisValue = options.(pointNames{ith_name});
            if ~isempty(thisValue) && (~isnumeric(thisValue) || numel(thisValue)~=3 || any(~isfinite(thisValue)))
                error('%s must be a finite [x y z]', pointNames{ith_name});
            end
        end

        % Check the frame inputs
        frameNames = {'PositionFrame','TargetFrame'};
        for ith_name = 1:length(frameNames)
            thisValue = options.(frameNames{ith_name});
            if ~isempty(thisValue) && ~any(strcmpi(char(thisValue),{'world','vehicle'}))
                error('%s must be ''world'' or ''vehicle''', frameNames{ith_name});
            end
        end

        % Check the FieldOfView input
        if ~isempty(options.FieldOfView) && (~isnumeric(options.FieldOfView) || ~isscalar(options.FieldOfView) || ...
                options.FieldOfView<=0 || options.FieldOfView>=180)
            error('FieldOfView must be a number of degrees between 0 and 180');
        end

        % Check the OrbitRate input
        if ~isempty(options.OrbitRate) && (~isnumeric(options.OrbitRate) || ~isscalar(options.OrbitRate) || ~isfinite(options.OrbitRate))
            error('OrbitRate must be a finite number of radians per second');
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

% Start from the preset
cameraSettings = fcn_INTERNAL_preset(char(options.Mode));

% Any value given overrides the preset
overrideNames = {'Position','PositionFrame','Target','TargetFrame','FieldOfView','OrbitRate','UpVector'};
for ith_name = 1:length(overrideNames)
    thisValue = options.(overrideNames{ith_name});
    if ~isempty(thisValue)
        if ischar(thisValue) || isstring(thisValue)
            thisValue = lower(char(thisValue));
        else
            thisValue = thisValue(:)';
        end
        cameraSettings.(overrideNames{ith_name}) = thisValue;
    end
end

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
    tiledlayout(1,2);
    % Show the camera relative to a vehicle at the origin, heading +X
    examplePose = [0 0 0];
    [cameraPosition, cameraTarget] = fcn_INTERNAL_pointsAt(cameraSettings, examplePose);
    carOutline = [-0.9 -0.9; 3.6 -0.9; 3.6 0.9; -0.9 0.9; -0.9 -0.9];
    for ith_view = 1:2
        nexttile;
        hold on; grid on; axis equal;
        if ith_view==1
            fill(carOutline(:,1), carOutline(:,2), [0.6 0.7 0.9], 'DisplayName','vehicle (top view)');
            plot(cameraPosition(1), cameraPosition(2), 'ks', 'MarkerFaceColor','k', 'MarkerSize',10, 'DisplayName','camera');
            plot(cameraTarget(1), cameraTarget(2), 'rx', 'MarkerSize',12, 'LineWidth',2, 'DisplayName','target');
            plot([cameraPosition(1) cameraTarget(1)], [cameraPosition(2) cameraTarget(2)], 'k--', 'HandleVisibility','off');
            xlabel('X [m] (forward)'); ylabel('Y [m] (left)'); title('From above');
        else
            fill([-0.9 3.6 3.6 -0.9], [0 0 1.45 1.45], [0.6 0.7 0.9], 'DisplayName','vehicle (side view)');
            plot(cameraPosition(1), cameraPosition(3), 'ks', 'MarkerFaceColor','k', 'MarkerSize',10, 'DisplayName','camera');
            plot(cameraTarget(1), cameraTarget(3), 'rx', 'MarkerSize',12, 'LineWidth',2, 'DisplayName','target');
            plot([cameraPosition(1) cameraTarget(1)], [cameraPosition(3) cameraTarget(3)], 'k--', 'HandleVisibility','off');
            xlabel('X [m] (forward)'); ylabel('Z [m] (up)'); title('From the side');
        end
        legend('Location','best');
    end
    sgtitle(sprintf('Camera mode ''%s'': position in %s frame, target in %s frame, FOV %.0f deg', ...
        cameraSettings.Mode, cameraSettings.PositionFrame, cameraSettings.TargetFrame, cameraSettings.FieldOfView), 'Interpreter','none');
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

%% fcn_INTERNAL_preset
function cameraSettings = fcn_INTERNAL_preset(modeName)
% The preset values for each named camera mode
cameraSettings = struct('Mode',modeName,'Position',[],'PositionFrame','','Target',[], ...
    'TargetFrame','','FieldOfView',[],'OrbitRate',0,'UpVector',[0 0 1]);
switch lower(modeName)
    case lower('wideFixed')
        cameraSettings = fcn_INTERNAL_set(cameraSettings, [-35 -45 30], 'world', [0 0 0], 'world', 35);
    case 'roadside'
        cameraSettings = fcn_INTERNAL_set(cameraSettings, [0 -8 1.5], 'world', [1.35 0 0.7], 'vehicle', 40);
    case 'overhead'
        cameraSettings = fcn_INTERNAL_set(cameraSettings, [0 0 60], 'world', [0 0 0], 'world', 40);
        cameraSettings.UpVector = [0 1 0];
    case 'chase'
        cameraSettings = fcn_INTERNAL_set(cameraSettings, [-7 0 2.5], 'vehicle', [4 0 1], 'vehicle', 50);
    case 'driver'
        cameraSettings = fcn_INTERNAL_set(cameraSettings, [1.5 0.37 1.15], 'vehicle', [20 0.37 0.9], 'vehicle', 70);
    case 'roof'
        cameraSettings = fcn_INTERNAL_set(cameraSettings, [0.6 0 1.9], 'vehicle', [12 0 0.4], 'vehicle', 65);
    case 'side'
        cameraSettings = fcn_INTERNAL_set(cameraSettings, [1.35 -7 1.2], 'vehicle', [1.35 0 0.7], 'vehicle', 40);
    case 'kite'
        cameraSettings = fcn_INTERNAL_set(cameraSettings, [-14 0 10], 'vehicle', [6 0 0], 'vehicle', 45);
    case 'orbit'
        cameraSettings = fcn_INTERNAL_set(cameraSettings, [-9 0 4], 'vehicle', [1.35 0 0.7], 'vehicle', 45);
        cameraSettings.OrbitRate = 0.4;
end
end % Ends fcn_INTERNAL_preset

%% fcn_INTERNAL_set
function cameraSettings = fcn_INTERNAL_set(cameraSettings, position, positionFrame, target, targetFrame, fieldOfView)
cameraSettings.Position = position;
cameraSettings.PositionFrame = positionFrame;
cameraSettings.Target = target;
cameraSettings.TargetFrame = targetFrame;
cameraSettings.FieldOfView = fieldOfView;
end % Ends fcn_INTERNAL_set

%% fcn_INTERNAL_pointsAt
function [cameraPosition, cameraTarget] = fcn_INTERNAL_pointsAt(cameraSettings, vehiclePose)
% World coordinates of the camera and target at time 0 (for the plot)
yaw = vehiclePose(3);
rotation = [cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1];
origin = [vehiclePose(1:2) 0];
cameraPosition = cameraSettings.Position;
if strcmp(cameraSettings.PositionFrame,'vehicle')
    cameraPosition = (rotation*cameraPosition(:))' + origin;
end
cameraTarget = cameraSettings.Target;
if strcmp(cameraSettings.TargetFrame,'vehicle')
    cameraTarget = (rotation*cameraTarget(:))' + origin;
end
end % Ends fcn_INTERNAL_pointsAt
