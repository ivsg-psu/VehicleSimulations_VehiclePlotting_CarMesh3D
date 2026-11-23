function viewer = fcn_CarMesh3D_viewOrientation(vehicleInput, options)
% fcn_CarMesh3D_viewOrientation

% A view for checking a vehicle mesh's orientation: the mesh, see-through,
% with its axes as large arrows from its origin (on the ground, under the
% middle of the rear axle): FRONT (+X, red) past the front bumper, UP
% (+Z, blue) above the roof, and +Y (left, green) past the left side.
% The red arrow should point to the front, the blue one up. It works on
% its own (its own window), or inside another window, such as the Model
% Reviewer (fcn_CarMesh3D_reviewVehicle), which gives it a panel to build
% into.
%
% FORMAT:
%
%       viewer = fcn_CarMesh3D_viewOrientation(vehicleInput,...
%           (Parent=container), (OnHint=function), (Visible=flag),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport'), or a CarMesh3D
%      mesh. With an ID, the mesh is the vehicle's mesh file.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Parent: a panel or grid to build into; [] (default) for a window of
%      its own.
%
%      OnHint: a function called with a hint (HTML text) to show; [] to
%      show it in its own window's hint line (or not at all, in a parent).
%
%      Visible: false to build the window hidden (for tests). Default true.
%
%      FigNum: not used (a window); [] or -1 (fast mode: no input checks).
%
% OUTPUTS:
%
%      viewer: a structure of the view's handles and functions:
%           Figure, Axes
%           ResetView(): the view as it was made
%           Close(): close its own window
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles
%
% EXAMPLES:
%
%       viewer = fcn_CarMesh3D_viewOrientation('2009_Honda_Fit_Sport');
%
%       See the script: script_test_fcn_CarMesh3D_viewOrientation.m for a
%       full test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewOrientation
%   % * First write: the Model Reviewer's orientation check, taken out into
%   %   % a function of its own (Sean, 06:00: separate panels, so the
%   %   % passing of the mesh is clear and each is easier to debug)
%   % * Its own window's title is this function's name, with the
%   %   % file's last change (its version) under it (fcn_CarMesh3D_addTitleBar;
%   %   % Sean, 14:31 and 14:40)

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewOrientation
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleInput
    options.Parent = []         % Panel or grid to build into; [] for a window of its own
    options.OnHint = []         % Called with hint text
    options.Visible = true      % Build the window hidden (tests)
    options.FigNum = []         % Not used (a window); -1 for fast mode
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
    debug_figNum = 999973; %#ok<NASGU>
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
        if ~(ischar(vehicleInput) || isstring(vehicleInput) || ...
                (isstruct(vehicleInput) && all(isfield(vehicleInput, {'Vertices','Faces'}))))
            error('vehicleInput must be a vehicle ID or a CarMesh3D mesh (Vertices, Faces)');
        end
        if ~isempty(options.OnHint) && ~isa(options.OnHint, 'function_handle')
            error('OnHint must be a function handle, or empty');
        end
        if ~isempty(options.Parent) && ~isgraphics(options.Parent)
            error('Parent must be a panel or grid, or empty');
        end
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

%%%% The mesh
vehicleName = 'mesh';
if ischar(vehicleInput) || isstring(vehicleInput)
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
    vehicleName = vehicleFiles.Name;
    loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
    vehicleMesh = loaded.vehicleMesh;
else
    vehicleMesh = vehicleInput;
    if isfield(vehicleMesh, 'Name')
        vehicleName = vehicleMesh.Name;
    end
end
Nfaces = size(vehicleMesh.Faces,1);
if ~isfield(vehicleMesh, 'FaceColors') || size(vehicleMesh.FaceColors,1) ~= Nfaces
    vehicleMesh.FaceColors = repmat([0.6 0.6 0.65], Nfaces, 1);
end
if ~isfield(vehicleMesh, 'FaceAlpha') || numel(vehicleMesh.FaceAlpha) ~= Nfaces
    vehicleMesh.FaceAlpha = ones(Nfaces,1);
end

