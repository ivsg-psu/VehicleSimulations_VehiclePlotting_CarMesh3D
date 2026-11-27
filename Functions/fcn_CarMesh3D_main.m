function [viewState, window] = fcn_CarMesh3D_main(vehicleInput, options)
% fcn_CarMesh3D_main
% The main window of CarMesh3D: one window that takes a vehicle from its
% download to a reviewed, finished mesh. It lists the steps in order, opens
% each step's window, and shows which steps are done, out of date, or not
% done, so the process lives in the window and not in the user's memory.
% (Design: Documents/Documentation_CarMesh3D_GUIdesign_main.md.)
%
% THE WORKING MODEL. Opening a vehicle makes a working copy of its folder
% in CarMesh3D\Working\<ID>\ (never committed to git). Every window opened
% from here reads and saves there, and the build runs there, so the
% vehicle's own folder does not change until Commit. Discard throws the
% working copy away. An unfinished working copy is offered for resuming
% the next time the window opens.
%
% THE STEPS (each with a mark: done, out of date, not done, or greyed
% when it cannot start yet):
%       0 Vehicle...        the library browser
%       1 Import            the import report (lamps and glass told apart?)
%       2 First labels      the painter: lamps and glass apart from the body
%       3 Face directions   the face-direction window
%       4 Build             the vehicle's script, in the working copy
%       5 Full labels       the painter: which lamp is which
%       6 Lamp functions    the lamp-functions window (L2F)
%       7 Checks            the viewers (any number at once)
%       8 V&V review        the V&V window
%       9 Commit            the working copy into the vehicle's folder
% Only one editing window (painter, face directions, lamp functions) is
% open at a time; opening one closes the V&V window. Viewers may be open
% in any number.
%
% FORMAT:
%
%       [viewState, window] = fcn_CarMesh3D_main((vehicleInput),...
%           (Resume=flag), (WorkingRoot=folder), (FlagWait=flag),...
%           (FlagVisible=flag), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: (optional) a vehicle ID ('2009_Honda_Fit_Sport') or a
%      vehicle's folder; or a view state (the first output of an earlier
%      call, or the .mat file it was saved in). Default: the repo's demo
%      vehicle, or the last vehicle used here if the Settings say so.
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Resume: true resumes an unfinished working copy of the vehicle
%      without asking; false sets it aside (its folder renamed
%      <ID>_setAside_<time>, untouched inside) and starts a new one. []
%      (default) asks, when the window is visible (else resumes).
%
%      WorkingRoot: the folder for working copies and saved views.
%      Default: CarMesh3D\Working (tests: a temporary folder).
%
%      Vehicle: the vehicle, by name (same as vehicleInput).
%
%      FlagWait: wait until the window is closed, then return. Default
%      false.
%
%      FlagVisible: false builds the window, and the windows it opens,
%      hidden (tests). Default true.
%
%      FigNum: not used (a window); -1 for fast mode.
%
%      For programmers only: while a main window is open, the other
%      windows are meant to be opened from it. (Their check is skipped for
%      hidden windows, and when the environment variable
%      MATLABFLAG_CARMESH3D_FLAG_ALLOW_STANDALONE is 1; step 2 of the
%      design's plan.)
%
% OUTPUTS:
%
%      viewState: (with FlagWait=true; else [], and window.SaveView()
%      gives it) the window's state when it closed: Vehicle (ID),
%      WorkingFolder, Settings, Windows (each open window's function and
%      position as fractions of the screen), SavedOn. Also saved in
%      <WorkingRoot>\views\mainView_<ID>_<yyyy_MM_dd_HHmmss>.mat.
%
%      window: a structure of functions for scripts and tests: Figure;
%      State, Press, Key, CheckLayout (fcn_CarMesh3D_guiDriver); Marks()
%      (each step's mark: 'done', 'outOfDate', 'notDone', 'cannotStart' or
%      ''); Step(number) (opens a step, as its button does); Build();
%      Commit(); Discard(); Changes() (the working copy's files that
%      differ from the vehicle's); Children() (the open windows: Kind,
%      Figure); WorkingFolder(); VehicleFolder(); Refresh(); Close().
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_findVehicleFiles,
%      fcn_CarMesh3D_demoVehicle, fcn_CarMesh3D_importReport,
%      fcn_CarMesh3D_browseLibrary, fcn_CarMesh3D_paintLabels,
%      fcn_CarMesh3D_fixFaceDirections, fcn_CarMesh3D_editLampFunctions,
%      fcn_CarMesh3D_viewLabels, fcn_CarMesh3D_viewDimensions,
%      fcn_CarMesh3D_viewOrientation, fcn_CarMesh3D_viewDetailLevels,
%      fcn_CarMesh3D_viewOutline, fcn_CarMesh3D_reviewVehicle,
%      fcn_CarMesh3D_meshHistory, fcn_CarMesh3D_loadingWindow,
%      fcn_CarMesh3D_addTitleBar, fcn_CarMesh3D_makePanelMenu,
%      fcn_CarMesh3D_guiDriver
%
% EXAMPLES:
%
%       fcn_CarMesh3D_main;                           % the default vehicle
%       fcn_CarMesh3D_main('2017_Mazda_CX3_Sport');   % a vehicle by ID
%       viewState = fcn_CarMesh3D_main('2009_Honda_Fit_Sport', FlagWait=true);
%       fcn_CarMesh3D_main(viewState);                % the same again
%
%       See the script: script_test_fcn_CarMesh3D_main.m for a full test
%       suite.
%
% This function was written on 2026_11_27 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_main
%   % * First write (step 1 of the design's plan): the steps and their
%   %   % marks, the working model (resume, set aside, Commit, Discard),
%   %   % one editor at a time, any number of viewers, the saved view

% TO-DO:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_main
%   % * Step 2 of the plan: the children told of saves (viewers redraw),
%   %   % views turning together with per-window Unlink, children blocked
%   %   % on their own, windows restored from a view state
%   % * "New from a download" in step 0

arguments
    vehicleInput = []
    options.Vehicle = []
    options.Resume = []
    options.WorkingRoot = ''
    options.FlagWait = false
    options.FlagVisible = true
    options.FigNum = []
end

%% Debugging and Input checks
flag_max_speed = 0;
if isequal(options.FigNum,-1)
    flag_check_inputs = 0;
    flag_max_speed = 1;
else
    flag_check_inputs = 1;
    MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS = getenv("MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS");
    if ~isempty(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS)
        flag_check_inputs = str2double(MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS);
    end
end
if ~isempty(options.Vehicle)
    vehicleInput = options.Vehicle;
end
if 0==flag_max_speed && flag_check_inputs
    if ~(isempty(vehicleInput) || ischar(vehicleInput) || isstring(vehicleInput) || isstruct(vehicleInput))
        error('CarMesh3D:badInput', 'vehicleInput must be a vehicle ID, a vehicle''s folder, a view state, or a view-state file');
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

%%%% A second main window: bring the open one forward instead
openMain = getappdata(groot, 'CarMesh3D_mainWindow');
if ~isempty(openMain) && isvalid(openMain) && options.FlagVisible
    figure(openMain);
    viewState = [];
    window = openMain.UserData;
    return;
end

%%%% The folders
functionsFolder = fileparts(mfilename('fullpath'));
rootFolder = fileparts(functionsFolder);
workingRoot = char(options.WorkingRoot);
if isempty(workingRoot)
    workingRoot = fullfile(rootFolder, 'Working');
end
if ~isfolder(workingRoot)
    mkdir(workingRoot);
end

%%%% Which vehicle (a view state names one)
viewIn = [];
if (ischar(vehicleInput) || isstring(vehicleInput)) && endsWith(char(vehicleInput), '.mat') && isfile(char(vehicleInput))
    loadedView = load(char(vehicleInput), 'viewState');
    vehicleInput = loadedView.viewState;
end
if isstruct(vehicleInput)
    viewIn = vehicleInput; %#ok<NASGU> (step 2: windows restored from a view state)
    vehicleInput = viewIn.Vehicle;
end
if isempty(vehicleInput)
    vehicleInput = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);
    try
        if ispref('CarMesh3D', 'MainStartWith') && strcmp(getpref('CarMesh3D', 'MainStartWith'), 'last') ...
                && ispref('CarMesh3D', 'MainLastVehicle')
            vehicleInput = getpref('CarMesh3D', 'MainLastVehicle');
        end
    catch
    end
end
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
if ~vehicleFiles.Found
    error('CarMesh3D:noVehicle', 'No folder was found for the vehicle %s.', char(vehicleInput));
end
vehicleID = vehicleFiles.ID;

loading = fcn_CarMesh3D_loadingWindow('Opening the main window', Vehicle=vehicleID, FlagVisible=options.FlagVisible);
loadingCleanup = onCleanup(@() loading.Close()); %#ok<NASGU>

%%%% The working copy (resume, set aside, or a new one)
workFolder = fullfile(workingRoot, vehicleID);
flagResumed = false;
if isfolder(workFolder)
    resumeChoice = options.Resume;
    if isempty(resumeChoice)
        resumeChoice = true;
        if options.FlagVisible
            loading.Close();
            askFigure = fcn_INTERNAL_askFigure();
            choice = uiconfirm(askFigure, sprintf(['%s has an unfinished working copy (changes not ' ...
                'committed). Resume it, or set it aside and start a new one from the vehicle''s committed files? ' ...
                '(A set-aside copy is kept, and listed as unfinished work.)'], vehicleFiles.Name), 'Unfinished work', ...
                'Options', {'Resume', 'Set aside and start new'}, 'DefaultOption', 1);
            delete(askFigure);
            resumeChoice = strcmp(choice, 'Resume');
        end
    end
    if resumeChoice
        flagResumed = true;
    else
        fcn_INTERNAL_setAside(workFolder);
    end
end
if ~isfolder(workFolder)
    fcn_INTERNAL_makeWorkingCopy(vehicleFiles.Folder, workFolder);
end
workFiles = fcn_CarMesh3D_findVehicleFiles(workFolder, FigNum=-1);
if options.FlagVisible   % (tests never change a shared preference)
    try
        setpref('CarMesh3D', 'MainLastVehicle', vehicleID);
    catch
    end
end

%%%% State
children = struct('Kind', {}, 'Name', {}, 'Figure', {});   % (the windows opened from here)
editorKinds = {'painter', 'faces', 'lampFunctions'};
stepNames = {'Vehicle...', 'Import', 'First labels', 'Face directions', 'Build', 'Full labels', ...
    'Lamp functions (L2F)', 'Checks', 'V&V review', 'Commit'};
stepHelp = {'Pick a vehicle in the library (the browser).', ...
    'The import report: are lamps and glass told apart? Where is the glass?', ...
    'The painter: lamps and glass apart from the body, lamps under glass too.', ...
    'Turn inside-out faces the right way (after the first labels).', ...
    'Run the vehicle''s script in the working copy: fit, repairs, saved edits, levels, outline, checks.', ...
    'The painter again: which lamp is which (headlamp, turn signal, marker ...).', ...
    'Which signals light which lamp, and how brightly.', ...
    'Viewers of the finished mesh (any number at once).', ...
    'The human review that signs the vehicle off.', ...
    'Put the working copy into the vehicle''s own folder.'};
checkNames = {'Labels', 'Dimensions', 'Orientation', 'Detail levels', 'Outline'};
marks = repmat({''}, 1, 10);

%%%% The window: a title bar; a top bar (the menu, Commit, Discard, the
%%%% status); the steps; a hint line
visibleText = 'on';
if ~options.FlagVisible
    visibleText = 'off';
end
figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_main: %s', vehicleFiles.Name), 'Position', [60 80 760 720], ...
    'Visible', visibleText, 'Tag', 'mainWindow');
