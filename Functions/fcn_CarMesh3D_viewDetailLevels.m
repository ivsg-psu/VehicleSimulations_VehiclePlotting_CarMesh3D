function viewer = fcn_CarMesh3D_viewDetailLevels(vehicleInput, options)
% fcn_CarMesh3D_viewDetailLevels

% A view for checking a vehicle's detail levels (from
% fcn_CarMesh3D_makeDetailLevels). Top: the full mesh and every detail
% level in a line, all at one distance (a line-up, to compare them side
% by side). Bottom: each level beside the full mesh at the distance where
% that level is first used, through the animations' camera (645 pixels
% per radian: what an animation would show). Every vehicle turns slowly,
% in both. It works on its own (its own window), or inside another
% window, such as the Model Reviewer (fcn_CarMesh3D_reviewVehicle), which
% gives it a panel to build into.
%
% FORMAT:
%
%       viewer = fcn_CarMesh3D_viewDetailLevels(vehicleInput,...
%           (Mesh=vehicleMesh), (Parent=container), (FlagTurn=flag),...
%           (OnHint=function), (FlagVisible=flag), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport'), or detail
%      levels (fcn_CarMesh3D_makeDetailLevels's output: Levels,
%      SizeDiagonal, BoxCenter, BoxSize). With an ID, the levels and the
%      full mesh are the vehicle's files.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Mesh: the full mesh, shown beside the levels. Needed with detail
%      levels given; with an ID, the default is the vehicle's mesh file.
%
%      Parent: a panel or grid to build into; [] (default) for a window of
%      its own.
%
%      FlagTurn: true (default) to turn every vehicle slowly (20 degrees a
%      second).
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
%           Figure, LineupAxes, SceneAxes, Transforms (one per vehicle
%               shown, each turning about its own middle)
%           StartTurning(), Stop(), IsTurning()
%           ResetViews(): both views as they were made
%           Close(): close its own window
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles
%
% EXAMPLES:
%
%       viewer = fcn_CarMesh3D_viewDetailLevels('2009_Honda_Fit_Sport');
%
%       See the script: script_test_fcn_CarMesh3D_viewDetailLevels.m for a
%       full test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewDetailLevels
%   % * First write: the Model Reviewer's detail-levels check, taken out
%   %   % into a function of its own (Sean, 06:00: separate panels, so the
%   %   % passing of the mesh is clear and each is easier to debug)
%   % * Its own window's title is this function's name, with the
%   %   % file's last change (its version) under it (fcn_CarMesh3D_addTitleBar;
%   %   % Sean, 14:31 and 14:40)
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewDetailLevels
%   % * The mouse is fcn_CarMesh3D_addCadMouse (one copy of the CAD-style
%   %   % mouse for every viewer; Sean, 03:15), in place of its own
%   %   % (drafted with Claude)

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_viewDetailLevels
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleInput
    options.Mesh = []           % The full mesh; [] for the vehicle's mesh file (an ID)
    options.Parent = []         % Panel or grid to build into; [] for a window of its own
    options.FlagTurn = true         % Turn every vehicle slowly
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
    debug_figNum = 999975; %#ok<NASGU>
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
                (isstruct(vehicleInput) && all(isfield(vehicleInput, {'Levels','SizeDiagonal','BoxCenter','BoxSize'}))))
            error('vehicleInput must be a vehicle ID or detail levels (Levels, SizeDiagonal, BoxCenter, BoxSize)');
        end
        if isstruct(vehicleInput) && isempty(options.Mesh)
            error('With detail levels given, Mesh (the full mesh) is needed');
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

%%%% The levels and the full mesh
data = struct('Levels', [], 'Mesh', options.Mesh);
vehicleName = 'detail levels';
if ischar(vehicleInput) || isstring(vehicleInput)
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
    vehicleName = vehicleFiles.Name;
    if vehicleFiles.HasLevels
        loaded = load(vehicleFiles.LevelsFile, 'detailLevels');
        data.Levels = loaded.detailLevels;
    end
    if isempty(data.Mesh)
        loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
        data.Mesh = loaded.vehicleMesh;
    end
else
    data.Levels = vehicleInput;
end