%%%% The window (or the parent given)
flagOwnWindow = isempty(options.Parent);
figureHandle = [];
hintLabel = [];
mouseMode = '';
mouseLast = [0 0];
if flagOwnWindow
    visibleText = 'on';
    if ~options.Visible
        visibleText = 'off';
    end
    figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_viewOrientation: %s', vehicleName), 'Position', [100 100 1100 760], ...
        'Visible', visibleText);
    % (the title bar: this function's name and version; the rest under it)
    contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_viewOrientation', Subtitle=vehicleName, FigNum=-1);
    rootGrid = uigridlayout(contentPanel, [2 2], 'ColumnWidth', {'1x', 120}, 'RowHeight', {'1x', 34}, ...
        'Padding', [6 6 6 6], 'ColumnSpacing', 6, 'RowSpacing', 4);
    parent = uipanel(rootGrid, 'BorderType', 'none');
    parent.Layout.Row = 1;
    parent.Layout.Column = 1;
else
    parent = options.Parent;
end

axesHandle = uiaxes(uigridlayout(parent, [1 1], 'Padding', [0 0 0 0]));
hold(axesHandle, 'on');
axis(axesHandle, 'off');
axesHandle.Color = [1 1 1];
axesHandle.Clipping = 'off';
% (the body see-through, so the arrows show through it)
fcn_INTERNAL_drawMesh(axesHandle, vehicleMesh, vehicleMesh.FaceColors, min(vehicleMesh.FaceAlpha(:), 0.45));
fcn_INTERNAL_drawAxesArrows(axesHandle, vehicleMesh);
view(axesHandle, -40, 25);
axis(axesHandle, 'equal');
axis(axesHandle, 'vis3d');
set(findobj(axesHandle, '-property', 'Clipping'), 'Clipping', 'off');
camlight(axesHandle, 'headlight');
fcn_INTERNAL_quietAxes(axesHandle);
startView = fcn_INTERNAL_getView(axesHandle);

if flagOwnWindow
    sideGrid = uigridlayout(rootGrid, [3 1], 'RowHeight', {30, 30, '1x'}, 'Padding', [0 0 0 0]);
    sideGrid.Layout.Row = 1;
    sideGrid.Layout.Column = 2;
    uibutton(sideGrid, 'Text', 'Reset view', 'ButtonPushedFcn', @(~,~) resetView());
    uibutton(sideGrid, 'Text', 'Close', 'ButtonPushedFcn', @(~,~) closeViewer());
    hintLabel = uilabel(rootGrid, 'Text', '', 'Interpreter', 'html', 'FontColor', [0.25 0.25 0.25]);
    hintLabel.Layout.Row = 2;
    hintLabel.Layout.Column = [1 2];
    set(figureHandle, 'WindowButtonDownFcn', @(~,~) onOwnDown(), 'WindowButtonMotionFcn', @(~,~) onOwnMove(), ...
        'WindowButtonUpFcn', @(~,~) onOwnUp(), 'WindowScrollWheelFcn', @onOwnScroll, ...
        'CloseRequestFcn', @(~,~) closeViewer());
end
setHint('Mouse: left-drag rotates, right-drag pans, the wheel zooms. Does the red arrow point to the front, and the blue one up?');

viewer = struct('Figure', figureHandle, 'Axes', axesHandle, 'ResetView', @resetView, 'Close', @closeViewer);
if flagOwnWindow
    figureHandle.UserData = viewer;
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the view's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function resetView()
        if isvalid(axesHandle)
            fcn_INTERNAL_setView(axesHandle, startView);
        end
    end

    function setHint(textIn)
        if ~isempty(options.OnHint)
            options.OnHint(textIn);
        elseif ~isempty(hintLabel) && isvalid(hintLabel)
            hintLabel.Text = textIn;
        end
    end

    %% Its own window: the mouse, CAD-style, and closing
    function onOwnDown()
        mouseMode = '';
        clicked = figureHandle.CurrentObject;
        if isempty(clicked) || ~isvalid(clicked) || ~isequal(ancestor(clicked, 'axes'), axesHandle)
            return;
        end
        if strcmp(figureHandle.SelectionType, 'alt')
            mouseMode = 'pan';
        else
            mouseMode = 'rotate';
        end
        mouseLast = figureHandle.CurrentPoint;
    end

    function onOwnMove()
        if isempty(mouseMode)
            return;
        end
        point = figureHandle.CurrentPoint;
        delta = point - mouseLast;
        mouseLast = point;
        if strcmp(mouseMode, 'rotate')
            camorbit(axesHandle, -0.5*delta(1), -0.5*delta(2), 'data', [0 0 1]);
        else
            camdolly(axesHandle, -delta(1), -delta(2), 0, 'movetarget', 'pixels');
        end
        drawnow limitrate;
    end

    function onOwnUp()
        mouseMode = '';
    end

    function onOwnScroll(~, event)
        camzoom(axesHandle, 1.15^(-event.VerticalScrollCount));
    end

    function closeViewer()
        if flagOwnWindow && ~isempty(figureHandle) && isvalid(figureHandle)
            delete(figureHandle);
        end
    end
end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_drawAxesArrows
function fcn_INTERNAL_drawAxesArrows(axesHandle, vehicleMesh)
% The vehicle's axes as large arrows from its origin (on the ground,
% under the middle of the rear axle), through the vehicle: FRONT (+X,
% red) past the front bumper, UP (+Z, blue) above the roof, and +Y (left,
% green) past the left side
vertexMin = min(vehicleMesh.Vertices,[],1);
vertexMax = max(vehicleMesh.Vertices,[],1);
vehicleLength = vertexMax(1) - vertexMin(1);
headLength = 0.09*vehicleLength;
headWidth = 0.04*vehicleLength;
arrows = {[1 0 0], vertexMax(1) + 0.45*vehicleLength, [0.85 0 0], 'FRONT (+X)';
    [0 0 1], vertexMax(3) + 0.35*vehicleLength, [0 0.3 0.9], 'UP (+Z)';
    [0 1 0], vertexMax(2) + 0.35*vehicleLength, [0 0.6 0], '+Y (left)'};