setappdata(groot, 'CarMesh3D_mainWindow', figureHandle);
contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_main', Subtitle=vehicleFiles.Name, FigNum=-1);
rootGrid = uigridlayout(contentPanel, [4 1], 'RowHeight', {36, 24, '1x', 20}, 'Padding', [6 4 6 4], 'RowSpacing', 3);
topGrid = uigridlayout(rootGrid, [1 5], 'ColumnWidth', {90, 90, 90, 90, '1x'}, 'Padding', [0 2 0 2], 'ColumnSpacing', 6);
menuButton = uibutton(topGrid, 'Text', [char(9776) ' Menu'], 'FontWeight', 'bold', 'FontSize', 13, 'Tag', 'mainMenu', ...
    'Tooltip', 'Settings and Help (pick an open one again to close it)');
uibutton(topGrid, 'Text', 'Commit', 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.95 0.85], 'Tag', 'mainCommit', ...
    'ButtonPushedFcn', @(~,~) commitWork(true), 'Tooltip', 'Put the working copy into the vehicle''s own folder (step 9).');
uibutton(topGrid, 'Text', 'Discard', 'Tag', 'mainDiscard', 'ButtonPushedFcn', @(~,~) discardWork(true), ...
    'Tooltip', 'Throw the working copy away and start again from the vehicle''s committed files (asks first).');
