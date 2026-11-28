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
% THE ROWS: do this, then check (Q116 (B), the chart of Sean 2026-11-27
% 21:27). Each row is a command, and a gate: a question with an automatic
% check and, where built, the person's answer (asked in the V&V window and
% kept with a fingerprint, so it goes out of date when its data changes).
% A Yes unlocks the next row; a No sends the user to the fix.
%       Choose a vehicle          Are lamps and glass labeled?  (No: Mark lamps and glass)
%       Turn faces outward        Do all faces point out?
%       Build the mesh            Does the mesh match specs?
%       Name each lamp            Does every lamp have a kind?
%       Wire the lamps            Is every lamp wired?
%       Review all gates          Do you sign it off?
%       Save to the library       (Commit)
% Built so far (one transition at a time): the first gate, with its
% question (fcn_CarMesh3D_assess_lampsAndGlass); "Turn faces outward"
% waits for it. The other gates show their automatic checks. Viewers (the
% View button) open at any time, any number.
%
% Only one editing window (painter, face directions, lamp functions) is
% open at a time; opening one closes the V&V window. Viewers may be open
% in any number.
%
% THE LAYOUT IS REMEMBERED on this computer (Q115 (B), Sean 2026-11-27):
% on closing, where the main window and each window it opened sit on the
% screen (as fractions of the screen, so it scales), and which viewers were
% open. On opening, on any vehicle, the main window goes back to its place
% and the same viewers reopen in theirs; only the vehicle changes. Editors
% and V&V open only when asked, in the place their kind had last.
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
%      LayoutFile: where the remembered layout is kept (tests). Default
%      '': this computer's MATLAB preference (CarMesh3D, MainLayout) when
%      the window is visible; none when hidden.
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
%      (each row's gate: 'done', 'outOfDate', 'notDone', 'failed',
%      'cannotStart' or ''); Step(row) (a row's command, as its button);
%      Check(row) (its gate's question); Fix(row) (its If-No button);
%      View(name) (a viewer: 'Labels', 'Dimensions' ...); Build();
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
%   % * A copy of a vehicle (a demo copy) keeps its working copies beside
%   %   % it, not in CarMesh3D\Working (Sean, 17:33: test on a temporary
%   %   % copy until the window is confirmed)
%   % * The layout remembered on this computer (Q115 (B)): the main
%   %   % window's place, each window's place by kind, and the viewers
%   %   % that were open, reopened on any vehicle; LayoutFile for tests
%   % * The rows as commands and gates (Q116 (B), Sean's chart of 21:27):
%   %   % the first gate built, "Are lamps and glass labeled?" (automatic
%   %   % check and the person's answer); its fix, "Mark lamps and glass";
%   %   % viewers moved to a View button; titles from the title bar
%   %   % ("CarMesh3D"; each window by its row); the dead "Turn all views
%   %   % together" line removed until its switch exists (T99)
%   % * The browser lands on this window's vehicle; closing it with
%   %   % nothing ticked keeps the vehicle (T99, Sean 19:31)
%   % * A working copy with no changes is made fresh on opening, with
%   %   % no question (Claude, before Sean's first look)

% TO-DO:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_main
%   % * Step 2 of the plan: the children told of saves (viewers redraw),
%   %   % views turning together with per-window Unlink, children blocked
%   %   % on their own
%   % * "New from a download" in step 0

arguments
    vehicleInput = []
    options.Vehicle = []
    options.Resume = []
    options.WorkingRoot = ''
    options.FlagWait = false
    options.FlagVisible = true
    options.LayoutFile = ''
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
% (a copy of a vehicle, such as a demo copy: its working copies are kept
% beside it, never in CarMesh3D\Working, so a copy's work can never be
% resumed, or committed, as the real vehicle's; Sean 2026-11-27 17:33)
if isempty(char(options.WorkingRoot))
    try
        libraryFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
        if ~strcmpi(libraryFiles.Folder, vehicleFiles.Folder)
            workingRoot = fullfile(fileparts(vehicleFiles.Folder), 'Working');
        end
    catch
        workingRoot = fullfile(fileparts(vehicleFiles.Folder), 'Working');
    end
end

loading = fcn_CarMesh3D_loadingWindow('Opening the main window', Vehicle=vehicleID, FlagVisible=options.FlagVisible);
loadingCleanup = onCleanup(@() loading.Close()); %#ok<NASGU>

%%%% The working copy (resume, set aside, or a new one)
workFolder = fullfile(workingRoot, vehicleID);
flagResumed = false;
if isfolder(workFolder) && isempty(fcn_INTERNAL_changedFiles(workFolder, vehicleFiles.Folder))
    % (a working copy with no changes: made fresh, nothing to ask; it
    % holds nothing the vehicle's folder does not, so it is deleted)
    rmdir(workFolder, 's');
end
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
% The rows: a command (left), its gate's question (right), and what to do
% if the answer is No (Q116 (B), the chart of Sean 2026-11-27 21:27)
rowActions = {'Choose a vehicle', 'Turn faces outward', 'Build the mesh', 'Name each lamp', ...
    'Wire the lamps', 'Review all gates', 'Save to the library'};
% (each command's tooltip: its description, then the function it calls,
% for debugging; Sean 21:37 and 21:40)
rowActionHelp = {'In the browser. (fcn_CarMesh3D_browseLibrary)', ...
    'Flip inside-out faces. (fcn_CarMesh3D_fixFaceDirections)', ...
    'Run its script, in the working copy. (script_CarMesh3D_vehicle_<ID>)', ...
    'Headlamp, turn signal, marker ... (fcn_CarMesh3D_paintLabels)', ...
    'To their signals, each with a source. (fcn_CarMesh3D_editLampFunctions)', ...
    'The V&V summary of every gate. (fcn_CarMesh3D_reviewVehicle)', ...
    'Commit the vehicle: the working copy into its own folder. (fcn_CarMesh3D_main, Commit)'};
rowQuestionHelp = {'Validate import. (fcn_CarMesh3D_importReport, fcn_CarMesh3D_assess_lampsAndGlass)', ...
    'No red faces left. (fcn_CarMesh3D_outwardSides: to build)', 'Dimension checks pass. (the build''s checks: to build)', ...
    'FMVSS 108 set present. (lamp kinds: to build)', 'Each with a source. (fcn_CarMesh3D_lampSources: to build)', ...
    'Every gate answered Yes. (fcn_CarMesh3D_reviewVehicle)', ''};
rowQuestions = {'Are lamps and glass labeled?', 'Do all faces point out?', 'Does the mesh match specs?', ...
    'Does every lamp have a kind?', 'Is every lamp wired?', 'Do you sign it off?', ''};
rowFix = {'Mark lamps and glass', '', '', '', '', '', ''};
checkNames = {'Labels', 'Dimensions', 'Orientation', 'Detail levels', 'Outline'};
marks = repmat({''}, 1, 10);      % (the checks behind the gates, one per old step)
rowMarks = repmat({''}, 1, 7);    % (each row's gate: 'done', 'outOfDate', 'notDone', 'failed', 'cannotStart')
gateOne = struct('Auto', false, 'Human', '', 'Mark', '', 'Text', '');

%%%% The window: a title bar; a top bar (the menu, Commit, Discard, the
%%%% status); the steps; a hint line
visibleText = 'on';
if ~options.FlagVisible
    visibleText = 'off';
end
figureHandle = uifigure('Name', 'CarMesh3D', 'Position', [60 80 900 640], ...
    'Visible', visibleText, 'Tag', 'mainWindow');
setappdata(groot, 'CarMesh3D_mainWindow', figureHandle);
contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_main', Subtitle=vehicleFiles.Name, FigNum=-1);
rootGrid = uigridlayout(contentPanel, [4 1], 'RowHeight', {36, 24, '1x', 20}, 'Padding', [6 4 6 4], 'RowSpacing', 3);
topGrid = uigridlayout(rootGrid, [1 7], 'ColumnWidth', {90, 90, 90, 90, 130, 70, '1x'}, 'Padding', [0 2 0 2], 'ColumnSpacing', 6);
menuButton = uibutton(topGrid, 'Text', [char(9776) ' Menu'], 'FontWeight', 'bold', 'FontSize', 13, 'Tag', 'mainMenu', ...
    'Tooltip', 'Settings and Help (pick an open one again to close it)');
uibutton(topGrid, 'Text', 'Commit', 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.95 0.85], 'Tag', 'mainCommit', ...
    'ButtonPushedFcn', @(~,~) commitWork(true), 'Tooltip', 'Put the working copy into the vehicle''s own folder (Save to the library).');
uibutton(topGrid, 'Text', 'Discard', 'Tag', 'mainDiscard', 'ButtonPushedFcn', @(~,~) discardWork(true), ...
    'Tooltip', 'Throw the working copy away and start again from the vehicle''s committed files (asks first).');
uibutton(topGrid, 'Text', 'Save view', 'Tag', 'mainSaveView', 'ButtonPushedFcn', @(~,~) saveView(), ...
    'Tooltip', 'Save the open windows'' places and the settings, to open the same view later.');
% (viewers: any number, at any step; looking finishes nothing, so they
% are not a row)
checksDropdown = uidropdown(topGrid, 'Items', checkNames, 'Value', 'Labels', 'Tag', 'mainChecksWhich', ...
    'Tooltip', 'Which viewer the View button opens (each press opens a new one).');
uibutton(topGrid, 'Text', 'View', 'Tag', 'mainView', 'ButtonPushedFcn', @(~,~) openViewer(checksDropdown.Value), ...
    'Tooltip', 'Open a viewer of the working copy (any number at once).');
statusLabel = uilabel(topGrid, 'Text', '', 'Interpreter', 'html', 'FontSize', 12, 'Tag', 'mainStatus');
workLabel = uilabel(rootGrid, 'Text', '', 'Interpreter', 'html', 'FontSize', 11, 'Tag', 'mainWorking');
bodyGrid = uigridlayout(rootGrid, [1 2], 'ColumnWidth', {0, '1x'}, 'Padding', [0 0 0 0], 'ColumnSpacing', 6);
menuColumn = uipanel(bodyGrid, 'BorderType', 'none');
panelMenu = fcn_CarMesh3D_makePanelMenu(menuButton, menuColumn, Resize=@(width) setMenuWidth(width), ...
    Exit=@() closeWindow(), ExitTag='mainExit', FigNum=-1);
settingsPanel = panelMenu.AddPanel('Settings', [0.93 0.95 1]);
helpPanel = panelMenu.AddPanel('Help: the process', [0.95 0.95 0.95]);
stepsPanel = uipanel(bodyGrid, 'Title', 'Do this, then check (each Yes unlocks the next row)', 'FontWeight', 'bold', 'BackgroundColor', 'w');
hintLabel = uilabel(rootGrid, 'Text', '', 'Interpreter', 'html', 'FontColor', [0.35 0.35 0.35], 'Tag', 'mainHint');

% The rows: the gate's mark, the command, the gate (its question and
% status), its Check button, and what to do if the answer is No
stepsGrid = uigridlayout(stepsPanel, [8 5], 'RowHeight', [{18}, repmat({48}, 1, 7)], 'ColumnWidth', {28, 170, '1x', 70, 160}, ...
    'Padding', [8 8 8 8], 'RowSpacing', 6, 'ColumnSpacing', 8, 'Scrollable', 'on', 'BackgroundColor', 'w');
headerTexts = {'', 'Do this', 'Then check', '', 'If No'};
for ith_header = 1:5
    uilabel(stepsGrid, 'Text', headerTexts{ith_header}, 'FontWeight', 'bold', 'FontColor', [0.35 0.35 0.35]);
end
markLabels = gobjects(1, 7);
stepButtons = gobjects(1, 7);
stepStatus = gobjects(1, 7);
checkButtons = gobjects(1, 7);
fixButtons = gobjects(1, 7);
for ith_step = 1:7
    markLabels(ith_step) = uilabel(stepsGrid, 'Text', '', 'FontSize', 18, 'HorizontalAlignment', 'center', ...
        'Tag', sprintf('mainMark%d', ith_step));
    stepButtons(ith_step) = uibutton(stepsGrid, 'Text', rowActions{ith_step}, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', 'Tag', sprintf('mainStep%d', ith_step), 'Tooltip', rowActionHelp{ith_step}, ...
        'ButtonPushedFcn', @(~,~) openStep(ith_step));
    stepStatus(ith_step) = uilabel(stepsGrid, 'Text', '', 'Interpreter', 'html', 'WordWrap', 'on', ...
        'Tag', sprintf('mainStatus%d', ith_step), 'Tooltip', rowQuestionHelp{ith_step});
    checkButtons(ith_step) = uibutton(stepsGrid, 'Text', 'Check', 'Tag', sprintf('mainCheck%d', ith_step), ...
        'ButtonPushedFcn', @(~,~) checkGate(ith_step), 'Visible', matlab.lang.OnOffSwitchState(ith_step == 1), ...
        'Tooltip', sprintf('Answer the gate''s question: %s %s', rowQuestions{ith_step}, rowQuestionHelp{ith_step}));
    if isempty(rowFix{ith_step})
        fixButtons(ith_step) = uilabel(stepsGrid, 'Text', fcn_INTERNAL_pick(ith_step < 7, 'Do it again', ''), ...
            'FontColor', [0.45 0.45 0.45]);
    else
        fixButtons(ith_step) = uibutton(stepsGrid, 'Text', rowFix{ith_step}, 'Tag', sprintf('mainFix%d', ith_step), ...
            'ButtonPushedFcn', @(~,~) fixGate(ith_step), ...
            'Tooltip', 'Mark the lamps and the glass apart from the body, then Check again. (fcn_CarMesh3D_paintLabels)');
    end
end

% Settings
settingsGrid = uigridlayout(settingsPanel, [4 1], 'RowHeight', {22, 26, 40, '1x'}, 'Padding', [8 8 8 8], ...
    'RowSpacing', 4, 'Scrollable', 'on', 'BackgroundColor', [0.93 0.95 1]);
uilabel(settingsGrid, 'Text', 'Start with which vehicle?', 'FontWeight', 'bold');
startGroup = uibuttongroup(settingsGrid, 'BorderType', 'none', 'Tag', 'mainStartWith', 'BackgroundColor', [0.93 0.95 1], ...
    'SelectionChangedFcn', @(source, ~) setStartWith(source.SelectedObject.UserData));
uiradiobutton(startGroup, 'Text', 'The default', 'UserData', 'default', 'Position', [4 2 110 20], 'Tag', 'mainStartWith_default');
uiradiobutton(startGroup, 'Text', 'The last used', 'UserData', 'last', 'Position', [120 2 120 20], 'Tag', 'mainStartWith_last');
% (Turn all views together globally? comes back with its switch, in step 2
% of the plan: T99, Sean 21:01, no line without a control)
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
    'Marks', @getMarks, 'Step', @openStep, 'Check', @checkGate, 'Fix', @fixGate, 'View', @openViewer, 'Build', @() buildWork(), 'Commit', @() commitWork(false), ...
    'Discard', @() discardWork(false), 'Changes', @changedFiles, 'Children', @getChildren, ...
    'WorkingFolder', @() workFolder, 'VehicleFolder', @() vehicleFiles.Folder, 'Refresh', @refresh, ...
    'SaveView', @saveView, 'Close', @closeWindow);
figureHandle.UserData = window;
viewState = [];
loading.Close();
applyLayout();

if options.FlagWait && options.FlagVisible && isvalid(figureHandle)
    uiwait(figureHandle);
    viewState = lastViewState();
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nested functions: they share the window's state above
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %% The marks
    function refresh()
        % Each row's gate, from the working copy's files (rule G40: the
        % item's data is the truth)
        if ~isvalid(figureHandle)
            return;
        end
        dropClosed();
        [marks, texts] = fcn_INTERNAL_marks(workFolder, vehicleFiles, workFiles, changedFiles());
        gateOne = fcn_INTERNAL_gateOne(workFolder, workFiles, ~isnan(fcn_INTERNAL_time(workFiles.MeshFile)));
        % (old step -> row: faces 4 -> 2, build 5 -> 3, lamp kinds 6 -> 4,
        % lamp functions 7 -> 5, V&V 9 -> 6, commit 10 -> 7)
        rowMarks = [{gateOne.Mark}, marks([4 5 6 7 9 10])];
        rowTexts = [{gateOne.Text}, texts([4 5 6 7 9 10])];
        symbols = struct('done', {char(10004)}, 'outOfDate', {char(9888)}, 'notDone', {char(9675)}, ...
            'cannotStart', {char(8856)}, 'failed', {char(10008)});
        colors = struct('done', [0.12 0.55 0.2], 'outOfDate', [0.85 0.45 0], 'notDone', [0.5 0.5 0.5], ...
            'cannotStart', [0.7 0.7 0.7], 'failed', [0.75 0.1 0.1]);
        for ith_row = 1:7
            if isempty(rowMarks{ith_row})
                markLabels(ith_row).Text = '';
            else
                markLabels(ith_row).Text = symbols.(rowMarks{ith_row});
                markLabels(ith_row).FontColor = colors.(rowMarks{ith_row});
            end
            stepButtons(ith_row).Enable = matlab.lang.OnOffSwitchState(~strcmp(rowMarks{ith_row}, 'cannotStart') && rowUnlocked(ith_row));
            question = '';
            if ~isempty(rowQuestions{ith_row})
                question = sprintf('<b>%s</b><br>', rowQuestions{ith_row});
            end
            stepStatus(ith_row).Text = [question rowTexts{ith_row}];
        end
        % (the fix: open until the gate passes)
        fixButtons(1).Enable = matlab.lang.OnOffSwitchState(~strcmp(rowMarks{1}, 'done'));
        numChanged = numel(changedFiles());
        if numChanged == 0
            statusLabel.Text = 'No changes';
        else
            statusLabel.Text = sprintf('<font color="#b05000"><b>Not committed:</b> %d file(s) changed</font>', numChanged);
        end
        workLabel.Text = sprintf('Working copy: %s', workFolder);
    end

    function flagUnlocked = rowUnlocked(rowNumber)
        % A row's command is open once the gate above it has passed (Q116
        % (B)). Built so far: the first gate (row 2 waits for it); the
        % other rows wait only for their inputs (Q118 decides the rest)
        flagUnlocked = true;
        if rowNumber == 2
            flagUnlocked = strcmp(rowMarks{1}, 'done');
        end
    end

    function marksOut = getMarks()
        refresh();
        marksOut = rowMarks;
    end

    function files = changedFiles()
        files = fcn_INTERNAL_changedFiles(workFolder, vehicleFiles.Folder);
    end

    %% The rows
    function openStep(rowNumber)
        % A row's command
        refresh();
        if strcmp(rowMarks{rowNumber}, 'cannotStart') || ~rowUnlocked(rowNumber)
            if ~rowUnlocked(rowNumber)
                setHint(sprintf('"%s" opens once "%s" is answered Yes.', rowActions{rowNumber}, rowQuestions{rowNumber - 1}));
            else
                setHint(sprintf('"%s" cannot start yet: %s', rowActions{rowNumber}, regexprep(stepStatus(rowNumber).Text, '<[^>]*>', ' ')));
            end
            return;
        end
        switch rowNumber
            case 1
                pickVehicle();
            case 2
                openChild('faces', 'Turn Faces Outward', @() fcn_CarMesh3D_fixFaceDirections(workFolder, FlagVisible=options.FlagVisible));
            case 3
                buildWork();
            case 4
                openChild('painter', 'Name Each Lamp', @() fcn_CarMesh3D_paintLabels(workFolder, FlagVisible=options.FlagVisible));
            case 5
                openChild('lampFunctions', 'Wire the Lamps', @() fcn_CarMesh3D_editLampFunctions(workFolder, FlagVisible=options.FlagVisible));
            case 6
                openChild('review', 'V&V Review', @() fcn_CarMesh3D_reviewVehicle(workFolder, FlagVisible=options.FlagVisible));
            case 7
                commitWork(true);
        end
        refresh();
    end

    function checkGate(rowNumber)
        % A gate's question, asked in the V&V window (its answer is kept
        % with a fingerprint of what it rested on)
        if rowNumber ~= 1
            return;
        end
        openChild('review', 'Validate Import', @() fcn_CarMesh3D_reviewVehicle(workFolder, ...
            Assessments={@fcn_CarMesh3D_assess_lampsAndGlass}, FlagVisible=options.FlagVisible));
        refresh();
    end

    function fixGate(rowNumber)
        if rowNumber ~= 1
            return;
        end
        openChild('painter', 'Mark Lamps and Glass', @() fcn_CarMesh3D_paintLabels(workFolder, FlagVisible=options.FlagVisible));
        refresh();
    end

    function pickVehicle()
        % The browser picks; this window then opens that vehicle (the
        % trunk opens, never the browser)
        if ~closeEditors(true, true)
            return;
        end
        % (the browser lands on this window's vehicle; T99, Sean 19:31)
        selected = fcn_CarMesh3D_browseLibrary(Preview=vehicleID, DefaultVehicle=vehicleID, ...
            FlagWait=options.FlagVisible, FlagVisible=options.FlagVisible);
        if isempty(selected)
            return;
        end
        newID = char(string(selected(1)));
        if isfolder(newID)
            % (nothing ticked: the browser returns a fresh demo copy of
            % its default vehicle; the main window keeps its vehicle)
            return;
        end
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
            placeChild(newFigures(ith_figure), kind, name);
            fcn_INTERNAL_retitle(newFigures(ith_figure), name);
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

    %% The remembered layout (Q115 (B))
    function layout = readLayout()
        layout = struct('Kind', {}, 'Name', {}, 'Position', {}, 'Open', {});
        try
            if ~isempty(options.LayoutFile)
                if isfile(options.LayoutFile)
                    loadedLayout = load(options.LayoutFile, 'layout');
                    layout = loadedLayout.layout;
                end
            elseif options.FlagVisible && ispref('CarMesh3D', 'MainLayout')
                layout = getpref('CarMesh3D', 'MainLayout');
            end
        catch
        end
    end

    function writeLayout(layout)
        try
            if ~isempty(options.LayoutFile)
                save(options.LayoutFile, 'layout');
            elseif options.FlagVisible   % (tests never change a shared preference)
                setpref('CarMesh3D', 'MainLayout', layout);
            end
        catch
        end
    end

    function layout = currentLayout()
        % Where each window sits now; viewers marked open. A window's
        % place is kept per kind and name, the n-th of its kind by order
        dropClosed();
        screen = get(groot, 'ScreenSize');
        layout = readLayout();
        if ~isempty(layout)
            [layout.Open] = deal(false);
        end
        entries = [struct('Kind', 'main', 'Name', 'Main', 'Figure', figureHandle), children];
        counts = containers.Map();
        for ith_entry = 1:numel(entries)
            key = sprintf('%s|%s', entries(ith_entry).Kind, entries(ith_entry).Name);
            if isKey(counts, key)
                counts(key) = counts(key) + 1;
            else
                counts(key) = 1;
            end
            name = entries(ith_entry).Name;
            if counts(key) > 1
                name = sprintf('%s #%d', name, counts(key));
            end
            position = fcn_INTERNAL_fraction(entries(ith_entry).Figure.Position, screen);
            match = find(strcmp({layout.Kind}, entries(ith_entry).Kind) & strcmp({layout.Name}, name), 1);
            if isempty(match)
                match = numel(layout) + 1;
            end
            layout(match).Kind = entries(ith_entry).Kind;
            layout(match).Name = name;
            layout(match).Position = position;
            layout(match).Open = strcmp(entries(ith_entry).Kind, 'viewer');
        end
    end

    function placeChild(childFigure, kind, name)
        % A new window goes where that kind (and name, and n-th) was last
        layout = readLayout();
        if isempty(layout)
            return;
        end
        numSame = nnz(strcmp({children.Kind}, kind) & strcmp({children.Name}, name));
        if numSame > 1
            name = sprintf('%s #%d', name, numSame);
        end
        match = find(strcmp({layout.Kind}, kind) & strcmp({layout.Name}, name), 1);
        if isempty(match)
            match = find(strcmp({layout.Kind}, kind), 1);   % (the kind's last place)
        end
        if ~isempty(match)
            childFigure.Position = fcn_INTERNAL_fromFraction(layout(match).Position, get(groot, 'ScreenSize'));
        end
    end

    function applyLayout()
        % The main window to its place, and the viewers open last time
        % reopened in theirs, on this vehicle
        layout = readLayout();
        if isempty(layout)
            return;
        end
        screen = get(groot, 'ScreenSize');
        mainEntry = find(strcmp({layout.Kind}, 'main'), 1);
        if ~isempty(mainEntry)
            figureHandle.Position = fcn_INTERNAL_fromFraction(layout(mainEntry).Position, screen);
        end
        viewerNames = {layout(strcmp({layout.Kind}, 'viewer') & [layout.Open]).Name};
        for ith_viewer = 1:numel(viewerNames)
            baseName = regexprep(viewerNames{ith_viewer}, ' #\d+$', '');
            if any(strcmp(baseName, checkNames)) && ~strcmp(marks{6}, 'cannotStart')
                openViewer(baseName);
            end
        end
        if ~isempty(viewerNames)
            figure(figureHandle);
            setHint(sprintf('The layout from last time: %d viewer(s) reopened on this vehicle.', numel(viewerNames)));
        end
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
        layoutNow = currentLayout();   % (before any window closes)
        if ~closeEditors(true, true)
            return;
        end
        writeLayout(layoutNow);
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

%% fcn_INTERNAL_gateOne
function gateOne = fcn_INTERNAL_gateOne(workFolder, workFiles, flagMesh)
% The first gate, "Are lamps and glass labeled?". The gate is one
% assessment function (Q116, Sean 2026-11-27 21:48: the main window only
% routes): fcn_CarMesh3D_assess_lampsAndGlass gives the automatic half
% (Mode='check') and the fingerprint the person's answer must match; the
% answer is read from the vehicle's review file. It passes when both say
% yes.
gateOne = struct('Auto', false, 'Human', '', 'Mark', 'notDone', 'Text', '');
if ~flagMesh
    gateOne.Mark = 'cannotStart';
    gateOne.Text = 'No mesh yet.';
    return;
end
autoText = '';
human = 'not answered yet (Check)';
try
    checked = fcn_CarMesh3D_assess_lampsAndGlass(workFolder, Mode='check');
    gateOne.Auto = checked.Pass;
    autoText = checked.CheckText;
    reviewFile = fullfile(workFiles.ChecksFolder, sprintf('review_%s.mat', workFiles.ID));
    if isfile(reviewFile)
        saved = load(reviewFile, 'vvAnswers');
        row = find(saved.vvAnswers.Key == "lampsAndGlass" & strlength(saved.vvAnswers.Answer) > 0, 1);
        if ~isempty(row)
            if strcmp(char(saved.vvAnswers.Fingerprint(row)), checked.Fingerprint)
                gateOne.Human = char(saved.vvAnswers.Answer(row));
                human = sprintf('you answered %s', gateOne.Human);
            else
                gateOne.Human = 'stale';
                human = 'your answer is out of date: the labels changed since (Check again)';
            end
        end
    end
catch checkError
    autoText = sprintf('the check could not run: %s', checkError.message);
end
autoWords = fcn_INTERNAL_pick(gateOne.Auto, 'Automatic check passed', 'Automatic check <font color="#b00000">not passed</font>');
gateOne.Text = sprintf('%s; %s.', autoWords, human);
if ~gateOne.Auto && ~isempty(autoText)
    gateOne.Text = sprintf('%s (%s)', gateOne.Text, autoText);
end
if gateOne.Auto && strcmp(gateOne.Human, 'Yes')
    gateOne.Mark = 'done';
elseif strcmp(gateOne.Human, 'No') || (~gateOne.Auto && ~isempty(gateOne.Human))
    gateOne.Mark = 'failed';
elseif strcmp(gateOne.Human, 'stale')
    gateOne.Mark = 'outOfDate';
end
end % Ends fcn_INTERNAL_gateOne

%% fcn_INTERNAL_retitle
function fcn_INTERNAL_retitle(childFigure, name)
% A window opened for a row is titled by the row (the painter is "Mark
% Lamps and Glass" or "Name Each Lamp"; the V&V window "Validate Import")
try
    childFigure.Name = name;
    titleLabel = findall(childFigure, 'Tag', 'titleBarTitle');
    if ~isempty(titleLabel)
        titleLabel(1).Text = name;
    end
catch
end
end % Ends fcn_INTERNAL_retitle

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

%% fcn_INTERNAL_fromFraction
function position = fcn_INTERNAL_fromFraction(fraction, screen)
% A remembered place back in pixels on this screen, kept on the screen
position = [screen(1) + fraction(1)*screen(3), screen(2) + fraction(2)*screen(4), fraction(3)*screen(3), fraction(4)*screen(4)];
position(3:4) = max(position(3:4), [300 200]);
position(1) = min(max(position(1), screen(1)), screen(1) + screen(3) - 100);
position(2) = min(max(position(2), screen(2)), screen(2) + screen(4) - 100);
end % Ends fcn_INTERNAL_fromFraction

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
