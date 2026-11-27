function viewer = fcn_CarMesh3D_viewDimensions(vehicleInput, options)
% fcn_CarMesh3D_viewDimensions

% A view for checking a vehicle's dimensions against its data, drawn as
% on a drawing: the side view (top, wide), the front and rear views, and
% a table of each quantity's target, as measured on the mesh, and error.
% One dimension at a time is drawn (a solid line with arrows at both
% ends, its value on top; BLUE the target, PURPLE as measured), in front
% of the vehicle so that nothing hides it, with thin guide lines across
% the vehicle to check the fit. It works on its own (its own window), or
% inside another window, such as the Model Reviewer
% (fcn_CarMesh3D_reviewVehicle), which gives it a panel to build into.
%
% FORMAT:
%
%       viewer = fcn_CarMesh3D_viewDimensions(vehicleInput,...
%           (DimensionTable=dimensionTable), (Parent=container),...
%           (OnSelect=function), (OnHint=function), (FlagVisible=flag),...
%           (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport'), or a labeled
%      CarMesh3D mesh. With an ID, the mesh is the vehicle's mesh file and
%      the dimensions are from its checks' cache (stage 3).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      DimensionTable: one row per quantity: its name (as
%      fcn_CarMesh3D_validateMesh's ValidationTable.Quantity), target (m),
%      measured (m), error (%), and pass. Needed with a mesh; with an ID,
%      the default is from the vehicle's cache. A ValidationTable may be
%      given instead.
%
%      Parent: a panel or grid to build into; [] (default) for a window of
%      its own.
%
%      OnSelect: a function called with a quantity's name when its row of
%      the table is clicked (the reviewer goes to that item); [] to show
%      that dimension.
%
%      OnHint: a function called with a hint (HTML text) to show; [] to
%      show it in its own window's hint line (or not at all, in a parent).
%
%      FlagVisible: false to build the window hidden (for tests). Default true.
%
%      FigNum: not used (a window); [] or -1 (fast mode: no input checks).
%
% OUTPUTS:
%
%      viewer: a structure of the view's handles and functions:
%           Figure, Axes (side, front, rear), Table, Quantities (the
%               names, in the table's order), Names (as shown)
%           ShowDimension(quantity): that dimension drawn, its view's
%               title bold, its row of the table in bold ('' for none)
%           Shown(): the quantity drawn now
%           ResetViews(): the views as they were made
%           Close(): close its own window
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles
%
% EXAMPLES:
%
%       viewer = fcn_CarMesh3D_viewDimensions('2009_Honda_Fit_Sport');
%       viewer.ShowDimension('Wheelbase');
%
%       See the script: script_test_fcn_CarMesh3D_viewDimensions.m for a
%       full test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewDimensions
%   % * First write: the Model Reviewer's dimensions check, taken out into
%   %   % a function of its own (Sean, 06:00: separate panels, so the
%   %   % passing of the mesh is clear and each is easier to debug)
%   % * Its own window's title is this function's name, with the
%   %   % file's last change (its version) under it (fcn_CarMesh3D_addTitleBar;
%   %   % Sean, 14:31 and 14:40)

% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewDimensions
%   % * A small loading window while this window opens (Q99 (A), rule G43)
%   % * It is closed once the window is built, whether or not the
%   %   % function waits (it stayed open: T95 BUG, Sean 02:39)

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewDimensions
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleInput
    options.DimensionTable = [] % The quantities; [] for the vehicle's cache (an ID)
    options.Parent = []         % Panel or grid to build into; [] for a window of its own
    options.OnSelect = []       % Called with a quantity when its table row is clicked
    options.OnHint = []         % Called with hint text
    options.FlagVisible = true      % Build the window hidden (tests)
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
    debug_figNum = 999974; %#ok<NASGU>
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
        if isstruct(vehicleInput) && isempty(options.DimensionTable)
            error('With a mesh given, DimensionTable is needed (or a ValidationTable from fcn_CarMesh3D_validateMesh)');
        end
        for callbackName = {'OnSelect','OnHint'}
            if ~isempty(options.(callbackName{1})) && ~isa(options.(callbackName{1}), 'function_handle')
                error('%s must be a function handle, or empty', callbackName{1});
            end
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

%%%% The mesh and the dimensions
% (a small loading window at once: this window takes a few seconds to
% open; closed when it is ready. Q99 (A), rule G43, Sean 2026-11-27)
loading = fcn_CarMesh3D_loadingWindow('Opening the dimensions viewer', Vehicle=vehicleInput, FlagVisible=options.FlagVisible && isempty(options.Parent));
loadingCleanup = onCleanup(@() loading.Close());
dimensionTable = options.DimensionTable;
vehicleName = 'mesh';
if ischar(vehicleInput) || isstring(vehicleInput)
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
    vehicleName = vehicleFiles.Name;
    loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
    vehicleMesh = loaded.vehicleMesh;
    if isempty(dimensionTable)
        stage3File = fullfile(vehicleFiles.Folder, 'cache', 'stage3_checks.mat');
        if isfile(stage3File)
            stage3 = load(stage3File, 'cacheOutputs');
            if isfield(stage3, 'cacheOutputs') && isfield(stage3.cacheOutputs, 'checkResults')
                dimensionTable = stage3.cacheOutputs.checkResults.ValidationTable;
            end
        end
    end
else
    vehicleMesh = vehicleInput;
    if isfield(vehicleMesh, 'Name')
        vehicleName = vehicleMesh.Name;
    end
end
if ~isfield(vehicleMesh, 'FaceColors') || size(vehicleMesh.FaceColors,1) ~= size(vehicleMesh.Faces,1)
    vehicleMesh.FaceColors = repmat([0.6 0.6 0.65], size(vehicleMesh.Faces,1), 1);
end
data = struct('Mesh', vehicleMesh, 'Geometry', fcn_INTERNAL_geometry(vehicleMesh), ...
    'DimensionTable', fcn_INTERNAL_asDimensionTable(dimensionTable));
Nrows = height(data.DimensionTable);
quantities = cellstr(data.DimensionTable{:,1});
names = cell(Nrows,1);
for ith_row = 1:Nrows
    names{ith_row} = fcn_INTERNAL_dimensionName(data.DimensionTable{ith_row,1}, data.DimensionTable);
end

%%%% The window (or the parent given)
flagOwnWindow = isempty(options.Parent);
figureHandle = [];
hintLabel = [];
viewAxes = gobjects(0);
tableHandle = [];
shownQuantity = '';
startViews = {};
mouseAxes = [];
mouseMode = '';
mouseLast = [0 0];
if flagOwnWindow
    visibleText = 'on';
    if ~options.FlagVisible
        visibleText = 'off';
    end
    figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_viewDimensions: %s', vehicleName), 'Position', [80 80 1400 860], ...
        'Visible', visibleText);
    % (the title bar: this function's name and version; the rest under it)
    contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_viewDimensions', Subtitle=vehicleName, FigNum=-1);
    rootGrid = uigridlayout(contentPanel, [2 2], 'ColumnWidth', {'1x', 120}, 'RowHeight', {'1x', 60}, ...
        'Padding', [6 6 6 6], 'ColumnSpacing', 6, 'RowSpacing', 4);
    parent = uipanel(rootGrid, 'BorderType', 'none');
    parent.Layout.Row = 1;
    parent.Layout.Column = 1;
else
    parent = options.Parent;
end

buildViews();

if flagOwnWindow
    sideGrid = uigridlayout(rootGrid, [3 1], 'RowHeight', {30, 30, '1x'}, 'Padding', [0 0 0 0]);
    sideGrid.Layout.Row = 1;
    sideGrid.Layout.Column = 2;
    uibutton(sideGrid, 'Text', 'Reset views', 'ButtonPushedFcn', @(~,~) resetViews());
    uibutton(sideGrid, 'Text', 'Close', 'ButtonPushedFcn', @(~,~) closeViewer());
    hintLabel = uilabel(rootGrid, 'Text', '', 'Interpreter', 'html', 'WordWrap', 'on', 'FontColor', [0.25 0.25 0.25]);
    hintLabel.Layout.Row = 2;
    hintLabel.Layout.Column = [1 2];
    set(figureHandle, 'WindowButtonDownFcn', @(~,~) onOwnDown(), 'WindowButtonMotionFcn', @(~,~) onOwnMove(), ...
        'WindowButtonUpFcn', @(~,~) onOwnUp(), 'WindowScrollWheelFcn', @onOwnScroll, ...
        'CloseRequestFcn', @(~,~) closeViewer());
end
setHint(['The wheel zooms, dragging pans.<br><br><b><font color="#0059E6">BLUE</font></b>: the target ' ...
    '(from the vehicle''s data).<br><b><font color="#8C1AA6">PURPLE</font></b>: as measured on the mesh.' ...
    '<br><br>The thin guide lines run across the vehicle, to check the fit.<br><br>Click a row of the table to go to it.']);

viewer = struct('Figure', figureHandle, 'Axes', viewAxes, 'Table', tableHandle, ...
    'Quantities', {quantities}, 'Names', {names}, ...
    'ShowDimension', @showDimension, 'Shown', @getShown, 'ResetViews', @resetViews, 'Close', @closeViewer);
if flagOwnWindow
    figureHandle.UserData = viewer;
end

loading.Close();   % (built: closed here, since the nested functions keep onCleanup from running while the window is open; T95 BUG, Sean 2026-11-27 02:39)
if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the view's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function buildViews()
        % The side view (top, wide), the front and rear views, and the
        % table
        layout = uigridlayout(parent, [2 3], 'RowHeight', {'1x', '1x'}, 'ColumnWidth', {'1x', '1x', '1x'}, ...
            'Padding', [0 0 0 0]);
        viewNames = {'side', 'front', 'rear'};
        viewAngles = {[0 0], [90 0], [-90 0]};
        viewPlaces = {[1 1 2], [1 3 3], [2 1 1]};   % (row, first and last column)
        limits = fcn_INTERNAL_dimensionLimits(data);
        viewAxes = gobjects(1,3);
        for ith_view = 1:3
            axesHandle = uiaxes(layout);
            hold(axesHandle, 'on');
            axis(axesHandle, 'off');
            axesHandle.Color = [1 1 1];
            axesHandle.Clipping = 'off';
            axesHandle.Layout.Row = viewPlaces{ith_view}(1);
            axesHandle.Layout.Column = unique(viewPlaces{ith_view}(2:3));
            % (the vehicle's own colors, faded, so the dimensions stand
            % out but the front, back, and windows can still be told apart)
            fadedColors = 0.45*data.Mesh.FaceColors + 0.55*[1 1 1];
            fcn_INTERNAL_drawMesh(axesHandle, data.Mesh, fadedColors, ones(size(data.Mesh.Faces,1),1));
            view(axesHandle, viewAngles{ith_view});
            axis(axesHandle, 'equal');
            set(axesHandle, 'XLim', limits(1,:), 'YLim', limits(2,:), 'ZLim', limits(3,:));
            camlight(axesHandle, 'headlight');
            set(findobj(axesHandle, '-property', 'Clipping'), 'Clipping', 'off');
            drawnow;
            if ith_view == 1
                camzoom(axesHandle, 1.5);   % (3D axes leave a wide margin)
            else
                camzoom(axesHandle, 1.2);   % (room above the roof for the widths)
            end
            fcn_INTERNAL_quietAxes(axesHandle);
            setappdata(axesHandle, 'mouse2D', true);   % (fixed views: dragging pans)
            axesHandle.Tag = viewNames{ith_view};
            title(axesHandle, fcn_INTERNAL_viewTitle(viewNames{ith_view}), 'Color', [0.55 0.55 0.55], 'FontWeight', 'normal');
            viewAxes(ith_view) = axesHandle;
            startViews{ith_view} = fcn_INTERNAL_getView(axesHandle);
        end
        shownTable = table(string(names), data.DimensionTable{:,2}, data.DimensionTable{:,3}, data.DimensionTable{:,4}, ...
            'VariableNames', {'Quantity', 'Target (m)', 'Measured (m)', 'Error (%)'});
        tableHandle = uitable(layout, 'Data', shownTable, 'RowName', {}, 'ColumnSortable', false, ...
            'ColumnWidth', {190, 90, 105, 80}, 'FontSize', 13, 'CellSelectionCallback', @onTableCell);
        tableHandle.Layout.Row = 2;
        tableHandle.Layout.Column = [2 3];
    end

    function onTableCell(~, event)
        if isempty(event.Indices)
            return;
        end
        quantity = quantities{event.Indices(1)};
        if ~isempty(options.OnSelect)
            options.OnSelect(quantity);
        elseif ~strcmp(quantity, shownQuantity)
            showDimension(quantity);
        end
    end

    function showDimension(quantity)
        % One dimension drawn, in the view it belongs to (its title bold),
        % and its row of the table in bold ('' for none)
        if isempty(viewAxes) || ~all(isvalid(viewAxes))
            return;
        end
        quantity = char(quantity);
        for ith_axes = 1:numel(viewAxes)
            delete(findobj(viewAxes(ith_axes), 'Tag', 'dimension'));
            title(viewAxes(ith_axes), fcn_INTERNAL_viewTitle(viewAxes(ith_axes).Tag), 'Color', [0.55 0.55 0.55], 'FontWeight', 'normal');
        end
        shownQuantity = '';
        rowIndex = find(strcmp(quantities, quantity), 1);
        if isempty(rowIndex)
            return;
        end
        shownQuantity = quantity;
        viewName = fcn_INTERNAL_drawDimension(viewAxes, data, rowIndex);
        thisAxes = findobj(viewAxes, 'Tag', viewName);
        if ~isempty(thisAxes)
            title(thisAxes(1), [fcn_INTERNAL_viewTitle(viewName) ':  ' upper(names{rowIndex})], ...
                'Color', [0 0 0], 'FontWeight', 'bold');
        end
        fcn_INTERNAL_styleDimensionTable(tableHandle, data.DimensionTable, rowIndex);
    end

    function quantity = getShown()
        quantity = shownQuantity;
    end

    function resetViews()
        for ith_view = 1:numel(startViews)
            if isvalid(viewAxes(ith_view))
                fcn_INTERNAL_setView(viewAxes(ith_view), startViews{ith_view});
            end
        end
    end

    function setHint(textIn)
        if ~isempty(options.OnHint)
            options.OnHint(textIn);
        elseif ~isempty(hintLabel) && isvalid(hintLabel)
            hintLabel.Text = strrep(textIn, '<br><br>', '  ');
        end
    end

    %% Its own window: the mouse (dragging pans, the wheel zooms), and closing
    function onOwnDown()
        mouseMode = '';
        clicked = figureHandle.CurrentObject;
        if isempty(clicked) || ~isvalid(clicked)
            return;
        end
        clickedAxes = ancestor(clicked, 'axes');
        if isempty(clickedAxes) || ~any(viewAxes == clickedAxes)
            return;
        end
        mouseAxes = clickedAxes;
        mouseMode = 'pan';
        mouseLast = figureHandle.CurrentPoint;
    end

    function onOwnMove()
        if isempty(mouseMode)
            return;
        end
        point = figureHandle.CurrentPoint;
        delta = point - mouseLast;
        mouseLast = point;
        camdolly(mouseAxes, -delta(1), -delta(2), 0, 'movetarget', 'pixels');
        drawnow limitrate;
    end

    function onOwnUp()
        mouseMode = '';
    end

    function onOwnScroll(~, event)
        % (the view under the mouse)
        point = figureHandle.CurrentPoint;
        for ith_view = 1:numel(viewAxes)
            if ~isvalid(viewAxes(ith_view))
                continue;
            end
            box = getpixelposition(viewAxes(ith_view), true);
            if point(1) >= box(1) && point(1) <= box(1)+box(3) && point(2) >= box(2) && point(2) <= box(2)+box(4)
                camzoom(viewAxes(ith_view), 1.15^(-event.VerticalScrollCount));
            end
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

%% fcn_INTERNAL_asDimensionTable
function dimensionTable = fcn_INTERNAL_asDimensionTable(tableIn)
% The dimensions as the reviewer keeps them: quantity, target, measured,
% error (%), pass (a ValidationTable is turned into this)
if isempty(tableIn)
    dimensionTable = table(strings(0,1), zeros(0,1), zeros(0,1), zeros(0,1), false(0,1));
elseif istable(tableIn) && any(strcmp(tableIn.Properties.VariableNames, 'Quantity'))
    dimensionTable = table(string(tableIn.Quantity), round(tableIn.Target_m,4), ...
        round(tableIn.Measured_m,4), round(tableIn.PercentError,2), logical(tableIn.Pass));
else
    dimensionTable = tableIn;
end
end % Ends fcn_INTERNAL_asDimensionTable

%% fcn_INTERNAL_drawDimension
function viewName = fcn_INTERNAL_drawDimension(allAxes, data, row)
% One dimension, drawn the way a drawing is dimensioned: the measured
% value (purple) and the target (blue), each a solid line with an arrow at
% both ends and its value written on top, and thin guide lines that run
% across the vehicle to check the fit. Everything is drawn in a plane in
% front of the vehicle (toward the camera), so the vehicle hides nothing.
% Returns the name of the view it is drawn in.
quantity = char(data.DimensionTable{row,1});
target = data.DimensionTable{row,2};
measured = data.DimensionTable{row,3};
geometry = data.Geometry;
low = geometry.Min;
high = geometry.Max;
vehicleLength = high(1) - low(1);
gap = 0.07*vehicleLength;                     % (between dimension lines)
colors = fcn_INTERNAL_dimensionColors();
measuredColor = colors.Measured;
targetColor = colors.Target;
flagMeasured = ~isnan(measured);
flagTarget = ~isnan(target);

frontAxleX = NaN; rearAxleX = NaN;
if numel(geometry.AxleX) >= 2
    frontAxleX = geometry.AxleX(1);
    rearAxleX = geometry.AxleX(end);
end
wheelCenters = geometry.WheelCenters;
roofZ = high(3);
if flagMeasured && strcmp(quantity, 'OverallHeight')
    roofZ = measured;                         % (the roof, not an antenna)
end

% Each view's plane: (u, v) on the screen -> 3D, in front of the vehicle
switch quantity
    case {'TrackFront', 'OverallWidth', 'WidthWithMirrors'}
        viewName = 'front';
    case 'TrackRear'
        viewName = 'rear';
    otherwise
        viewName = 'side';
end
switch viewName
    case 'side'   % (seen from the right: u = x, v = z)
        depth = low(2) - 0.3;
        toXYZ = @(u,v) [u(:), repmat(depth,numel(u),1), v(:)];
    case 'front'  % (seen from ahead: u = y, v = z)
        depth = high(1) + 0.3;
        toXYZ = @(u,v) [repmat(depth,numel(u),1), u(:), v(:)];
    case 'rear'   % (seen from behind: u = -y, v = z)
        depth = low(1) - 0.3;
        toXYZ = @(u,v) [repmat(depth,numel(u),1), -u(:), v(:)];
end
axesHandle = findobj(allAxes, 'Tag', viewName);
if isempty(axesHandle)
    return;
end
axesHandle = axesHandle(1);
arrowSize = 0.025*vehicleLength;
measuredText = sprintf('measured %.3f m', measured);
targetText = sprintf('target %.3f m', target);
    function horizontal(u1, u2, v, color, labelText)
        fcn_INTERNAL_dimensionArrow(axesHandle, toXYZ, [u1 v], [u2 v], color, labelText, arrowSize);
    end
    function vertical(u, v1, v2, color, labelText, textSide)
        % (textSide: -1 for text on the left, +1 on the right)
        fcn_INTERNAL_dimensionArrow(axesHandle, toXYZ, [u v1], [u v2], color, labelText, arrowSize, textSide);
    end
    function guide(u, v, color)
        % (a thin guide line from (u(1),v(1)) to (u(2),v(2)))
        points = toXYZ(u, v);
        plot3(axesHandle, points(:,1), points(:,2), points(:,3), '-', 'Color', [color 0.7], ...
            'LineWidth', 0.75, 'Tag', 'dimension', 'Clipping', 'off');
    end
    function ground()
        points = toXYZ([low(1)-gap high(1)+gap], [0 0]);
        if ~strcmp(viewName, 'side')
            points = toXYZ([low(2)-gap high(2)+gap], [0 0]);
        end
        plot3(axesHandle, points(:,1), points(:,2), points(:,3), '-', 'Color', [0.3 0.3 0.3], ...
            'LineWidth', 1.5, 'Tag', 'dimension', 'Clipping', 'off');
    end
over = 0.3*gap;                               % (guide lines pass the arrow a little)

switch quantity
    case 'OverallLength'
        % Below the vehicle: measured, then target; guides up over the roof
        vMeasured = -gap;
        vTarget = -2*gap;
        if flagMeasured
            horizontal(low(1), low(1)+measured, vMeasured, measuredColor, measuredText);
            guide([1 1]*low(1), [vMeasured-over roofZ], measuredColor);
            guide([1 1]*(low(1)+measured), [vMeasured-over roofZ], measuredColor);
        end
        if flagTarget
            horizontal(low(1), low(1)+target, vTarget, targetColor, targetText);
            guide([1 1]*low(1), [vTarget-over vMeasured], targetColor);
            guide([1 1]*(low(1)+target), [vTarget-over roofZ], targetColor);
        end
    case 'OverallHeight'
        % Ahead of the vehicle: measured, then target; guides back over it
        uMeasured = high(1) + gap;
        uTarget = high(1) + 2*gap;
        ground();
        if flagMeasured
            vertical(uMeasured, 0, measured, measuredColor, measuredText, -1);
            guide([low(1) uMeasured+over], [1 1]*measured, measuredColor);
        end
        if flagTarget
            vertical(uTarget, 0, target, targetColor, targetText, +1);
            guide([low(1) uTarget+over], [1 1]*target, targetColor);
        end
    case {'Wheelbase', 'FrontOverhang'}
        % Above the roof: measured, then target; guides down to the ground
        % through the wheel centers (and the front, for the overhang)
        if isnan(frontAxleX)
            return;
        end
        vMeasured = roofZ + gap;
        vTarget = roofZ + 2*gap;
        if strcmp(quantity, 'Wheelbase')
            startX = rearAxleX;
        else
            startX = frontAxleX;
        end
        if flagMeasured
            horizontal(startX, startX+measured, vMeasured, measuredColor, measuredText);
            guide([1 1]*startX, [0 vMeasured+over], measuredColor);
            guide([1 1]*(startX+measured), [0 vMeasured+over], measuredColor);
        end
        if flagTarget
            horizontal(startX, startX+target, vTarget, targetColor, targetText);
            guide([1 1]*startX, [vMeasured vTarget+over], targetColor);
            guide([1 1]*(startX+target), [0 vTarget+over], targetColor);
        end
    case 'GroundClearance'
        % Between the axles: measured, then target, up from the ground;
        % guides along the whole length at each height
        if isnan(frontAxleX)
            middleX = (low(1)+high(1))/2;
        else
            middleX = (frontAxleX+rearAxleX)/2;
        end
        ground();
        uMeasured = middleX - gap;
        uTarget = middleX + gap;
        if flagMeasured
            vertical(uMeasured, 0, measured, measuredColor, measuredText, -1);
            guide([low(1) high(1)], [1 1]*measured, measuredColor);
        end
        if flagTarget
            vertical(uTarget, 0, target, targetColor, targetText, +1);
            guide([low(1) high(1)], [1 1]*target, targetColor);
        end
    case {'TireDiameter', 'TireDiameterRear', 'TireRoundMin', 'TireRoundMax'}
        % Circles on the wheel (the front wheel; the rear for the rear
        % tire), and their diameters beside it, with guides at the top and
        % bottom of each circle
        if isempty(wheelCenters)
            return;
        end
        if strcmp(quantity, 'TireDiameterRear')
            [~, wheelIndex] = min(wheelCenters(:,1));
        else
            [~, wheelIndex] = max(wheelCenters(:,1));
        end
        center = wheelCenters(wheelIndex,:);
        angles = linspace(0, 2*pi, 145);
        biggest = max([target measured], [], 'omitnan')/2;
        uMeasured = center(1) - biggest - 0.6*gap;   % (left of the wheel)
        uTarget = center(1) + biggest + 0.6*gap;     % (right of the wheel)
        if flagMeasured
            points = toXYZ(center(1) + measured/2*cos(angles), center(3) + measured/2*sin(angles));
            plot3(axesHandle, points(:,1), points(:,2), points(:,3), '-', 'Color', measuredColor, ...
                'LineWidth', 2, 'Tag', 'dimension', 'Clipping', 'off');
            vertical(uMeasured, center(3)-measured/2, center(3)+measured/2, measuredColor, measuredText, -1);
            guide([center(1) uMeasured-over], [1 1]*(center(3)+measured/2), measuredColor);
            guide([center(1) uMeasured-over], [1 1]*(center(3)-measured/2), measuredColor);
        end
        if flagTarget
            points = toXYZ(center(1) + target/2*cos(angles), center(3) + target/2*sin(angles));
            plot3(axesHandle, points(:,1), points(:,2), points(:,3), '-', 'Color', targetColor, ...
                'LineWidth', 2, 'Tag', 'dimension', 'Clipping', 'off');
            vertical(uTarget, center(3)-target/2, center(3)+target/2, targetColor, targetText, +1);
            guide([center(1) uTarget+over], [1 1]*(center(3)+target/2), targetColor);
            guide([center(1) uTarget+over], [1 1]*(center(3)-target/2), targetColor);
        end
    case 'WidthWithMirrors'
        % Above the roof: measured, then target (centered); guides down
        vMeasured = roofZ + gap;
        vTarget = roofZ + 2*gap;
        if flagMeasured
            horizontal(low(2), low(2)+measured, vMeasured, measuredColor, measuredText);
            guide([1 1]*low(2), [0 vMeasured+over], measuredColor);
            guide([1 1]*(low(2)+measured), [0 vMeasured+over], measuredColor);
        end
        if flagTarget
            middleY = (low(2)+high(2))/2;
            horizontal(middleY-target/2, middleY+target/2, vTarget, targetColor, targetText);
            guide([1 1]*(middleY-target/2), [0 vTarget+over], targetColor);
            guide([1 1]*(middleY+target/2), [0 vTarget+over], targetColor);
        end
    case 'OverallWidth'
        % Above the roof, the target only (centered); guides down to the
        % ground, for the body (without mirrors) to fit between
        if flagTarget
            vTarget = roofZ + gap;
            middleY = (low(2)+high(2))/2;
            horizontal(middleY-target/2, middleY+target/2, vTarget, targetColor, targetText);
            guide([1 1]*(middleY-target/2), [0 vTarget+over], targetColor);
            guide([1 1]*(middleY+target/2), [0 vTarget+over], targetColor);
        end
    case {'TrackFront', 'TrackRear'}
        % Below the ground: measured, then target (centered on the
        % wheels); guides up through the wheel centers
        if size(wheelCenters,1) < 4
            return;
        end
        if strcmp(quantity, 'TrackFront')
            pair = wheelCenters(wheelCenters(:,1) > mean(wheelCenters(:,1)), :);
            uPair = pair(:,2);                % (front view: u = y)
        else
            pair = wheelCenters(wheelCenters(:,1) <= mean(wheelCenters(:,1)), :);
            uPair = -pair(:,2);               % (rear view: u = -y)
        end
        uPair = sort(uPair);
        centerZ = mean(pair(:,3));
        vMeasured = -gap;
        vTarget = -2*gap;
        if flagMeasured
            horizontal(uPair(1), uPair(1)+measured, vMeasured, measuredColor, measuredText);
            guide([1 1]*uPair(1), [vMeasured-over centerZ+0.5*gap], measuredColor);
            guide([1 1]*(uPair(1)+measured), [vMeasured-over centerZ+0.5*gap], measuredColor);
        end
        if flagTarget
            middleU = mean(uPair);
            horizontal(middleU-target/2, middleU+target/2, vTarget, targetColor, targetText);
            guide([1 1]*(middleU-target/2), [vTarget-over centerZ+0.5*gap], targetColor);
            guide([1 1]*(middleU+target/2), [vTarget-over centerZ+0.5*gap], targetColor);
        end
    otherwise
        return;
end
end % Ends fcn_INTERNAL_drawDimension

%% fcn_INTERNAL_dimensionArrow
function fcn_INTERNAL_dimensionArrow(axesHandle, toXYZ, pointA, pointB, color, labelText, arrowSize, textSide)
% A dimension line from A to B (2D, in the view's plane): solid, with a
% filled arrowhead at each end and its text on top of the line, centered.
% A long vertical line has its text on its left, reading upward; a short
% one (shorter than its text) has level text beside its middle, on the
% side given (textSide: -1 left, +1 right).
if nargin < 8
    textSide = -1;
end
direction = pointB - pointA;
lineLength = norm(direction);
if lineLength <= 0 || any(isnan([pointA pointB]))
    return;
end
direction = direction/lineLength;
if direction(1) < -1e-9 || (abs(direction(1)) <= 1e-9 && direction(2) < 0)
    % (so that the text reads left to right, or upward)
    [pointA, pointB] = deal(pointB, pointA);
    direction = -direction;
end
normal = [-direction(2) direction(1)];        % (to the left of the line: up, for a level line)
headLength = min(arrowSize, 0.3*lineLength);
headWidth = 0.35*headLength;
points = toXYZ([pointA(1) pointB(1)], [pointA(2) pointB(2)]);
plot3(axesHandle, points(:,1), points(:,2), points(:,3), '-', 'Color', color, 'LineWidth', 2, ...
    'Tag', 'dimension', 'Clipping', 'off');
for tip = {pointA, pointB}
    tipPoint = tip{1};
    inward = direction;
    if isequal(tipPoint, pointB)
        inward = -direction;
    end
    base = tipPoint + headLength*inward;
    corners = [tipPoint; base + headWidth*normal; base - headWidth*normal];
    cornerPoints = toXYZ(corners(:,1), corners(:,2));
    patch(axesHandle, 'XData', cornerPoints(:,1), 'YData', cornerPoints(:,2), 'ZData', cornerPoints(:,3), ...
        'FaceColor', color, 'EdgeColor', color, 'Tag', 'dimension', 'Clipping', 'off', 'FaceLighting', 'none');
end
flagVertical = abs(direction(1)) < 1e-6;
textLength = (arrowSize/0.025)*0.3*numel(labelText)/16;   % (16 letters: about 0.3 of the vehicle's length)
if flagVertical && lineLength < textLength
    % (level text beside the middle of a short vertical line)
    middle = (pointA + pointB)/2 + [textSide*0.3*arrowSize 0];
    middlePoint = toXYZ(middle(1), middle(2));
    if textSide < 0
        alignment = 'right';
    else
        alignment = 'left';
    end
    text(axesHandle, middlePoint(1), middlePoint(2), middlePoint(3), labelText, 'Color', color, ...
        'FontWeight', 'bold', 'FontSize', 11, 'HorizontalAlignment', alignment, 'VerticalAlignment', 'middle', ...
        'BackgroundColor', [1 1 1 0.75], 'Margin', 1, 'Tag', 'dimension', 'Clipping', 'off');
    return;
end
middle = (pointA + pointB)/2 + 0.15*arrowSize*normal;
middlePoint = toXYZ(middle(1), middle(2));
text(axesHandle, middlePoint(1), middlePoint(2), middlePoint(3), labelText, 'Color', color, ...
    'FontWeight', 'bold', 'FontSize', 11, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'Rotation', atan2d(direction(2), direction(1)), 'BackgroundColor', [1 1 1 0.75], 'Margin', 1, ...
    'Tag', 'dimension', 'Clipping', 'off');
end % Ends fcn_INTERNAL_dimensionArrow

%% fcn_INTERNAL_dimensionColors
function colors = fcn_INTERNAL_dimensionColors()
% The colors of the dimensions and of the table
colors.Target = [0 0.35 0.9];        % blue
colors.Measured = [0.55 0.1 0.65];   % purple
colors.Pass = [0 0.55 0];            % green (the selected row's error)
colors.Fail = [0.85 0 0];            % red
colors.PassLight = [0.45 0.75 0.45]; % (the other rows' errors)
colors.FailLight = [0.95 0.5 0.5];
colors.Gray = [0.7 0.7 0.7];         % (the other rows' text)
end % Ends fcn_INTERNAL_dimensionColors

%% fcn_INTERNAL_styleDimensionTable
function fcn_INTERNAL_styleDimensionTable(tableHandle, dimensionTable, selectedRow)
% The other rows light gray (their errors light green or light red); the
% selected row bold: the quantity black, the target blue, the measured
% purple, the error green or red
if isempty(tableHandle) || ~isvalid(tableHandle)
    return;
end
colors = fcn_INTERNAL_dimensionColors();
removeStyle(tableHandle);
Nrows = height(dimensionTable);
addStyle(tableHandle, uistyle('FontColor', colors.Gray));   % (the whole table)
percentErrors = dimensionTable{:,4};
flagPass = dimensionTable{:,5};
passRows = find(flagPass & ~isnan(percentErrors));
failRows = find(~flagPass & ~isnan(percentErrors));
if ~isempty(passRows)
    addStyle(tableHandle, uistyle('FontColor', colors.PassLight), 'cell', [passRows, 4*ones(numel(passRows),1)]);
end
if ~isempty(failRows)
    addStyle(tableHandle, uistyle('FontColor', colors.FailLight), 'cell', [failRows, 4*ones(numel(failRows),1)]);
end
if selectedRow < 1 || selectedRow > Nrows
    return;
end
addStyle(tableHandle, uistyle('FontColor', [0 0 0], 'FontWeight', 'bold', 'BackgroundColor', [1 0.97 0.8]), 'row', selectedRow);
addStyle(tableHandle, uistyle('FontColor', colors.Target), 'cell', [selectedRow 2]);
addStyle(tableHandle, uistyle('FontColor', colors.Measured), 'cell', [selectedRow 3]);
if ~isnan(percentErrors(selectedRow))
    if flagPass(selectedRow)
        addStyle(tableHandle, uistyle('FontColor', colors.Pass), 'cell', [selectedRow 4]);
    else
        addStyle(tableHandle, uistyle('FontColor', colors.Fail), 'cell', [selectedRow 4]);
    end
end
try
    scroll(tableHandle, 'row', selectedRow);
catch
    % (older MATLAB: no scrolling)
end
drawnow;
end % Ends fcn_INTERNAL_styleDimensionTable

%% fcn_INTERNAL_dimensionName
function name = fcn_INTERNAL_dimensionName(quantity, dimensionTable)
% A quantity's name in words. With different front and rear tires (a
% TireDiameterRear row), the tire diameter is the front's.
quantity = char(quantity);
flagStaggered = any(dimensionTable{:,1}=="TireDiameterRear");
switch quantity
    case 'OverallWidth',     name = 'Overall width (body)';
    case 'TrackFront',       name = 'Track, front';
    case 'TrackRear',        name = 'Track, rear';
    case 'TireRoundMin',     name = 'Tire roundness, smallest';
    case 'TireRoundMax',     name = 'Tire roundness, largest';
    case 'TireDiameterRear', name = 'Tire diameter, rear';
    case 'TireDiameter'
        name = 'Tire diameter';
        if flagStaggered
            name = 'Tire diameter, front';
        end
    otherwise
        name = fcn_INTERNAL_words(quantity);
end
end % Ends fcn_INTERNAL_dimensionName

%% fcn_INTERNAL_viewTitle
function titleText = fcn_INTERNAL_viewTitle(viewName)
switch viewName
    case 'side',  titleText = 'SIDE VIEW';
    case 'front', titleText = 'FRONT VIEW (from ahead)';
    case 'rear',  titleText = 'REAR VIEW (from behind)';
    otherwise,    titleText = upper(viewName);
end
end % Ends fcn_INTERNAL_viewTitle

%% fcn_INTERNAL_dimensionLimits
function limits = fcn_INTERNAL_dimensionLimits(data)
% Fixed axes limits for the dimension views, with room for every
% dimension, so the view does not jump from one item to the next
low = data.Geometry.Min;
high = data.Geometry.Max;
vehicleLength = high(1) - low(1);
gap = 0.07*vehicleLength;
targets = data.DimensionTable{:,2};
biggestWidth = max([high(2)-low(2); targets(ismember(data.DimensionTable{:,1}, ["OverallWidth","WidthWithMirrors"]))], [], 'omitnan');
limits = [low(1)-3*gap-0.4, high(1)+3*gap+0.4;
    -biggestWidth/2-gap-0.4, biggestWidth/2+gap+0.4;
    -3.3*gap, high(3)+3.3*gap];
limits(1,2) = max(limits(1,2), low(1) + max(targets,[],'omitnan') + gap);
end % Ends fcn_INTERNAL_dimensionLimits


%% fcn_INTERNAL_words
function words = fcn_INTERNAL_words(name)
% 'WidthWithMirrors' -> 'Width with mirrors'
words = regexprep(char(name), '([a-z])([A-Z])', '$1 $2');
words = [words(1) lower(words(2:end))];
end % Ends fcn_INTERNAL_words

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

%% fcn_INTERNAL_geometry
function geometry = fcn_INTERNAL_geometry(vehicleMesh)
% Extents, and each wheel's center and diameter (from its faces)
vertices = vehicleMesh.Vertices;
geometry.Min = min(vertices,[],1);
geometry.Max = max(vertices,[],1);
geometry.WheelCenters = nan(0,3);
geometry.WheelDiameters = nan(0,1);
if isfield(vehicleMesh, 'FaceWheelIndex')
    wheelNumbers = unique(vehicleMesh.FaceWheelIndex(vehicleMesh.FaceWheelIndex>0));
    for ith_wheel = 1:numel(wheelNumbers)
        wheelVertices = vertices(unique(vehicleMesh.Faces(vehicleMesh.FaceWheelIndex==wheelNumbers(ith_wheel),:)),:);
        boxMin = min(wheelVertices,[],1);
        boxMax = max(wheelVertices,[],1);
        geometry.WheelCenters(end+1,:) = (boxMin+boxMax)/2;
        geometry.WheelDiameters(end+1,1) = boxMax(3) - boxMin(3);
    end
end
geometry.AxleX = [];
if isfield(vehicleMesh, 'AxleX')
    geometry.AxleX = sort(vehicleMesh.AxleX(:), 'descend');   % front first
elseif ~isempty(geometry.WheelCenters)
    geometry.AxleX = sort(uniquetol(geometry.WheelCenters(:,1), 0.05), 'descend');
end
end % Ends fcn_INTERNAL_geometry