uibutton(topGrid, 'Text', 'Save view', 'Tag', 'mainSaveView', 'ButtonPushedFcn', @(~,~) saveView(), ...
    'Tooltip', 'Save the open windows'' places and the settings, to open the same view later.');
statusLabel = uilabel(topGrid, 'Text', '', 'Interpreter', 'html', 'FontSize', 12, 'Tag', 'mainStatus');
workLabel = uilabel(rootGrid, 'Text', '', 'Interpreter', 'html', 'FontSize', 11, 'Tag', 'mainWorking');
bodyGrid = uigridlayout(rootGrid, [1 2], 'ColumnWidth', {0, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 6);
menuColumn = uipanel(bodyGrid, 'BorderType', 'none');
panelMenu = fcn_CarMesh3D_makePanelMenu(menuButton, menuColumn, Resize=@(width) setMenuWidth(width), ...
    Exit=@() closeWindow(), ExitTag='mainExit', FigNum=-1);
settingsPanel = panelMenu.AddPanel('Settings', [0.93 0.95 1]);
helpPanel = panelMenu.AddPanel('Help: the process', [0.95 0.95 0.95]);
stepsPanel = uipanel(bodyGrid, 'Title', 'The steps, in order', 'FontWeight', 'bold', 'BackgroundColor', 'w');
hintLabel = uilabel(rootGrid, 'Text', '', 'Interpreter', 'html', 'FontColor', [0.35 0.35 0.35], 'Tag', 'mainHint');

% The steps: a mark, a button, and a line of status for each
stepsGrid = uigridlayout(stepsPanel, [10 3], 'RowHeight', repmat({34}, 1, 10), 'ColumnWidth', {28, 170, '1x'}, ...
    'Padding', [8 8 8 8], 'RowSpacing', 6, 'Scrollable', 'on', 'BackgroundColor', 'w');
markLabels = gobjects(1, 10);
stepButtons = gobjects(1, 10);
stepStatus = gobjects(1, 10);
checksDropdown = [];
for ith_step = 1:10
    markLabels(ith_step) = uilabel(stepsGrid, 'Text', '', 'FontSize', 18, 'HorizontalAlignment', 'center', ...
        'Tag', sprintf('mainMark%d', ith_step - 1));
    stepButtons(ith_step) = uibutton(stepsGrid, 'Text', sprintf('%d  %s', ith_step - 1, stepNames{ith_step}), ...
        'HorizontalAlignment', 'left', 'Tag', sprintf('mainStep%d', ith_step - 1), 'Tooltip', stepHelp{ith_step}, ...
        'ButtonPushedFcn', @(~,~) openStep(ith_step - 1));
    if ith_step == 8
        statusGrid = uigridlayout(stepsGrid, [1 2], 'ColumnWidth', {130, '1x'}, 'Padding', [0 0 0 0], 'BackgroundColor', 'w');
        checksDropdown = uidropdown(statusGrid, 'Items', checkNames, 'Value', 'Labels', 'Tag', 'mainChecksWhich', ...
            'Tooltip', 'Which viewer the Checks button opens (each press opens a new one).');
        stepStatus(ith_step) = uilabel(statusGrid, 'Text', '', 'Interpreter', 'html', 'WordWrap', 'on');
    else
        stepStatus(ith_step) = uilabel(stepsGrid, 'Text', '', 'Interpreter', 'html', 'WordWrap', 'on', ...
            'Tag', sprintf('mainStatus%d', ith_step - 1));
    end
end

% Settings
settingsGrid = uigridlayout(settingsPanel, [6 1], 'RowHeight', {22, 26, 22, 26, 40, '1x'}, 'Padding', [8 8 8 8], ...
    'RowSpacing', 4, 'Scrollable', 'on', 'BackgroundColor', [0.93 0.95 1]);
uilabel(settingsGrid, 'Text', 'Start with which vehicle?', 'FontWeight', 'bold');
startGroup = uibuttongroup(settingsGrid, 'BorderType', 'none', 'Tag', 'mainStartWith', 'BackgroundColor', [0.93 0.95 1], ...
    'SelectionChangedFcn', @(source, ~) setStartWith(source.SelectedObject.UserData));
uiradiobutton(startGroup, 'Text', 'The default', 'UserData', 'default', 'Position', [4 2 110 20], 'Tag', 'mainStartWith_default');
uiradiobutton(startGroup, 'Text', 'The last used', 'UserData', 'last', 'Position', [120 2 120 20], 'Tag', 'mainStartWith_last');
uilabel(settingsGrid, 'Text', 'Turn all views together globally?', 'FontWeight', 'bold');
uilabel(settingsGrid, 'Text', '(coming in the next build: views turning together, with Unlink per window)', ...
    'FontAngle', 'italic', 'WordWrap', 'on');
uilabel(settingsGrid, 'Text', sprintf('Working copies and saved views: %s', workingRoot), 'WordWrap', 'on', 'FontSize', 10);
fcn_INTERNAL_selectStartWith(startGroup);

% Help
helpGrid = uigridlayout(helpPanel, [1 1], 'Padding', [8 8 8 8], 'Scrollable', 'on', 'BackgroundColor', [0.95 0.95 0.95]);
uilabel(helpGrid, 'Interpreter', 'html', 'WordWrap', 'on', 'VerticalAlignment', 'top', 'Text', fcn_INTERNAL_helpText());

set(figureHandle, 'CloseRequestFcn', @(~,~) closeWindow(), 'WindowKeyPressFcn', @onKey);
refresh();
if flagResumed
    setHint('Resumed the unfinished working copy. Commit puts it into the vehicle''s folder; Discard throws it away.');
else
    setHint('A fresh working copy of the vehicle: windows opened here save into it. Work down the steps; Commit when done.');
end

window = struct('Figure', figureHandle, ...
    'State', @() fcn_CarMesh3D_guiDriver(figureHandle, 'state'), ...
    'Press', @(varargin) fcn_CarMesh3D_guiDriver(figureHandle, 'press', varargin{:}), ...
    'Key', @(key, varargin) fcn_CarMesh3D_guiDriver(figureHandle, 'key', key, varargin{:}), ...
    'CheckLayout', @() fcn_CarMesh3D_guiDriver(figureHandle, 'checkLayout'), ...
    'Marks', @getMarks, 'Step', @openStep, 'Build', @() buildWork(), 'Commit', @() commitWork(false), ...
    'Discard', @() discardWork(false), 'Changes', @changedFiles, 'Children', @getChildren, ...
    'WorkingFolder', @() workFolder, 'VehicleFolder', @() vehicleFiles.Folder, 'Refresh', @refresh, ...
    'SaveView', @saveView, 'Close', @closeWindow);
figureHandle.UserData = window;
viewState = [];
loading.Close();

if options.FlagWait && options.FlagVisible && isvalid(figureHandle)
    uiwait(figureHandle);
    viewState = lastViewState();
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the window's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% The marks
    function refresh()
        % Each step's mark and status, from the working copy's files
        if ~isvalid(figureHandle)
            return;
        end
        dropClosed();
        [marks, texts] = fcn_INTERNAL_marks(workFolder, vehicleFiles, workFiles, changedFiles());
        symbols = struct('done', {char(10004)}, 'outOfDate', {char(9888)}, 'notDone', {char(9675)}, 'cannotStart', {char(8856)});
        colors = struct('done', [0.12 0.55 0.2], 'outOfDate', [0.85 0.45 0], 'notDone', [0.5 0.5 0.5], 'cannotStart', [0.7 0.7 0.7]);
        for ith_mark = 1:10
            if isempty(marks{ith_mark})
                markLabels(ith_mark).Text = '';
            else
                markLabels(ith_mark).Text = symbols.(marks{ith_mark});
                markLabels(ith_mark).FontColor = colors.(marks{ith_mark});
            end
            stepButtons(ith_mark).Enable = matlab.lang.OnOffSwitchState(~strcmp(marks{ith_mark}, 'cannotStart'));
            stepStatus(ith_mark).Text = texts{ith_mark};
        end
        numChanged = numel(changedFiles());
        if numChanged == 0
            statusLabel.Text = 'No changes';
        else
            statusLabel.Text = sprintf('<font color="#b05000"><b>Not committed:</b> %d file(s) changed</font>', numChanged);
        end
        workLabel.Text = sprintf('Working copy: %s', workFolder);
        figureHandle.Name = sprintf('fcn_CarMesh3D_main: %s', vehicleFiles.Name);
    end

    function marksOut = getMarks()
        refresh();
        marksOut = marks;
    end

    function files = changedFiles()
        files = fcn_INTERNAL_changedFiles(workFolder, vehicleFiles.Folder);
    end

    %% The steps
    function openStep(stepNumber)
        refresh();
        if strcmp(marks{stepNumber + 1}, 'cannotStart')
            setHint(sprintf('%s cannot start yet: %s', stepNames{stepNumber + 1}, ...
                regexprep(stepStatus(stepNumber + 1).Text, '<[^>]*>', '')));
            return;
        end
        switch stepNumber
            case 0
                pickVehicle();
            case 1
                importReport();
            case {2, 5}
                openChild('painter', 'Painter', @() fcn_CarMesh3D_paintLabels(workFolder, FlagVisible=options.FlagVisible));
            case 3
                openChild('faces', 'Face directions', @() fcn_CarMesh3D_fixFaceDirections(workFolder, FlagVisible=options.FlagVisible));
            case 4
                buildWork();
            case 6
                openChild('lampFunctions', 'Lamp functions', @() fcn_CarMesh3D_editLampFunctions(workFolder, FlagVisible=options.FlagVisible));
            case 7
                openViewer(checksDropdown.Value);
            case 8
                openChild('review', 'V&V', @() fcn_CarMesh3D_reviewVehicle(workFolder, FlagVisible=options.FlagVisible));
            case 9
                commitWork(true);
        end
        refresh();
    end

    function importReport()
        loaded = load(workFiles.MeshFile, 'vehicleMesh');
        figureNumber = fcn_INTERNAL_freeFigure();
        report = fcn_CarMesh3D_importReport(loaded.vehicleMesh, FigNum=figureNumber);
        reportFigure = figure(figureNumber);
        if ~options.FlagVisible
            reportFigure.Visible = 'off';
        end
        children(end+1) = struct('Kind', 'viewer', 'Name', 'Import report', 'Figure', reportFigure);
        setHint(sprintf('Import report: %s', report.GateText));
    end

    function pickVehicle()
        % The browser picks; this window then opens that vehicle (the
        % trunk opens, never the browser)
        if ~closeEditors(true, true)
            return;
        end
        selected = fcn_CarMesh3D_browseLibrary(DefaultVehicle=vehicleID, FlagWait=options.FlagVisible, FlagVisible=options.FlagVisible);
        if isempty(selected)
            return;
        end
        newID = char(string(selected(1)));
        if strcmp(newID, vehicleID)
            return;
        end
        if ~isempty(changedFiles()) && options.FlagVisible
            choice = uiconfirm(figureHandle, sprintf('%s has changes not committed. What should happen to them?', vehicleFiles.Name), ...
                'Changing vehicle', 'Options', {'Commit', 'Discard', 'Keep for later', 'Cancel'}, 'DefaultOption', 3, 'CancelOption', 4);
            switch choice
                case 'Cancel'
                    return;
                case 'Commit'
                    if ~commitWork(false)
                        return;
                    end
                case 'Discard'
                    discardWork(false);
            end
        end
        closeWindow();
        fcn_CarMesh3D_main(newID, WorkingRoot=workingRoot, FlagVisible=options.FlagVisible);
    end

    function openViewer(which)
        switch which
            case 'Labels'
                opener = @() fcn_CarMesh3D_viewLabels(workFiles.MeshFile, Outline=workFiles.OutlineFile, FlagVisible=options.FlagVisible);
            case 'Dimensions'
                opener = @() fcn_CarMesh3D_viewDimensions(workFolder, FlagVisible=options.FlagVisible);
            case 'Orientation'
                opener = @() fcn_CarMesh3D_viewOrientation(workFolder, FlagVisible=options.FlagVisible);
            case 'Detail levels'
                opener = @() fcn_CarMesh3D_viewDetailLevels(workFolder, FlagVisible=options.FlagVisible);
            case 'Outline'
                opener = @() fcn_CarMesh3D_viewOutline(workFolder, FlagVisible=options.FlagVisible);
            otherwise
                return;
        end
        openChild('viewer', which, opener);
    end

    function openChild(kind, name, opener)
        % Opens a window, after closing what it may not share the screen
        % with: one editor at a time; any editor closes V&V; V&V closes
        % the editor
        if any(strcmp(kind, editorKinds))
            if ~closeEditors(true, true)
                return;
            end
        elseif strcmp(kind, 'review')
            if ~closeEditors(true, true)
                return;
            end
        end
        figuresBefore = findall(groot, 'Type', 'figure');
        try
            opener();
        catch openError
            setHint(sprintf('<font color="#b00000">%s could not open: %s</font>', name, openError.message));
            return;
        end
        newFigures = setdiff(findall(groot, 'Type', 'figure'), figuresBefore);
        newFigures = newFigures(isvalid(newFigures) & ~strcmp(get(newFigures, 'Tag'), 'loadingWindow'));
        for ith_figure = 1:numel(newFigures)
            children(end+1) = struct('Kind', kind, 'Name', name, 'Figure', newFigures(ith_figure)); %#ok<AGROW>
        end
        setHint(sprintf('%s opened on the working copy.', name));
    end

    function flagClosed = closeEditors(flagEditors, flagReview)
        % Closes the open editors and/or V&V through their own close (each
        % asks about unsaved changes); false if one was kept open
        dropClosed();
        flagClosed = true;
        for ith_child = numel(children):-1:1
            thisKind = children(ith_child).Kind;
            if (flagEditors && any(strcmp(thisKind, editorKinds))) || (flagReview && strcmp(thisKind, 'review'))
                close(children(ith_child).Figure);
                drawnow;
                if isvalid(children(ith_child).Figure)
                    flagClosed = false;
                    setHint(sprintf('%s is still open (its close was cancelled).', children(ith_child).Name));
                end
            end
        end
        dropClosed();
    end

    function dropClosed()
        if isempty(children)
            return;
        end
        children = children(arrayfun(@(child) isvalid(child.Figure), children));
    end

    function childrenOut = getChildren()
        dropClosed();
        childrenOut = children;
    end

    %% Build, Commit, Discard
    function flagBuilt = buildWork()
        % Runs the vehicle's script in the working copy (it builds in
        % place: Q111)
        flagBuilt = false;
        if ~closeEditors(true, true)
            return;
        end
        building = fcn_CarMesh3D_loadingWindow('Building the working copy (a minute or two)', Vehicle=vehicleID, FlagVisible=options.FlagVisible);
        buildCleanup = onCleanup(@() building.Close()); %#ok<NASGU>
        logFile = fullfile(workFolder, 'buildLog.txt');
        try
            assignin('base', 'zzCarMesh3DMainScript', workFiles.ScriptFile);
            visibleBefore = get(groot, 'DefaultFigureVisible');
            set(groot, 'DefaultFigureVisible', 'off');
            restoreVisible = onCleanup(@() set(groot, 'DefaultFigureVisible', visibleBefore)); %#ok<NASGU>
            output = evalin('base', 'evalc(''run(zzCarMesh3DMainScript)'')');
            evalin('base', 'clear zzCarMesh3DMainScript');
            fcn_INTERNAL_writeText(logFile, output);
            flagBuilt = true;
            setHint(sprintf('Built in the working copy. The log: %s', logFile));
        catch buildError
            fcn_INTERNAL_writeText(logFile, getReport(buildError, 'extended', 'hyperlinks', 'off'));
            setHint(sprintf('<font color="#b00000">The build failed: %s (log: %s)</font>', buildError.message, logFile));
        end
        building.Close();
        workFiles = fcn_CarMesh3D_findVehicleFiles(workFolder, FigNum=-1);
        refresh();
    end

    function flagDone = commitWork(flagAsk)
        % The working copy into the vehicle's folder: built first if the
        % build is out of date; then its files copied across, a row in the
        % change log, and the working copy removed (a fresh one is made)
        flagDone = false;
        refresh();
        files = changedFiles();
        if isempty(files)
            setHint('Nothing to commit: the working copy is the same as the vehicle''s folder.');
            return;
        end
        if flagAsk && options.FlagVisible
            choice = uiconfirm(figureHandle, sprintf('Commit %d changed file(s) into %s?\n%s', numel(files), vehicleFiles.Folder, ...
                strjoin(files(1:min(end,12)), ', ')), 'Commit', 'Options', {'Commit', 'Cancel'}, 'DefaultOption', 1, 'CancelOption', 2);
            if ~strcmp(choice, 'Commit')
                return;
            end
        end
        if ~closeEditors(true, true)
            return;
        end
        if strcmp(marks{5}, 'outOfDate') || strcmp(marks{5}, 'notDone')
            if ~buildWork()
                return;
            end
            files = changedFiles();
        end
        for ith_file = 1:numel(files)
            target = fullfile(vehicleFiles.Folder, files{ith_file});
            targetFolder = fileparts(target);
            if ~isfolder(targetFolder)
                mkdir(targetFolder);
            end
            copyfile(fullfile(workFolder, files{ith_file}), target, 'f');
        end
        whoName = 'SBB';
        try
            if ispref('CarMesh3D', 'Initials')
                whoName = char(getpref('CarMesh3D', 'Initials'));
            end
        catch
        end
        try
            fcn_CarMesh3D_meshHistory(vehicleFiles.Folder, Action='committed', Who=whoName, ...
                Details=sprintf('from the main window: %s', strjoin(files, ', ')), FigNum=-1);
        catch
        end
        closeViewers();
        fcn_INTERNAL_remove(workFolder);
        fcn_INTERNAL_makeWorkingCopy(vehicleFiles.Folder, workFolder);
        workFiles = fcn_CarMesh3D_findVehicleFiles(workFolder, FigNum=-1);
        refresh();
        setHint(sprintf('Committed %d file(s) into the vehicle''s folder; a fresh working copy was made.', numel(files)));
        flagDone = true;
    end

    function discardWork(flagAsk)
        if flagAsk && options.FlagVisible
            choice = uiconfirm(figureHandle, ['Throw the working copy away (every change not committed), ' ...
                'and start again from the vehicle''s committed files?'], 'Discard', ...
                'Options', {'Discard', 'Cancel'}, 'DefaultOption', 2, 'CancelOption', 2);
            if ~strcmp(choice, 'Discard')
                return;
            end
        end
        if ~closeEditors(true, true)
            return;
        end
        closeViewers();
        fcn_INTERNAL_remove(workFolder);
        fcn_INTERNAL_makeWorkingCopy(vehicleFiles.Folder, workFolder);
        workFiles = fcn_CarMesh3D_findVehicleFiles(workFolder, FigNum=-1);
        refresh();
        setHint('Discarded: a fresh working copy from the vehicle''s committed files.');
    end

    function closeViewers()
        dropClosed();
        for ith_child = numel(children):-1:1
            if strcmp(children(ith_child).Kind, 'viewer')
                delete(children(ith_child).Figure);
            end
        end
        dropClosed();
    end

    %% The view state
    function state = lastViewState()
        state = getappdata(groot, 'CarMesh3D_mainLastView');
    end

    function state = saveView()
        dropClosed();
        screen = get(groot, 'ScreenSize');
        windows = struct('Kind', {}, 'Name', {}, 'Position', {});
        windows(end+1) = struct('Kind', 'main', 'Name', 'Main', 'Position', fcn_INTERNAL_fraction(figureHandle.Position, screen));
        for ith_child = 1:numel(children)
            windows(end+1) = struct('Kind', children(ith_child).Kind, 'Name', children(ith_child).Name, ...
                'Position', fcn_INTERNAL_fraction(children(ith_child).Figure.Position, screen)); %#ok<AGROW>
        end
        startWith = 'default';
        try
            if ispref('CarMesh3D', 'MainStartWith')
                startWith = getpref('CarMesh3D', 'MainStartWith');
            end
        catch
        end
        state = struct('Vehicle', vehicleID, 'WorkingFolder', workFolder, 'Settings', struct('StartWith', startWith), ...
            'Windows', windows, 'SavedOn', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')));
        viewsFolder = fullfile(workingRoot, 'views');
        if ~isfolder(viewsFolder)
            mkdir(viewsFolder);
        end
        viewState = state;
        save(fullfile(viewsFolder, sprintf('mainView_%s_%s.mat', vehicleID, char(datetime('now', 'Format', 'yyyy_MM_dd_HHmmss')))), 'viewState');
        setappdata(groot, 'CarMesh3D_mainLastView', state);
        setHint(sprintf('View saved in %s.', viewsFolder));
    end

    %% Small things
    function setHint(textIn)
        if isvalid(hintLabel)
            hintLabel.Text = textIn;
        end
    end

    function setMenuWidth(width)
        bodyGrid.ColumnWidth{1} = width;
    end

    function setStartWith(value)
        try
            setpref('CarMesh3D', 'MainStartWith', char(value));
        catch
        end
    end

    function onKey(~, event)
        if strcmp(event.Key, 'escape') && isempty(event.Modifier)
            setHint('');
        end
    end

    function closeWindow()
        % Closes every window opened from here (each asks about its own
        % unsaved changes; a cancel keeps this window open), saves the
        % view, and closes
        if ~isvalid(figureHandle)
            return;
        end
        if ~closeEditors(true, true)
            return;
        end
        saveView();
        closeViewers();
        if isequal(getappdata(groot, 'CarMesh3D_mainWindow'), figureHandle)
            rmappdata(groot, 'CarMesh3D_mainWindow');
        end
        delete(figureHandle);
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

%% fcn_INTERNAL_marks
function [marks, texts] = fcn_INTERNAL_marks(workFolder, vehicleFiles, workFiles, changed)
% Each step's mark ('done', 'outOfDate', 'notDone', 'cannotStart', or ''
% for none) and a short status, from the working copy's files (rule G40:
% the item's data is the truth)
marks = repmat({''}, 1, 10);
texts = repmat({''}, 1, 10);
ID = vehicleFiles.ID;
timeOf = @(file) fcn_INTERNAL_time(fullfile(workFolder, file));
meshTime = fcn_INTERNAL_time(workFiles.MeshFile);
labelsTime = timeOf(sprintf('labelEdits_%s.mat', ID));
flipsTime = timeOf(sprintf('faceFlips_%s.mat', ID));
lampTime = timeOf(sprintf('lampFunctions_%s.csv', ID));
scriptTime = fcn_INTERNAL_time(workFiles.ScriptFile);
flagMesh = ~isnan(meshTime);

