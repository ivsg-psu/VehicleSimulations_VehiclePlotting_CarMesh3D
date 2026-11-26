function [lampFunctions, editor] = fcn_CarMesh3D_editLampFunctions(vehicleInput, options)
% fcn_CarMesh3D_editLampFunctions
% The lamp-to-function (L2F) matrix window: where a vehicle's matrix is
% set, each lamp unit by each signal, from 0 (off) to 1 (full), with the
% vehicle lit in the viewer as it is set. The design is
% Documentation_CarMesh3D_GUIdesign_lampFunctions.md, section 6 (chosen by
% Sean, 2026-11-26 03:58 to 04:35): a tall column, from the top:
%
%   Editing: [signal]   Table | Tuner     the one signal being edited
%   Also on: [+ add a signal]             other signals lit at the same
%     (chips: "Brake ×")                  time, to see together, never
%                                         edited; a click on a chip
%                                         takes it off
%   Only lamps this signal lights; Front, Side, Rear   (filters)
%   Table: a row per lamp unit, a column per signal, each cell a bar of
%     its brightness; the edited column edged in cyan. A click on a cell
%     edits its signal and marks its lamp; a double-click switches the
%     cell on (1) or off (0). No numbers are typed.
%   Tuner: one vertical slider per lamp, up is brighter, steps of 0.05,
%     for the signal being edited; under each, in grey, what the "also
%     on" signals light it to
%   Checks, in words: a signal that lights no lamp; a lamp no signal
%     lights; a beam, the brakes or the backup lamps lit at both ends;
%     a lamp lit on one side only. They warn; they never block.
%   Save, Revert, Hazards (both turn signals also on)
%
% In the view, at night, the lamps light with the edited signal and the
% "also on" signals together, and the lamps the edited signal lights are
% outlined in cyan. A row changed is marked 'edited', with a source, so
% the vehicle's file keeps it (rule G40).
%
% FORMAT:
%
%       [lampFunctions, editor] = fcn_CarMesh3D_editLampFunctions(vehicleInput,...
%           (Mesh=vehicleMesh), (Viewer=viewer), (Parent=container),...
%           (Who=initials), (Visible=flag), (OnChange=function), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID ('2009_Honda_Fit_Sport') or its folder
%      (its matrix is read from, and saved to, lampFunctions_<ID>.csv); or
%      a labeled mesh (nothing is saved: the matrix is returned).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Mesh: the vehicle's mesh, when already loaded (the viewer's).
%
%      Viewer: the hooks of the viewer that shows the vehicle (the second
%      output of fcn_CarMesh3D_viewLabels), so the lamps light in it as
%      the matrix is set. Default []: a window of its own, with a viewer.
%
%      Parent: the panel to build the column into (a host such as the
%      painter). Default []: a window of its own.
%
%      Who: initials for the source of edited rows. Default: yours
%      (fcn_CarMesh3D_userInfo, not asked).
%
%      Visible: false to build a window of its own hidden (tests).
%
%      OnChange: f(lampFunctions), called after each change.
%
%      FigNum: not used (a window); -1 for fast mode.
%
% OUTPUTS:
%
%      lampFunctions: the matrix when the window opened (a table, as
%      fcn_CarMesh3D_lampFunctions gives it); editor.Table() is the
%      matrix now.
%
%      editor: a structure of functions, for a host and for tests:
%      Table(), SetSignal(name), Signal(), AddAlsoOn(name),
%      RemoveAlsoOn(name), AlsoOn(), SetMode('table' or 'tuner'),
%      SetValue(unit, signal, value), ClickCell(unit, signal, flagDouble),
%      SetOnlyLit(flag), SetGroups(names), ShownUnits(), Checks(),
%      Save(), Revert(), Hazards(), Units(), Figure, Viewer, Close().
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_lampFunctions, fcn_CarMesh3D_lampSignals,
%      fcn_CarMesh3D_findVehicleFiles, fcn_CarMesh3D_meshWithLabelEdits,
%      fcn_CarMesh3D_viewLabels, fcn_CarMesh3D_userInfo
%
% EXAMPLES:
%
%       fcn_CarMesh3D_editLampFunctions('2009_Honda_Fit_Sport');
%
%       See the script: script_test_fcn_CarMesh3D_editLampFunctions.m for a
%       full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLampFunctions
%   % * First write (the lamp-functions plan, item 5; the design file,
%   %   % section 6) (drafted with Claude)
%   % * The table laid out in pixels: rows of 22 px, lamp names at 11 pt,
%   %   % signal names at 10 pt, every other row shaded; the panel scrolls
%   %   % instead of the rows shrinking. The tuner's names at 11 pt, wrapped
%   %   % at the underscores. The column 520 px wide (T80, T81 BUG: "lamp
%   %   % labels on matrix too small to see clearly")
%   % * A top bar in its own window, as the viewer's and the painter's: its
%   %   % name, and the Mesh, Grid and sun/moon buttons at the right (Sean,
%   %   % 10:41, in place of Q94 (A))
%   % * The lamp names a column of their own that stays put; the signals'
%   %   % columns scroll sideways with a slider shown when they do not all
%   %   % fit, and picking a signal brings its column to the middle (Sean,
%   %   % T89 BUG, 12:59: the Reflectors column was cut off). New hooks
%   %   % ColumnView, SetColumnOffset

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_editLampFunctions
%   % * "Add a lamp kind" (section 6), into fcn_CarMesh3D_lampTypes

arguments
    vehicleInput                % Vehicle ID or folder, or a labeled mesh
    options.Mesh = []           % The vehicle's mesh, if already loaded
    options.Viewer = []         % The viewer's hooks (fcn_CarMesh3D_viewLabels)
    options.Parent = []         % The panel to build into; [] for a window of its own
    options.Who = ''            % Initials for edited rows' sources
    options.Visible = true      % false: a window of its own built hidden (tests)
    options.OnChange = []       % f(lampFunctions) after each change
    options.FigNum = []         % Not used; -1 for fast mode
end

%% Debugging and Input checks
flag_check_inputs = ~isequal(options.FigNum, -1);
if flag_check_inputs
    if ~(isstruct(vehicleInput) || ischar(vehicleInput) || isstring(vehicleInput))
        error('CarMesh3D:badInput', 'vehicleInput must be a vehicle ID or folder, or a labeled mesh.');
    end
    if ~isempty(options.Viewer) && ~(isstruct(options.Viewer) && isfield(options.Viewer, 'SetLampFunctions'))
        error('CarMesh3D:badInput', 'Viewer must be the hooks of fcn_CarMesh3D_viewLabels.');
    end
    if ~isempty(options.OnChange) && ~isa(options.OnChange, 'function_handle')
        error('CarMesh3D:badInput', 'OnChange must be a function handle, or empty.');
    end
end

%% Main code
% The vehicle, its mesh and its matrix
folder = '';
if isstruct(vehicleInput)
    vehicleMesh = vehicleInput;
    [lampFunctions, units] = fcn_CarMesh3D_lampFunctions(vehicleMesh, FigNum=-1);
    vehicleName = 'mesh';
else
    vehicleFiles = fcn_CarMesh3D_findVehicleFiles(char(vehicleInput), FigNum=-1);
    folder = vehicleFiles.Folder;
    vehicleName = vehicleFiles.ID;
    if isempty(options.Mesh)
        vehicleMesh = fcn_CarMesh3D_meshWithLabelEdits(folder, FigNum=-1);
    else
        vehicleMesh = options.Mesh;
    end
    [lampFunctions, units] = fcn_CarMesh3D_lampFunctions(folder, Mesh=vehicleMesh, FigNum=-1);
end
signals = fcn_CarMesh3D_lampSignals();
signalNames = {signals.Name};
signalLabels = {signals.Label};
unitNames = {units.Name};
numUnits = numel(units);
groupOf = cell(1, numUnits);   % (Front, Side or Rear, from the position)
for ith_position = 1:numUnits
    if startsWith(units(ith_position).Position, 'front')
        groupOf{ith_position} = 'Front';
    elseif startsWith(units(ith_position).Position, 'rear')
        groupOf{ith_position} = 'Rear';
    else
        groupOf{ith_position} = 'Side';
    end
end
who = char(options.Who);
if isempty(who)
    try
        user = fcn_CarMesh3D_userInfo(Ask=false, FigNum=-1);
        who = user.Initials;
    catch
        who = '';
    end
end

% The state
matrixNow = lampFunctions;
editSignal = 'LowBeam';
alsoOn = {};
mode = 'table';
flagOnlyLit = false;
groupsShown = {'Front', 'Side', 'Rear'};
markedUnit = 0;
flagCenterColumn = true;
columnOffset = 0;   % (the table's columns scrolled sideways, in pixels: T89)
columnSlider = [];
flagChanged = false;

% The window: the column, and the viewer beside it when on its own
figureHandle = [];
viewer = options.Viewer;
if isempty(options.Parent)
    figureHandle = uifigure('Name', sprintf('fcn_CarMesh3D_editLampFunctions: %s', vehicleName), ...
        'Position', [60 60 1500 900], 'Visible', 'off', 'Tag', 'lampFunctionsWindow', ...
        'CloseRequestFcn', @(~,~) closeEditor());
    % (a top bar as in the viewer and the painter: the window's name at the
    % left, and at the right the viewer's Mesh, Grid and sun/moon buttons;
    % Sean, 2026-11-26 10:41: one top bar design in every window)
    outerGrid = uigridlayout(figureHandle, [2 1], 'RowHeight', {36, '1x'}, 'Padding', [4 4 4 4], 'RowSpacing', 3);
    topBar = uigridlayout(outerGrid, [1 4], 'ColumnWidth', {'1x', 70, 70, 44}, 'Padding', [0 2 0 2], 'ColumnSpacing', 6, ...
        'Tag', 'lampTopBar');
    uilabel(topBar, 'Text', sprintf('Lamp functions: %s', vehicleName), 'FontWeight', 'bold', 'FontSize', 13, 'Interpreter', 'none');
    rootGrid = uigridlayout(outerGrid, [1 2], 'ColumnWidth', {520, '1x'}, 'Padding', [0 0 0 0]);   % (520: the table's names at 11 pt, T80)
    columnPanel = uipanel(rootGrid, 'BorderType', 'none');
    if isempty(viewer)
        viewPanel = uipanel(rootGrid, 'BorderType', 'none');
        [~, viewer] = fcn_CarMesh3D_viewLabels(vehicleMesh, Parent=viewPanel, ShowTools=false, ...
            CheckStale=false, Visible=options.Visible, Wait=false, QuickBar=topBar);
    end
else
    columnPanel = options.Parent;
    delete(columnPanel.Children);
end
band = [0.95 0.93 1];   % (pale violet: the lamp-functions work)

columnGrid = uigridlayout(columnPanel, [8 1], 'RowHeight', {30, 30, 'fit', 30, 0, 160, 96, 30}, ...
    'Padding', [8 8 8 8], 'RowSpacing', 6, 'BackgroundColor', band, 'Scrollable', 'on');   % (scrolls when short: under another panel in the painter)
% 1. Editing, and Table | Tuner
rowGrid = uigridlayout(columnGrid, [1 3], 'ColumnWidth', {60, '1x', 130}, 'Padding', [0 0 0 0], 'BackgroundColor', band);
uilabel(rowGrid, 'Text', 'Editing:', 'FontWeight', 'bold');
signalDropdown = uidropdown(rowGrid, 'Items', signalLabels, 'ItemsData', signalNames, 'Value', editSignal, ...
    'Tag', 'lampEditing', 'Tooltip', 'The one signal being edited: its lamps are outlined in cyan on the vehicle', ...
    'ValueChangedFcn', @(source,~) setSignal(source.Value));
modeGroup = uibuttongroup(rowGrid, 'BorderType', 'none', 'BackgroundColor', band, 'Tag', 'lampMode', ...
    'SelectionChangedFcn', @(~,event) setMode(event.NewValue.UserData));
uitogglebutton(modeGroup, 'Text', 'Table', 'Position', [2 2 60 24], 'UserData', 'table', ...
    'Tooltip', 'Every lamp by every signal, each cell a bar of its brightness');
uitogglebutton(modeGroup, 'Text', 'Tuner', 'Position', [64 2 60 24], 'UserData', 'tuner', ...
    'Tooltip', 'One slider per lamp for the signal being edited: up is brighter');
% 2. Also on
rowGrid = uigridlayout(columnGrid, [1 2], 'ColumnWidth', {60, '1x'}, 'Padding', [0 0 0 0], 'BackgroundColor', band);
uilabel(rowGrid, 'Text', 'Also on:', 'FontWeight', 'bold');
alsoDropdown = uidropdown(rowGrid, 'Items', [{'+ add a signal...'}, signalLabels], 'ItemsData', [{''}, signalNames], ...
    'Value', '', 'Tag', 'lampAlsoOn', ...
    'Tooltip', 'Other signals lit at the same time, to see together (never edited): the brakes with a turn signal, say', ...
    'ValueChangedFcn', @(source,~) addAlsoOn(source.Value));
% 3. The chips
chipGrid = uigridlayout(columnGrid, [1 1], 'RowHeight', {24}, 'ColumnWidth', {'1x'}, 'Padding', [0 0 0 0], ...
    'ColumnSpacing', 4, 'RowSpacing', 4, 'BackgroundColor', band, 'Tag', 'lampChips');
% 4. Filters
rowGrid = uigridlayout(columnGrid, [1 4], 'ColumnWidth', {'1x', 'fit', 'fit', 'fit'}, 'Padding', [0 0 0 0], ...
    'BackgroundColor', band);
onlyLitBox = uicheckbox(rowGrid, 'Text', 'Only lamps this signal lights', 'Tag', 'lampOnlyLit', ...
    'ValueChangedFcn', @(source,~) setOnlyLit(source.Value));
groupBoxes = gobjects(1, 3);
groupNames = {'Front', 'Side', 'Rear'};
for ith_group = 1:3
    groupBoxes(ith_group) = uicheckbox(rowGrid, 'Text', groupNames{ith_group}, 'Value', true, ...
        'Tag', ['lampGroup' groupNames{ith_group}], 'ValueChangedFcn', @(~,~) setGroups(groupNames([groupBoxes.Value])));
end
% 5. The table's columns, scrolled sideways when they do not all fit
% (the lamp names stay: Sean, T89 BUG, 2026-11-26 12:59: "Need a horizontal
% scroll capability ... the scroll should only move the matrix portion, not
% the labels"); shown only when needed
columnSlider = uislider(columnGrid, 'Limits', [0 1], 'Value', 0, 'MajorTicks', [], 'MinorTicks', [], ...
    'Tag', 'lampColumnScroll', 'Tooltip', 'Scroll the signals sideways (the lamp names stay)', ...
    'ValueChangingFcn', @(~,event) setColumnOffset(event.Value), 'ValueChangedFcn', @(source,~) setColumnOffset(source.Value));
% 6. The table or the tuner
contentPanel = uipanel(columnGrid, 'BorderType', 'line', 'BackgroundColor', [1 1 1], 'Tag', 'lampContent', ...
    'AutoResizeChildren', 'off', 'SizeChangedFcn', @(~,~) drawContent());
% 7. Checks
checksArea = uitextarea(columnGrid, 'Editable', 'off', 'Tag', 'lampChecks', 'FontSize', 11, ...
    'Tooltip', 'Things to look at: warnings only, never blocking (odd vehicles are allowed)');
% 8. Save, Revert, Hazards
rowGrid = uigridlayout(columnGrid, [1 3], 'ColumnWidth', {'1x', '1x', '1x'}, 'Padding', [0 0 0 0], 'BackgroundColor', band);
saveButton = uibutton(rowGrid, 'Text', 'Save', 'Tag', 'lampSave', 'FontWeight', 'bold', ...
    'Tooltip', 'Write the matrix to the vehicle''s lampFunctions_<ID>.csv (changed rows marked edited, with you as the source)', ...
    'ButtonPushedFcn', @(~,~) saveMatrix());
if isempty(folder)
    saveButton.Enable = 'off';
    saveButton.Tooltip = 'A mesh given as a variable: the matrix is returned, not saved';
end
uibutton(rowGrid, 'Text', 'Revert', 'Tag', 'lampRevert', 'Tooltip', 'Back to the matrix as it was opened (or last saved)', ...
    'ButtonPushedFcn', @(~,~) revertMatrix());
uibutton(rowGrid, 'Text', 'Hazards', 'Tag', 'lampHazards', 'Tooltip', 'Both turn signals also on (or off again)', ...
    'ButtonPushedFcn', @(~,~) hazards());

% (the table or tuner fills the height left, but never less than 160 px:
% under another panel in the painter, the column scrolls instead)
sizeListener = addlistener(columnPanel, 'SizeChanged', @(~,~) fitContent()); %#ok<NASGU>
fitContent();

savedMatrix = matrixNow;
editor = struct('Table', @getTable, 'SetSignal', @setSignal, 'Signal', @getSignal, ...
    'AddAlsoOn', @addAlsoOn, 'RemoveAlsoOn', @removeAlsoOn, 'AlsoOn', @getAlsoOn, 'SetMode', @setMode, ...
    'Mode', @getMode, 'SetValue', @setValue, 'ClickCell', @clickCell, 'SetOnlyLit', @setOnlyLit, ...
    'SetGroups', @setGroups, 'ShownUnits', @shownUnits, 'Checks', @getChecks, 'Save', @saveMatrix, ...
    'Revert', @revertMatrix, 'Hazards', @hazards, 'Units', @getUnits, 'Figure', figureHandle, ...
    'Viewer', viewer, 'Column', columnGrid, 'Close', @closeEditor, ...
    'ColumnView', @getColumnView, 'SetColumnOffset', @setColumnOffset);
refreshAll(true);
if ~isempty(figureHandle)
    figureHandle.UserData = editor;
    if options.Visible
        figureHandle.Visible = 'on';
    end
end

%% Nested functions (they share the window's state above)
    % (the getters: nested, so they read the state now, not as it was
    % when the hooks were made)
    function value = getTable()
        value = matrixNow;
    end
    function value = getSignal()
        value = editSignal;
    end
    function value = getAlsoOn()
        value = alsoOn;
    end
    function value = getMode()
        value = mode;
    end
    function value = getUnits()
        value = units;
    end

    function fitContent()
        if ~isvalid(columnPanel) || ~isvalid(columnGrid)
            return;
        end
        panelSize = getpixelposition(columnPanel);
        fixedHeight = 30 + 30 + 28 + 30 + columnGrid.RowHeight{5} + 96 + 30 + 7*6 + 16;   % (the other rows, the spacing and the padding)
        newHeight = max(160, floor(panelSize(4) - fixedHeight));
        if ~isequal(columnGrid.RowHeight{6}, newHeight)
            columnGrid.RowHeight{6} = newHeight;
        end
    end

    function refreshAll(flagViewer)
        refreshChips();
        drawContent();
        refreshChecks();
        if flagViewer
            lightViewer();
        end
    end

    function setSignal(name)
        if ~any(strcmp(signalNames, name))
            return;
        end
        editSignal = char(name);
        signalDropdown.Value = editSignal;
        alsoOn = setdiff(alsoOn, {editSignal}, 'stable');   % (the edited signal is lit anyway)
        flagCenterColumn = true;   % (its column brought to the middle of the view: T89)
        refreshAll(true);
    end

    function addAlsoOn(name)
        alsoDropdown.Value = '';
        if isempty(name) || ~any(strcmp(signalNames, name)) || strcmp(name, editSignal)
            return;
        end
        alsoOn = union(alsoOn, {char(name)}, 'stable');
        refreshAll(true);
    end

    function removeAlsoOn(name)
        alsoOn = setdiff(alsoOn, {char(name)}, 'stable');
        refreshAll(true);
    end

    function hazards()
        if all(ismember({'TurnLeft', 'TurnRight'}, [alsoOn, {editSignal}]))
            alsoOn = setdiff(alsoOn, {'TurnLeft', 'TurnRight'}, 'stable');
        else
            alsoOn = union(alsoOn, setdiff({'TurnLeft', 'TurnRight'}, {editSignal}), 'stable');
        end
        refreshAll(true);
    end

    function setMode(name)
        mode = char(name);
        buttons = modeGroup.Children;
        modeGroup.SelectedObject = buttons(strcmp({buttons.UserData}, mode));
        drawContent();
    end

    function setOnlyLit(flagOn)
        flagOnlyLit = logical(flagOn);
        onlyLitBox.Value = flagOnlyLit;
        drawContent();
    end

    function setGroups(names)
        groupsShown = cellstr(names);
        for ith = 1:3
            groupBoxes(ith).Value = any(strcmp(groupsShown, groupNames{ith}));
        end
        drawContent();
    end

    function indices = shownUnits()
        % The units in the list: the groups shown, and (filter) only the
        % ones the edited signal lights; in Front, Side, Rear order
        indices = [];
        for ith = 1:3
            if ~any(strcmp(groupsShown, groupNames{ith}))
                continue;
            end
            indices = [indices, find(strcmp(groupOf, groupNames{ith}))]; %#ok<AGROW>
        end
        if flagOnlyLit
            indices = indices(matrixNow.(editSignal)(indices) > 0);
        end
    end

    function setValue(unit, signalName, value)
        % One cell set (0 to 1, in steps of 0.05); its row marked edited
        if ischar(unit) || isstring(unit)
            unit = find(strcmp(unitNames, unit), 1);
        end
        value = min(1, max(0, round(double(value)*20)/20));
        if isempty(unit) || ~any(strcmp(signalNames, signalName)) || matrixNow.(signalName)(unit) == value
            return;
        end
        matrixNow.(signalName)(unit) = value;
        if ~strcmpi(matrixNow.Default{unit}, 'edited')
            matrixNow.Default{unit} = 'edited';
            matrixNow.Source{unit} = sprintf('(edited in the lamp-functions window by %s, %s)', who, ...
                char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
        end
        flagChanged = true;
        if ~isempty(viewer)
            viewer.SetLampFunctions(matrixNow);
        end
        refreshAll(true);
        if ~isempty(options.OnChange)
            options.OnChange(matrixNow);
        end
    end

    function clickCell(unit, signalName, flagDouble)
        % A click on a cell: its signal is the one edited and its lamp is
        % marked; a double-click switches the cell on (1) or off (0)
        if ischar(unit) || isstring(unit)
            unit = find(strcmp(unitNames, unit), 1);
        end
        markedUnit = unit;
        if ~strcmp(signalName, editSignal)
            editSignal = char(signalName);
            signalDropdown.Value = editSignal;
            alsoOn = setdiff(alsoOn, {editSignal}, 'stable');
        end
        if nargin > 2 && flagDouble
            setValue(unit, signalName, double(matrixNow.(signalName)(unit) == 0));
            return;
        end
        refreshAll(true);
    end

    %% Drawing
    function refreshChips()
        delete(chipGrid.Children);
        if isempty(alsoOn)
            chipGrid.ColumnWidth = {'1x'};
            uilabel(chipGrid, 'Text', '(none)', 'FontColor', [0.5 0.5 0.5]);
            return;
        end
        chipGrid.ColumnWidth = repmat({'fit'}, 1, numel(alsoOn));
        for ith = 1:numel(alsoOn)
            name = alsoOn{ith};
            uibutton(chipGrid, 'Text', [signalLabels{strcmp(signalNames, name)} ' ' char(215)], ...
                'Tag', ['lampChip_' name], 'Tooltip', 'Click to take this signal off', ...
                'BackgroundColor', [0.88 0.85 0.98], 'ButtonPushedFcn', @(~,~) removeAlsoOn(name));
        end
    end

    function drawContent()
        if isempty(contentPanel) || ~isvalid(contentPanel)
            return;
        end
        delete(contentPanel.Children);
        if strcmp(mode, 'table')
            drawTable();
        else
            drawTuner();
        end
    end

    function drawTable()
        % Bar cells: a row per lamp unit, a column per signal; the edited
        % column edged in cyan; no numbers typed. Laid out in pixels (rows
        % of 22 px, names at 11 pt), so the table stays readable however
        % many lamps there are: the panel scrolls up and down instead of
        % the rows shrinking (T80, T81). The lamp names are a column of
        % their own that stays put; the signals' columns scroll sideways
        % with the slider above, and the edited signal's column is brought
        % to the middle when it is picked (Sean, T89 BUG, 12:59)
        indices = shownUnits();
        numShown = numel(indices);
        numSignals = numel(signalNames);
        rowPx = 22;
        cellPx = 26;
        headerPx = 96;   % (the signals' names, turned 60 degrees)
        namePx = 8 + 7*max([12, cellfun(@numel, unitNames(indices))]);   % (about 7 px a character at 11 pt)
        panelSize = getpixelposition(contentPanel);
        tableHeight = headerPx + max(numShown, 1)*rowPx + 6;
        heightPx = max(tableHeight, panelSize(4) - 4);
        scrollbarPx = 18 * (tableHeight > panelSize(4) - 4);   % (room for the up-down scroll bar)
        matrixWidth = numSignals*cellPx + 60;   % (the columns, and room for the last signal's turned name)
        viewWidth = max(60, panelSize(3) - 4 - scrollbarPx - namePx);
        flagSideways = matrixWidth > viewWidth;
        shownWidth = min(matrixWidth, viewWidth);
        % (the slider: shown only when the columns do not all fit)
        maxOffset = max(0, matrixWidth - shownWidth);
        editColumn = find(strcmp(signalNames, editSignal));
        if flagCenterColumn
            columnOffset = (editColumn - 0.5)*cellPx - shownWidth/2;
            flagCenterColumn = false;
        end
        columnOffset = min(max(0, columnOffset), maxOffset);
        newRow = 24*flagSideways;
        if ~isequal(columnGrid.RowHeight{5}, newRow)
            columnGrid.RowHeight{5} = newRow;
            fitContent();
        end
        columnSlider.Visible = matlab.lang.OnOffSwitchState(flagSideways);
        columnSlider.Limits = [0, max(maxOffset, 1)];
        columnSlider.Value = columnOffset;
        contentPanel.Scrollable = 'on';
        % (the lamp names: an axes of their own, left)
        nameAxes = uiaxes(contentPanel, 'Units', 'pixels', 'Tag', 'lampTableNames');
        nameAxes.PositionConstraint = 'innerposition';
        nameAxes.InnerPosition = [1, 1, namePx, heightPx];
        % (the matrix: its own axes, right, showing the columns from
        % columnOffset on)
        axesHandle = uiaxes(contentPanel, 'Units', 'pixels', 'Tag', 'lampTable');
        axesHandle.PositionConstraint = 'innerposition';
        axesHandle.InnerPosition = [namePx + 1, 1, shownWidth, heightPx];
        for thisAxes = [nameAxes, axesHandle]
            disableDefaultInteractivity(thisAxes);
            thisAxes.Toolbar.Visible = 'off';
            hold(thisAxes, 'on');
            axis(thisAxes, 'off');
            thisAxes.YDir = 'reverse';
            ylim(thisAxes, [0, heightPx]);   % (data units are pixels, from the top)
        end
        xlim(nameAxes, [0, namePx]);
        xlim(axesHandle, columnOffset + [0, shownWidth]);
        for ith_signal = 1:numSignals
            text(axesHandle, (ith_signal - 0.5)*cellPx, headerPx - 4, signalLabels{ith_signal}, 'Rotation', 60, ...
                'FontSize', 10, 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle', 'Interpreter', 'none', ...
                'Clipping', 'on', 'FontWeight', fcn_INTERNAL_weight(strcmp(signalNames{ith_signal}, editSignal)), 'Tag', 'lampColumnName');
        end
        for ith_row = 1:numShown
            unit = indices(ith_row);
            y0 = headerPx + (ith_row - 1)*rowPx;
            if mod(ith_row, 2) == 0   % (every other row shaded, to follow a row across)
                rectangle(nameAxes, 'Position', [0, y0, namePx, rowPx], 'FaceColor', [0.95 0.96 0.99], ...
                    'EdgeColor', 'none', 'HitTest', 'off', 'Tag', 'lampRowShade');
                rectangle(axesHandle, 'Position', [0, y0, numSignals*cellPx, rowPx], 'FaceColor', [0.95 0.96 0.99], ...
                    'EdgeColor', 'none', 'HitTest', 'off', 'Tag', 'lampRowShade');
            end
            text(nameAxes, 4, y0 + rowPx/2, unitNames{unit}, 'FontSize', 11, 'Interpreter', 'none', ...
                'VerticalAlignment', 'middle', 'FontWeight', fcn_INTERNAL_weight(unit == markedUnit), 'Tag', 'lampRowName');
            for ith_signal = 1:numSignals
                signalName = signalNames{ith_signal};
                value = matrixNow.(signalName)(unit);
                x0 = (ith_signal - 1)*cellPx;
                rectangle(axesHandle, 'Position', [x0 + 2, y0 + 2, cellPx - 4, rowPx - 4], 'FaceColor', [0.96 0.96 0.96], ...
                    'EdgeColor', [0.75 0.75 0.75], 'Tag', 'lampCell', 'UserData', [unit ith_signal], ...
                    'ButtonDownFcn', @(source,~) onCellDown(source));
                if value > 0
                    barHeight = (rowPx - 4)*value;
                    rectangle(axesHandle, 'Position', [x0 + 2, y0 + rowPx - 2 - barHeight, cellPx - 4, barHeight], ...
                        'FaceColor', [0.30 0.45 0.85], 'EdgeColor', 'none', 'HitTest', 'off', 'Tag', 'lampBar');
                end
            end
        end
        % (the edited column's cyan edge)
        rectangle(axesHandle, 'Position', [(editColumn - 1)*cellPx, headerPx, cellPx, max(numShown, 1)*rowPx], ...
            'EdgeColor', [0 0.8 0.9], 'LineWidth', 2, 'HitTest', 'off', 'Tag', 'lampEditedColumn');
        if numShown == 0
            text(nameAxes, 8, headerPx + rowPx/2, 'No lamps to show (see the filters)', 'Color', [0.4 0.4 0.4], 'FontSize', 11);
        end
        scroll(contentPanel, 'top');
    end

    function setColumnOffset(value)
        % (the slider moved: the columns scrolled sideways, the names stay)
        columnOffset = value;
        tableAxes = findobj(contentPanel, 'Tag', 'lampTable');
        if ~isempty(tableAxes) && isvalid(tableAxes(1))
            tableAxes(1).XLim = value + [0, diff(tableAxes(1).XLim)];
        end
    end

    function value = getColumnView()
        % (the signals' columns in view now: for the tests)
        value = struct('Offset', columnOffset, 'Width', NaN, 'Sideways', strcmp(columnSlider.Visible, 'on'));
        tableAxes = findobj(contentPanel, 'Tag', 'lampTable');
        if ~isempty(tableAxes)
            value.Width = diff(tableAxes(1).XLim);
        end
    end

    function onCellDown(source)
        % (a double-click is a second press called 'open')
        where = source.UserData;
        flagDouble = false;
        theFigure = ancestor(source, 'figure');
        if ~isempty(theFigure)
            flagDouble = strcmp(theFigure.SelectionType, 'open');
        end
        clickCell(where(1), signalNames{where(2)}, flagDouble);
    end

    function drawTuner()
        % One vertical slider per lamp, up is brighter, for the signal
        % edited; under each, in grey, what the "also on" signals light it to
        indices = shownUnits();
        numShown = numel(indices);
        if numShown == 0
            uilabel(contentPanel, 'Text', 'No lamps to show (see the filters)', 'Position', [10 10 300 22]);
            return;
        end
        contentPanel.Scrollable = 'off';   % (the tuner's own grid scrolls)
        columnSlider.Visible = 'off';
        if columnGrid.RowHeight{5} ~= 0
            columnGrid.RowHeight{5} = 0;
            fitContent();
        end
        grid = uigridlayout(contentPanel, [3 numShown], 'RowHeight', {'1x', 64, 20}, ...
            'ColumnWidth', repmat({84}, 1, numShown), 'Padding', [4 4 4 4], 'ColumnSpacing', 4, ...
            'BackgroundColor', [1 1 1], 'Scrollable', 'on', 'Tag', 'lampTuner');
        for ith = 1:numShown
            unit = indices(ith);
            slider = uislider(grid, 'Orientation', 'vertical', 'Limits', [0 1], ...
                'Value', matrixNow.(editSignal)(unit), 'MajorTicks', 0:0.25:1, 'MinorTicks', 0:0.05:1, ...
                'Tag', ['lampSlider_' num2str(unit)], 'Tooltip', unitNames{unit}, ...
                'ValueChangedFcn', @(source,~) setValue(unit, editSignal, source.Value));
            slider.Layout.Row = 1;
            slider.Layout.Column = ith;
            % (11 pt, and the underscores as spaces so the name wraps:
            % T81 BUG, the 9 pt names were too small to read)
            nameLabel = uilabel(grid, 'Text', strrep(unitNames{unit}, '_', ' '), 'WordWrap', 'on', 'FontSize', 11, ...
                'HorizontalAlignment', 'center', 'Tooltip', unitNames{unit});
            nameLabel.Layout.Row = 2;
            nameLabel.Layout.Column = ith;
            alsoLevel = 0;
            for ith_also = 1:numel(alsoOn)
                alsoLevel = max(alsoLevel, matrixNow.(alsoOn{ith_also})(unit));
            end
            alsoText = '';
            if ~isempty(alsoOn)
                alsoText = sprintf('also %.2g', alsoLevel);
            end
            alsoLabel = uilabel(grid, 'Text', alsoText, 'FontColor', [0.55 0.55 0.55], 'FontSize', 11, ...
                'HorizontalAlignment', 'center', 'Tag', ['lampAlso_' num2str(unit)], ...
                'Tooltip', 'What the "also on" signals light this lamp to');
            alsoLabel.Layout.Row = 3;
            alsoLabel.Layout.Column = ith;
        end
    end

    function refreshChecks()
        checksArea.Value = getChecks();
    end

    function lines = getChecks()
        % Things to look at, in words; warnings only
        lines = {};
        values = matrixNow{:, signalNames};
        for ith_signal = 1:numel(signalNames)
            if ~any(values(:, ith_signal) > 0)
                lines{end+1} = sprintf('%s lights no lamp.', signalLabels{ith_signal}); %#ok<AGROW>
            end
        end
        for ith_unit = 1:numUnits
            if ~any(values(ith_unit,:) > 0) && ~strcmp(units(ith_unit).Kind, 'warningLamp')
                lines{end+1} = sprintf('No signal lights the %s.', unitNames{ith_unit}); %#ok<AGROW>
            end
        end
        for signalName = {'LowBeam', 'HighBeam', 'Brake', 'Backup'}
            column = strcmp(signalNames, signalName{1});
            litGroups = unique(groupOf(values(:, column) > 0));
            if all(ismember({'Front', 'Rear'}, litGroups))
                lines{end+1} = sprintf('%s lights lamps at both ends of the vehicle.', signalLabels{column}); %#ok<AGROW>
            end
        end
        for ith_unit = 1:numUnits
            if ~contains(unitNames{ith_unit}, 'left')
                continue;
            end
            twin = find(strcmp(unitNames, strrep(unitNames{ith_unit}, 'left', 'right')), 1);
            if isempty(twin)
                continue;
            end
            for ith_signal = 1:numel(signalNames)
                if any(strcmp(signalNames{ith_signal}, {'TurnLeft', 'TurnRight'}))
                    continue;   % (one side on purpose)
                end
                flagLeft = values(ith_unit, ith_signal) > 0;
                if flagLeft ~= (values(twin, ith_signal) > 0)
                    litOne = unitNames{ith_unit};
                    darkOne = unitNames{twin};
                    if ~flagLeft
                        [litOne, darkOne] = deal(darkOne, litOne);
                    end
                    lines{end+1} = sprintf('%s lights the %s but not the %s.', signalLabels{ith_signal}, ...
                        litOne, darkOne); %#ok<AGROW>
                end
            end
        end
        if isempty(lines)
            lines = {'No checks to report.'};
        end
    end

    %% The viewer
    function lightViewer()
        % The lamps lit at night by the edited signal and the "also on"
        % signals, each at its brightest, and the edited signal's lamps
        % outlined in cyan (with the marked lamp)
        if isempty(viewer)
            return;
        end
        lit = struct();
        for name = [{editSignal}, alsoOn]
            lit.(name{1}) = 1;
        end
        viewer.SetNightView(true);
        viewer.SetLampSignals(lit);
        litUnits = find(matrixNow.(editSignal) > 0);
        if markedUnit > 0
            litUnits = union(litUnits, markedUnit);
        end
        faces = vertcat(units(litUnits).Faces);
        viewer.OutlineFaces(faces);
    end

    %% Saving
    function saveMatrix()
        if isempty(folder)
            return;
        end
        matrixNow = fcn_CarMesh3D_lampFunctions(folder, Mesh=vehicleMesh, Table=matrixNow, Save=true, FigNum=-1);
        savedMatrix = matrixNow;
        flagChanged = false;
        refreshAll(false);
    end

    function revertMatrix()
        matrixNow = savedMatrix;
        flagChanged = false;
        if ~isempty(viewer)
            viewer.SetLampFunctions(matrixNow);
        end
        refreshAll(true);
    end

    function closeEditor()
        if ~isempty(figureHandle) && isvalid(figureHandle)
            if flagChanged && strcmp(figureHandle.Visible, 'on')
                answer = uiconfirm(figureHandle, 'The matrix has changes not saved. Save them?', 'Lamp functions', ...
                    'Options', {'Save', 'Close without saving', 'Cancel'}, 'DefaultOption', 1, 'CancelOption', 3);
                if strcmp(answer, 'Cancel')
                    return;
                elseif strcmp(answer, 'Save')
                    saveMatrix();
                end
            end
            if ~isempty(viewer) && isfield(viewer, 'Stop')
                try
                    viewer.Stop();
                catch
                end
            end
            delete(figureHandle);
        end
    end

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_weight
function weight = fcn_INTERNAL_weight(flagBold)
% 'bold' or 'normal'
if flagBold
    weight = 'bold';
else
    weight = 'normal';
end
end % Ends fcn_INTERNAL_weight
