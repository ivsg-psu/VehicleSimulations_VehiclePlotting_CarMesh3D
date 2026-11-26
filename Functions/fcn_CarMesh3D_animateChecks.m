function animator = fcn_CarMesh3D_animateChecks(vehicleInput, checkKey, options)
% fcn_CarMesh3D_animateChecks

% The animation checks of a vehicle's mesh, drawn live from the mesh and
% the test motion: Lights, Body, Steering, Wheels, or Drive. Two copies of
% the vehicle side by side, one seen from ahead and to the left, one from
% behind and to the right, each view following its vehicle, with a
% caption naming the step. It works on its own (its own window), or
% inside another window, such as the Model Reviewer
% (fcn_CarMesh3D_reviewVehicle), which gives it a panel to build into.
%
% It takes a mesh in, so the mesh animated is exactly the one given: the
% reviewer gives it the mesh with the painted label edits (from
% fcn_CarMesh3D_paintLabels), so a face painted as a lamp lights up here.
%
% THE CHECKS (checkKey):
%   'lights'   at night, matte paint: do the right lamps light up?
%   'body'     roll, pitch, heave, a lifted tire
%   'steering' the front wheels steer, with dashed lines from each wheel
%              to the turn center (black dot)
%   'wheels'   spinning, locked, backward; skid marks where a tire slips
%   'drive'    steering and wheels together, along a path
% Each check is the rows of the test motion whose captions start with its
% name ('Lights: ...'); each caption is one step.
%
% FORMAT:
%
%       animator = fcn_CarMesh3D_animateChecks(vehicleInput, checkKey,...
%           (TestMotion=testMotion), (Rows=rows), (StepRows=stepRows),...
%           (Parent=container), (FlagShowPlayer=flag), (OnStep=function),...
%           (OnHint=function), (FlagVisible=flag), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport'), or a labeled
%      CarMesh3D mesh. With an ID, the mesh is the vehicle's mesh file
%      (with its saved label edits, when those are newer than the mesh
%      file), and the test motion is from its checks' cache (stage 3).
%
%      checkKey: 'lights', 'body', 'steering', 'wheels', or 'drive'
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      TestMotion: the test motion (as fcn_CarMesh3D_checkVehicle's
%      checkResults.TestMotion). Needed with a mesh; with an ID, the
%      default is from the vehicle's cache.
%
%      Rows: the rows of the test motion to animate. Default: the rows
%      whose captions start with the check's name.
%
%      StepRows: one row per step, the row each step is shown at. Default:
%      one per caption (the middle of the step; for the lights, its second
%      row, as signals blink "on" first).
%
%      Parent: a panel or grid to build into; [] (default) for a window of
%      its own.
%
%      FlagShowPlayer: true to show Play, a time slider, and the inputs
%      plotted over time. Default: true in its own window, false in a
%      parent.
%
%      OnStep: a function called with a step number as the whole
%      animation plays, when the step showing changes (0 when it stops):
%      the reviewer lights up that step's item.
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
%      animator: a structure of the animation's handles and functions:
%           Figure, Axes (the two views), InputAxes, Handles (the
%               fcn_CarMesh3D_plotVehicle handles of each view), Mesh,
%               Rows, Steps (Name, Row of each step), CheckKey
%           ShowFrame(frameIndex), Frame(): one time step (an index into
%               Rows)
%           ShowStep(stepIndex): a step's scene; 0 for the whole animation,
%               played over and over
%           Play(), Pause(), IsPlaying()
%           ResetViews(): the cameras back on the vehicle
%           Stop(): stop playing (before the parent is cleared)
%           Close(): close its own window
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_plotVehicle,
%      fcn_CarMesh3D_paintLabels (an ID with label edits newer than its
%      mesh file)
%
% EXAMPLES:
%
%       % The Fit's lights check, in a window of its own
%       animator = fcn_CarMesh3D_animateChecks('2009_Honda_Fit_Sport', 'lights');
%       animator.ShowStep(0);   % the whole animation, over and over
%
%       See the script: script_test_fcn_CarMesh3D_animateChecks.m for a
%       full test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_animateChecks
%   % * First write: the Model Reviewer's animation checks, taken out into
%   %   % a function of their own (Sean, 06:00: separate panels, so the
%   %   % passing of the mesh is clear and each is easier to debug); a mesh
%   %   % in, so painted label edits show in the lights check
%   % * Its own window's title is this function's name, with the
%   %   % file's last change (its version) under it (fcn_CarMesh3D_addTitleBar;
%   %   % Sean, 14:31 and 14:40)

% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_animateChecks
%   % * The mesh with its saved label fixes comes from
%   %   % fcn_CarMesh3D_meshWithLabelEdits (no window), not a hidden
%   %   % painter (the tree rule; Q32 (A))

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_animateChecks
%   % * (none yet)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    vehicleInput
    checkKey
    options.TestMotion = []     % The test motion; [] for the vehicle's cache (an ID)
    options.Rows = []           % Rows to animate; [] for the check's rows
    options.StepRows = []       % One row per step; [] for one per caption
    options.Parent = []         % Panel or grid to build into; [] for a window of its own
    options.FlagShowPlayer = []     % Play, slider and inputs plot; [] for the default
    options.OnStep = []         % Called with the step showing as the whole animation plays
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
    debug_figNum = 999977; %#ok<NASGU>
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
checkNames = fcn_INTERNAL_checkNames();
if 0==flag_max_speed
    if flag_check_inputs
        if ~(ischar(vehicleInput) || isstring(vehicleInput) || ...
                (isstruct(vehicleInput) && all(isfield(vehicleInput, {'Vertices','Faces','LabelPartNames','LabelFacePart'}))))
            error('vehicleInput must be a vehicle ID or a labeled CarMesh3D mesh (Vertices, Faces, LabelPartNames, LabelFacePart)');
        end
        if ~(ischar(checkKey) || isstring(checkKey)) || ~any(strcmp(char(checkKey), checkNames(:,1)))
            error('checkKey must be one of: %s', strjoin(checkNames(:,1)', ', '));
        end
        if isstruct(vehicleInput) && isempty(options.TestMotion)
            error('With a mesh given, TestMotion is needed (checkResults.TestMotion from fcn_CarMesh3D_checkVehicle)');
        end
        for callbackName = {'OnStep','OnHint'}
            if ~isempty(options.(callbackName{1})) && ~isa(options.(callbackName{1}), 'function_handle')
                error('%s must be a function handle, or empty', callbackName{1});
            end
        end
        if ~isempty(options.Parent) && ~isgraphics(options.Parent)
            error('Parent must be a panel or grid, or empty');
        end
    end
end
checkKey = char(checkKey);

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

%%%% The mesh and the test motion
testMotion = options.TestMotion;
vehicleName = 'mesh';
if ischar(vehicleInput) || isstring(vehicleInput)
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
    vehicleName = vehicleFiles.Name;
    % (the mesh with its saved label fixes, from a plain function with no
    % window: the tree rule, Q32 (A), Sean 2026_11_24 01:55; this was a
    % hidden painter)
    vehicleMesh = fcn_CarMesh3D_meshWithLabelEdits(char(vehicleInput), FigNum=-1);
    if isempty(testMotion)
        stage3File = fullfile(vehicleFiles.Folder, 'cache', 'stage3_checks.mat');
        if isfile(stage3File)
            stage3 = load(stage3File, 'cacheOutputs');
            if isfield(stage3, 'cacheOutputs') && isfield(stage3.cacheOutputs, 'checkResults')
                testMotion = stage3.cacheOutputs.checkResults.TestMotion;
            end
        end
    end
else
    vehicleMesh = vehicleInput;
    if isfield(vehicleMesh, 'Name')
        vehicleName = vehicleMesh.Name;
    end
end
if ~isfield(vehicleMesh, 'FaceAlpha') || isempty(vehicleMesh.FaceAlpha)
    vehicleMesh.FaceAlpha = ones(size(vehicleMesh.Faces,1),1);
end
geometry = fcn_INTERNAL_geometry(vehicleMesh);

%%%% The check's rows and steps
checkRow = find(strcmp(checkNames(:,1), checkKey), 1);
animationRows = options.Rows(:);
stepRows = options.StepRows(:);
if ~isempty(testMotion) && isempty(animationRows)
    [animationRows, defaultStepRows] = fcn_INTERNAL_checkRows(testMotion, checkKey, checkNames(checkRow,:));
    if isempty(options.StepRows)
        stepRows = defaultStepRows;
    end
end
steps = struct('Name', {}, 'Row', {});
for ith_step = 1:numel(stepRows)
    steps(ith_step).Name = strtrim(regexprep(testMotion.Caption{stepRows(ith_step)}, '^[A-Za-z]+:\s*', ''));
    steps(ith_step).Row = stepRows(ith_step);
end
flagNight = strcmp(checkKey, 'lights');

%%%% State
playTimer = [];
currentFrame = 1;
activeStep = 0;
flagLoop = false;
frameStep = zeros(numel(animationRows),1);
for ith_step = 1:numel(steps)
    stepCaption = testMotion.Caption{steps(ith_step).Row};
    frameStep(strcmp(testMotion.Caption(animationRows), stepCaption)) = ith_step;
end
viewAxes = gobjects(1,2);
viewHandles = cell(1,2);
viewTurnLines = cell(1,2);
skidPatches = gobjects(0);
skidData = [];
captionLabel = [];
playButton = [];
timeSlider = [];
timeLabel = [];
cursorLine = [];
inputAxes = [];
hintLabel = [];
sides = {'frontLeft', 'rearRight'};
mouseMode = '';
mouseAxes = [];
mouseStart = [0 0];
mouseLast = [0 0];

%%%% The window (or the parent given)
flagOwnWindow = isempty(options.Parent);
showPlayer = options.FlagShowPlayer;
if isempty(showPlayer)
    showPlayer = flagOwnWindow;
end
figureHandle = [];
if flagOwnWindow
    visibleText = 'on';
    if ~options.FlagVisible
        visibleText = 'off';
    end
    figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_animateChecks: %s check, %s', checkNames{checkRow,2}, vehicleName), ...
        'Position', [80 80 1400 820], 'Visible', visibleText);
    % (the title bar: this function's name and version; the rest under it)
    contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_animateChecks', Subtitle=sprintf('%s check, %s', checkNames{checkRow,2}, vehicleName), FigNum=-1);
    rootGrid = uigridlayout(contentPanel, [2 2], 'ColumnWidth', {'1x', 230}, 'RowHeight', {'1x', 44}, ...
        'Padding', [6 6 6 6], 'ColumnSpacing', 6, 'RowSpacing', 4);
    parent = uipanel(rootGrid, 'BorderType', 'none');
    parent.Layout.Row = 1;
    parent.Layout.Column = 1;
else
    parent = options.Parent;
end

if isempty(testMotion) || isempty(animationRows)
    uilabel(uigridlayout(parent, [1 1]), 'Text', 'No test motion in the checks'' cache (run the vehicle''s script).', ...
        'HorizontalAlignment', 'center');
else
    buildViews();
end

if flagOwnWindow
    % The steps (pick one to see it; "The whole animation" plays it over
    % and over), a reset, and Close
    sideGrid = uigridlayout(rootGrid, [4 1], 'RowHeight', {24, '1x', 30, 30}, 'Padding', [0 0 0 0]);
    sideGrid.Layout.Row = 1;
    sideGrid.Layout.Column = 2;
    uilabel(sideGrid, 'Text', 'Steps', 'FontWeight', 'bold');
    stepNames = [{'The whole animation'}, {steps.Name}];
    uilistbox(sideGrid, 'Items', stepNames, 'ItemsData', 0:numel(steps), 'Value', 0, ...
        'ValueChangedFcn', @(source,~) showStep(source.Value), 'Tag', 'stepList');
    uibutton(sideGrid, 'Text', 'Reset views', 'ButtonPushedFcn', @(~,~) resetViews());
    uibutton(sideGrid, 'Text', 'Close', 'ButtonPushedFcn', @(~,~) closeAnimator());
    hintLabel = uilabel(rootGrid, 'Text', '', 'Interpreter', 'html', 'WordWrap', 'on', 'FontColor', [0.25 0.25 0.25]);
    hintLabel.Layout.Row = 2;
    hintLabel.Layout.Column = [1 2];
    set(figureHandle, 'WindowButtonDownFcn', @onOwnDown, 'WindowButtonMotionFcn', @(~,~) onOwnMove(), ...
        'WindowButtonUpFcn', @(~,~) onOwnUp(), 'WindowScrollWheelFcn', @onOwnScroll, ...
        'CloseRequestFcn', @(~,~) closeAnimator());
end

if ~isempty(captionLabel)
    setHint(['Left: from ahead and to the left. Right: from behind and to the right.<br><br>' ...
        '"The whole animation" plays it over and over, lighting up each step''s item as it goes.<br><br>' ...
        'Mouse: left-drag rotates, right-drag pans, the wheel zooms. The views follow the vehicle.']);
    showFrame(1);
    % (the timer stops when the views are deleted, as when the reviewer
    % clears its panel)
    captionLabel.DeleteFcn = @(~,~) stopPlaying();
end

animator = struct('Figure', figureHandle, 'Axes', viewAxes, 'InputAxes', inputAxes, 'Handles', {viewHandles}, ...
    'Mesh', vehicleMesh, 'Rows', animationRows, 'Steps', steps, 'CheckKey', checkKey, ...
    'ShowFrame', @showFrame, 'Frame', @getFrame, 'ShowStep', @showStep, ...
    'Play', @play, 'Pause', @stopPlaying, 'IsPlaying', @isPlaying, ...
    'ResetViews', @resetViews, 'Stop', @stopPlaying, 'Close', @closeAnimator);
if flagOwnWindow
    figureHandle.UserData = animator;
end

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the animation's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% Building the views
    function buildViews()
        % Two views side by side, a caption, and (when shown) the player
        % and the inputs plot. The lights check is at night, with matte
        % paint so the lamps show.
        playerHeights = {0, 0};
        if showPlayer
            playerHeights = {32, 170};
        end
        layout = uigridlayout(parent, [4 2], 'RowHeight', [{30, '1x'}, playerHeights], 'ColumnWidth', {'1x', '1x'}, ...
            'Padding', [0 0 0 0], 'RowSpacing', 2, 'ColumnSpacing', 4);
        captionLabel = uilabel(layout, 'Text', '', 'FontSize', 16, 'FontWeight', 'bold', 'Tag', 'captionLabel', ...
            'BackgroundColor', [0.95 0.95 0.95]);
        captionLabel.Layout.Column = [1 2];
        for ith_view = 1:2
            % (each view in its own panel: a panel clips its axes, which
            % can otherwise draw over its neighbor)
            viewPanel = uipanel(layout, 'BorderType', 'none');
            viewPanel.Layout.Row = 2;
            viewPanel.Layout.Column = ith_view;
            axesHandle = uiaxes(uigridlayout(viewPanel, [1 1], 'Padding', [0 0 0 0]));
            hold(axesHandle, 'on');
            axis(axesHandle, 'off');
            fcn_INTERNAL_drawGround(axesHandle, testMotion.Pose(animationRows,1:2), flagNight);
            if flagNight
                % (a faint light from above, so the body can be seen, and
                % the lamps do the rest)
                light(axesHandle, 'Style', 'infinite', 'Position', [0.3 -0.5 1], 'Color', [0.22 0.22 0.26]);
                viewHandles{ith_view} = fcn_CarMesh3D_plotVehicle(vehicleMesh, 'Finish', 'matte', 'FlagLightEffects', true, ...
                    'SceneLights', 'none', 'AxesHandle', axesHandle);
                axesHandle.Color = [0.04 0.05 0.09];
            else
                viewHandles{ith_view} = fcn_CarMesh3D_plotVehicle(vehicleMesh, 'Finish', 'matte', 'AxesHandle', axesHandle);
                axesHandle.Color = [0.78 0.86 0.95];
            end
            axis(axesHandle, 'off');
            axis(axesHandle, 'equal');
            % (clipped to its own box: unclipped, the ground of one view
            % is drawn over the other)
            set(findobj(axesHandle, '-property', 'Clipping'), 'Clipping', 'on');
            axesHandle.Clipping = 'on';
            axesHandle.Projection = 'perspective';
            fcn_INTERNAL_quietAxes(axesHandle);
            % (the steering check: dashed lines from the turn center to
            % each wheel, and the turn center)
            turnLines = gobjects(0);
            if strcmp(checkKey, 'steering')
                lineColors = [0 0 1; 1 0 0; 0.2 0.2 0.2; 0.2 0.2 0.2];
                for ith_wheel = 1:4
                    turnLines(ith_wheel) = plot3(axesHandle, nan(1,2), nan(1,2), [0.05 0.05], '--', ...
                        'Color', lineColors(ith_wheel,:), 'LineWidth', 1.5, 'Clipping', 'off');
                end
                turnLines(5) = plot3(axesHandle, nan, nan, 0.05, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 6, 'Clipping', 'off');
            end
            viewTurnLines{ith_view} = turnLines;
            viewAxes(ith_view) = axesHandle;
            fcn_INTERNAL_aimCamera(axesHandle, testMotion, animationRows(1), sides{ith_view}, geometry, flagNight);
        end
        layout.BackgroundColor = viewAxes(1).Color;
        controlGrid = uigridlayout(layout, [1 3], 'ColumnWidth', {90, '1x', 120}, 'Padding', [0 0 0 0]);
        controlGrid.Layout.Row = 3;
        controlGrid.Layout.Column = [1 2];
        playButton = uibutton(controlGrid, 'Text', char([9654 ' Play']), 'ButtonPushedFcn', @(~,~) onPlayButton());
        timeSlider = uislider(controlGrid, 'Limits', [1 max(2,numel(animationRows))], 'Value', 1, ...
            'MajorTicks', [], 'MinorTicks', [], 'ValueChangingFcn', @(~,event) showFrame(round(event.Value)), ...
            'ValueChangedFcn', @(source,~) showFrame(round(source.Value)));
        timeLabel = uilabel(controlGrid, 'Text', '', 'Tag', 'timeLabel');
        inputAxes = uiaxes(layout);
        inputAxes.Layout.Row = 4;
        inputAxes.Layout.Column = [1 2];
        cursorLine = fcn_INTERNAL_plotInputs(inputAxes, testMotion, checkNames{checkRow,4}, animationRows);
        % (the wheels and drive checks: skid marks where a tire slips, so
        % spinning or locked wheels show against the ground)
        if any(strcmp(checkKey, {'wheels', 'drive'}))
            skidData = fcn_INTERNAL_skidData(testMotion, animationRows, viewHandles{1}.WheelCenters, geometry);
            for ith_view = 1:2
                skidPatches(ith_view) = patch(viewAxes(ith_view), 'Faces', zeros(0,4), 'Vertices', zeros(0,3), ...
                    'FaceColor', [0.06 0.06 0.06], 'EdgeColor', 'none', 'FaceAlpha', 'flat', 'FaceVertexAlphaData', zeros(0,1), ...
                    'AlphaDataMapping', 'none', 'FaceLighting', 'none', 'HitTest', 'off', 'Clipping', 'on', 'Tag', 'skid');
            end
        end
    end

    %% Showing a time step
    function showFrame(frameIndex)
        % One time step of the check: both vehicles as they are then, the
        % caption, the slider, and the line on the input plot
        if isempty(captionLabel) || ~all(isvalid(viewAxes))
            return;
        end
        frameIndex = max(1, min(numel(animationRows), round(frameIndex)));
        currentFrame = frameIndex;
        row = animationRows(frameIndex);
        pose = testMotion.Pose(row,:);
        for ith_view = 1:2
            fcn_CarMesh3D_plotVehicle(vehicleMesh, 'Pose', pose, ...
                'WheelSpin', testMotion.WheelSpin(row,:), 'SteerAngle', testMotion.SteerAngle(row,:), ...
                'WheelLift', testMotion.WheelLift(row,:), 'BodyRoll', testMotion.BodyRoll(row), ...
                'BodyPitch', testMotion.BodyPitch(row), 'BodyHeave', testMotion.BodyHeave(row), ...
                'Signals', testMotion.Signals(row), 'PlotHandles', viewHandles{ith_view}, 'FigNum', -1);
            % (each camera moves with the vehicle, keeping its angle and
            % distance, and any rotation made)
            axesHandle = viewAxes(ith_view);
            if ~isappdata(axesHandle, 'lastPose')
                setappdata(axesHandle, 'lastPose', pose(1:2));
            end
            shift = [pose(1:2) - getappdata(axesHandle, 'lastPose'), 0];
            setappdata(axesHandle, 'lastPose', pose(1:2));
            set(axesHandle, 'CameraTarget', axesHandle.CameraTarget + shift, 'CameraPosition', axesHandle.CameraPosition + shift);
            if ~isempty(viewTurnLines{ith_view})
                fcn_INTERNAL_turnLines(viewTurnLines{ith_view}, testMotion, row, viewHandles{ith_view});
            end
        end
        if ~isempty(skidData)
            [skidFaces, skidVertices, skidAlpha] = fcn_INTERNAL_skidMarks(skidData, frameIndex);
            set(skidPatches, 'Faces', skidFaces, 'Vertices', skidVertices, 'FaceVertexAlphaData', skidAlpha);
        end
        captionLabel.Text = sprintf('  %s', testMotion.Caption{row});
        if ~isempty(timeSlider) && isvalid(timeSlider) && round(timeSlider.Value)~=frameIndex
            timeSlider.Value = frameIndex;
        end
        if ~isempty(cursorLine) && isvalid(cursorLine)
            set(cursorLine, 'XData', testMotion.Time(row)*[1 1]);
        end
        if ~isempty(timeLabel) && isvalid(timeLabel)
            timeLabel.Text = sprintf('t = %.2f s', testMotion.Time(row));
        end
        drawnow limitrate;
    end

    function showStep(stepIndex)
        % A step: its scene, in the same views (they are not moved). 0, the
        % whole animation: played over and over, its steps lit up in turn
        % (OnStep).
        stopPlaying();
        if isempty(captionLabel) || ~all(isvalid(viewAxes))
            return;
        end
        if stepIndex == 0
            showFrame(1);
            startPlaying(true);
        else
            [~, frameIndex] = min(abs(animationRows - steps(stepIndex).Row));
            showFrame(frameIndex);
        end
    end

    %% Playing
    function play()
        % Once through, from where it is (from the start, if at the end)
        stopPlaying();
        if isempty(captionLabel)
            return;
        end
        if currentFrame >= numel(animationRows)
            showFrame(1);
        end
        startPlaying(false);
    end

    function startPlaying(flagOverAndOver)
        flagLoop = flagOverAndOver;
        period = median(diff(testMotion.Time));
        if ~(period > 0)
            period = 0.05;
        end
        if ~isempty(playButton) && isvalid(playButton)
            playButton.Text = char([10073 10073 ' Pause']);
        end
        playTimer = timer('ExecutionMode', 'fixedSpacing', 'Period', max(0.02, round(period,3)), ...
            'BusyMode', 'drop', 'TimerFcn', @(~,~) onTick());
        start(playTimer);
    end

    function onPlayButton()
        if isPlaying()
            stopPlaying();
        else
            play();
        end
    end

    function onTick()
        if isempty(captionLabel) || ~isvalid(captionLabel)
            stopPlaying();
            return;
        end
        nextFrame = currentFrame + 1;
        if nextFrame > numel(animationRows)
            if flagLoop
                nextFrame = 1;   % (over and over; the views follow the vehicle back)
                if ~isempty(skidData)
                    set(skidPatches, 'Faces', zeros(0,4));
                end
            else
                stopPlaying();
                return;
            end
        end
        showFrame(nextFrame);
        lightStep(nextFrame);
    end

    function lightStep(frameIndex)
        % (as the whole animation plays: the step now showing, to OnStep)
        if ~flagLoop
            return;
        end
        thisStep = frameStep(frameIndex);
        if thisStep == activeStep
            return;
        end
        activeStep = thisStep;
        if ~isempty(options.OnStep)
            options.OnStep(thisStep);
        end
    end

    function frameIndex = getFrame()
        frameIndex = currentFrame;
    end

    function flag = isPlaying()
        flag = ~isempty(playTimer) && isvalid(playTimer) && strcmp(playTimer.Running, 'on');
    end

    function stopPlaying()
        flagWasLooping = ~isempty(playTimer) && flagLoop;
        if ~isempty(playTimer) && isvalid(playTimer)
            stop(playTimer);
            delete(playTimer);
        end
        playTimer = [];
        flagLoop = false;
        if ~isempty(playButton) && isvalid(playButton)
            playButton.Text = char([9654 ' Play']);
        end
        if flagWasLooping
            activeStep = 0;
            if ~isempty(options.OnStep)
                options.OnStep(0);   % (the items back to their usual look)
            end
        end
    end

    %% Views
    function resetViews()
        % The cameras back on the vehicle where it is now
        if isempty(captionLabel)
            return;
        end
        for ith_view = 1:2
            fcn_INTERNAL_aimCamera(viewAxes(ith_view), testMotion, animationRows(currentFrame), sides{ith_view}, geometry, flagNight);
            setappdata(viewAxes(ith_view), 'lastPose', testMotion.Pose(animationRows(currentFrame),1:2));
        end
    end

    function setHint(textIn)
        if ~isempty(options.OnHint)
            options.OnHint(textIn);
        elseif ~isempty(hintLabel) && isvalid(hintLabel)
            hintLabel.Text = strrep(textIn, '<br><br>', ' ');
        end
    end

    %% Its own window: the mouse, CAD-style, and closing
    function onOwnDown(~, ~)
        % Left-drag rotates, right-drag pans (the view clicked)
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
        if strcmp(figureHandle.SelectionType, 'alt')
            mouseMode = 'pan';
        else
            mouseMode = 'rotate';
        end
        mouseStart = figureHandle.CurrentPoint;
        mouseLast = mouseStart;
    end

    function onOwnMove()
        if isempty(mouseMode)
            return;
        end
        point = figureHandle.CurrentPoint;
        delta = point - mouseLast;
        mouseLast = point;
        if strcmp(mouseMode, 'rotate')
            camorbit(mouseAxes, -0.5*delta(1), -0.5*delta(2), 'data', [0 0 1]);
        else
            camdolly(mouseAxes, -delta(1), -delta(2), 0, 'movetarget', 'pixels');
        end
        drawnow limitrate;
    end

    function onOwnUp()
        mouseMode = '';
    end

    function onOwnScroll(~, event)
        % (the view under the mouse)
        point = figureHandle.CurrentPoint;
        for ith_view = 1:2
            if ~isvalid(viewAxes(ith_view))
                continue;
            end
            box = getpixelposition(viewAxes(ith_view), true);
            if point(1) >= box(1) && point(1) <= box(1)+box(3) && point(2) >= box(2) && point(2) <= box(2)+box(4)
                camzoom(viewAxes(ith_view), 1.15^(-event.VerticalScrollCount));
            end
        end
    end

    function closeAnimator()
        stopPlaying();
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

%% fcn_INTERNAL_checkNames
function checkNames = fcn_INTERNAL_checkNames()
% Each check: its key, its title, the caption prefixes of its rows, and
% the inputs plotted under it
checkNames = {
    'lights',   'Lights',   {'Lights'},              'lights';
    'body',     'Body',     {'Body'},                'body';
    'steering', 'Steering', {'Steering'},            'steering';
    'wheels',   'Wheels',   {'Wheels'},              'wheels';
    'drive',    'Drive',    {'Steering','Wheels'},   'drive'};
end % Ends fcn_INTERNAL_checkNames

%% fcn_INTERNAL_checkRows
function [rows, stepRows] = fcn_INTERNAL_checkRows(testMotion, checkKey, checkName)
% The rows of the check (captions starting with its prefixes), and one row
% per step (caption): the middle of the step, or for the lights, its
% second row (signals blink "on" first). The drive check is the whole
% animation only: no steps.
rows = find(startsWith(testMotion.Caption, strcat(checkName{3}, ':')));
rows = rows(:);
stepRows = zeros(0,1);
if strcmp(checkKey, 'drive') || isempty(rows)
    return;
end
stepNames = unique(testMotion.Caption(rows), 'stable');
for ith_step = 1:numel(stepNames)
    thisStepRows = rows(strcmp(testMotion.Caption(rows), stepNames{ith_step}));
    if strcmp(checkKey, 'lights')
        stepRows(end+1,1) = thisStepRows(min(2, numel(thisStepRows))); %#ok<AGROW>
    else
        stepRows(end+1,1) = thisStepRows(ceil(end/2)); %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_checkRows

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
end % Ends fcn_INTERNAL_geometry

%% fcn_INTERNAL_quietAxes
function fcn_INTERNAL_quietAxes(axesHandle)
% No built-in mouse interactions or toolbar: the window's own mouse
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

%% fcn_INTERNAL_drawGround
function fcn_INTERNAL_drawGround(axesHandle, pathXY, flagNight)
% A checkered ground (2 m squares; larger for a long path) under the
% path, so the motion and the wheels' turning can be seen against it
extent = [min(pathXY(:,1))-15, max(pathXY(:,1))+15, min(pathXY(:,2))-15, max(pathXY(:,2))+15];
squareSize = max(2, 2*ceil(max(extent(2)-extent(1), extent(4)-extent(3))/120));
xEdges = extent(1):squareSize:extent(2)+squareSize;
yEdges = extent(3):squareSize:extent(4)+squareSize;
[gridX, gridY] = meshgrid(xEdges(1:end-1), yEdges(1:end-1));
Nsquares = numel(gridX);
corners = [0 0; squareSize 0; squareSize squareSize; 0 squareSize];
vertices = zeros(4*Nsquares, 3);
faces = reshape(1:4*Nsquares, 4, [])';
for ith_corner = 1:4
    vertices(ith_corner:4:end, 1:2) = [gridX(:) gridY(:)] + corners(ith_corner,:);
end
flagDark = mod(round(gridX(:)/squareSize) + round(gridY(:)/squareSize), 2) == 0;
if flagNight
    shades = [0.11 0.11 0.13; 0.14 0.14 0.16];
else
    shades = [0.56 0.6 0.56; 0.62 0.66 0.62];
end
faceColors = shades(1 + flagDark, :);
patch(axesHandle, 'Faces', faces, 'Vertices', vertices, 'FaceVertexCData', faceColors, 'FaceColor', 'flat', ...
    'EdgeColor', 'none', 'FaceLighting', 'none', 'Clipping', 'off', 'HitTest', 'off');
end % Ends fcn_INTERNAL_drawGround

%% fcn_INTERNAL_aimCamera
function fcn_INTERNAL_aimCamera(axesHandle, testMotion, row, side, geometry, flagLights)
% The camera on the vehicle at this row: from ahead and to the left
% ('frontLeft') or from behind and to the right ('rearRight'), above it,
% far enough to see the whole vehicle. For the lights, farther and aimed
% past the vehicle, so the light on the ground ahead (or behind) shows.
pose = testMotion.Pose(row,:);
yaw = pose(end);
vehicleLength = geometry.Max(1) - geometry.Min(1);
height = 0.45*(geometry.Max(3) - geometry.Min(3));
switch side
    case 'rearRight'
        localAngle = -145;
        aimAhead = -1;
    otherwise
        localAngle = 35;
        aimAhead = 1;
end
direction = [cosd(localAngle + rad2deg(yaw)), sind(localAngle + rad2deg(yaw))];
heading = [cos(yaw) sin(yaw)];
if flagLights
    distance = 3.6*vehicleLength;
    elevation = 24;
    target = [pose(1:2) + aimAhead*0.9*vehicleLength*heading, 0];
else
    distance = 2.6*vehicleLength;
    elevation = 20;
    target = [pose(1:2) height];
end
position = target + distance*[cosd(elevation)*direction, sind(elevation)];
set(axesHandle, 'CameraTarget', target, 'CameraPosition', position, 'CameraUpVector', [0 0 1], ...
    'CameraViewAngle', 28);
end % Ends fcn_INTERNAL_aimCamera

%% fcn_INTERNAL_skidData
function skidData = fcn_INTERNAL_skidData(testMotion, rows, wheelCenters, geometry)
% Where each tire touches the ground at each of these rows, and whether it
% slips there: its surface speed (spin rate times radius) differs from the
% vehicle's speed by more than 0.5 m/s and 20% (a spinning or locked tire)
Nrows = numel(rows);
Nwheels = size(wheelCenters,1);
radius = mean(geometry.WheelDiameters, 'omitnan')/2;
if ~(radius > 0)
    radius = 0.3;
end
time = testMotion.Time(:);
spinRate = zeros(size(testMotion.WheelSpin));
for ith_wheel = 1:size(testMotion.WheelSpin,2)
    spinRate(:,ith_wheel) = gradient(testMotion.WheelSpin(:,ith_wheel), time);
end
skidData.Contacts = zeros(Nrows, Nwheels, 2);
skidData.Slip = false(Nrows, Nwheels);
for ith_row = 1:Nrows
    row = rows(ith_row);
    pose = testMotion.Pose(row,:);
    yaw = pose(end);
    rotation = [cos(yaw) -sin(yaw); sin(yaw) cos(yaw)];
    skidData.Contacts(ith_row,:,:) = reshape((rotation*wheelCenters(:,1:2)')' + pose(1:2), [1 Nwheels 2]);
    speed = abs(testMotion.Speed(row));
    for ith_wheel = 1:min(Nwheels, size(spinRate,2))
        surfaceSpeed = abs(spinRate(row, ith_wheel))*radius;
        skidData.Slip(ith_row, ith_wheel) = abs(surfaceSpeed - speed) > max(0.5, 0.2*speed);
    end
end
skidData.FadeRows = max(10, round(2/max(median(diff(time)), eps)));   % (fades over about 2 s)
skidData.HalfWidth = 0.09;
end % Ends fcn_INTERNAL_skidData

%% fcn_INTERNAL_skidMarks
function [faces, vertices, alpha] = fcn_INTERNAL_skidMarks(skidData, frameIndex)
% The skid marks up to this frame: a dark strip under each slipping tire,
% from one row to the next, fading with age
faces = zeros(0,4);
vertices = zeros(0,3);
alpha = zeros(0,1);
firstFrame = max(2, frameIndex - skidData.FadeRows);
for ith_wheel = 1:size(skidData.Slip,2)
    for ith_frame = firstFrame:frameIndex
        if ~skidData.Slip(ith_frame, ith_wheel)
            continue;
        end
        startPoint = squeeze(skidData.Contacts(ith_frame-1, ith_wheel, :))';
        endPoint = squeeze(skidData.Contacts(ith_frame, ith_wheel, :))';
        direction = endPoint - startPoint;
        if norm(direction) < 1e-4
            continue;   % (a tire spinning in place leaves no streak)
        end
        sideways = [-direction(2) direction(1)]/norm(direction)*skidData.HalfWidth;
        corners = [startPoint + sideways; endPoint + sideways; endPoint - sideways; startPoint - sideways];
        base = size(vertices,1);
        vertices = [vertices; corners, 0.006*ones(4,1)]; %#ok<AGROW>
        faces = [faces; base + (1:4)]; %#ok<AGROW>
        alpha = [alpha; 0.75*(1 - (frameIndex - ith_frame)/skidData.FadeRows)]; %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_skidMarks

%% fcn_INTERNAL_turnLines
function fcn_INTERNAL_turnLines(turnLines, testMotion, row, plotHandles)
% Lines from the turn center (from yaw rate / speed) to each wheel center
pose = testMotion.Pose(row,:);
yaw = pose(end);
rotation = [cos(yaw) -sin(yaw); sin(yaw) cos(yaw)];
wheelXY = (rotation*plotHandles.WheelCenters(:,1:2)')' + pose(1:2);
curvature = 0;
if abs(testMotion.Speed(row)) > 0.1 && isfield(testMotion.Data,'yaw_rate')
    curvature = testMotion.Data.yaw_rate(row)/testMotion.Speed(row);
end
if abs(curvature) < 1e-3
    set(turnLines(1:4), 'XData', nan(1,2), 'YData', nan(1,2));
    set(turnLines(5), 'XData', nan, 'YData', nan);
    return;
end
turnCenter = pose(1:2) + [-sin(yaw) cos(yaw)]/curvature;
for ith_wheel = 1:4
    set(turnLines(ith_wheel), 'XData', [turnCenter(1) wheelXY(ith_wheel,1)], 'YData', [turnCenter(2) wheelXY(ith_wheel,2)]);
end
set(turnLines(5), 'XData', turnCenter(1), 'YData', turnCenter(2));
end % Ends fcn_INTERNAL_turnLines

%% fcn_INTERNAL_plotInputs
function cursorLine = fcn_INTERNAL_plotInputs(axesHandle, testMotion, inputs, rows)
% The inputs that drive this animation, over its time, with a line at the
% current time
cursorLine = [];
if isempty(testMotion)
    return;
end
hold(axesHandle, 'on');
time = testMotion.Time(rows);
motionData = testMotion.Data;
switch inputs
    case 'lights'
        % (one 0/1 line per signal column, each a little higher than the
        % last so the lines do not hide one another)
        names = fieldnames(motionData)';
        names = names(startsWith(names, 'signal'));   % (every signal column the file has)
        names = names(cellfun(@(name) any(motionData.(name)(rows) ~= 0), names));   % (only those switched on here: 29 lines would hide one another)
        for ith_name = 1:numel(names)
            if isfield(motionData, names{ith_name})
                stairs(axesHandle, time, motionData.(names{ith_name})(rows) + 0.04*ith_name, 'LineWidth', 1.5, 'DisplayName', names{ith_name});
            end
        end
        ylabel(axesHandle, 'input value (0 off, 1 on)');
    case 'body'
        plot(axesHandle, time, fcn_INTERNAL_degrees(testMotion.BodyRoll(rows)), 'LineWidth', 1.5, 'DisplayName', 'roll (deg)');
        plot(axesHandle, time, fcn_INTERNAL_degrees(testMotion.BodyPitch(rows)), 'LineWidth', 1.5, 'DisplayName', 'pitch (deg)');
        plot(axesHandle, time, 100*testMotion.BodyHeave(rows), 'LineWidth', 1.5, 'DisplayName', 'heave (cm)');
        wheelNames = {'FL','RL','RR','FR'};
        for ith_wheel = 1:size(testMotion.WheelLift,2)
            plot(axesHandle, time, 100*testMotion.WheelLift(rows,ith_wheel), '--', 'LineWidth', 1, ...
                'DisplayName', sprintf('lift %s (cm)', wheelNames{min(ith_wheel,4)}));
        end
    case {'steering','drive'}
        plot(axesHandle, time, fcn_INTERNAL_degrees(testMotion.SteerAngle(rows,1)), 'LineWidth', 1.5, 'DisplayName', 'steer FL (deg)');
        plot(axesHandle, time, fcn_INTERNAL_degrees(testMotion.SteerAngle(rows,2)), 'LineWidth', 1.5, 'DisplayName', 'steer FR (deg)');
        plot(axesHandle, time, testMotion.Speed(rows), 'LineWidth', 1.5, 'DisplayName', 'speed (m/s)');
    case 'wheels'
        plot(axesHandle, time, testMotion.Speed(rows), 'LineWidth', 1.5, 'DisplayName', 'speed (m/s)');
        speedNames = {'wheelSpeed_FL','wheelSpeed_FR','wheelSpeed_RL','wheelSpeed_RR'};
        for ith_name = 1:numel(speedNames)
            if isfield(motionData, speedNames{ith_name})
                plot(axesHandle, time, motionData.(speedNames{ith_name})(rows), '--', 'DisplayName', strrep(speedNames{ith_name},'_',' '));
            end
        end
        if isfield(motionData, 'signalBrake')
            stairs(axesHandle, time, motionData.signalBrake(rows), 'LineWidth', 1.5, 'DisplayName', 'signalBrake');
        end
        if isfield(motionData, 'signalBackup')
            stairs(axesHandle, time, motionData.signalBackup(rows), 'LineWidth', 1.5, 'DisplayName', 'signalBackup');
        end
end
legend(axesHandle, 'Location', 'eastoutside', 'Interpreter', 'none', 'AutoUpdate', 'off');
grid(axesHandle, 'on');
xlabel(axesHandle, 'time (s)');
xlim(axesHandle, [time(1) time(end)+eps]);
yLimits = ylim(axesHandle);
cursorLine = plot(axesHandle, time(1)*[1 1], yLimits, 'k-', 'LineWidth', 2, 'HandleVisibility', 'off');
ylim(axesHandle, yLimits);
end % Ends fcn_INTERNAL_plotInputs

%% fcn_INTERNAL_degrees
function degrees = fcn_INTERNAL_degrees(values)
% Radians to degrees (values that are already degrees are left alone)
if max(abs(values)) < 1.6
    degrees = rad2deg(values);
else
    degrees = values;
end
end % Ends fcn_INTERNAL_degrees