% 0 Vehicle
marks{1} = 'done';
texts{1} = vehicleFiles.Name;

% 1 Import, 2 First labels (the import report's gate)
if ~flagMesh
    marks{2} = 'cannotStart';
    texts{2} = 'No mesh yet: build it (step 4).';
    marks{3} = 'notDone';
else
    [flagGate, gateText] = fcn_INTERNAL_gate(workFiles.MeshFile, meshTime);
    marks{2} = fcn_INTERNAL_pick(flagGate, 'done', 'notDone');
    texts{2} = gateText;
    marks{3} = marks{2};
    texts{3} = fcn_INTERNAL_pick(flagGate, 'Lamps and glass are told apart.', 'Paint the lamps and the glass apart from the body.');
end

% 3 Face directions: saved after the last change to the labels
if isnan(flipsTime)
    marks{4} = 'notDone';
    texts{4} = 'No face flips saved yet (none may be needed).';
elseif ~isnan(labelsTime) && labelsTime > flipsTime
    marks{4} = 'outOfDate';
    texts{4} = 'The labels changed after the face flips were saved.';
else
    marks{4} = 'done';
    texts{4} = 'Face flips saved.';
end

% 4 Build: the mesh newer than every edit and the script
newestEdit = max([labelsTime, flipsTime, scriptTime], [], 'omitnan');
if ~flagMesh
    marks{5} = 'notDone';
    texts{5} = 'Not built yet.';
elseif ~isnan(newestEdit) && newestEdit > meshTime
    marks{5} = 'outOfDate';
    texts{5} = 'Edits were saved after the last build: build again.';
else
    marks{5} = 'done';
    texts{5} = sprintf('Built %s.', char(datetime(meshTime, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd HH:mm')));
end

% 5 Full labels: every lamp face has a kind
if ~flagMesh
    marks{6} = 'cannotStart';
    texts{6} = 'Build the mesh first (step 4).';
else
    [marks{6}, texts{6}] = fcn_INTERNAL_lampKinds(workFiles.MeshFile);
end

% 6 Lamp functions
if ~flagMesh
    marks{7} = 'cannotStart';
    texts{7} = 'Build the mesh first (step 4).';
elseif isnan(lampTime)
    marks{7} = 'notDone';
    texts{7} = 'No lamp functions saved yet.';
elseif lampTime < meshTime && ~isnan(labelsTime) && labelsTime > lampTime
    marks{7} = 'outOfDate';
    texts{7} = 'The labels changed after the lamp functions were saved.';
else
    marks{7} = 'done';
    texts{7} = 'Lamp functions saved.';
end

% 7 Checks (no mark of its own)
if ~flagMesh
    marks{8} = 'cannotStart';
    texts{8} = 'Build the mesh first.';
end

% 8 V&V
if ~flagMesh
    marks{9} = 'cannotStart';
    texts{9} = 'Build the mesh first (step 4).';
else
    reviewFiles = [dir(fullfile(workFolder, '*review*')); dir(fullfile(workFolder, 'checks', 'review_*.mat'))];
    if isempty(reviewFiles)
        marks{9} = 'notDone';
        texts{9} = 'Not reviewed yet.';
    elseif max([reviewFiles.datenum]) < meshTime
        marks{9} = 'outOfDate';
        texts{9} = 'The mesh was built again after the review.';
    else
        marks{9} = 'done';
        texts{9} = 'Reviewed.';
    end
end

% 9 Commit
if isempty(changed)
    marks{10} = 'done';
    texts{10} = 'Nothing to commit.';
else
    marks{10} = 'notDone';
    texts{10} = sprintf('%d file(s) not committed.', numel(changed));
end
end % Ends fcn_INTERNAL_marks

%% fcn_INTERNAL_gate
function [flagGate, gateText] = fcn_INTERNAL_gate(meshFile, meshTime)
% The import report's gate, kept until the mesh file changes (it takes a
% few seconds on a large mesh, and the marks are refreshed often)
persistent lastFile lastTime lastGate lastText
if isequal(lastFile, meshFile) && isequal(lastTime, meshTime)
    flagGate = lastGate;
    gateText = lastText;
    return;
end
flagGate = false;
gateText = '';
try
    loaded = load(meshFile, 'vehicleMesh');
    report = fcn_CarMesh3D_importReport(loaded.vehicleMesh, FigNum=-1);
    flagGate = report.Gate;
    gateText = report.GateText;
catch
end
lastFile = meshFile;
lastTime = meshTime;
lastGate = flagGate;
lastText = gateText;
end % Ends fcn_INTERNAL_gate

%% fcn_INTERNAL_lampKinds
function [mark, text] = fcn_INTERNAL_lampKinds(meshFile)
% Every face labeled as a lamp part has a lamp kind
mark = 'notDone';
text = 'Paint which lamp is which.';
try
    loaded = load(meshFile, 'vehicleMesh');
    vehicleMesh = loaded.vehicleMesh;
    if ~isfield(vehicleMesh, 'LabelFacePart') || ~isfield(vehicleMesh, 'LabelPartNames')
        return;
    end
    lightIndex = find(strcmp(cellstr(vehicleMesh.LabelPartNames), 'light'));
    flagLight = ismember(vehicleMesh.LabelFacePart(:), lightIndex);
    lampKind = zeros(numel(flagLight), 1);
    if isfield(vehicleMesh, 'LabelFaceLamp') && numel(vehicleMesh.LabelFaceLamp) == numel(flagLight)
        lampKind = double(vehicleMesh.LabelFaceLamp(:));
    end
    numWithout = nnz(flagLight & lampKind == 0);
    numLamp = nnz(lampKind > 0);
    if numLamp > 0 && numWithout == 0
        mark = 'done';
        text = sprintf('%d lamp faces, every one with a kind.', numLamp);
    else
        text = sprintf('%d lamp faces with a kind; %d light faces without one.', numLamp, numWithout);
    end
catch
end
end % Ends fcn_INTERNAL_lampKinds

%% fcn_INTERNAL_changedFiles
function files = fcn_INTERNAL_changedFiles(workFolder, vehicleFolder)
% The working copy's files (not its cache) that are new or differ from the
% vehicle's, as paths relative to the folder. The change log and the
% build log do not count.
files = {};
if ~isfolder(workFolder)
    return;
end
listing = dir(fullfile(workFolder, '**', '*'));
listing = listing(~[listing.isdir]);
for ith_file = 1:numel(listing)
    fullName = fullfile(listing(ith_file).folder, listing(ith_file).name);
    relative = fullName(numel(workFolder) + 2:end);
    if startsWith(relative, ['cache' filesep]) || startsWith(listing(ith_file).name, 'meshHistory_') ...
            || strcmp(listing(ith_file).name, 'buildLog.txt')
        continue;
    end
    other = fullfile(vehicleFolder, relative);
    if ~isfile(other) || ~fcn_INTERNAL_sameFile(fullName, other)
        files{end+1} = relative; %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_changedFiles

%% fcn_INTERNAL_sameFile
function flagSame = fcn_INTERNAL_sameFile(fileA, fileB)
infoA = dir(fileA);
infoB = dir(fileB);
flagSame = false;
if infoA.bytes ~= infoB.bytes
    return;
end
fidA = fopen(fileA, 'r');
bytesA = fread(fidA, Inf, '*uint8');
fclose(fidA);
fidB = fopen(fileB, 'r');
bytesB = fread(fidB, Inf, '*uint8');
fclose(fidB);
flagSame = isequal(bytesA, bytesB);
end % Ends fcn_INTERNAL_sameFile

%% fcn_INTERNAL_time
function timeValue = fcn_INTERNAL_time(fileName)
timeValue = NaN;
if ~isempty(fileName) && isfile(fileName)
    info = dir(fileName);
    timeValue = info.datenum;
end
end % Ends fcn_INTERNAL_time

%% fcn_INTERNAL_pick
function value = fcn_INTERNAL_pick(flag, valueTrue, valueFalse)
if flag
    value = valueTrue;
else
    value = valueFalse;
end
end % Ends fcn_INTERNAL_pick

%% fcn_INTERNAL_makeWorkingCopy
function fcn_INTERNAL_makeWorkingCopy(vehicleFolder, workFolder)
% A working copy: the vehicle's folder copied whole (its edits, its script,
% and its built mesh for the viewers); the download stays where it is
parentFolder = fileparts(workFolder);
if ~isfolder(parentFolder)
    mkdir(parentFolder);
end
[flagCopied, message] = copyfile(vehicleFolder, workFolder);
if ~flagCopied
    error('CarMesh3D:workingCopy', 'The vehicle''s folder could not be copied to %s:\n%s', workFolder, message);
end
end % Ends fcn_INTERNAL_makeWorkingCopy

%% fcn_INTERNAL_setAside
function fcn_INTERNAL_setAside(workFolder)
% An unfinished working copy set aside, untouched inside (Resume=false)
newName = sprintf('%s_setAside_%s', workFolder, char(datetime('now', 'Format', 'yyyy_MM_dd_HHmmss')));
[flagMoved, message] = movefile(workFolder, newName);
if ~flagMoved
    error('CarMesh3D:setAside', 'The working copy could not be set aside (is a file in it open?):\n%s\n%s', workFolder, message);
end
end % Ends fcn_INTERNAL_setAside

%% fcn_INTERNAL_remove
function fcn_INTERNAL_remove(folder)
% A working copy removed: to the Recycle Bin on Windows, else deleted
if ~isfolder(folder)
    return;
end
if ispc
    try
        NET.addAssembly('Microsoft.VisualBasic');
        Microsoft.VisualBasic.FileIO.FileSystem.DeleteDirectory(folder, ...
            Microsoft.VisualBasic.FileIO.UIOption.OnlyErrorDialogs, Microsoft.VisualBasic.FileIO.RecycleOption.SendToRecycleBin);
        return;
    catch
    end
end
rmdir(folder, 's');
end % Ends fcn_INTERNAL_remove

%% fcn_INTERNAL_writeText
function fcn_INTERNAL_writeText(fileName, textIn)
fid = fopen(fileName, 'w');
if fid > 0
    fwrite(fid, textIn);
    fclose(fid);
end
end % Ends fcn_INTERNAL_writeText

%% fcn_INTERNAL_fraction
function fraction = fcn_INTERNAL_fraction(position, screen)
% A window's place as fractions of the screen, so a view scales to another
fraction = [(position(1) - screen(1))/screen(3), (position(2) - screen(2))/screen(4), position(3)/screen(3), position(4)/screen(4)];
end % Ends fcn_INTERNAL_fraction

%% fcn_INTERNAL_freeFigure
function figureNumber = fcn_INTERNAL_freeFigure()
figureNumber = 7001;
while ishandle(figureNumber)
    figureNumber = figureNumber + 1;
end
end % Ends fcn_INTERNAL_freeFigure

%% fcn_INTERNAL_askFigure
function askFigure = fcn_INTERNAL_askFigure()
% (a small window to hold a question asked before the main window exists)
askFigure = uifigure('Name', 'fcn_CarMesh3D_main', 'Position', [200 300 420 160]);
end % Ends fcn_INTERNAL_askFigure

%% fcn_INTERNAL_selectStartWith
function fcn_INTERNAL_selectStartWith(group)
startWith = 'default';
try
    if ispref('CarMesh3D', 'MainStartWith')
        startWith = getpref('CarMesh3D', 'MainStartWith');
    end
catch
end
buttons = group.Children;
for ith_button = 1:numel(buttons)
    if strcmp(buttons(ith_button).UserData, startWith)
        group.SelectedObject = buttons(ith_button);
    end
end
end % Ends fcn_INTERNAL_selectStartWith

%% fcn_INTERNAL_helpText
function textOut = fcn_INTERNAL_helpText()
textOut = ['<b>The process</b><br>Work down the steps. Each has a mark:<br>' ...
    '&#10004; done &nbsp; &#9888; out of date (something before it changed) &nbsp; &#9675; not done &nbsp; ' ...
    '&#8856; cannot start yet (its tooltip says why)<br><br>' ...
    '<b>Why this order</b> (agreed 2026-11-27): lamps and glass are painted first, because many downloads come ' ...
    'without them named, and the face directions use them (glass is seen through). The build then works out the ' ...
    'lamp covers and overlays from those. Then the full labels (which lamp is which), then which signals light ' ...
    'each lamp, then the review.<br><br>' ...
    '<b>The working copy</b><br>Every window opened here saves into a working copy of the vehicle, not into the ' ...
    'vehicle itself. Commit puts it into the vehicle''s folder; Discard throws it away. Closing this window keeps ' ...
    'it, to resume next time.<br><br>' ...
    '<b>Windows</b><br>One editing window at a time (painter, face directions, lamp functions); opening one ' ...
    'closes the V&amp;V window. Viewers (Checks): any number.'];
end % Ends fcn_INTERNAL_helpText