%%%% The window (or the parent given)
flagOwnWindow = isempty(options.Parent);
figureHandle = [];
hintLabel = [];
lineupAxes = [];
sceneAxes = [];
allTransforms = gobjects(0,1);
turnTimer = [];
turnStart = [];
startViews = {};
if flagOwnWindow
    visibleText = 'on';
    if ~options.FlagVisible
        visibleText = 'off';
    end
    figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_viewDetailLevels: %s', vehicleName), 'Position', [100 80 1300 860], ...
        'Visible', visibleText);
    % (the title bar: this function's name and version; the rest under it)
    contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_viewDetailLevels', Subtitle=vehicleName, FigNum=-1);
    rootGrid = uigridlayout(contentPanel, [2 2], 'ColumnWidth', {'1x', 150}, 'RowHeight', {'1x', 44}, ...
        'Padding', [6 6 6 6], 'ColumnSpacing', 6, 'RowSpacing', 4);
    parent = uipanel(rootGrid, 'BorderType', 'none');
    parent.Layout.Row = 1;
    parent.Layout.Column = 1;
else
    parent = options.Parent;
end

if isempty(data.Levels)
    uilabel(uigridlayout(parent, [1 1]), 'Text', 'No detail levels yet.', 'HorizontalAlignment', 'center');
else
    buildViews();
end

if flagOwnWindow
    sideGrid = uigridlayout(rootGrid, [4 1], 'RowHeight', {30, 30, 30, '1x'}, 'Padding', [0 0 0 0]);
    sideGrid.Layout.Row = 1;
    sideGrid.Layout.Column = 2;
    uibutton(sideGrid, 'state', 'Text', 'Turning', 'Value', options.FlagTurn && ~isempty(turnTimer), ...
        'ValueChangedFcn', @(source,~) onTurnButton(source), 'Tag', 'turnButton');
    uibutton(sideGrid, 'Text', 'Reset views', 'ButtonPushedFcn', @(~,~) resetViews());
    uibutton(sideGrid, 'Text', 'Close', 'ButtonPushedFcn', @(~,~) closeViewer());
    hintLabel = uilabel(rootGrid, 'Text', '', 'Interpreter', 'html', 'WordWrap', 'on', 'FontColor', [0.25 0.25 0.25]);
    hintLabel.Layout.Row = 2;
    hintLabel.Layout.Column = [1 2];
    set(figureHandle, 'CloseRequestFcn', @(~,~) closeViewer());
    % (the CAD mouse: left-drag turns, right-drag pans, the wheel zooms the
    % view under the pointer; a flat view pans: fcn_CarMesh3D_addCadMouse)
    mouseAxes = [lineupAxes, sceneAxes];
    mouseAxes = mouseAxes(arrayfun(@(h) isgraphics(h), mouseAxes));
    if ~isempty(mouseAxes)
        fcn_CarMesh3D_addCadMouse(mouseAxes, FigNum=-1);
    end
end
if ~isempty(lineupAxes)
    setHint(['Every vehicle turns slowly.<br><br>Top: rotate (left-drag) and zoom (wheel) freely.<br><br>' ...
        'Bottom: at this size, the screen shows what an animation would; zooming in shows more than it would.']);
end

viewer = struct('Figure', figureHandle, 'LineupAxes', lineupAxes, 'SceneAxes', sceneAxes, 'Transforms', allTransforms, ...
    'StartTurning', @startTurning, 'Stop', @stopTurning, 'IsTurning', @isTurning, ...
    'ResetViews', @resetViews, 'Close', @closeViewer);
if flagOwnWindow
    figureHandle.UserData = viewer;
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the view's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function buildViews()
        layout = uigridlayout(parent, [4 1], 'RowHeight', {24, '1x', 24, '1x'}, 'Padding', [0 0 0 0], 'RowSpacing', 2);
        uilabel(layout, 'Text', '  LINE-UP: the full mesh and each detail level, all at the same distance', ...
            'BackgroundColor', [0.86 0.92 1], 'FontWeight', 'bold', 'FontSize', 14);
        lineupAxes = uiaxes(layout);
        hold(lineupAxes, 'on');
        axis(lineupAxes, 'off');
        lineupAxes.Clipping = 'off';
        lineupTransforms = fcn_INTERNAL_drawLevelLineup(lineupAxes, data);
        view(lineupAxes, 80, 12);   % (from ahead and a little to the side: the line runs across the view)
        axis(lineupAxes, 'equal');
        axis(lineupAxes, 'vis3d');
        set(findobj(lineupAxes, '-property', 'Clipping'), 'Clipping', 'off');
        camlight(lineupAxes, 'headlight');
        fcn_INTERNAL_quietAxes(lineupAxes);
        camzoom(lineupAxes, 2.6);   % (the line fills the view's width)
        lineupAxes.Color = [1 1 1];
        uilabel(layout, 'Text', ['  WHERE EACH IS USED: each level (right of each pair) beside the full mesh, at the distance ' ...
            'where that level is first used, through the animations'' camera'], ...
            'BackgroundColor', [0.86 0.92 1], 'FontWeight', 'bold', 'FontSize', 14);
        sceneAxes = uiaxes(layout);
        hold(sceneAxes, 'on');
        axis(sceneAxes, 'off');
        sceneAxes.Clipping = 'off';
        sceneAxes.Color = [0.86 0.92 1];
        sceneTransforms = fcn_INTERNAL_drawLevelScene(sceneAxes, data);
        set(findobj(sceneAxes, '-property', 'Clipping'), 'Clipping', 'off');
        fcn_INTERNAL_quietAxes(sceneAxes);
        setappdata(sceneAxes, 'mouse2D', true);   % (a fixed view: dragging pans)
        drawnow;
        fcn_INTERNAL_setLevelCamera(sceneAxes);
        startViews = {fcn_INTERNAL_getView(lineupAxes), fcn_INTERNAL_getView(sceneAxes)};
        allTransforms = [lineupTransforms; sceneTransforms];
        % (the timer stops when the views are deleted, as when the reviewer
        % clears its panel)
        lineupAxes.DeleteFcn = @(~,~) stopTurning();
        if options.FlagTurn
            startTurning();
        end
    end

    %% Turning
    function startTurning()
        stopTurning();
        if isempty(allTransforms)
            return;
        end
        if isempty(turnStart)
            turnStart = tic;
        end
        turnTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', 0.1, 'BusyMode', 'drop', ...
            'TimerFcn', @(~,~) turnLevels());
        start(turnTimer);
    end

    function turnLevels()
        % (20 degrees a second, each vehicle about its own middle)
        if isempty(allTransforms) || ~all(isvalid(allTransforms))
            stopTurning();
            return;
        end
        angle = deg2rad(20*toc(turnStart));
        for ith_transform = 1:numel(allTransforms)
            center = getappdata(allTransforms(ith_transform), 'center');
            allTransforms(ith_transform).Matrix = makehgtform('translate', center, 'zrotate', angle, 'translate', -center);
        end
        drawnow limitrate;
    end

    function stopTurning()
        if ~isempty(turnTimer) && isvalid(turnTimer)
            stop(turnTimer);
            delete(turnTimer);
        end
        turnTimer = [];
    end

    function flag = isTurning()
        flag = ~isempty(turnTimer) && isvalid(turnTimer) && strcmp(turnTimer.Running, 'on');
    end

    function onTurnButton(source)
        if source.Value
            startTurning();
        else
            stopTurning();
        end
    end

    %% Views
    function resetViews()
        % Both views as they were made
        if isempty(startViews)
            return;
        end
        viewAxes = {lineupAxes, sceneAxes};
        for ith_view = 1:2
            if isvalid(viewAxes{ith_view})
                fcn_INTERNAL_setView(viewAxes{ith_view}, startViews{ith_view});
            end
        end
    end

    function setHint(textIn)
        if ~isempty(options.OnHint)
            options.OnHint(textIn);
        elseif ~isempty(hintLabel) && isvalid(hintLabel)
            hintLabel.Text = strrep(textIn, '<br><br>', ' ');
        end
    end

    function closeViewer()
        stopTurning();
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

%% fcn_INTERNAL_drawLevelScene
function transforms = fcn_INTERNAL_drawLevelScene(axesHandle, data)
% Each detail level beside the full mesh, at the distance where that
% level is first used (its largest screen size, at 645 pixels per radian:
% 40 degrees across 450 pixels), seen from the camera at the origin
levels = data.Levels;
pixelsPerRadian = 450/deg2rad(40);
yaw = deg2rad(-35);
rotation = [cos(yaw) -sin(yaw) 0; sin(yaw) cos(yaw) 0; 0 0 1];
Nlevels = numel(levels.Levels);
fullMesh = data.Mesh;
ground = 0;
transforms = gobjects(0,1);
for ith_level = 1:Nlevels
    level = levels.Levels(ith_level);
    distance = levels.SizeDiagonal*pixelsPerRadian/level.MaxScreenSize;
    % (the pairs fanned out across the view, nearest on the left, so none
    % stands in front of another)
    bearing = deg2rad(32 - 64*(ith_level-1)/max(1,Nlevels-1));
    center = distance*[cos(bearing) sin(bearing) 0];
    gap = 0.75*levels.SizeDiagonal*[ -sin(bearing) cos(bearing) 0];
    levelMesh = level.Mesh;
    if ~isstruct(levelMesh)
        % (the farthest level is a box in the body's color)
        levelMesh = fcn_INTERNAL_boxMesh(levels.BoxCenter, levels.BoxSize, fullMesh);
    end
    meshes = {fullMesh, levelMesh};
    places = [center + gap; center - gap];
    for ith_mesh = 1:2
        thisMesh = meshes{ith_mesh};
        vertices = thisMesh.Vertices - [mean([min(thisMesh.Vertices(:,1:2));max(thisMesh.Vertices(:,1:2))]) 0];
        vertices = (rotation*vertices')' + places(ith_mesh,:);
        faceColors = [0.6 0.6 0.6];
        if isfield(thisMesh, 'FaceColors') && ~isempty(thisMesh.FaceColors)
            faceColors = thisMesh.FaceColors;
        end
        if size(faceColors,1) == 1
            faceColors = repmat(faceColors, size(thisMesh.Faces,1), 1);
        end
        transforms(end+1,1) = hgtransform('Parent', axesHandle); %#ok<AGROW>
        setappdata(transforms(end), 'center', [places(ith_mesh,1:2) 0]);   % (each turns about its own middle)
        patch('Parent', transforms(end), 'Faces', thisMesh.Faces, 'Vertices', vertices, 'FaceVertexCData', faceColors, ...
            'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceLighting', 'flat', 'Clipping', 'off');
    end
    text(axesHandle, center(1), center(2), ground + 1.4*levels.SizeDiagonal/2 + 0.6, ...
        sprintf('%d: %d faces, %.0f m', ith_level, level.Faces, distance), 'HorizontalAlignment', 'center', ...
        'FontSize', 9, 'Tag', 'levelText', 'UserData', ith_level, 'Color', [0.2 0.2 0.2], 'Clipping', 'off');
end
lastDistance = levels.SizeDiagonal*pixelsPerRadian/levels.Levels(end).MaxScreenSize;
patch(axesHandle, [0 1.2*lastDistance 1.2*lastDistance 0], 0.5*lastDistance*[-1 -1 1 1], -0.01*[1 1 1 1], ...
    [0.80 0.86 0.78], 'EdgeColor', 'none', 'Clipping', 'off', 'FaceLighting', 'none');
light(axesHandle, 'Position', [-1 -0.5 1], 'Style', 'infinite');
end % Ends fcn_INTERNAL_drawLevelScene

%% fcn_INTERNAL_drawLevelLineup
function transforms = fcn_INTERNAL_drawLevelLineup(axesHandle, data)
% The full mesh and each detail level in one line, side by side, all at
% the same distance, each named under it with its number of faces; each
% in its own transform, to turn about its own middle
levels = data.Levels;
meshes = {data.Mesh};
names = {sprintf('Full mesh\n%d faces', size(data.Mesh.Faces,1))};
for ith_level = 1:numel(levels.Levels)
    level = levels.Levels(ith_level);
    levelMesh = level.Mesh;
    if ~isstruct(levelMesh)
        levelMesh = fcn_INTERNAL_boxMesh(levels.BoxCenter, levels.BoxSize, data.Mesh);
    end
    meshes{end+1} = levelMesh; %#ok<AGROW>
    names{end+1} = sprintf('Level %d\n%d faces', ith_level, level.Faces); %#ok<AGROW>
end
spacing = 1.1*levels.SizeDiagonal;
transforms = gobjects(numel(meshes),1);
for ith_mesh = 1:numel(meshes)
    thisMesh = meshes{ith_mesh};
    place = [0, -(ith_mesh-1)*spacing, 0];
    vertices = thisMesh.Vertices - [mean([min(thisMesh.Vertices(:,1:2)); max(thisMesh.Vertices(:,1:2))]) 0] + place;
    faceColors = [0.6 0.6 0.6];
    if isfield(thisMesh, 'FaceColors') && ~isempty(thisMesh.FaceColors)
        faceColors = thisMesh.FaceColors;
    end
    if size(faceColors,1) == 1
        faceColors = repmat(faceColors, size(thisMesh.Faces,1), 1);
    end
    faceAlpha = ones(size(thisMesh.Faces,1),1);
    if isfield(thisMesh, 'FaceAlpha') && numel(thisMesh.FaceAlpha) == size(thisMesh.Faces,1)
        faceAlpha = thisMesh.FaceAlpha(:);
    end
    transforms(ith_mesh) = hgtransform('Parent', axesHandle);
    setappdata(transforms(ith_mesh), 'center', place);
    patch('Parent', transforms(ith_mesh), 'Faces', thisMesh.Faces, 'Vertices', vertices, 'FaceVertexCData', faceColors, ...
        'FaceColor', 'flat', 'FaceVertexAlphaData', faceAlpha, 'FaceAlpha', 'flat', 'AlphaDataMapping', 'none', ...
        'EdgeColor', 'none', 'FaceLighting', 'flat', 'Clipping', 'off');
    text(axesHandle, place(1), place(2), -0.35*levels.SizeDiagonal, names{ith_mesh}, 'HorizontalAlignment', 'center', ...
        'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2], 'Clipping', 'off');
end
end % Ends fcn_INTERNAL_drawLevelLineup

%% fcn_INTERNAL_boxMesh
function boxMesh = fcn_INTERNAL_boxMesh(boxCenter, boxSize, fullMesh)
% A box mesh (12 triangles) in the most common body color
corners = boxCenter + 0.5*boxSize.*[-1 -1 -1; 1 -1 -1; 1 1 -1; -1 1 -1; -1 -1 1; 1 -1 1; 1 1 1; -1 1 1];
faces = [1 2 3; 1 3 4; 5 6 7; 5 7 8; 1 2 6; 1 6 5; 2 3 7; 2 7 6; 3 4 8; 3 8 7; 4 1 5; 4 5 8];
bodyColor = [0.5 0.5 0.5];
if isfield(fullMesh, 'FaceColors') && ~isempty(fullMesh.FaceColors)
    [uniqueColors, ~, colorIndex] = unique(round(fullMesh.FaceColors*50)/50, 'rows');
    bodyColor = uniqueColors(mode(colorIndex),:);
end
boxMesh = struct('Vertices', corners, 'Faces', faces, 'FaceColors', repmat(bodyColor, 12, 1));
end % Ends fcn_INTERNAL_boxMesh

%% fcn_INTERNAL_setLevelCamera
function fcn_INTERNAL_setLevelCamera(axesHandle)
% The camera at eye height at the origin, looking down the line of pairs,
% with a view angle that gives 645 pixels per radian on this axes
axis(axesHandle, 'equal');
axesHandle.Projection = 'perspective';
axesHandle.CameraPosition = [0 0 1.5];
axesHandle.CameraTarget = [100 0 1.0];
axesHandle.CameraUpVector = [0 0 1];
oldUnits = axesHandle.Units;
axesHandle.Units = 'pixels';
axesSize = axesHandle.InnerPosition(3:4);
axesHandle.Units = oldUnits;
pixelsPerRadian = 450/deg2rad(40);
axesHandle.CameraViewAngle = rad2deg(2*atan(min(axesSize)/2/pixelsPerRadian));
end % Ends fcn_INTERNAL_setLevelCamera

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
