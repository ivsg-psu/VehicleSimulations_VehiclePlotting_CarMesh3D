function [selectedNames, browser] = fcn_CarMesh3D_browseLibrary(options)
% fcn_CarMesh3D_browseLibrary
% A window listing every finished vehicle in the library, one row each,
% in a scrolling list. Each row shows:
%   * the labeled 3D mesh (each part and light in its label color),
%   * the vehicle's 2D overhead outline,
%   * the vehicle's name, large, with a star when it is the exemplar of
%     its class; under it, its MATLAB name (the vehicle ID);
%   * its details: class (body style), size, the downloaded model's
%     license, whether and when it was processed (with its quality
%     score), and whether a person has reviewed it (how many items were
%     answered and approved, by whom, and when).
% The list can be sorted and grouped (by class, make, year, length,
% score, review, build date, ...) and filtered: type part of a name,
% year, make or class and press "Apply filter"; each filter narrows the
% vehicles shown ("2022", then "honda": the 2022 Hondas), and "Clear
% filters" shows them all again. Tick "Select"
% on the vehicles wanted: their MATLAB names are shown at the top, as a
% cell array to copy, and returned when the window is closed, in the
% order they are shown.
%
% Each row also has buttons that open the vehicle in the viewer (View),
% the label painter (Edit labels) or the reviewer (Review). The editor and
% the reviewer save their changes, so the user is asked whether to open
% the vehicle itself or a fresh demo copy of it.
%
% If no vehicle is selected when the window is closed, the default test
% vehicle is returned instead: a fresh, temporary copy of it
% (fcn_CarMesh3D_makeDemoCopy), so that a tool tried on it (the mesh
% editor, the reviewer) changes only the copy, and the next copy starts
% from the vehicle as it is again. The copy is returned as its folder,
% which the tools take in place of a vehicle ID.
%
% FORMAT:
%
%       [selectedNames, browser] = fcn_CarMesh3D_browseLibrary(...
%           (Vehicles=names), (SortBy=key), (GroupBy=key), (Order=words),...
%           (Descending=flag),...
%           (Selected=names), (DefaultVehicle=id), (Wait=flag),...
%           (Visible=flag), (DataFolder=folder), (FigNum=figNum))
%
%      Optional inputs are given as Name=Value pairs, in any order. Any
%      option not given takes its default.
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Vehicles: a cell array of MATLAB names (vehicle IDs), such as
%      {'2009_Honda_Fit_Sport', '2013_Toyota_Prius_Four'}: the browser
%      shows, sorts, groups, filters and selects only these vehicles.
%      Names not found among the finished vehicles are listed in a
%      warning and left out. Default {}: the whole library.
%
%      SortBy: 'make', 'year', 'class' (default), 'length', 'score',
%      'review' (the percent of review items approved), 'built' (when the
%      mesh was made), or 'reviewDate'. Ties are ordered by name. ('name'
%      is no longer a choice, Sean 21:54: the name starts with the year,
%      so a name sort looked random; old calls with 'name' sort by make.)
%
%      GroupBy: 'class' (default), 'make', 'year', 'review' (reviewed,
%      partly reviewed, not reviewed), 'exemplar' (exemplars first),
%      'license', or 'none'.
%
%      Order: how the vehicles are ordered within each group, in the
%      words of the window's Order? drop-down, which depend on SortBy:
%          'make', 'class':                   'A to Z' or 'Z to A'
%          'year', 'built', 'reviewDate':     'Newest first' or 'Oldest first'
%          'length':                          'Longest first' or 'Shortest first'
%          'score':                           'Highest first' or 'Lowest first'
%          'review':                          'Most approved first' or
%                                             'Least approved first'
%      Default '': the sort's own default, the first of each pair (A to
%      Z for names; newest, longest, highest and most approved first for
%      the others). The groups always keep their own order.
%
%      Descending: the older way to give the order, kept so old calls
%      work: true for Z to A, newest, longest, highest or most approved
%      first; false for the reverse. Default []: the sort's own default.
%      Order, when given, wins.
%
%      Selected: MATLAB names (vehicle IDs) ticked when the window opens.
%      Default {}.
%
%      DefaultVehicle: the vehicle copied and returned when none is
%      selected. Default '2009_Honda_Fit_Sport' (the demo menu's test
%      vehicle).
%
%      Wait: true to wait until the window is closed, and return the
%      selection then. Default: true when Visible, else false.
%
%      Visible: false to build the window hidden (for tests). Default true.
%
%      DataFolder: the library's Data folder. Default: the one next to
%      the Functions folder.
%
%      FigNum: not used (a window). If set to -1, input checking is
%      skipped (fast mode).
%
% OUTPUTS:
%
%      selectedNames: a cell array of the selected vehicles' MATLAB names
%      (vehicle IDs), in the order they were shown when the window was
%      closed (vehicles selected but hidden by the filter come last). If
%      none was selected: a one-element cell array holding the folder of
%      a fresh copy of DefaultVehicle. (With Wait=false: the selection
%      when the window opened; the browser's Result() gives it later.)
%
%      browser: a structure of the window's handles and functions:
%           Figure, Vehicles (one element per vehicle: ID, Name, details)
%           Order(): the IDs in the order shown (those the filter hides
%               are left out)
%           SetSort(key, (flagDescending)): with no flag, the sort's own
%               default order; SortOrder(): the Order? words shown;
%           SetGroup(key)
%           ApplyFilter(text): keep, of the vehicles shown, those whose
%               name, MATLAB name or class holds the text (filters stack);
%               a text matching none is not applied (true if applied)
%           ClearFilters(), Filters(): the filters applied, in order
%           Open(name, tool, (flagUseCopy)): open a vehicle in a tool, as
%               its row's buttons do: 'view', 'edit' or 'review'. For
%               'edit' and 'review', flagUseCopy true opens a fresh demo
%               copy (the default when the window is hidden), false the
%               vehicle itself; omitted in a shown window, the user is
%               asked. Returns the tool's handles and the folder used
%           Select(names), Deselect(names), Selected(): the selected
%               names, in the order shown
%           Result(): what closing the window returns (makes the default
%               vehicle's copy when none is selected)
%           Close(): close the window
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_browseVehicles, fcn_CarMesh3D_findVehicleFiles,
%      fcn_CarMesh3D_meshHistory, fcn_CarMesh3D_loadBodyStyles,
%      fcn_CarMesh3D_plotLabels, fcn_CarMesh3D_plotVehicle,
%      fcn_CarMesh3D_makeDemoCopy
%
% EXAMPLES:
%
%       % Pick vehicles; their names are returned when the window closes
%       selectedNames = fcn_CarMesh3D_browseLibrary()
%
%       % Only some vehicles: choose among these
%       selectedNames = fcn_CarMesh3D_browseLibrary(Vehicles={'2009_Honda_Fit_Sport', ...
%           '2013_Toyota_Prius_Four', '2014_Honda_CRV_EXL'})
%
%       % Longest first, grouped by make
%       selectedNames = fcn_CarMesh3D_browseLibrary(SortBy='length', Order='Shortest first', GroupBy='make')
%
%       See the script: script_test_fcn_CarMesh3D_browseLibrary.m for a
%       full test suite.
%
% This function was written on 2026_11_22 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_browseLibrary
%   % * First write of the code (Sean, 14:30): a scrolling list of the
%   %   % library's vehicles, each with its labeled 3D mesh, its 2D
%   %   % overhead outline, and its details; sorted, grouped and
%   %   % filtered; the selected vehicles' MATLAB names returned on
%   %   % closing, else a fresh copy of the default test vehicle
%   % * The window's title is its function's name, with the file's last
%   %   % change under it (fcn_CarMesh3D_addTitleBar; Sean, 14:31, 14:40)
%   % * Fixed: the sort, Descending and group controls' callbacks named
%   %   % the controls before they existed (Group by failed:
%   %   % "Unrecognized function or variable 'groupDropdown'"; Sean, 14:56)
%   % * The filter is applied only with "Apply filter", not while typing;
%   %   % filters stack on what is shown; "Clear filters"; a filter that
%   %   % matches none of the vehicles shown is not applied, and the user
%   %   % is warned (Sean, 14:56)
%   % * Vehicles option: only the vehicles given (MATLAB names); every
%   %   % sort, group, filter and selection works on them alone (Sean, 16:32)
%   % * View, Edit labels and Review buttons on each row; the editor and
%   %   % the reviewer ask whether to open the vehicle or a demo copy
%   % * The pictures are drawn once and kept in the temporary folder
%   %   % (CarMesh3D_thumbnails), made again when the mesh or outline
%   %   % file changes
%
% 2026_11_22 (later) by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_browseLibrary
%   % * The controls in three boxes, in the order they are used, left
%   %   % to right: 1. Group by, 2. Sort within each group by, 3. Filter
%   %   % (Sean, 23:33: the sort box, read first, was taken for the main
%   %   % order)
%   % * The selection is shown as text, not in a text box (it read as a
%   %   % place to type; Sean, 23:35), with a Copy names button

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_browseLibrary
%   % * (none)
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_browseLibrary (from the design file's review,
%   % Documentation_CarMesh3D_GUIdesign_browseLibrary.md, Sean 17:56)
%   % * Descending orders only the vehicles within each group; the
%   %   % groups keep their own order (rule B7)
%   % * Enter in the filter box applies the filter (rule B9)
%   % * A data folder other than the default is named in the subtitle
%   %   % (rule B10: every input argument shown in the GUI)
%   % * Tooltips on every control; "Clear" renamed "Clear selection";
%   %   % Copy names grayed out while nothing is selected
%   % * Result() makes the default vehicle's demo copy once, not at
%   %   % each call; Open() with a name not in the list gives a clear
%   %   % error (CarMesh3D:notInList); "mesh editor" now "label painter"
%   % * The Descending check box is replaced by an Order? drop-down whose
%   %   % two choices are worded for the sort chosen (A to Z, Newest
%   %   % first, Longest first ...), each sort opening at its own default
%   %   % (Sean, C2S 6, 21:22); new option Order=; Descending= kept for
%   %   % old calls; new hook SortOrder()
%   % * "Name" is no longer a sort choice (Sean, 21:54: the name starts
%   %   % with the year, so the order looked random; Make covers it);
%   %   % SortBy='name' in old calls sorts by make
%   % * A progress bar while the list is arranged, and the list hidden
%   %   % while its rows move (Sean, 22:15: changing the sort in a visible
%   %   % window gave no response; anything longer than 2 or 3 seconds
%   %   % shows a progress bar); an error while arranging is shown in
%   %   % the window and the command window, not lost
%   % * Ties are ordered by make, then name, and for a text sort in the
%   %   % order chosen: sorting by Class within Class groups, Z to A, gave
%   %   % the coupes by year, not Z to A (Sean's screenshot, 22:05)
%   % * Text sorts ignore upper and lower case ("GUITestVehicle" came
%   %   % before "GenericSedan"; found by the new every-arrangement test)
%   % * Fixed: ticking Descending put the sort back to the one the window
%   %   % opened with, and choosing a sort cleared Descending (their
%   %   % callbacks kept the values from when the window was built;
%   %   % Sean's T2, 21:17)



% Declare the inputs. This block only names the inputs and sets the
% option defaults: it has no class, size, or validator checks, so it
% adds little time to each call. The real input checks are in the
% gated section below, which can be skipped with FigNum=-1 or with
% the MATLABFLAG_CARMESH3D_FLAG_CHECK_INPUTS environment variable.
arguments
    options.Vehicles = {}             % Only these vehicles (MATLAB names); {} for the whole library
    options.SortBy = 'class'          % How the list is sorted
    options.GroupBy = 'class'         % How the list is grouped
    options.Order = ''                % The order within each group, in the drop-down's words; '' for the sort's default
    options.Descending = []           % (older way) true for Z to A / newest / longest / highest first; [] for the sort's default
    options.Selected = {}             % Names ticked at the start
    options.DefaultVehicle = '2009_Honda_Fit_Sport'   % Returned (as a fresh copy) when none is selected
    options.Wait = []                 % Wait for the window to close; [] for "when visible"
    options.Visible = true            % false to build the window hidden
    options.DataFolder = []           % The Data folder; [] for the one next to Functions
    options.FigNum = []               % Not used; -1 for fast mode
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
sortKeys = {'make','year','class','length','score','review','built','reviewDate'};
groupKeys = {'class','make','year','review','exemplar','license','none'};
if 0==flag_max_speed
    if flag_check_inputs
        % The number of inputs and the option names are checked by the
        % arguments block above
        if ~any(strcmpi(char(options.SortBy), [sortKeys, {'name'}]))
            error('CarMesh3D:badInput', 'SortBy must be one of: %s', strjoin(sortKeys, ', '));
        end
        if ~isempty(options.Order)
            [orderWords, ~] = fcn_INTERNAL_orderWords(char(options.SortBy));
            if ~any(strcmpi(char(options.Order), orderWords))
                error('CarMesh3D:badInput', 'For SortBy=''%s'', Order must be ''%s'' or ''%s''.', ...
                    char(options.SortBy), orderWords{1}, orderWords{2});
            end
        end
        if ~isempty(options.Descending) && ~(islogical(options.Descending) || isnumeric(options.Descending))
            error('CarMesh3D:badInput', 'Descending must be true or false.');
        end
        if ~any(strcmpi(char(options.GroupBy), groupKeys))
            error('CarMesh3D:badInput', 'GroupBy must be one of: %s', strjoin(groupKeys, ', '));
        end
        if ~(iscellstr(options.Vehicles) || isstring(options.Vehicles) || ischar(options.Vehicles)) %#ok<ISCLSTR>
            error('CarMesh3D:badInput', 'Vehicles must be a cell array of vehicle IDs (MATLAB names), or {} for the whole library.');
        end
        if ~(iscellstr(options.Selected) || isstring(options.Selected) || ischar(options.Selected)) %#ok<ISCLSTR>
            error('CarMesh3D:badInput', 'Selected must be a cell array of vehicle IDs.');
        end
        if ~(ischar(options.DefaultVehicle) || (isstring(options.DefaultVehicle) && isscalar(options.DefaultVehicle)))
            error('CarMesh3D:badInput', 'DefaultVehicle must be a vehicle ID.');
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

functionName = 'fcn_CarMesh3D_browseLibrary';
flagWait = options.Wait;
if isempty(flagWait)
    flagWait = logical(options.Visible);
end

% The window, first (so the progress of drawing the pictures is shown)
figureHandle = uifigure('Name', [functionName ': the vehicle library'], ...
    'Position', fcn_INTERNAL_windowPosition(), 'Visible', fcn_INTERNAL_onOff(options.Visible), ...
    'Color', [0.97 0.97 0.97]);
% (the title bar: this function's name and version; the rest under it)
librarySubtitle = 'The vehicle library: tick "Select" on the vehicles wanted; their MATLAB names are returned when this window is closed';
if ~isempty(options.Vehicles)
    librarySubtitle = sprintf('Part of the vehicle library: the %d vehicles given (Vehicles option). Tick "Select" on the ones wanted; their MATLAB names are returned when this window is closed', ...
        numel(cellstr(options.Vehicles)));
end
if ~isempty(options.DataFolder)
    librarySubtitle = sprintf('%s. Data folder: %s', librarySubtitle, char(options.DataFolder));
end
contentPanel = fcn_CarMesh3D_addTitleBar(figureHandle, functionName, FigNum=-1, Subtitle=librarySubtitle);
mainGrid = uigridlayout(contentPanel, [3 1], 'RowHeight', {66, 44, '1x'}, ...
    'Padding', [10 8 10 8], 'RowSpacing', 6);

% Gather the vehicles' details (and draw their pictures, the first time)
progressDialog = [];
if options.Visible
    progressDialog = uiprogressdlg(figureHandle, 'Title', functionName, 'Message', 'Reading the library...');
end
vehicles = fcn_INTERNAL_gatherVehicles(options.DataFolder, cellstr(options.Vehicles), progressDialog);
if ~isempty(progressDialog) && isvalid(progressDialog)
    close(progressDialog);
end
numVehicles = numel(vehicles);
flagSelected = ismember({vehicles.ID}, cellstr(options.Selected));
sortKey = fcn_INTERNAL_sortKey(options.SortBy);
groupKey = lower(char(options.GroupBy));
[orderWords, orderDescending] = fcn_INTERNAL_orderWords(sortKey);
flagDescending = orderDescending(1);   % (the sort's own default)
if ~isempty(options.Order)
    flagDescending = orderDescending(strcmpi(char(options.Order), orderWords));
elseif ~isempty(options.Descending)
    flagDescending = logical(options.Descending);
end
filterTerms = {};   % (the filters applied, in order: each narrows what is shown)
currentOrder = 1:numVehicles;   % (indices into vehicles, as shown)
result = {};
flagResultFixed = false;
defaultCopyNames = {};   % (the default vehicle's demo copy, made once)
lastFilterTime = -inf;   % (when Enter last tried a filter)
lastFilterText = '';     % (and the text it tried)

% Row 1: the three ways to arrange the list, each in a box of its own,
% in the order they are used, left to right: group, then sort within the
% groups, then filter what is shown (Sean, 23:33: the sort box was left of
% the group box, read first, and mistaken for the main order). Then the
% count and the Done button, at the right
controlGrid = uigridlayout(mainGrid, [1 4], 'ColumnWidth', {220, 400, '1x', 175}, ...
    'Padding', [0 0 0 0], 'ColumnSpacing', 8);

groupPanel = uipanel(controlGrid, 'Title', '1. Group by', 'FontWeight', 'bold');
groupGrid = uigridlayout(groupPanel, [1 1], 'Padding', [6 4 6 4]);
groupLabels = {'Class (body style)','Make','Year','Review status','Exemplars first','License','(no groups)'};
% (callbacks take the control's value from the control itself: an
% anonymous function made before a control exists cannot name it)
groupDropdown = uidropdown(groupGrid, 'Items', groupLabels, 'ItemsData', groupKeys, 'Value', groupKey, ...
    'Tooltip', 'The headings the list is divided under', ...
    'ValueChangedFcn', @(source,~) setGroup(source.Value));

sortPanel = uipanel(controlGrid, 'Title', '2. Sort within each group by', 'FontWeight', 'bold');
sortGrid = uigridlayout(sortPanel, [1 3], 'ColumnWidth', {'1x', 48, 150}, 'Padding', [6 4 6 4], 'ColumnSpacing', 4);
sortLabels = {'Make','Year','Class (body style)','Length','Score','Review (% approved)','Date built','Date reviewed'};
sortDropdown = uidropdown(sortGrid, 'Items', sortLabels, 'ItemsData', sortKeys, 'Value', sortKey, ...
    'Tooltip', 'The order of the vehicles under each heading', ...
    'ValueChangedFcn', @(source,~) onSortKeyChanged(source.Value));
% (the order within each group, in words that fit the sort chosen:
% Sean, C2S 6, 21:22; "Descending" was an odd word for alphabetical order)
uilabel(sortGrid, 'Text', 'Order?', 'HorizontalAlignment', 'right');
orderDropdown = uidropdown(sortGrid, 'Items', orderWords, 'ItemsData', double(orderDescending), ...
    'Value', double(flagDescending), ...
    'Tooltip', 'The order of the vehicles under each heading (the headings keep their own order)', ...
    'ValueChangedFcn', @(source,~) onOrderChanged(source.Value));

filterPanel = uipanel(controlGrid, 'Title', '3. Filter: keep the vehicles shown whose name, MATLAB name or class holds', 'FontWeight', 'bold');
filterGrid = uigridlayout(filterPanel, [1 3], 'ColumnWidth', {'1x', 90, 90}, 'Padding', [6 4 6 4]);
filterField = uieditfield(filterGrid, 'text', 'Placeholder', 'part of a name, year, make, class', ...
    'Tooltip', 'Type, then press Enter or Apply filter: each filter narrows what is shown; Clear filters shows them all again', ...
    'ValueChangedFcn', @(source,~) onFilterEnter(source.Value));
uibutton(filterGrid, 'Text', 'Apply filter', ...
    'Tooltip', 'Keep, of the vehicles shown, those whose name, MATLAB name or class holds every word typed. A filter that matches none is not applied.', ...
    'ButtonPushedFcn', @(~,~) onApplyButton());
uibutton(filterGrid, 'Text', 'Clear filters', 'Tooltip', 'Remove every filter: show all the vehicles again', ...
    'ButtonPushedFcn', @(~,~) clearFilters());

doneGrid = uigridlayout(controlGrid, [2 1], 'RowHeight', {'1x', 30}, 'Padding', [0 0 0 0], 'RowSpacing', 2);
countLabel = uilabel(doneGrid, 'Text', '', 'FontColor', [0.3 0.3 0.3], 'WordWrap', 'on', 'VerticalAlignment', 'bottom');
uibutton(doneGrid, 'Text', 'Done: close and return', 'FontWeight', 'bold', ...
    'Tooltip', 'Close this window and return the selected vehicles'' MATLAB names (with none selected: a fresh copy of the default test vehicle)', ...
    'ButtonPushedFcn', @(~,~) closeWindow());

% Row 2: the selection, as a cell array to copy
% (shown as text, not in a text box: a box reads as a place to type, and
% this is only what will be returned; Sean, 23:35)
selectionGrid = uigridlayout(mainGrid, [1 5], 'ColumnWidth', {215, '1x', 110, 120, 120}, ...
    'Padding', [0 0 0 0], 'ColumnSpacing', 6);
uilabel(selectionGrid, 'Text', {'Returned when closed:', 'the selected, in the order shown'}, 'FontWeight', 'bold');
selectionArea = uilabel(selectionGrid, 'Text', '', 'FontName', 'Courier New', 'FontSize', 12, 'WordWrap', 'on', ...
    'VerticalAlignment', 'center', 'FontColor', [0.10 0.25 0.55]);
copyButton = uibutton(selectionGrid, 'Text', 'Copy names', 'Tooltip', 'Copy the line shown, a MATLAB cell array, to the clipboard', ...
    'ButtonPushedFcn', @(~,~) clipboard('copy', selectionArea.Text));
uibutton(selectionGrid, 'Text', 'Select all shown', 'Tooltip', 'Tick Select on every vehicle shown (not on those the filters hide)', ...
    'ButtonPushedFcn', @(~,~) selectShown(true));
uibutton(selectionGrid, 'Text', 'Clear selection', 'Tooltip', 'Untick Select on every vehicle shown', ...
    'ButtonPushedFcn', @(~,~) selectShown(false));

% Row 3: the scrolling list, one row per vehicle, and a header per group
listGrid = uigridlayout(mainGrid, [max(numVehicles,1) 1], 'Scrollable', 'on', ...
    'Padding', [0 0 0 0], 'RowSpacing', 4, 'BackgroundColor', [0.97 0.97 0.97]);
rowPanels = gobjects(numVehicles, 1);
selectBoxes = gobjects(numVehicles, 1);
for ith_vehicle = 1:numVehicles
    [rowPanels(ith_vehicle), selectBoxes(ith_vehicle)] = fcn_INTERNAL_buildRow(listGrid, vehicles(ith_vehicle), ...
        flagSelected(ith_vehicle), @(source,~) onSelect(ith_vehicle, source.Value), ...
        @(toolName) openTool(ith_vehicle, toolName));
end
groupHeaders = gobjects(0, 1);

figureHandle.CloseRequestFcn = @(~,~) closeWindow();
arrangeList();

% The browser's handles and functions
browser = struct('Figure', figureHandle, 'Vehicles', vehicles, ...
    'Order', @getOrder, 'SetSort', @setSort, 'SortOrder', @getSortOrder, 'SetGroup', @setGroup, ...
    'Open', @openByName, ...
    'ApplyFilter', @applyFilter, 'ClearFilters', @clearFilters, 'Filters', @getFilters, ...
    'Select', @(names) setSelected(names, true), 'Deselect', @(names) setSelected(names, false), ...
    'Selected', @getSelected, 'Result', @getResult, 'Close', @closeWindow);

if flagWait && options.Visible
    uiwait(figureHandle);
    selectedNames = result;
else
    selectedNames = getSelected();
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

if flag_do_debug
    fprintf(1,'ENDING function: %s, in file: %s\n\n',st(1).name,st(1).file);
end

%% The window's nested functions (they share its state)

    function arrangeList()
        % Sorts, groups and filters the rows, and places them (with a
        % header per group) in the list. In a visible window this shows a
        % progress bar while it works (anything that can take more than 2
        % or 3 seconds shows one: Sean, 22:15). An error is shown in the
        % window, not lost. (The list is NOT hidden while its rows move:
        % hiding the scrolling list stalled the window's drawing for about
        % 60 s, measured 22:28)
        progressBar = [];
        if strcmp(figureHandle.Visible, 'on')
            progressBar = uiprogressdlg(figureHandle, 'Title', functionName, ...
                'Message', 'Arranging the list...', 'Indeterminate', 'on');
        end
        cleanupList = onCleanup(@() fcn_INTERNAL_endArrange(progressBar));
        try
            arrangeRows();
        catch ME
            warnUser(sprintf('The list could not be arranged: %s', ME.message));
            fprintf(2, '%s: the list could not be arranged:\n%s\n', functionName, getReport(ME));
        end
    end

    function arrangeRows()
        currentOrder = fcn_INTERNAL_order(vehicles, sortKey, groupKey, flagDescending);
        flagShown = fcn_INTERNAL_matchesFilter(vehicles, filterTerms);
        shownOrder = currentOrder(flagShown(currentOrder));
        hiddenOrder = currentOrder(~flagShown(currentOrder));

        delete(groupHeaders(isgraphics(groupHeaders)));
        groupHeaders = gobjects(0, 1);
        rowHeights = {};
        lastGroup = string(missing);
        for ith_shown = 1:numel(shownOrder)
            thisVehicle = shownOrder(ith_shown);
            thisGroup = fcn_INTERNAL_groupName(vehicles(thisVehicle), groupKey);
            if ~strcmp(groupKey, 'none') && (ismissing(lastGroup) || ~strcmp(thisGroup, lastGroup))
                numInGroup = sum(arrayfun(@(k) strcmp(fcn_INTERNAL_groupName(vehicles(k), groupKey), thisGroup), shownOrder));
                header = uilabel(listGrid, 'Text', sprintf('  %s   (%d)', thisGroup, numInGroup), ...
                    'FontSize', 16, 'FontWeight', 'bold', 'FontColor', [1 1 1], 'BackgroundColor', [0.25 0.35 0.5]);
                rowHeights{end+1} = 30; %#ok<AGROW>
                header.Layout.Row = numel(rowHeights);
                groupHeaders(end+1, 1) = header; %#ok<AGROW>
                lastGroup = thisGroup;
            end
            rowHeights{end+1} = 210; %#ok<AGROW>
            rowPanels(thisVehicle).Layout.Row = numel(rowHeights);
            rowPanels(thisVehicle).Visible = 'on';
        end
        for ith_hidden = 1:numel(hiddenOrder)
            rowHeights{end+1} = 0; %#ok<AGROW>
            rowPanels(hiddenOrder(ith_hidden)).Layout.Row = numel(rowHeights);
            rowPanels(hiddenOrder(ith_hidden)).Visible = 'off';
        end
        if isempty(rowHeights)
            rowHeights = {0};
        end
        listGrid.RowHeight = rowHeights;
        if isempty(filterTerms)
            countLabel.Text = sprintf('%d of %d vehicles shown', numel(shownOrder), numVehicles);
        else
            countLabel.Text = sprintf('%d of %d shown; filters: %s', numel(shownOrder), numVehicles, ...
                strjoin(strcat('"', filterTerms, '"'), ' + '));
        end
        showSelection();
    end

    function setSort(newKey, newDescending)
        % Sorts by newKey; with no newDescending, in that sort's own
        % default order (the first of its Order? choices)
        sortKey = fcn_INTERNAL_sortKey(newKey);
        [newWords, newOrderDescending] = fcn_INTERNAL_orderWords(sortKey);
        if nargin < 2 || isempty(newDescending)
            newDescending = newOrderDescending(1);
        end
        flagDescending = logical(newDescending);
        sortDropdown.Value = sortKey;
        orderDropdown.Items = newWords;
        orderDropdown.ItemsData = double(newOrderDescending);
        orderDropdown.Value = double(flagDescending);
        arrangeList();
    end

    function words = getSortOrder()
        % The Order? words shown now
        words = orderDropdown.Items{orderDropdown.ItemsData == orderDropdown.Value};
    end

    function onSortKeyChanged(newKey)
        % The sort drop-down: the new sort opens in its own default order
        % (C2S 6). A nested function, so it reads the current values, not
        % those of when the window was built (Sean's T2, 21:17)
        setSort(newKey);
    end

    function onOrderChanged(newDescending)
        % The Order? drop-down: keeps the sort key as it is now
        setSort(sortKey, logical(newDescending));
    end

    function setGroup(newKey)
        groupKey = lower(char(newKey));
        groupDropdown.Value = groupKey;
        arrangeList();
    end

    function [toolOutput, folderUsed] = openByName(name, toolName, varargin)
        % Opens the named vehicle (one in this list) in a tool
        index = find(strcmp({vehicles.ID}, char(name)), 1);
        if isempty(index)
            error('CarMesh3D:notInList', '%s: "%s" is not among the vehicles in this list.', functionName, char(name));
        end
        [toolOutput, folderUsed] = openTool(index, toolName, varargin{:});
    end

    function [toolOutput, folderUsed] = openTool(index, toolName, flagUseCopy)
        % Opens this vehicle in a tool: 'view' (the viewer: changes
        % nothing), 'edit' (the label painter) or 'review' (the reviewer).
        % The editor and the reviewer save to the vehicle, so the user is
        % asked first, and may open a fresh demo copy instead
        % (flagUseCopy: true or false skips the question, for scripts)
        vehicle = vehicles(index);
        folderUsed = vehicle.Folder;
        toolOutput = [];
        if any(strcmp(toolName, {'edit','review'}))
            if nargin < 3
                if strcmp(figureHandle.Visible, 'on')
                    answer = uiconfirm(figureHandle, sprintf(['Changes made in the %s are saved to %s itself. ' ...
                        'Open the vehicle, or a fresh demo copy of it (changes not saved)?'], ...
                        fcn_INTERNAL_toolTitle(toolName), vehicle.Name), functionName, ...
                        'Options', {'Open the vehicle', 'Open a demo copy', 'Cancel'}, ...
                        'DefaultOption', 2, 'CancelOption', 3, 'Icon', 'warning');
                    if strcmp(answer, 'Cancel')
                        return;
                    end
                    flagUseCopy = strcmp(answer, 'Open a demo copy');
                else
                    flagUseCopy = true;
                end
            end
            if flagUseCopy
                demoFiles = fcn_CarMesh3D_makeDemoCopy(vehicle.ID, FigNum=-1);
                folderUsed = demoFiles.Folder;
            end
        end
        files = fcn_CarMesh3D_findVehicleFiles(folderUsed, FigNum=-1);
        switch toolName
            case 'view'
                outlineArguments = {};
                if files.HasOutline
                    outlineArguments = {'Outline', files.OutlineFile};
                end
                [~, toolOutput] = fcn_CarMesh3D_viewLabels(files.MeshFile, outlineArguments{:}, Wait=false, ...
                    Visible=strcmp(figureHandle.Visible, 'on'));
            case 'edit'
                [~, ~, toolOutput] = fcn_CarMesh3D_paintLabels(files.Folder, Visible=strcmp(figureHandle.Visible, 'on'));
            case 'review'
                [~, toolOutput] = fcn_CarMesh3D_reviewVehicle(files.Folder, Visible=strcmp(figureHandle.Visible, 'on'));
        end
    end

    function flagApplied = applyFilter(newText)
        % Narrows the vehicles shown to those that also match this text
        % (filters stack). A text that matches none of them is not
        % applied, and the user is told, so the list is never emptied
        newText = strtrim(char(newText));
        flagApplied = false;
        if isempty(newText)
            warnUser('Type part of a name, year, make or class in the filter box, then press Apply filter.');
            return;
        end
        flagShownNow = fcn_INTERNAL_matchesFilter(vehicles, filterTerms);
        flagShownAfter = flagShownNow & fcn_INTERNAL_matchesFilter(vehicles, {newText});
        if ~any(flagShownAfter)
            warnUser(sprintf(['No vehicle now shown has "%s" in its name, MATLAB name, or class, ' ...
                'so the filter was not applied.'], newText));
            return;
        end
        filterTerms{end+1} = newText;
        filterField.Value = '';
        flagApplied = true;
        arrangeList();
    end

    function onFilterEnter(newText)
        % Enter in the filter box (rule B9). MATLAB also calls this when
        % the box loses focus after typing, for example when Apply filter
        % is pressed; the button then finds the box empty and does nothing
        if isempty(strtrim(char(newText)))
            return;
        end
        applyFilter(newText);
        lastFilterTime = now; %#ok<TNOW1>
        lastFilterText = strtrim(char(newText));
    end

    function onApplyButton()
        % Apply filter: when Enter (or leaving the box) has just tried this
        % same text, the box is empty (applied) or holds that text (not
        % applied, already warned), so do nothing more
        textNow = strtrim(char(filterField.Value));
        if (now - lastFilterTime) * 86400 < 2 && (isempty(textNow) || strcmp(textNow, lastFilterText)) %#ok<TNOW1>
            return;
        end
        applyFilter(filterField.Value);
    end

    function clearFilters()
        filterTerms = {};
        filterField.Value = '';
        arrangeList();
    end

    function terms = getFilters()
        terms = filterTerms;
    end

    function warnUser(message)
        % A warning in the window (and in the command window when the
        % window is hidden, as in tests)
        if strcmp(figureHandle.Visible, 'on')
            uialert(figureHandle, message, functionName, 'Icon', 'warning');
        else
            fprintf(1, '%s: %s\n', functionName, message);
        end
    end

    function onSelect(index, flagValue)
        flagSelected(index) = flagValue;
        showSelection();
    end

    function selectShown(flagValue)
        flagShown = fcn_INTERNAL_matchesFilter(vehicles, filterTerms);
        flagSelected(flagShown) = flagValue;
        for ith_box = find(flagShown)
            selectBoxes(ith_box).Value = flagValue;
        end
        showSelection();
    end

    function setSelected(names, flagValue)
        flagNames = ismember({vehicles.ID}, cellstr(names));
        flagSelected(flagNames) = flagValue;
        for ith_box = find(flagNames)
            selectBoxes(ith_box).Value = flagValue;
        end
        showSelection();
    end

    function names = getSelected()
        flagShown = fcn_INTERNAL_matchesFilter(vehicles, filterTerms);
        shownFirst = [currentOrder(flagShown(currentOrder)), currentOrder(~flagShown(currentOrder))];
        names = {vehicles(shownFirst(flagSelected(shownFirst))).ID};
    end

    function ids = getOrder()
        flagShown = fcn_INTERNAL_matchesFilter(vehicles, filterTerms);
        ids = {vehicles(currentOrder(flagShown(currentOrder))).ID};
    end

    function showSelection()
        names = getSelected();
        if isempty(names)
            selectionArea.Text = sprintf('(none selected: closing returns a fresh copy of %s)', char(options.DefaultVehicle));
            copyButton.Enable = 'off';
        else
            copyButton.Enable = 'on';
            selectionArea.Text = sprintf('selectedNames = {%s};   %% %d vehicle(s)', ...
                strjoin(strcat('''', names, ''''), ', '), numel(names));
        end
    end

    function names = getResult()
        % What closing returns: the selection, else the default vehicle's
        % fresh copy (made once)
        if flagResultFixed
            names = result;
            return;
        end
        names = getSelected();
        if isempty(names) && ~isempty(defaultCopyNames)
            names = defaultCopyNames;
        elseif isempty(names)
            demoFiles = fcn_CarMesh3D_makeDemoCopy(char(options.DefaultVehicle), FigNum=-1);
            names = {demoFiles.Folder};
            defaultCopyNames = names;
            fprintf(1, ['%s: no vehicle was selected, so a fresh copy of the default test vehicle is returned:\n' ...
                '    %s\n    (changes made to it are not saved to the vehicle)\n'], functionName, demoFiles.Folder);
        end
    end

    function closeWindow()
        if ~flagResultFixed
            result = getResult();
            flagResultFixed = true;
        end
        if isvalid(figureHandle)
            uiresume(figureHandle);
            delete(figureHandle);
        end
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

%% fcn_INTERNAL_gatherVehicles
function vehicles = fcn_INTERNAL_gatherVehicles(dataFolder, onlyIDs, progressDialog)
% One element per finished vehicle (or per vehicle of onlyIDs, when it is
% not empty): its names, class, size, processing, license, review, and its
% two pictures
vehicleTable = fcn_CarMesh3D_browseVehicles(Interactive=false, DataFolder=dataFolder, FigNum=-1);
onlyIDs = onlyIDs(~cellfun(@isempty, onlyIDs));
if ~isempty(onlyIDs)
    missingIDs = setdiff(onlyIDs, cellstr(vehicleTable.ID), 'stable');
    if ~isempty(missingIDs)
        warning('CarMesh3D:notInLibrary', 'These vehicles are not among the finished vehicles, so they are left out: %s', ...
            strjoin(missingIDs, ', '));
    end
    vehicleTable = vehicleTable(ismember(cellstr(vehicleTable.ID), onlyIDs), :);
end
bodyStyles = fcn_CarMesh3D_loadBodyStyles();
numVehicles = height(vehicleTable);
template = struct('ID','', 'Name','', 'Year',NaN, 'Make','', 'Model','', 'Trim','', 'Folder','', ...
    'ClassKey','', 'ClassName','', 'IsExemplar',false, 'IsGeneric',false, ...
    'Length',NaN, 'Width',NaN, 'Height',NaN, 'Faces',NaN, 'Score',NaN, 'ChecksFailed',NaN, ...
    'Built',NaT, 'MeshVersion','', 'BuildStatus','', 'License','', 'LicenseAuthor','', ...
    'ReviewTotal',0, 'ReviewAnswered',0, 'ReviewApproved',0, 'ReviewRejected',0, 'ReviewPercent',NaN, ...
    'Reviewers','', 'ReviewDate',NaT, 'ReviewDecision','', 'ReviewStatus','not reviewed', ...
    'Picture3D','', 'Picture2D','');
vehicles = repmat(template, numVehicles, 1);
for ith_vehicle = 1:numVehicles
    row = vehicleTable(ith_vehicle, :);
    thisID = char(row.ID);
    if ~isempty(progressDialog) && isvalid(progressDialog)
        progressDialog.Value = (ith_vehicle-1)/max(numVehicles,1);
        progressDialog.Message = sprintf('Reading %s (%d of %d)...', thisID, ith_vehicle, numVehicles);
    end
    thisVehicle = template;
    files = fcn_CarMesh3D_findVehicleFiles(thisID, DataFolder=dataFolder, FigNum=-1);
    thisVehicle.ID = thisID;
    thisVehicle.Name = files.Name;
    thisVehicle.Year = files.Year;
    thisVehicle.Make = files.Make;
    thisVehicle.Model = files.Model;
    thisVehicle.Trim = files.Trim;
    thisVehicle.Folder = files.Folder;

    % Class
    thisVehicle.ClassKey = char(row.BodyStyle);
    thisVehicle.ClassName = thisVehicle.ClassKey;
    styleIndex = find(strcmpi({bodyStyles.BodyStyle}, thisVehicle.ClassKey), 1);
    if ~isempty(styleIndex)
        thisVehicle.ClassName = char(bodyStyles(styleIndex).Name);
    elseif ~isempty(thisVehicle.ClassName)
        thisVehicle.ClassName = [upper(thisVehicle.ClassName(1)) thisVehicle.ClassName(2:end)];
    else
        thisVehicle.ClassName = '(no class)';
    end
    thisVehicle.IsExemplar = logical(row.IsExemplar);
    thisVehicle.IsGeneric = logical(row.FromBodyStyle);

    % Size and processing
    thisVehicle.Length = row.Length_m;
    thisVehicle.Width = row.Width_m;
    thisVehicle.Height = row.Height_m;
    thisVehicle.Faces = row.Faces;
    thisVehicle.Score = row.Score;
    thisVehicle.ChecksFailed = row.ChecksFailed;
    thisVehicle.MeshVersion = char(row.MeshVersion);
    thisVehicle.BuildStatus = char(row.Status);
    try
        thisVehicle.Built = datetime(char(row.Made), 'InputFormat', 'yyyy-MM-dd HH:mm');
    catch
    end

    % License and the logged review decision
    try
        history = fcn_CarMesh3D_meshHistory(files.Folder, FigNum=-1);
        thisVehicle.License = char(history.License.Name);
        thisVehicle.LicenseAuthor = char(history.License.Author);
        if ~strcmpi(history.Review.Status, 'not reviewed')
            thisVehicle.ReviewDecision = char(history.Review.Status);
        end
    catch
    end
    if isempty(thisVehicle.License)
        if thisVehicle.IsGeneric
            thisVehicle.License = 'none needed (made by CarMesh3D from its body style)';
        else
            thisVehicle.License = '(not found)';
        end
    end

    % The review's answers
    reviewFile = fullfile(files.ChecksFolder, sprintf('review_%s.mat', thisID));
    if isfile(reviewFile)
        try
            loaded = load(reviewFile, 'reviewTable');
            reviewTable = loaded.reviewTable;
            status = string(reviewTable.Status);
            thisVehicle.ReviewTotal = numel(status);
            thisVehicle.ReviewAnswered = sum(strlength(status) > 0);
            thisVehicle.ReviewApproved = sum(status == "approved");
            thisVehicle.ReviewRejected = sum(status == "rejected");
            if thisVehicle.ReviewAnswered > 0
                thisVehicle.ReviewPercent = 100*thisVehicle.ReviewApproved/thisVehicle.ReviewAnswered;
            end
            reviewers = unique(string(reviewTable.Reviewer(strlength(status) > 0)));
            reviewers = reviewers(strlength(reviewers) > 0);
            thisVehicle.Reviewers = char(strjoin(reviewers, ', '));
            times = string(reviewTable.Time(strlength(string(reviewTable.Time)) > 0));
            if ~isempty(times)
                thisVehicle.ReviewDate = max(datetime(times, 'InputFormat', 'yyyy-MM-dd HH:mm'));
            end
        catch
        end
    end
    if thisVehicle.ReviewAnswered == 0
        thisVehicle.ReviewStatus = 'not reviewed';
    elseif thisVehicle.ReviewAnswered < thisVehicle.ReviewTotal && isempty(thisVehicle.ReviewDecision)
        thisVehicle.ReviewStatus = 'partly reviewed';
    else
        thisVehicle.ReviewStatus = 'reviewed';
    end

    % The pictures (drawn once, then kept)
    [thisVehicle.Picture3D, thisVehicle.Picture2D] = fcn_INTERNAL_pictures(files);
    vehicles(ith_vehicle) = thisVehicle;
end
end % Ends fcn_INTERNAL_gatherVehicles

%% fcn_INTERNAL_pictures
function [picture3D, picture2D] = fcn_INTERNAL_pictures(files)
% The labeled 3D mesh and the 2D overhead outline, as small pictures kept
% in the temporary folder; drawn again when the file they show changes
pictureFolder = fullfile(tempdir, 'CarMesh3D_thumbnails');
if ~isfolder(pictureFolder)
    mkdir(pictureFolder);
end
picture3D = '';
picture2D = '';
if isfile(files.MeshFile)
    meshInfo = dir(files.MeshFile);
    picture3D = fullfile(pictureFolder, sprintf('%s_3D_%s.png', files.ID, datestr(meshInfo.datenum, 'yyyymmddHHMMSS'))); %#ok<DATST>
    if ~isfile(picture3D)
        try
            loaded = load(files.MeshFile, 'vehicleMesh');
            fcn_INTERNAL_draw3D(loaded.vehicleMesh, picture3D);
        catch
            picture3D = '';
        end
    end
end
if isfile(files.OutlineFile)
    outlineInfo = dir(files.OutlineFile);
    picture2D = fullfile(pictureFolder, sprintf('%s_2D_%s.png', files.ID, datestr(outlineInfo.datenum, 'yyyymmddHHMMSS'))); %#ok<DATST>
    if ~isfile(picture2D)
        try
            loaded = load(files.OutlineFile, 'vehicleOutline');
            fcn_INTERNAL_draw2D(loaded.vehicleOutline, picture2D);
        catch
            picture2D = '';
        end
    end
end
end % Ends fcn_INTERNAL_pictures

%% fcn_INTERNAL_draw3D
function fcn_INTERNAL_draw3D(vehicleMesh, pictureFile)
% The mesh in its label colors, seen from the front left, a little above
labelMesh = fcn_CarMesh3D_plotLabels(vehicleMesh, FigNum=-1);
drawFigure = figure('Visible', 'off', 'Position', [100 100 420 300], 'Color', [1 1 1]);
cleanupFigure = onCleanup(@() delete(drawFigure));
drawAxes = axes(drawFigure, 'Position', [0 0 1 1]);
fcn_CarMesh3D_plotVehicle(labelMesh, AxesHandle=drawAxes, FigNum=-1);
title(drawAxes, '');
axis(drawAxes, 'equal');
axis(drawAxes, 'off');
view(drawAxes, 135, 18);
camproj(drawAxes, 'perspective');
axis(drawAxes, 'tight');
drawnow;
picture = print(drawFigure, '-RGBImage', '-r96');
imwrite(picture, pictureFile);
end % Ends fcn_INTERNAL_draw3D

%% fcn_INTERNAL_draw2D
function fcn_INTERNAL_draw2D(vehicleOutline, pictureFile)
% The overhead outline: body, interior, windows, lights and wheels; the
% front to the right
drawFigure = figure('Visible', 'off', 'Position', [100 100 420 300], 'Color', [1 1 1]);
cleanupFigure = onCleanup(@() delete(drawFigure));
drawAxes = axes(drawFigure, 'Position', [0.02 0.02 0.96 0.96]);
hold(drawAxes, 'on');
fcn_INTERNAL_fill(drawAxes, vehicleOutline.Body, [0.10 0.22 0.55], 1);
if isfield(vehicleOutline, 'Interior')
    for ith_piece = 1:numel(vehicleOutline.Interior)
        fcn_INTERNAL_fill(drawAxes, vehicleOutline.Interior(ith_piece).Polygon, [0.85 0.72 0.52], 0.8);
    end
end
if isfield(vehicleOutline, 'Windows')
    for ith_piece = 1:numel(vehicleOutline.Windows)
        fcn_INTERNAL_fill(drawAxes, vehicleOutline.Windows(ith_piece).Polygon, [0.62 0.78 0.92], 0.55);
    end
end
if isfield(vehicleOutline, 'Lights')
    lightColors = struct('headlight', [1 0.85 0.1], 'tail', [0.85 0 0], 'turn', [1 0.55 0], ...
        'running', [0 0.8 0.8], 'backup', [0.2 0.75 0.2]);
    for ith_piece = 1:numel(vehicleOutline.Lights)
        lightType = char(vehicleOutline.Lights(ith_piece).Type);
        thisColor = [0.85 0 0.85];
        names = fieldnames(lightColors);
        for ith_name = 1:numel(names)
            if contains(lower(lightType), names{ith_name})
                thisColor = lightColors.(names{ith_name});
            end
        end
        fcn_INTERNAL_fill(drawAxes, vehicleOutline.Lights(ith_piece).Polygon, thisColor, 1);
    end
end
if isfield(vehicleOutline, 'Wheels')
    for ith_piece = 1:numel(vehicleOutline.Wheels)
        % (the rectangle is about the wheel's center)
        fcn_INTERNAL_fill(drawAxes, vehicleOutline.Wheels(ith_piece).Rectangle + vehicleOutline.Wheels(ith_piece).Center(:)', ...
            [0.08 0.08 0.08], 1);
    end
end
axis(drawAxes, 'equal');
axis(drawAxes, 'off');
drawnow;
picture = print(drawFigure, '-RGBImage', '-r96');
imwrite(picture, pictureFile);
end % Ends fcn_INTERNAL_draw2D

%% fcn_INTERNAL_fill
function fcn_INTERNAL_fill(drawAxes, polygon, color, alpha)
if size(polygon, 1) >= 3
    fill(drawAxes, polygon(:,1), polygon(:,2), color, 'FaceAlpha', alpha, 'EdgeColor', color*0.6);
end
end % Ends fcn_INTERNAL_fill

%% fcn_INTERNAL_buildRow
function [rowPanel, selectBox] = fcn_INTERNAL_buildRow(listGrid, vehicle, flagSelected, onSelect, onOpen)
% One vehicle's row: its 3D picture, its 2D picture, its details, and
% its Select box with buttons that open it in the viewer, the label
% painter, or the reviewer
rowPanel = uipanel(listGrid, 'BackgroundColor', [1 1 1]);
if vehicle.IsExemplar
    rowPanel.HighlightColor = [0.85 0.65 0];
    rowPanel.BorderWidth = 2;
end
rowGrid = uigridlayout(rowPanel, [1 4], 'ColumnWidth', {270, 270, '1x', 120}, ...
    'Padding', [6 6 6 6], 'ColumnSpacing', 10, 'BackgroundColor', [1 1 1]);
fcn_INTERNAL_picture(rowGrid, vehicle.Picture3D, 'no 3D picture');
fcn_INTERNAL_picture(rowGrid, vehicle.Picture2D, 'no 2D outline');

detailGrid = uigridlayout(rowGrid, [3 1], 'RowHeight', {34, 20, '1x'}, 'Padding', [0 0 0 0], ...
    'RowSpacing', 2, 'BackgroundColor', [1 1 1]);
nameText = vehicle.Name;
if vehicle.IsExemplar
    nameText = [char(9733) ' ' nameText];
end
nameLabel = uilabel(detailGrid, 'Text', nameText, 'FontSize', 22, 'FontWeight', 'bold');
if vehicle.IsExemplar
    nameLabel.FontColor = [0.6 0.4 0];
end
uilabel(detailGrid, 'Text', vehicle.ID, 'FontName', 'Courier New', 'FontSize', 13, 'FontColor', [0.35 0.35 0.35]);
uilabel(detailGrid, 'Text', fcn_INTERNAL_detailsHTML(vehicle), 'Interpreter', 'html', ...
    'VerticalAlignment', 'top', 'WordWrap', 'on', 'FontSize', 12);

buttonGrid = uigridlayout(rowGrid, [5 1], 'RowHeight', {34, 8, 28, 28, 28}, 'Padding', [0 10 0 0], ...
    'RowSpacing', 4, 'BackgroundColor', [1 1 1]);
selectBox = uicheckbox(buttonGrid, 'Text', 'Select', 'FontSize', 15, 'FontWeight', 'bold', ...
    'Value', flagSelected, 'Tooltip', 'Return this vehicle''s MATLAB name when the window is closed', ...
    'ValueChangedFcn', onSelect);
uilabel(buttonGrid, 'Text', '');
uibutton(buttonGrid, 'Text', 'View', 'Tooltip', 'Open in fcn_CarMesh3D_viewLabels (changes nothing)', ...
    'ButtonPushedFcn', @(~,~) onOpen('view'));
uibutton(buttonGrid, 'Text', 'Edit labels', 'Tooltip', 'Open in the label painter, fcn_CarMesh3D_paintLabels (asks: the vehicle or a demo copy)', ...
    'ButtonPushedFcn', @(~,~) onOpen('edit'));
uibutton(buttonGrid, 'Text', 'Review', 'Tooltip', 'Open in the Model Reviewer, fcn_CarMesh3D_reviewVehicle (asks: the vehicle or a demo copy)', ...
    'ButtonPushedFcn', @(~,~) onOpen('review'));
end % Ends fcn_INTERNAL_buildRow

%% fcn_INTERNAL_toolTitle
function title = fcn_INTERNAL_toolTitle(toolName)
switch toolName
    case 'edit',   title = 'label painter (fcn_CarMesh3D_paintLabels)';
    case 'review', title = 'reviewer (fcn_CarMesh3D_reviewVehicle)';
    otherwise,     title = 'viewer (fcn_CarMesh3D_viewLabels)';
end
end % Ends fcn_INTERNAL_toolTitle

%% fcn_INTERNAL_picture
function fcn_INTERNAL_picture(parent, pictureFile, missingText)
if ~isempty(pictureFile) && isfile(pictureFile)
    uiimage(parent, 'ImageSource', pictureFile, 'ScaleMethod', 'fit');
else
    uilabel(parent, 'Text', missingText, 'HorizontalAlignment', 'center', 'FontColor', [0.5 0.5 0.5], ...
        'BackgroundColor', [0.94 0.94 0.94]);
end
end % Ends fcn_INTERNAL_picture

%% fcn_INTERNAL_detailsHTML
function html = fcn_INTERNAL_detailsHTML(vehicle)
% The details, as lines of HTML
lines = {};
classText = vehicle.ClassName;
if vehicle.IsExemplar
    classText = sprintf('%s &nbsp;<b><font color="#9a6700">%s exemplar of its class</font></b>', classText, char(9733));
end
if vehicle.IsGeneric
    classText = [classText ' &nbsp;(generic: made by CarMesh3D from the class)'];
end
lines{end+1} = sprintf('<b>Class:</b> %s', classText);
lines{end+1} = sprintf('<b>Size:</b> %.2f m long, %.2f m wide, %.2f m tall; %s faces', ...
    vehicle.Length, vehicle.Width, vehicle.Height, fcn_INTERNAL_thousands(vehicle.Faces));
if isnat(vehicle.Built)
    builtText = 'not yet';
else
    builtText = char(string(vehicle.Built, 'yyyy-MM-dd HH:mm'));
end
lines{end+1} = sprintf('<b>Processed:</b> %s (mesh %s, %s); <b>score %.1f</b>, %d check(s) failed', ...
    builtText, vehicle.MeshVersion, vehicle.BuildStatus, vehicle.Score, vehicle.ChecksFailed);
if vehicle.ReviewAnswered == 0
    reviewText = '<font color="#b00000"><b>not reviewed</b> by a person</font>';
else
    reviewText = sprintf('<b>%s</b>: %d of %d items answered, <b>%.0f%% approved</b> (%d rejected)', ...
        vehicle.ReviewStatus, vehicle.ReviewAnswered, vehicle.ReviewTotal, vehicle.ReviewPercent, vehicle.ReviewRejected);
    if ~isempty(vehicle.ReviewDecision)
        reviewText = [reviewText sprintf('; decision: <b>%s</b>', vehicle.ReviewDecision)];
    end
    if ~isempty(vehicle.Reviewers)
        reviewText = [reviewText ', by ' vehicle.Reviewers];
    end
    if ~isnat(vehicle.ReviewDate)
        reviewText = [reviewText ', ' char(string(vehicle.ReviewDate, 'yyyy-MM-dd HH:mm'))];
    end
end
lines{end+1} = ['<b>Review: </b>' reviewText];   % (the space inside the bold: outside, before a colored part, it was dropped)
licenseText = vehicle.License;
if ~isempty(vehicle.LicenseAuthor)
    licenseText = sprintf('%s, model by %s', licenseText, vehicle.LicenseAuthor);
end
lines{end+1} = ['<b>License:</b>&nbsp;' licenseText];
html = strjoin(lines, '<br>');
end % Ends fcn_INTERNAL_detailsHTML

%% fcn_INTERNAL_thousands
function text = fcn_INTERNAL_thousands(value)
if isnan(value)
    text = '?';
else
    text = regexprep(sprintf('%d', round(value)), '(\d)(?=(\d{3})+$)', '$1,');
end
end % Ends fcn_INTERNAL_thousands

%% fcn_INTERNAL_order
function order = fcn_INTERNAL_order(vehicles, sortKey, groupKey, flagDescending)
% The vehicles' order: by group (always in the groups' own order), then
% by the sort key (descending when asked), then ties by make and then by
% name. For a text sort (make, class) the ties follow the same order
% (Z to A gives Honda, Ford, CarMesh3D among the coupes when the sort is
% Class within Class groups: Sean, 22:05); for the others, A to Z
numVehicles = numel(vehicles);
if numVehicles == 0
    order = zeros(1,0);
    return;
end
names = lower(string({vehicles.Name}))';   % (text sorts ignore case: "Generic" before "GUI")
switch sortKey
    case 'name',       sortValues = names;
    case 'year',       sortValues = [vehicles.Year]';
    case 'make',       sortValues = lower(string({vehicles.Make}))';
    case 'class',      sortValues = lower(string({vehicles.ClassName}))';
    case 'length',     sortValues = [vehicles.Length]';
    case 'score',      sortValues = [vehicles.Score]';
    case 'review',     sortValues = [vehicles.ReviewPercent]';
    case 'built',      sortValues = datenum([vehicles.Built]'); %#ok<DATNM>
    case 'reviewDate', sortValues = datenum([vehicles.ReviewDate]'); %#ok<DATNM>
    otherwise,         sortValues = names;
end
groupValues = arrayfun(@(v) fcn_INTERNAL_groupSortValue(v, groupKey), vehicles(:));
direction = 'ascend';
if flagDescending
    direction = 'descend';
end
tieDirection = 'ascend';
if any(strcmp(sortKey, {'make','class'}))
    tieDirection = direction;
end
makes = lower(string({vehicles.Make}))';
sortTable = table((1:numVehicles)', groupValues, sortValues, makes, names, 'VariableNames', {'Index','Group','Value','Make','Name'});
sortTable = sortrows(sortTable, {'Group','Value','Make','Name'}, {'ascend', direction, tieDirection, tieDirection}, 'MissingPlacement', 'last');
order = sortTable.Index';
end % Ends fcn_INTERNAL_order

%% fcn_INTERNAL_endArrange
function fcn_INTERNAL_endArrange(progressBar)
% After the list is arranged (or fails): close the progress bar
if ~isempty(progressBar) && isvalid(progressBar)
    close(progressBar);
end
end % Ends fcn_INTERNAL_endArrange

%% fcn_INTERNAL_sortKey
function sortKey = fcn_INTERNAL_sortKey(sortKey)
% A sort key as the window uses it: 'reviewDate' spelled so, and the old
% 'name' (no longer a choice: Sean, 21:54) taken as 'make'
sortKey = lower(char(sortKey));
if strcmp(sortKey, 'reviewdate')
    sortKey = 'reviewDate';
elseif strcmp(sortKey, 'name')
    sortKey = 'make';
end
end % Ends fcn_INTERNAL_sortKey

%% fcn_INTERNAL_orderWords
function [words, flagDescending] = fcn_INTERNAL_orderWords(sortKey)
% The two Order? choices for a sort, the sort's own default first, and
% whether each one is a descending sort (Sean, C2S 6, 21:22)
switch lower(char(sortKey))
    case {'name','make','class'}
        words = {'A to Z', 'Z to A'};                         flagDescending = [false true];
    case {'year','built','reviewdate'}
        words = {'Newest first', 'Oldest first'};             flagDescending = [true false];
    case 'length'
        words = {'Longest first', 'Shortest first'};          flagDescending = [true false];
    case 'score'
        words = {'Highest first', 'Lowest first'};            flagDescending = [true false];
    case 'review'
        words = {'Most approved first', 'Least approved first'}; flagDescending = [true false];
    otherwise
        words = {'A to Z', 'Z to A'};                         flagDescending = [false true];
end
end % Ends fcn_INTERNAL_orderWords

%% fcn_INTERNAL_groupName
function groupName = fcn_INTERNAL_groupName(vehicle, groupKey)
switch groupKey
    case 'class'
        groupName = string(vehicle.ClassName);
    case 'make'
        groupName = string(vehicle.Make);
    case 'year'
        groupName = string(vehicle.Year);
    case 'review'
        groupName = string([upper(vehicle.ReviewStatus(1)) vehicle.ReviewStatus(2:end)]);
    case 'exemplar'
        if vehicle.IsExemplar
            groupName = string([char(9733) ' Exemplars of their class']);
        else
            groupName = "Other vehicles";
        end
    case 'license'
        groupName = string(vehicle.License);
    otherwise
        groupName = "";
end
end % Ends fcn_INTERNAL_groupName

%% fcn_INTERNAL_groupSortValue
function value = fcn_INTERNAL_groupSortValue(vehicle, groupKey)
% What the groups are ordered by
switch groupKey
    case 'year'
        value = string(sprintf('%04d', vehicle.Year));
    case 'review'
        value = string(find(strcmp(vehicle.ReviewStatus, {'reviewed','partly reviewed','not reviewed'})));
    case 'exemplar'
        value = string(double(~vehicle.IsExemplar));
    case 'none'
        value = "";
    otherwise
        value = lower(fcn_INTERNAL_groupName(vehicle, groupKey));
end
end % Ends fcn_INTERNAL_groupSortValue

%% fcn_INTERNAL_matchesFilter
function flagShown = fcn_INTERNAL_matchesFilter(vehicles, filterTerms)
% The vehicles that match every filter: a filter matches when its words
% are all in the vehicle's name, MATLAB name (ID), or class
flagShown = true(1, numel(vehicles));
for ith_term = 1:numel(filterTerms)
    words = split(string(strtrim(filterTerms{ith_term})));
    words = lower(words(strlength(words) > 0));
    for ith_vehicle = 1:numel(vehicles)
        v = vehicles(ith_vehicle);
        haystack = lower(strjoin(string({v.Name, v.ID, v.ClassName, v.ClassKey}), ' '));
        flagShown(ith_vehicle) = flagShown(ith_vehicle) && all(contains(haystack, words));
    end
end
end % Ends fcn_INTERNAL_matchesFilter

%% fcn_INTERNAL_windowPosition
function position = fcn_INTERNAL_windowPosition()
% A large window, centered on the screen
screen = get(groot, 'ScreenSize');
windowSize = [min(1400, screen(3)-80), min(900, screen(4)-120)];
position = [max(20, (screen(3)-windowSize(1))/2), max(40, (screen(4)-windowSize(2))/2), windowSize];
end % Ends fcn_INTERNAL_windowPosition

%% fcn_INTERNAL_onOff
function text = fcn_INTERNAL_onOff(flagValue)
if flagValue
    text = 'on';
else
    text = 'off';
end
end % Ends fcn_INTERNAL_onOff
