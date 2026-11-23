function viewer = fcn_CarMesh3D_viewOutline(vehicleInput, options)
% fcn_CarMesh3D_viewOutline

% A view for checking a vehicle's 2D outline (from
% fcn_CarMesh3D_makeOutline2D): the outlines from above, in gray, over the
% vehicle drawn faintly, with one element at a time filled in orange (the
% body, each window, each wheel, the lights by type and side, the
% interior). A toggle shows the 3D model, see-through, over the outlines.
% It works on its own (its own window, with a list of the elements), or
% inside another window, such as the Model Reviewer
% (fcn_CarMesh3D_reviewVehicle), which gives it a panel to build into.
%
% Each outline should be one closed loop around its part, with no lines
% crossing through it.
%
% FORMAT:
%
%       viewer = fcn_CarMesh3D_viewOutline(vehicleInput,...
%           (Mesh=vehicleMesh), (Parent=container), (OnHint=function),...
%           (Visible=flag), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport'), or a 2D outline
%      (fcn_CarMesh3D_makeOutline2D's output). With an ID, the outline and
%      the mesh are the vehicle's files.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Mesh: the vehicle's mesh, drawn under the outlines (and in 3D with
%      the toggle). Default: the vehicle's mesh file (with an ID), else
%      none.
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
%           Figure, Axes, Elements (Key, Label, Polygons of each element)
%           ShowElement(key): that element filled in orange ('' for none)
%           SetModel3D(flag): the 3D model over the outlines, or not
%           ResetView(): back to the view from above
%           Close(): close its own window
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles
%
% EXAMPLES:
%
%       viewer = fcn_CarMesh3D_viewOutline('2009_Honda_Fit_Sport');
%       viewer.ShowElement('body');
%
%       See the script: script_test_fcn_CarMesh3D_viewOutline.m for a full
%       test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewOutline
%   % * First write: the Model Reviewer's 2D outline check, taken out into a
%   %   % function of its own (Sean, 06:00: separate panels, so the passing
%   %   % of the mesh is clear and each is easier to debug); the interior
%   %   % outlines are an element too
%   % * Its own window's title is this function's name, with the
%   %   % file's last change (its version) under it (fcn_CarMesh3D_addTitleBar;
%   %   % Sean, 14:31 and 14:40)

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewOutline
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleInput
    options.Mesh = []           % The mesh drawn under the outlines; [] for the default
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
    debug_figNum = 999976; %#ok<NASGU>
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
        if ~(ischar(vehicleInput) || isstring(vehicleInput) || isempty(vehicleInput) || ...
                (isstruct(vehicleInput) && all(isfield(vehicleInput, {'Body','Windows','Wheels','Lights'}))))
            error('vehicleInput must be a vehicle ID or a 2D outline (Body, Windows, Wheels, Lights)');
        end
        if ~isempty(options.Mesh) && ~(isstruct(options.Mesh) && all(isfield(options.Mesh, {'Vertices','Faces'})))
            error('Mesh must be a CarMesh3D mesh (Vertices, Faces), or empty');
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

%%%% The outline and the mesh
vehicleMesh = options.Mesh;
outline = [];
vehicleName = 'outline';
if ischar(vehicleInput) || isstring(vehicleInput)
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
    vehicleName = vehicleFiles.Name;
    if vehicleFiles.HasOutline
        loaded = load(vehicleFiles.OutlineFile, 'vehicleOutline');
        outline = loaded.vehicleOutline;
    end
    if isempty(vehicleMesh)
        loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
        vehicleMesh = loaded.vehicleMesh;
    end
else
    outline = vehicleInput;
    if isstruct(outline) && isfield(outline, 'Name')
        vehicleName = outline.Name;
    end
end
elements = struct('Key',{},'Label',{},'Polygons',{});
if ~isempty(outline)
    elements = fcn_INTERNAL_outlineElements(outline);
end

%%%% The window (or the parent given)
flagOwnWindow = isempty(options.Parent);
figureHandle = [];
hintLabel = [];
axesHandle = [];
flagModel3D = false;
mouseMode = '';
mouseLast = [0 0];
if flagOwnWindow
    visibleText = 'on';
    if ~options.Visible
        visibleText = 'off';
    end
    figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_viewOutline: %s', vehicleName), 'Position', [100 100 1300 800], ...
        'Visible', visibleText);
    % (the title bar: this function's name and version; the rest under it)
    contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_viewOutline', Subtitle=vehicleName, FigNum=-1);
    rootGrid = uigridlayout(contentPanel, [2 2], 'ColumnWidth', {'1x', 260}, 'RowHeight', {'1x', 44}, ...
        'Padding', [6 6 6 6], 'ColumnSpacing', 6, 'RowSpacing', 4);
    parent = uipanel(rootGrid, 'BorderType', 'none');
    parent.Layout.Row = 1;
    parent.Layout.Column = 1;
else
    parent = options.Parent;
end

if isempty(outline)
    uilabel(uigridlayout(parent, [1 1]), 'Text', 'No 2D outline yet.', 'HorizontalAlignment', 'center');
else
    axesHandle = uiaxes(uigridlayout(parent, [1 1], 'Padding', [0 0 0 0]));
    hold(axesHandle, 'on');
    % (the vehicle from above, faintly, under the outlines)
    if ~isempty(vehicleMesh)
        patch(axesHandle, 'Faces', vehicleMesh.Faces, 'Vertices', vehicleMesh.Vertices(:,1:2), ...
            'FaceColor', [0.93 0.93 0.93], 'EdgeColor', 'none', 'HitTest', 'off');
    end
    for ith_element = 1:numel(elements)
        for ith_polygon = 1:numel(elements(ith_element).Polygons)
            polygon = elements(ith_element).Polygons{ith_polygon};
            plot(axesHandle, polygon([1:end 1],1), polygon([1:end 1],2), '-', 'Color', [0.55 0.55 0.55], ...
                'LineWidth', 0.75, 'HitTest', 'off');
        end
    end
    axis(axesHandle, 'equal');
    fcn_INTERNAL_quietAxes(axesHandle);
    setappdata(axesHandle, 'mouse2D', true);   % (for a window's own mouse: dragging pans)
    setHint('The wheel zooms, dragging pans. Each outline should be one closed loop around its part.');
end

if flagOwnWindow
    % The elements (pick one to fill it in orange), the 3D toggle, and
    % Close
    sideGrid = uigridlayout(rootGrid, [5 1], 'RowHeight', {24, '1x', 30, 30, 30}, 'Padding', [0 0 0 0]);
    sideGrid.Layout.Row = 1;
    sideGrid.Layout.Column = 2;
    uilabel(sideGrid, 'Text', 'Elements', 'FontWeight', 'bold');
    uilistbox(sideGrid, 'Items', [{'(none)'}, {elements.Label}], 'ItemsData', [{''}, {elements.Key}], 'Value', '', ...
        'ValueChangedFcn', @(source,~) showElement(source.Value), 'Tag', 'elementList');
    uibutton(sideGrid, 'state', 'Text', 'Show the 3D model (see-through)', ...
        'ValueChangedFcn', @(source,~) setModel3D(source.Value), 'Tag', 'model3DButton');
    uibutton(sideGrid, 'Text', 'Reset view', 'ButtonPushedFcn', @(~,~) resetView());
    uibutton(sideGrid, 'Text', 'Close', 'ButtonPushedFcn', @(~,~) closeViewer());
    hintLabel = uilabel(rootGrid, 'Text', '', 'Interpreter', 'html', 'WordWrap', 'on', 'FontColor', [0.25 0.25 0.25]);
    hintLabel.Layout.Row = 2;
    hintLabel.Layout.Column = [1 2];
    setHint('The wheel zooms, dragging pans. Each outline should be one closed loop around its part.');
    set(figureHandle, 'WindowButtonDownFcn', @(~,~) onOwnDown(), 'WindowButtonMotionFcn', @(~,~) onOwnMove(), ...
        'WindowButtonUpFcn', @(~,~) onOwnUp(), 'WindowScrollWheelFcn', @onOwnScroll, ...
        'CloseRequestFcn', @(~,~) closeViewer());
end

viewer = struct('Figure', figureHandle, 'Axes', axesHandle, 'Elements', elements, ...
    'ShowElement', @showElement, 'SetModel3D', @setModel3D, 'ResetView', @resetView, 'Close', @closeViewer);
if flagOwnWindow
    figureHandle.UserData = viewer;
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the view's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function showElement(key)
        % One element filled in orange ('' for none)
        if isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        delete(findobj(axesHandle, 'Tag', 'selected'));
        elementIndex = find(strcmp({elements.Key}, key), 1);
        if isempty(elementIndex)
            return;
        end
        polygons = elements(elementIndex).Polygons;
        for ith_polygon = 1:numel(polygons)
            polygon = polygons{ith_polygon};
            patch(axesHandle, polygon(:,1), polygon(:,2), [1 0.5 0], 'FaceAlpha', 0.25, 'EdgeColor', [0.85 0.2 0], ...
                'LineWidth', 2, 'Tag', 'selected', 'Marker', '.', 'MarkerSize', 10, 'HitTest', 'off');
        end
    end

    function setModel3D(flagOn)
        % The 3D model over the outlines (see-through), with rotating; or
        % back to the flat view from above
        if isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        flagModel3D = flagOn;
        delete(findobj(axesHandle, 'Tag', 'model3D'));
        if flagOn && ~isempty(vehicleMesh)
            % (the outlines lie at ground level, under the model)
            if isfield(vehicleMesh, 'FaceColors') && size(vehicleMesh.FaceColors,1) == size(vehicleMesh.Faces,1)
                colorArguments = {'FaceVertexCData', vehicleMesh.FaceColors, 'FaceColor', 'flat'};
            else
                colorArguments = {'FaceColor', [0.6 0.6 0.65]};
            end
            patch(axesHandle, 'Faces', vehicleMesh.Faces, 'Vertices', vehicleMesh.Vertices, colorArguments{:}, ...
                'FaceAlpha', 0.3, 'EdgeColor', 'none', 'FaceLighting', 'flat', 'Tag', 'model3D', 'HitTest', 'off', ...
                'Clipping', 'off');
            if isempty(findobj(axesHandle, 'Type', 'light'))
                light(axesHandle, 'Style', 'infinite', 'Position', [-1 -1 2]);
            end
            if isappdata(axesHandle, 'mouse2D')
                rmappdata(axesHandle, 'mouse2D');   % (left-drag rotates now)
            end
            view(axesHandle, -30, 35);
            setHint('Left-drag rotates, right-drag pans, the wheel zooms. The outlines lie at ground level, under the model.');
        else
            setappdata(axesHandle, 'mouse2D', true);
            view(axesHandle, 0, 90);
            setHint('The wheel zooms, dragging pans. Each outline should be one closed loop around its part.');
        end
    end

    function resetView()
        if isempty(axesHandle) || ~isvalid(axesHandle)
            return;
        end
        if flagModel3D
            view(axesHandle, -30, 35);
        else
            view(axesHandle, 0, 90);
        end
        axis(axesHandle, 'auto');
        axis(axesHandle, 'equal');
    end

    function setHint(textIn)
        if ~isempty(options.OnHint)
            options.OnHint(textIn);
        elseif ~isempty(hintLabel) && isvalid(hintLabel)
            hintLabel.Text = textIn;
        end
    end

    %% Its own window: the mouse, and closing
    function onOwnDown()
        % Dragging pans (from above); with the 3D model, left-drag rotates
        % and right-drag pans
        mouseMode = '';
        clicked = figureHandle.CurrentObject;
        if isempty(axesHandle) || isempty(clicked) || ~isvalid(clicked) || ~isequal(ancestor(clicked, 'axes'), axesHandle)
            return;
        end
        if strcmp(figureHandle.SelectionType, 'alt') || isappdata(axesHandle, 'mouse2D')
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
        if ~isempty(axesHandle) && isvalid(axesHandle)
            camzoom(axesHandle, 1.15^(-event.VerticalScrollCount));
        end
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

%% fcn_INTERNAL_outlineElements
function elements = fcn_INTERNAL_outlineElements(outline)
% The outline's parts, one item each: the body, each window, each wheel,
% the lights grouped by type and side, and the interior (one element for
% all its pieces)
elements = struct('Key',{},'Label',{},'Polygons',{});
if ~isempty(outline.Body)
    elements(end+1) = struct('Key','body','Label','Body outline','Polygons',{{outline.Body}});
end
for ith_window = 1:numel(outline.Windows)
    elements(end+1) = struct('Key', sprintf('window%d', ith_window), ...
        'Label', sprintf('Window: %s', outline.Windows(ith_window).Name), ...
        'Polygons', {{outline.Windows(ith_window).Polygon}}); %#ok<AGROW>
end
for ith_wheel = 1:numel(outline.Wheels)
    elements(end+1) = struct('Key', sprintf('wheel%d', ith_wheel), ...
        'Label', sprintf('Wheel: %s', outline.Wheels(ith_wheel).Name), ...
        'Polygons', {{outline.Wheels(ith_wheel).Rectangle + outline.Wheels(ith_wheel).Center}}); %#ok<AGROW>
    % (a wheel's rectangle is kept about its own center, so it can steer)
end
if ~isempty(outline.Lights)
    types = string({outline.Lights.Type});
    sides = string({outline.Lights.Side});
    groups = unique(types + "|" + sides, 'stable');
    for ith_group = 1:numel(groups)
        parts = split(groups(ith_group), "|");
        flagGroup = types==parts(1) & sides==parts(2);
        elements(end+1) = struct('Key', sprintf('lights_%s_%s', parts(1), parts(2)), ...
            'Label', sprintf('Lights: %s, %s (%d outlines)', parts(1), parts(2), sum(flagGroup)), ...
            'Polygons', {{outline.Lights(flagGroup).Polygon}}); %#ok<AGROW>
    end
end
if isfield(outline, 'Interior') && ~isempty(outline.Interior)
    elements(end+1) = struct('Key', 'interior', ...
        'Label', sprintf('Interior (%d outlines)', numel(outline.Interior)), ...
        'Polygons', {{outline.Interior.Polygon}});
end
end % Ends fcn_INTERNAL_outlineElements

%% fcn_INTERNAL_quietAxes
function fcn_INTERNAL_quietAxes(axesHandle)
% No built-in mouse interactions or toolbar: the window's own mouse
% handling works the view
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
