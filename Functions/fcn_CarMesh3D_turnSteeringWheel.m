function [turnedVertices, handwheelAngleDeg] = fcn_CarMesh3D_turnSteeringWheel(vertices, steeringWheel, roadWheelAngleDeg, options)
% fcn_CarMesh3D_turnSteeringWheel
% Turns a vehicle mesh's steering wheel to match the road wheels' steer
% angle, for animation: the steering wheel (handwheel) turns by the road
% wheel angle times the steering ratio, about the wheel's own axis.
%
% Written to move as it is into AnimateCar3D, where it belongs (Sean,
% 2026-11-24 09:25): it uses base MATLAB only and no other CarMesh3D
% function; its inputs are plain numbers and a small structure. To move
% it, copy the file and rename the prefix.
%
% The turn, in plain words:
%   handwheel angle = steering ratio x road wheel angle
% (a ratio of 15 means 15 degrees of steering-wheel turn for each degree
% the road wheels steer; passenger cars run about 12 to 20). A positive
% road wheel angle steers LEFT (the vehicle frame: x forward, y left, z
% up), and the driver turns the wheel counterclockwise as they see it, so
% the wheel turns by a positive angle about its axis pointing at the
% driver (right-hand rule). The handwheel can be held to its lock
% (MaxTurns, the turns from center to either lock).
%
% FORMAT:
%
%       [turnedVertices, handwheelAngleDeg] = fcn_CarMesh3D_turnSteeringWheel(...
%           vertices, steeringWheel, roadWheelAngleDeg,...
%           (SteeringRatio=ratio), (MaxTurns=turns), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs after the required
%      inputs, in any order. Any option not given takes its default.
%
% INPUTS:
%
%      vertices: N x 3, the mesh's vertices in its own frame (meters).
%
%      steeringWheel: a structure with
%           Center: 1 x 3, the middle of the wheel (the hub)
%           Normal: 1 x 3, the wheel's axis, pointing at the driver
%           and one of
%           VertexIndices: the vertices that turn with the wheel, or
%           Faces: the faces that do (with FacesOfMesh, the mesh's M x 3
%               Faces, to find their vertices)
%      fcn_CarMesh3D_findInteriorObjects returns this structure as
%      result.SteeringWheel (Center, Normal, Faces).
%
%      roadWheelAngleDeg: the road wheels' steer angle, degrees (positive
%      to the left); a scalar.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      SteeringRatio: handwheel degrees per road wheel degree. Default 15
%      (the project's default, decided 2026-11-23; a vehicle's own ratio,
%      when known, is better: the 2007 to 2008 Fit's was 12.8).
%
%      MaxTurns: the steering wheel's turns from center to either lock
%      (half the "turns lock to lock"); the handwheel is held there.
%      Default Inf (no limit).
%
%      FacesOfMesh: M x 3, the mesh's faces, needed when steeringWheel
%      gives Faces. Default [].
%
%      FigNum: a figure to show the wheel before (gray) and after (red).
%      If empty or omitted, no plot is made. If -1, input checking is
%      skipped and no plot is made (fast mode).
%
% OUTPUTS:
%
%      turnedVertices: N x 3, the vertices with the steering wheel's
%      turned; every other vertex unchanged.
%
%      handwheelAngleDeg: the steering wheel's turn, degrees (positive:
%      counterclockwise as the driver sees it).
%
% DEPENDENCIES:
%
%      (none: base MATLAB only)
%
% EXAMPLES:
%
%       % A wheel found in the Fit, turned for a 10 degree left steer
%       result = fcn_CarMesh3D_findInteriorObjects(vehicleMesh, FigNum=-1);
%       wheel = result.SteeringWheel;
%       [newVertices, handwheel] = fcn_CarMesh3D_turnSteeringWheel(vehicleMesh.Vertices, ...
%           wheel, 10, FacesOfMesh=vehicleMesh.Faces, SteeringRatio=15);
%       % handwheel is 150 degrees
%
%       See the script: script_test_fcn_CarMesh3D_turnSteeringWheel.m for
%       a full test suite.
%
% This function was written on 2026_11_24 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_turnSteeringWheel
%   % * First write of the code (Sean, 09:25): the steering wheel turned
%   %   % by the steering ratio times the road wheel angle, about its own
%   %   % axis; held at its lock; made to move into AnimateCar3D

% TO-DO:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_turnSteeringWheel
%   % * Each vehicle's own steering ratio and turns lock to lock, in its
%   %   % vehicleParameters file, when known


% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vertices
    steeringWheel
    roadWheelAngleDeg
    options.SteeringRatio = 15    % handwheel degrees per road wheel degree
    options.MaxTurns = Inf        % turns from center to either lock
    options.FacesOfMesh = []      % the mesh's faces, when steeringWheel gives Faces
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
        % The option names are checked by the arguments block above
        if ~isnumeric(vertices) || size(vertices,2) ~= 3
            error('CarMesh3D:badInput', 'vertices must be N x 3 (the mesh''s vertices).');
        end
        if ~isstruct(steeringWheel) || ~all(isfield(steeringWheel, {'Center','Normal'})) ...
                || ~(isfield(steeringWheel, 'VertexIndices') || isfield(steeringWheel, 'Faces'))
            error('CarMesh3D:badInput', 'steeringWheel must be a structure with Center, Normal, and VertexIndices or Faces.');
        end
        if numel(steeringWheel.Center) ~= 3 || numel(steeringWheel.Normal) ~= 3 || norm(steeringWheel.Normal) == 0
            error('CarMesh3D:badInput', 'steeringWheel.Center and Normal must be 1 x 3 (Normal not zero).');
        end
        if ~isfield(steeringWheel, 'VertexIndices') && isempty(options.FacesOfMesh)
            error('CarMesh3D:badInput', 'steeringWheel gives Faces: give the mesh''s faces too (FacesOfMesh=vehicleMesh.Faces).');
        end
        if ~isnumeric(roadWheelAngleDeg) || ~isscalar(roadWheelAngleDeg) || ~isfinite(roadWheelAngleDeg)
            error('CarMesh3D:badInput', 'roadWheelAngleDeg must be one number (degrees, positive to the left).');
        end
        if ~isnumeric(options.SteeringRatio) || ~isscalar(options.SteeringRatio) || options.SteeringRatio <= 0
            error('CarMesh3D:badInput', 'SteeringRatio must be a positive number.');
        end
        if ~isnumeric(options.MaxTurns) || ~isscalar(options.MaxTurns) || options.MaxTurns <= 0
            error('CarMesh3D:badInput', 'MaxTurns must be a positive number (or Inf).');
        end
    end
end

% Make the plot?
flag_do_plots = 0; % Default is to NOT plot
if (0==flag_max_speed) && ~isempty(options.FigNum)
    flag_do_plots = 1;
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

% The handwheel's turn: the ratio times the road wheel angle, held at the
% lock
handwheelAngleDeg = options.SteeringRatio*roadWheelAngleDeg;
lockDeg = 360*options.MaxTurns;
handwheelAngleDeg = max(-lockDeg, min(lockDeg, handwheelAngleDeg));

% The vertices that turn with the wheel
if isfield(steeringWheel, 'VertexIndices')
    wheelVertices = unique(steeringWheel.VertexIndices(:));
else
    wheelVertices = unique(options.FacesOfMesh(steeringWheel.Faces(:), :));
end

% Turned about the wheel's axis (unit, pointing at the driver), through
% its center: Rodrigues' rotation formula, as a 3 x 3 matrix
axisUnit = steeringWheel.Normal(:)'/norm(steeringWheel.Normal);
rotation = fcn_INTERNAL_axisRotation(axisUnit, handwheelAngleDeg);
center = steeringWheel.Center(:)';
turnedVertices = vertices;
turnedVertices(wheelVertices,:) = (vertices(wheelVertices,:) - center)*rotation' + center;

%% Plot the results (for debugging)?
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
    if ishandle(options.FigNum)
        figureHandle = figure(options.FigNum);
        clf(figureHandle);
    else
        figureHandle = figure(options.FigNum);
    end
    axesHandle = axes(figureHandle);
    hold(axesHandle, 'on');
    plot3(axesHandle, vertices(wheelVertices,1), vertices(wheelVertices,2), vertices(wheelVertices,3), '.', 'Color', [0.6 0.6 0.6]);
    plot3(axesHandle, turnedVertices(wheelVertices,1), turnedVertices(wheelVertices,2), turnedVertices(wheelVertices,3), '.', 'Color', [0.85 0.1 0.1]);
    quiver3(axesHandle, center(1), center(2), center(3), 0.15*axisUnit(1), 0.15*axisUnit(2), 0.15*axisUnit(3), 0, 'k', 'LineWidth', 1.5);
    axis(axesHandle, 'equal');
    grid(axesHandle, 'on');
    xlabel(axesHandle, 'x (m, forward)'); ylabel(axesHandle, 'y (m, left)'); zlabel(axesHandle, 'z (m)');
    view(axesHandle, -60, 20);
    title(axesHandle, sprintf('Steering wheel: road wheels %.1f deg, ratio %.1f, handwheel %.0f deg (gray before, red after; arrow toward the driver)', ...
        roadWheelAngleDeg, options.SteeringRatio, handwheelAngleDeg));
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

%% fcn_INTERNAL_axisRotation
function rotation = fcn_INTERNAL_axisRotation(axisUnit, angleDeg)
% The 3 x 3 rotation by angleDeg about the unit axis (right-hand rule:
% positive is counterclockwise looking back along the axis from its tip)
crossMatrix = [0 -axisUnit(3) axisUnit(2); axisUnit(3) 0 -axisUnit(1); -axisUnit(2) axisUnit(1) 0];
rotation = eye(3) + sind(angleDeg)*crossMatrix + (1 - cosd(angleDeg))*(crossMatrix*crossMatrix);
end % Ends fcn_INTERNAL_axisRotation