for ith_arrow = 1:3
    [direction, tipDistance, color, name] = arrows{ith_arrow,:};
    tip = tipDistance*direction;
    base = (tipDistance - headLength)*direction;
    plot3(axesHandle, [0 base(1)], [0 base(2)], [0 base(3)], '-', 'Color', color, 'LineWidth', 6, 'Clipping', 'off');
    % (the head: two crossed triangles, so it shows from any side)
    sideways = null(direction)';
    for ith_plane = 1:2
        corners = [tip; base + headWidth*sideways(ith_plane,:); base - headWidth*sideways(ith_plane,:)];
        patch(axesHandle, corners(:,1), corners(:,2), corners(:,3), color, 'EdgeColor', color, 'Clipping', 'off');
    end
    labelPoint = tip + 0.06*vehicleLength*direction + [0 0 0.04*vehicleLength];
    text(axesHandle, labelPoint(1), labelPoint(2), labelPoint(3), name, 'Color', color, 'FontWeight', 'bold', ...
        'FontSize', 15, 'HorizontalAlignment', 'center', 'Clipping', 'off');
end
plot3(axesHandle, 0, 0, 0, 'ko', 'MarkerFaceColor', [1 1 1], 'MarkerSize', 9, 'LineWidth', 2, 'Clipping', 'off');
end % Ends fcn_INTERNAL_drawAxesArrows

%% fcn_INTERNAL_drawMesh
function patchHandle = fcn_INTERNAL_drawMesh(axesHandle, vehicleMesh, faceColors, faceAlpha)
% One patch, colored and see-through by face, unclipped
faceAlpha = faceAlpha(:);
if isscalar(faceAlpha)
    faceAlpha = repmat(faceAlpha, size(vehicleMesh.Faces,1), 1);
end
patchHandle = patch(axesHandle, 'Faces', vehicleMesh.Faces, 'Vertices', vehicleMesh.Vertices, ...
    'FaceVertexCData', faceColors, 'FaceColor', 'flat', 'EdgeColor', 'none', ...
    'FaceVertexAlphaData', faceAlpha, 'FaceAlpha', 'flat', 'AlphaDataMapping', 'none', ...
    'FaceLighting', 'flat', 'AmbientStrength', 0.7, 'DiffuseStrength', 0.45, 'SpecularStrength', 0.05, ...
    'BackFaceLighting', 'lit', 'Clipping', 'off');
end % Ends fcn_INTERNAL_drawMesh

%% fcn_INTERNAL_quietAxes
function fcn_INTERNAL_quietAxes(axesHandle)
% No built-in mouse interactions or toolbar: the reviewer's own mouse
% handling (CAD-style) works every view
axesHandle.Interactions = [];
try
    disableDefaultInteractivity(axesHandle);
catch
end
try
    axesHandle.Toolbar.Visible = 'off';
catch
end
axesHandle.PickableParts = 'all';
axesHandle.HitTest = 'on';
end % Ends fcn_INTERNAL_quietAxes

%% fcn_INTERNAL_getView / fcn_INTERNAL_setView
function viewState = fcn_INTERNAL_getView(axesHandle)
drawnow;
viewState = struct('CameraPosition', axesHandle.CameraPosition, 'CameraTarget', axesHandle.CameraTarget, ...
    'CameraUpVector', axesHandle.CameraUpVector, 'CameraViewAngle', axesHandle.CameraViewAngle, ...
    'XLim', axesHandle.XLim, 'YLim', axesHandle.YLim, 'ZLim', axesHandle.ZLim);
end % Ends fcn_INTERNAL_getView

function fcn_INTERNAL_setView(axesHandle, viewState)
set(axesHandle, 'XLim', viewState.XLim, 'YLim', viewState.YLim, 'ZLim', viewState.ZLim, ...
    'CameraPosition', viewState.CameraPosition, 'CameraTarget', viewState.CameraTarget, ...
    'CameraUpVector', viewState.CameraUpVector, 'CameraViewAngle', viewState.CameraViewAngle);
end % Ends fcn_INTERNAL_setView
