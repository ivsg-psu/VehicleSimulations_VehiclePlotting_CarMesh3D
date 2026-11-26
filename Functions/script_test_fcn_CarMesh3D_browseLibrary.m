% script_test_fcn_CarMesh3D_browseLibrary.m
% Tests fcn_CarMesh3D_browseLibrary
%
% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_browseLibrary
%   % * First write of the test script
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_browseLibrary
%   % * Tests for the design review (Sean, 17:56): Descending keeps the
%   %   % groups' order; Enter applies the filter; the demo copy is made
%   %   % once; Open() with an unknown name; tooltips; Copy names grayed
%   %   % out; the data folder named in the subtitle
%   % * The Order? drop-down (Sean, C2S 6, 21:22): its words follow the
%   %   % sort, each sort opens at its own default, Order= and the older
%   %   % Descending= options, and a bad Order is refused
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_browseLibrary
%   % * Automated GUI tests (Sean, 05:03: "User testing is a very (very)
%   %   % poor way to catch bugs"; Q39), all in hidden windows, driven
%   %   % through the browser's hooks and fcn_CarMesh3D_guiDriver:
%   %   % every control tagged; every Group by x Sort x Order? x Filter
%   %   % combination set through the controls, with the table's rows,
%   %   % headers, preview, highlight, ticks and buttons checked; random
%   %   % walks (3 seeds x 250 steps) with those rules checked after every
%   %   % step; each action button returns its step, closes the window and
%   %   % opens no other window (the tree rule); closing takes < 1 s; the
%   %   % layout at 640x400, 800x500, 1400x900 and 1600x1000; the "Use as
%   %   % demo vehicle" buttons (the user's preference put back after)
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_browseLibrary
%   % * One Status column (D, E) instead of the two star columns; Reviewer
%   %   % right of Review; Author; the Status key line (Sean, 11:20)

%% Set up the workspace
close all;
% (the repo's demo vehicle, now the 2009 Honda Fit; a few checks below use
% facts of the Fit, and say so if the repo's choice changes)
demoID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);
fitMessage = sprintf(['This check uses facts of the 2009 Honda Fit (a Honda, listed before the 2014 Honda CR-V and ' ...
    'the Prius by make; "fit" in its name), but the repo''s demo vehicle is now %s: update the check'], demoID);

%% Basic case: every finished vehicle, with its pictures and details
[selectedNames, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false);
assert(isempty(selectedNames), 'Nothing is selected at the start');
vehicles = browser.Vehicles;
assert(numel(vehicles) > 10);
assert(all(~cellfun(@isempty, {vehicles.Picture3D})) && all(~cellfun(@isempty, {vehicles.Picture2D})), ...
    'Every finished vehicle has its two pictures');
assert(any([vehicles.IsExemplar]), 'Some vehicles are exemplars');
assert(isequal(sort(browser.Order()), sort({vehicles.ID})));
assert(strcmp(browser.Figure.Name(1:numel('fcn_CarMesh3D_browseLibrary')), 'fcn_CarMesh3D_browseLibrary'), ...
    'The window''s title is its function''s name');

%% Sorting: by length, longest first
browser.SetGroup('none');
browser.SetSort('length', true);
order = browser.Order();
lengths = arrayfun(@(id) vehicles(strcmp({vehicles.ID}, id{1})).Length, order);
assert(all(diff(lengths) <= 1e-9), 'Sorted by length, longest first');

%% Grouping: by class, then by year within each class
browser.SetGroup('class');
browser.SetSort('year', false);
order = browser.Order();
classes = arrayfun(@(id) string(vehicles(strcmp({vehicles.ID}, id{1})).ClassName), order);
assert(issorted(lower(classes)), 'Grouped by class');

%% Exemplars first
browser.SetGroup('exemplar');
order = browser.Order();
flagExemplar = arrayfun(@(id) vehicles(strcmp({vehicles.ID}, id{1})).IsExemplar, order);
assert(all(flagExemplar(1:sum(flagExemplar))), 'Exemplars come first');

%% Descending orders only the vehicles within each group (rule B7)
browser.SetSort('year', true);
order = browser.Order();
flagExemplar = arrayfun(@(id) vehicles(strcmp({vehicles.ID}, id{1})).IsExemplar, order);
assert(all(flagExemplar(1:sum(flagExemplar))), 'Descending: exemplars still come first');
browser.SetGroup('class');
order = browser.Order();
classes = arrayfun(@(id) string(vehicles(strcmp({vehicles.ID}, id{1})).ClassName), order);
assert(issorted(lower(classes)), 'Descending: the classes are still A to Z');
years = arrayfun(@(id) vehicles(strcmp({vehicles.ID}, id{1})).Year, order);
for thisClass = unique(classes)
    yearsInClass = years(classes == thisClass);
    assert(all(diff(yearsInClass(~isnan(yearsInClass))) <= 0), 'Descending: years newest first within each class');
end
browser.SetSort('year', false);

%% Filtering: filters stack on what is shown; one matching nothing is not applied
assert(browser.ApplyFilter('2014'));
order = browser.Order();
assert(~isempty(order) && all(contains(string(order), '2014')));
assert(browser.ApplyFilter('honda'));
order = browser.Order();
assert(~isempty(order) && all(contains(lower(string(order)), 'honda') & contains(string(order), '2014')), ...
    'The 2014 Hondas');
numShown = numel(order);
assert(~browser.ApplyFilter('toyota'), 'No 2014 Honda is a Toyota: not applied');
assert(numel(browser.Order()) == numShown && numel(browser.Filters()) == 2, 'The list is not emptied');
assert(~browser.ApplyFilter('   '), 'An empty filter is not applied');
browser.ClearFilters();
assert(numel(browser.Order()) == numel(vehicles));
% (Enter in the filter box applies the filter, rule B9; then Apply filter
% with the box emptied does nothing and warns nothing)
filterBox = findall(browser.Figure, 'Type', 'uieditfield');
filterBox.Value = 'honda';
filterBox.ValueChangedFcn(filterBox, []);
assert(isequal(browser.Filters(), {'honda'}) && isempty(filterBox.Value), 'Enter applied the filter');
applyButton = findall(browser.Figure, 'Type', 'uibutton', 'Text', 'Apply filter');
lastOutput = evalc('applyButton.ButtonPushedFcn(applyButton, [])');
assert(isempty(lastOutput) && isequal(browser.Filters(), {'honda'}), 'The button right after Enter does nothing');
browser.ClearFilters();
% (every control has a tooltip, rule 14)
controls = [findall(browser.Figure, 'Type', 'uibutton'); findall(browser.Figure, 'Type', 'uicheckbox'); ...
    findall(browser.Figure, 'Type', 'uidropdown'); findall(browser.Figure, 'Type', 'uieditfield')];
flagNoTip = arrayfun(@(c) isempty(c.Tooltip), controls);
if any(flagNoTip)
    error('Every control should have a tooltip; missing on %d control(s), the first: %s "%s"', ...
        sum(flagNoTip), class(controls(find(flagNoTip,1))), fcn_INTERNAL_controlText(controls(find(flagNoTip,1))));
end
assert(~isempty(findall(browser.Figure, 'Type', 'uibutton', 'Text', 'Clear selection')), '"Clear" is now "Clear selection"');
% (the controls' callbacks work: they once named controls not yet made)
groupControl = findall(browser.Figure, 'Type', 'uidropdown');
for ith_control = 1:numel(groupControl)
    groupControl(ith_control).ValueChangedFcn(groupControl(ith_control), []);
end
% (The Order? drop-down, worded for the sort: Sean's C2S 6, 21:22. And
% Sean's T2, 21:17: changing the order must keep the sort chosen)
browser.SetGroup('exemplar');
sortControl = findall(browser.Figure, 'Type', 'uidropdown', 'Tooltip', 'The order of the vehicles under each heading');
orderControl = findall(browser.Figure, 'Type', 'uidropdown', 'Tooltip', ...
    'The order of the vehicles under each heading (the headings keep their own order)');
assert(isscalar(sortControl) && isscalar(orderControl));
assert(~ismember('name', sortControl.ItemsData), 'Name is no longer a sort choice (Sean, 21:54)');
sortControl.Value = 'make';
sortControl.ValueChangedFcn(sortControl, []);
assert(isequal(orderControl.Items, {'A to Z','Z to A'}) && strcmp(browser.SortOrder(), 'A to Z'), 'Make opens A to Z');
sortControl.Value = 'year';
sortControl.ValueChangedFcn(sortControl, []);
assert(isequal(orderControl.Items, {'Newest first','Oldest first'}) && strcmp(browser.SortOrder(), 'Newest first'), ...
    'Year opens newest first');
order = browser.Order();
flagExemplar = arrayfun(@(id) vehicles(strcmp({vehicles.ID}, id{1})).IsExemplar, order);
years = arrayfun(@(id) vehicles(strcmp({vehicles.ID}, id{1})).Year, order);
for flagGroup = [true false]
    yearsInGroup = years(flagExemplar == flagGroup);
    assert(all(diff(yearsInGroup(~isnan(yearsInGroup))) <= 0), 'Newest first in each group');
end
orderControl.Value = orderControl.ItemsData(2);
orderControl.ValueChangedFcn(orderControl, []);
assert(strcmp(sortControl.Value, 'year') && strcmp(browser.SortOrder(), 'Oldest first'), 'Changing the order keeps the sort by year');
years = arrayfun(@(id) vehicles(strcmp({vehicles.ID}, id{1})).Year, browser.Order());
yearsInGroup = years(flagExemplar(1) == arrayfun(@(id) vehicles(strcmp({vehicles.ID}, id{1})).IsExemplar, browser.Order()));
assert(all(diff(yearsInGroup(~isnan(yearsInGroup))) >= 0), 'Oldest first');
sortControl.Value = 'length';
sortControl.ValueChangedFcn(sortControl, []);
assert(strcmp(browser.SortOrder(), 'Longest first'), 'A new sort opens at its own default');
browser.SetSort('make', false);
browser.SetGroup('class');

%% Selecting: names returned in the order shown
browser.SetGroup('none');
browser.SetSort('make', false);
assert(strcmp(demoID, '2009_Honda_Fit_Sport'), fitMessage);
browser.Select({'2013_Toyota_Prius_Four', demoID});
assert(isequal(browser.Selected(), {demoID, '2013_Toyota_Prius_Four'}));
browser.SetSort('make', true);
assert(isequal(browser.Selected(), {'2013_Toyota_Prius_Four', demoID}));
% (selected but hidden by the filter: last)
browser.ApplyFilter('prius');
assert(isequal(browser.Selected(), {'2013_Toyota_Prius_Four', demoID}));
browser.ClearFilters();
browser.ApplyFilter('fit');
assert(isequal(browser.Selected(), {demoID, '2013_Toyota_Prius_Four'}));
browser.ClearFilters();
browser.Deselect({'2013_Toyota_Prius_Four'});
assert(isequal(browser.Result(), {demoID}));
browser.Close();
assert(~isvalid(browser.Figure));

%% Nothing selected: a fresh copy of the default test vehicle
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, Selected={demoID});
browser.Deselect({demoID});
copyButton = findall(browser.Figure, 'Type', 'uibutton', 'Text', 'Copy names');
assert(strcmp(copyButton.Enable, 'off'), 'Copy names is grayed out while nothing is selected');
result = browser.Result();
assert(isequal(browser.Result(), result), 'The demo copy is made once, not at each call');
browser.Close();
assert(iscell(result) && isscalar(result) && isfolder(result{1}));
assert(contains(result{1}, fullfile(tempdir, 'CarMesh3D_demo')), 'The default is a copy in the temporary folder');
copyFiles = fcn_CarMesh3D_findVehicleFiles(result{1});
assert(strcmp(copyFiles.ID, fcn_CarMesh3D_demoVehicle(FigNum=-1)) && copyFiles.HasMesh, ...
    'The default is a copy of the demo vehicle (the user''s own choice, if any)');

%% Options given at the start: the order, in words or the older Descending
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, SortBy='length', Order='Shortest first', GroupBy='none');
assert(strcmp(browser.SortOrder(), 'Shortest first'));
lengths = arrayfun(@(id) vehicles(strcmp({vehicles.ID}, id{1})).Length, browser.Order());
assert(all(diff(lengths) >= -1e-9), 'Shortest first');
browser.Close();
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, SortBy='name', Descending=true);
assert(strcmp(browser.SortOrder(), 'Z to A'), 'Old calls: Descending=true still works, and SortBy=''name'' sorts by make');
browser.Close();
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, SortBy='year');
assert(strcmp(browser.SortOrder(), 'Newest first'), 'With no order given, the sort''s own default');
browser.Close();

[selectedNames, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, SortBy='score', Descending=true, ...
    GroupBy='make', Selected={demoID});
assert(isequal(selectedNames, {demoID}));
browser.Close();

%% Only the vehicles given: every operation works on them alone
assert(strcmp(demoID, '2009_Honda_Fit_Sport'), fitMessage);
someIDs = {'2013_Toyota_Prius_Four', demoID, '2014_Honda_CRV_EXL'};
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, Vehicles=someIDs, GroupBy='none', SortBy='name');
assert(isequal(sort(browser.Order()), sort(someIDs)));
assert(isequal(browser.Order(), {demoID, '2014_Honda_CRV_EXL', '2013_Toyota_Prius_Four'}), ...
    'By make (the old SortBy=''name''), ties by name');
assert(browser.ApplyFilter('honda') && numel(browser.Order()) == 2);
assert(~browser.ApplyFilter('camry'), 'No Camry among those given');
browser.ClearFilters();
labels = findall(browser.Figure, 'Type', 'uilabel');
labelTexts = cellfun(@(t) strjoin(cellstr(t), ' '), {labels.Text}, 'UniformOutput', false);
assert(any(contains(labelTexts, 'the 3 vehicles given')));
browser.Close();
% (names not in the library: a warning, and left out)
lastwarn('');
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, Vehicles={demoID, '1900_No_Such_Car'});
[~, warningID] = lastwarn();
assert(strcmp(warningID, 'CarMesh3D:notInLibrary'));
assert(isequal(browser.Order(), {demoID}));
browser.Close();

%% A vehicle's next step: the browser returns it and opens no tool (the tree rule; C2S 13 (A))
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, Vehicles={demoID});
figuresBefore = numel(findall(groot, 'Type', 'figure'));
[viewStep, folderUsed] = browser.Open(demoID, 'view');
assert(strcmp(viewStep.Tool, 'view') && strcmp(folderUsed, browser.Vehicles(1).Folder) && strcmp(viewStep.Folder, folderUsed));
[editStep, folderUsed] = browser.Open(demoID, 'edit');
assert(contains(folderUsed, fullfile(tempdir, 'CarMesh3D_demo')), 'Hidden: the editor step uses a demo copy');
[reviewStep, folderUsed] = browser.Open(demoID, 'review', true);
assert(strcmp(reviewStep.Tool, 'review') && contains(folderUsed, fullfile(tempdir, 'CarMesh3D_demo')));
assert(isequal(browser.NextStep(), reviewStep));
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore, 'The browser opened a tool''s window');
% (the trunk opens the step: fcn_CarMesh3D_openTool, tested in its own script)
buttons = findall(browser.Figure, 'Type', 'uibutton');
assert(all(ismember({'View','Edit labels','Review'}, {buttons.Text})));
try
    browser.Open('1900_No_Such_Car', 'view');
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:notInList'), ME.message);
end
browser.Close();

%% The table and the preview (Sean, Q23 (A) and C2S 9 to 12 (A), 23:06)
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, GroupBy='class', SortBy='make');
vehicleTable = browser.Table;
assert(isa(vehicleTable, 'matlab.ui.control.Table'), 'The vehicles are in a table');
assert(isempty(findall(browser.Figure, 'Type', 'uiimage')) || numel(findall(browser.Figure, 'Type', 'uiimage')) == 2, ...
    'Only the preview''s two pictures');
assert(isequal(vehicleTable.ColumnName(1:5)', {'Select', 'Status', 'Vehicle', 'Year', 'Make'}) && ...
    ~ismember('Class', vehicleTable.ColumnName), 'The columns (no Class column when grouped by class)');
% (one Status column, D and E; Reviewer right of Review; Author; Sean 2026-11-24 11:20)
columnNow = vehicleTable.ColumnName(:)';
assert(~ismember('Demo', columnNow) && ~ismember(char(9733), columnNow), 'No separate star columns');
reviewColumn = find(strcmp(columnNow, 'Review'));
assert(isscalar(reviewColumn) && strcmp(columnNow{reviewColumn+1}, 'Reviewer') && ismember('Author', columnNow), ...
    'Reviewer is right of Review, and there is an Author column');
statusKey = findall(browser.Figure, 'Tag', 'statusKey');
assert(isscalar(statusKey) && contains(statusKey.Text, 'demo vehicle') && contains(statusKey.Text, 'exemplar'), 'The Status key line');
statusCells = vehicleTable.Data(~cellfun(@isempty, vehicleTable.Data(:, 1)), strcmp(columnNow, 'Status'));
demoMark = '<b><font color="#cc0000">D</font></b>';
assert(all(ismember(statusCells, {'', 'E', demoMark, [demoMark ', E']})), 'Status is blank, E, D (red, bold) or D, E');
assert(sum(contains(statusCells, demoMark)) == 1, 'One D: the demo vehicle');
authorCells = vehicleTable.Data(~cellfun(@isempty, vehicleTable.Data(:, 1)), strcmp(columnNow, 'Author'));
assert(any(~cellfun(@isempty, authorCells)), 'The authors are listed');
% (the preview starts at the first vehicle shown, and keeps its vehicle
% through a re-sort while it is still shown)
order = browser.Order();
assert(strcmp(browser.Previewed(), order{1}), 'The preview starts at the first vehicle shown');
browser.SetGroup('make');
assert(ismember('Class', vehicleTable.ColumnName), 'A Class column when not grouped by class');
assert(strcmp(browser.Previewed(), order{1}), 'The preview keeps its vehicle through a re-sort');
order = browser.Order();
% (clicking a row: its vehicle in the preview; a group row: no change)
flagGroupRow = cellfun(@isempty, vehicleTable.Data(:, 1));
vehicleRows = find(~flagGroupRow);
vehicleTable.Selection = vehicleRows(3);
vehicleTable.SelectionChangedFcn(vehicleTable, []);
assert(strcmp(browser.Previewed(), order{3}), 'A row clicked is previewed');
vehicleTable.Selection = find(flagGroupRow, 1);
vehicleTable.SelectionChangedFcn(vehicleTable, []);
assert(strcmp(browser.Previewed(), order{3}), 'A group row clicked changes nothing');
previewName = findall(browser.Figure, 'Type', 'uilabel', 'FontSize', 20);
previewedVehicle = vehicles(strcmp({vehicles.ID}, order{3}));
assert(contains(previewName.Text, previewedVehicle.Name), 'The preview shows the vehicle''s name');
pictures = findall(browser.Figure, 'Type', 'uiimage');
assert(any(strcmp(cellfun(@char, {pictures.ImageSource}, 'UniformOutput', false), previewedVehicle.Picture3D)), ...
    'The preview shows the vehicle''s 3D picture');
% (ticking Select in the table, in the preview, and by the hooks: all agree)
event = struct('Indices', [vehicleRows(3) 1], 'NewData', true);
vehicleTable.CellEditCallback(vehicleTable, event);
previewSelect = findall(browser.Figure, 'Type', 'uicheckbox', 'Text', 'Select');
assert(isequal(browser.Selected(), order(3)) && previewSelect.Value, 'Ticked in the table: selected, and ticked in the preview');
previewSelect.Value = false;
previewSelect.ValueChangedFcn(previewSelect, []);
assert(isempty(browser.Selected()) && isequal(vehicleTable.Data{vehicleRows(3), 1}, false), ...
    'Unticked in the preview: unselected, and unticked in the table');
browser.Select(order(1));
assert(isequal(vehicleTable.Data{vehicleRows(1), 1}, true), 'Select() ticks the table');
groupRow = find(flagGroupRow, 1);
vehicleTable.Data{groupRow, 1} = true;
vehicleTable.CellEditCallback(vehicleTable, struct('Indices', [groupRow 1], 'NewData', true));
assert(isempty(vehicleTable.Data{groupRow, 1}) && isequal(browser.Selected(), order(1)), 'A group row cannot be ticked');
% (Preview(name), and a name not in the list)
browser.Preview(order{5});
assert(strcmp(browser.Previewed(), order{5}) && isequal(vehicleTable.Selection, vehicleRows(5)), 'Preview(name)');
try
    browser.Preview('1900_No_Such_Car');
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:notInList'), ME.message);
end
% (a filter that hides the previewed vehicle moves the preview to the first shown)
browser.ApplyFilter(vehicles(strcmp({vehicles.ID}, order{1})).Make);
shownNow = browser.Order();
assert(any(strcmp(browser.Previewed(), shownNow)), 'The preview is of a vehicle shown');
browser.ClearFilters();
% (the preview's View button asks for the vehicle in the preview now, not
% the one previewed when the window was built; it closes the browser and
% returns the step, and opens no viewer itself: the tree rule, C2S 13 (A))
viewButton = findall(browser.Figure, 'Type', 'uibutton', 'Text', 'View');
browser.Preview(order{2});
viewersBefore = numel(findall(groot, 'Type', 'figure', '-regexp', 'Name', 'viewLabels'));
viewButton.ButtonPushedFcn(viewButton, []);
pickedStep = browser.NextStep();
assert(strcmp(pickedStep.Tool, 'view') && strcmp(pickedStep.VehicleID, order{2}), 'View asks for the vehicle in the preview');
assert(~isvalid(browser.Figure), 'View closes the browser');
assert(numel(findall(groot, 'Type', 'figure', '-regexp', 'Name', 'viewLabels')) == viewersBefore, 'The browser opened no viewer');

%% A data folder given is named in the subtitle (rule B10)
dataFolder = fullfile(fileparts(fileparts(which('fcn_CarMesh3D_browseVehicles'))), 'Data');   % (the library's own Data folder)
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, Vehicles={demoID}, DataFolder=dataFolder);
labels = findall(browser.Figure, 'Type', 'uilabel');
labelTexts = cellfun(@(t) strjoin(cellstr(t), ' '), {labels.Text}, 'UniformOutput', false);
assert(any(contains(labelTexts, 'Data folder:')), 'The data folder is named in the subtitle');
browser.Close();

%% No timers left running
assert(isempty(timerfindall), 'No timers are left running');

%% Every arrangement: each Group by x Sort x Order? (Sean, 21:36: too
% many to check by hand). For each: the groups keep their own order, the
% vehicles within each group follow the order chosen, and the headers in
% the list are the groups, in the same order, each above its vehicles
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false);
vehicles = browser.Vehicles;
vehicleTable = browser.Table;
groupKeyList = {'class','make','year','review','exemplar','license','none'};
sortKeyList = {'make','year','class','length','score','review','built','reviewDate'};
numChecked = 0;
for ith_group = 1:numel(groupKeyList)
    browser.SetGroup(groupKeyList{ith_group});
    for ith_sort = 1:numel(sortKeyList)
        for flagDescending = [false true]
            browser.SetSort(sortKeyList{ith_sort}, flagDescending);
            what = sprintf('Group by %s, sort by %s, %s', groupKeyList{ith_group}, sortKeyList{ith_sort}, browser.SortOrder());
            order = browser.Order();
            index = cellfun(@(id) find(strcmp({vehicles.ID}, id), 1), order);
            [groupNames, groupRank] = fcn_INTERNAL_groupOf(vehicles(index), groupKeyList{ith_group});
            % (the groups in their own order, each in one block)
            assert(issorted(groupRank), '%s: the groups are out of order', what);
            % (within each group, the order chosen; ties and missing values aside)
            values = fcn_INTERNAL_sortValues(vehicles(index), sortKeyList{ith_sort});
            if any(strcmp(sortKeyList{ith_sort}, {'make','class'}))
                % (a text sort: ties by make in the same order, so make
                % breaks ties in the value checked)
                [~, ~, makeRank] = unique(lower(string({vehicles(index).Make})));
                values = values * 1000 + makeRank(:)';
            end
            for thisRank = unique(groupRank)
                v = values(groupRank == thisRank);
                v = v(~isnan(v));
                if flagDescending
                    assert(all(diff(v) <= 0), '%s: not descending within group %s', what, groupNames(find(groupRank == thisRank, 1)));
                else
                    assert(all(diff(v) >= 0), '%s: not ascending within group %s', what, groupNames(find(groupRank == thisRank, 1)));
                end
            end
            % (the table as filled: the vehicles in the order shown, and,
            % when grouped, one group row before each group's vehicles,
            % named for it)
            tableData = vehicleTable.Data;
            flagGroupRow = cellfun(@isempty, tableData(:, 1));
            assert(isequal(tableData(~flagGroupRow, 3)', {vehicles(index).Name}), '%s: the table rows are not in the order shown', what);
            if strcmp(groupKeyList{ith_group}, 'none')
                assert(~any(flagGroupRow), '%s: group rows with no groups', what);
            else
                groupRowNames = string(regexprep(tableData(flagGroupRow, 3), '\s+\(\d+\)$', ''));
                assert(isequal(groupRowNames(:), upper(unique(groupNames, 'stable'))), '%s: the group rows do not match the groups', what);
                % (each group row is followed by its group's first vehicle)
                groupRowIndex = find(flagGroupRow);
                vehicleRowIndex = cumsum(~flagGroupRow);
                for ith_header = 1:numel(groupRowIndex)
                    firstOfGroup = find(upper(groupNames) == groupRowNames(ith_header), 1);
                    assert(vehicleRowIndex(groupRowIndex(ith_header) + 1) == firstOfGroup, ...
                        '%s: a group row is not just above its group', what);
                end
            end
            numChecked = numChecked + 1;
        end
    end
end
assert(numChecked == 112);
% (Sean's screenshot, 22:05: sort by Class within Class groups, Z to A:
% the coupes by make, Z to A; and A to Z, the reverse)
browser.SetGroup('class');
browser.SetSort('class', true);
coupes = browser.Order();
coupes = coupes(arrayfun(@(id) strcmp(vehicles(strcmp({vehicles.ID}, id{1})).ClassName, 'Coupe'), coupes));
assert(isequal(coupes, {'2012_Honda_Civic_Si', '2006_Ford_Mustang_GT', '2026_CarMesh3D_Generic_Coupe'}), ...
    'Coupes, Z to A: Honda, Ford, CarMesh3D (got %s)', strjoin(coupes, ', '));
browser.SetSort('class', false);
coupesAtoZ = browser.Order();
coupesAtoZ = coupesAtoZ(arrayfun(@(id) strcmp(vehicles(strcmp({vehicles.ID}, id{1})).ClassName, 'Coupe'), coupesAtoZ));
assert(isequal(coupesAtoZ, fliplr(coupes)), 'Coupes, A to Z: CarMesh3D, Ford, Honda');
browser.Close();

%% Hooks and Tags: every control a user clicks or reads has a unique Tag (Q39)
fig_num = 30001;
fprintf(1, 'Figure %d: hooks and Tags\n', fig_num);
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false);
vehicles = browser.Vehicles;
browser.SetSize(1400, 900);
fcn_INTERNAL_waitForLayout(browser, [1400 900]);
controls = fcn_CarMesh3D_guiDriver(browser.Figure, 'controls');
neededTags = {'groupBy','sortBy','sortOrder','filterText','applyFilter','clearFilters','count','done', ...
    'selection','copyNames','selectAllShown','clearSelection','vehicleTable','previewName','previewID', ...
    'picture3D','picture2D','previewDetails','previewSelect','previewHint','view','editLabels','review', ...
    'useAsDemo','useRepoDemo'};
missingTags = setdiff(neededTags, controls.Tag);
assert(isempty(missingTags), 'Controls with no Tag: %s', strjoin(missingTags, ', '));
problems = browser.CheckLayout();
assert(~any(strcmp(problems.Severity, 'note')), 'A clickable control with no Tag: %s', strjoin(problems.Control(strcmp(problems.Severity, 'note')), '; '));
state = browser.State();
assert(isfield(state, 'Browser') && strcmp(state.Values.groupBy, 'class') && strcmp(state.Values.sortBy, 'class'));
assert(numel(state.Browser.TableRows) == size(browser.Table.Data, 1), 'State gives the vehicle on each table row');
assert(strcmp(state.Browser.Previewed, browser.Previewed()) && ...
    strcmp(state.Browser.TableRows{state.Browser.SelectedRow}, browser.Previewed()), 'The highlighted row is the previewed vehicle''s');
problem = fcn_INTERNAL_viewProblem(browser, vehicles);
assert(isempty(problem), 'At the start: %s', problem);
% (SelectRow and TickRow act as clicks do, through the table's own callbacks)
rowIDs = state.Browser.TableRows;
vehicleRows = find(~cellfun(@isempty, rowIDs));
browser.SelectRow(vehicleRows(4));
assert(strcmp(browser.Previewed(), rowIDs{vehicleRows(4)}), 'SelectRow previews the row''s vehicle');
browser.SelectRow(rowIDs{vehicleRows(2)});
assert(strcmp(browser.Previewed(), rowIDs{vehicleRows(2)}), 'SelectRow by vehicle ID');
browser.TickRow(vehicleRows(2), true);
assert(isequal(browser.Selected(), rowIDs(vehicleRows(2))), 'TickRow selects');
browser.TickRow(vehicleRows(2), false);
assert(isempty(browser.Selected()), 'TickRow unselects');
% (Copy names: the line shown goes to the clipboard, and run as MATLAB it
% gives the names selected, in the order shown. Sean, 2026-11-24 09:10:
% "Feel free to overwrite my clipboard"; it is put back afterwards anyway)
clipboardBefore = clipboard('paste');
cleanupClipboard = onCleanup(@() clipboard('copy', clipboardBefore));
browser.TickRow(vehicleRows(1), true);
browser.TickRow(vehicleRows(3), true);
state = browser.Press('copyNames');
copiedText = clipboard('paste');
assert(strcmp(copiedText, state.Values.selection), 'Copy names puts the line shown on the clipboard');
copiedNames = fcn_INTERNAL_runCopiedLine(copiedText);
assert(isequal(copiedNames(:), browser.Selected()'), 'The copied line, run as MATLAB, gives the names selected, in the order shown');
browser.TickRow(vehicleRows(1), false);
browser.TickRow(vehicleRows(3), false);
clear cleanupClipboard;   % (the clipboard put back)
try
    browser.SelectRow(numel(rowIDs) + 1);
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:badInput'), ME.message);
end
% (Bug found 2026-11-24: after a re-sort the highlight stayed on the old
% row NUMBER, now another vehicle's row, while the preview kept its vehicle)
browser.SelectRow(vehicleRows(3));
browser.SetState('groupBy', 'make');
browser.SetState('sortBy', 'length');
problem = fcn_INTERNAL_viewProblem(browser, vehicles);
assert(isempty(problem), 'After a re-sort: %s', problem);
% (Bug found 2026-11-24: clicking a group row moved the highlight off the
% previewed vehicle; now it goes back to the previewed vehicle's row)
state = browser.State();
browser.SelectRow(find(cellfun(@isempty, state.Browser.TableRows), 1));
problem = fcn_INTERNAL_viewProblem(browser, vehicles);
assert(isempty(problem), 'After a group row is clicked: %s', problem);
browser.Key('escape');   % (no keys are used: nothing happens, no error)
browser.Close();

%% Every combination of Group by x Sort x Order? x Filter, set through the controls
% The controls are set as a user would (fcn_CarMesh3D_guiDriver 'set',
% which runs their callbacks); after each, every rule of the view is
% checked: the table shows exactly the vehicles the filters allow, the
% groups in their own order, each with its header row just above it, the
% vehicles within each group in the order chosen; the preview is a shown
% vehicle and its row is the one highlighted; ticks, buttons and texts agree
fig_num = 30002;
fprintf(1, 'Figure %d: every Group x Sort x Order x Filter\n', fig_num);
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false);
vehicles = browser.Vehicles;
browser.Select({demoID, '2013_Toyota_Prius_Four'});
filterSets = {{}, {'2014'}, {'honda'}, {'coupe'}, {'2014', 'honda'}};
groupKeyList = {'class','make','year','review','exemplar','license','none'};
sortKeyList = {'make','year','class','length','score','review','built','reviewDate'};
numChecked = 0;
for ith_filterSet = 1:numel(filterSets)
    browser.Press('clearFilters');
    for ith_term = 1:numel(filterSets{ith_filterSet})
        browser.SetState('filterText', filterSets{ith_filterSet}{ith_term});   % (typed, then Enter)
    end
    assert(isequal(browser.Filters(), filterSets{ith_filterSet}), 'The filters typed are applied');
    for ith_group = 1:numel(groupKeyList)
        browser.SetState('groupBy', groupKeyList{ith_group});
        for ith_sort = 1:numel(sortKeyList)
            browser.SetState('sortBy', sortKeyList{ith_sort});
            for orderValue = [0 1]
                browser.SetState('sortOrder', orderValue);
                problem = fcn_INTERNAL_viewProblem(browser, vehicles);
                assert(isempty(problem), 'Filters {%s}, group by %s, sort by %s, %s: %s', ...
                    strjoin(filterSets{ith_filterSet}, ', '), groupKeyList{ith_group}, sortKeyList{ith_sort}, browser.SortOrder(), problem);
                numChecked = numChecked + 1;
            end
        end
    end
end
assert(numChecked == 560);
fprintf(1, '    %d combinations checked\n', numChecked);
browser.Close();

%% Random walks: long random sequences of clicks, every rule checked after each step
% (fcn_CarMesh3D_guiRandomWalk; a failing sequence is saved in tempdir to
% replay with Replay=)
fig_num = 30003;
fprintf(1, 'Figure %d: random walks\n', fig_num);
for seed = 1:3
    [~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false);
    vehicles = browser.Vehicles;
    figuresBefore = numel(findall(groot, 'Type', 'figure'));
    [actions, invariants] = fcn_INTERNAL_walkActions(browser, vehicles, figuresBefore);
    report = fcn_CarMesh3D_guiRandomWalk(actions, invariants, Steps=250, Seed=seed, Name='browseLibraryWalk', FigNum=-1);
    if ~report.Passed
        error('Random walk, seed %d: step %d (%s) failed, %s: %s. Replay: load(''%s'')', seed, report.Failures(1).Step, ...
            report.Failures(1).Action, report.Failures(1).Kind, report.Failures(1).Message, report.FailureFile);
    end
    fprintf(1, '    seed %d: %d steps passed\n', seed, numel(report.Steps));
    browser.Close();
end

%% The action buttons: each returns its step, closes the window, opens no other window (the tree rule)
fig_num = 30004;
fprintf(1, 'Figure %d: the action buttons\n', fig_num);
someIDs = {'2013_Toyota_Prius_Four', demoID, '2014_Honda_CRV_EXL'};
buttonTags = {'view', 'editLabels', 'review'};
toolNames = {'view', 'edit', 'review'};
for ith_button = 1:numel(buttonTags)
    [~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, Vehicles=someIDs);
    figuresBefore = numel(findall(groot, 'Type', 'figure'));
    browser.SelectRow('2014_Honda_CRV_EXL');
    browser.Press(buttonTags{ith_button});
    step = browser.NextStep();
    assert(strcmp(step.Tool, toolNames{ith_button}) && strcmp(step.VehicleID, '2014_Honda_CRV_EXL'), ...
        '%s: the step asks for the vehicle in the preview', buttonTags{ith_button});
    if strcmp(toolNames{ith_button}, 'view')
        assert(strcmp(step.Folder, browser.Vehicles(strcmp({browser.Vehicles.ID}, '2014_Honda_CRV_EXL')).Folder));
    else
        assert(contains(step.Folder, fullfile(tempdir, 'CarMesh3D_demo')), '%s: hidden, a demo copy is used', buttonTags{ith_button});
    end
    assert(~isvalid(browser.Figure), '%s closes the browser', buttonTags{ith_button});
    assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore - 1, '%s opened another window (the tree rule)', buttonTags{ith_button});
end
% (Done: closes, returns the selection, opens nothing; quickly)
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, Vehicles=someIDs);
figuresBefore = numel(findall(groot, 'Type', 'figure'));
browser.TickRow(demoID, true);
closeTimer = tic;
browser.Press('done');
closeTime = toc(closeTimer);
assert(~isvalid(browser.Figure) && isequal(browser.Result(), {demoID}), 'Done closes and returns the selection');
step = browser.NextStep();
assert(isempty(step.Tool), 'Done asks for no tool');
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore - 1, 'Done opened another window');
assert(closeTime < 1, 'Done took %.2f s to close the window', closeTime);
% (closing with the window's X, through its CloseRequestFcn)
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, Vehicles=someIDs, Selected={'2014_Honda_CRV_EXL'});
closeTimer = tic;
close(browser.Figure);
closeTime = toc(closeTimer);
assert(~isvalid(browser.Figure) && isequal(browser.Result(), {'2014_Honda_CRV_EXL'}));
assert(closeTime < 1, 'Closing with the X took %.2f s', closeTime);
fprintf(1, '    closing took %.2f s\n', closeTime);

%% No vehicle at all: nothing to preview, and every vehicle button grayed out
fig_num = 30005;
fprintf(1, 'Figure %d: an empty list\n', fig_num);
warningState = warning('off', 'CarMesh3D:notInLibrary');
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false, Vehicles={'1900_No_Such_Car'});
warning(warningState);
state = browser.State();
assert(isempty(browser.Order()) && isempty(state.Browser.Previewed) && isempty(state.Browser.SelectedRow));
assert(~state.Enabled.view && ~state.Enabled.editLabels && ~state.Enabled.review && ~state.Enabled.previewSelect && ...
    ~state.Enabled.useAsDemo, 'With nothing previewed, the vehicle buttons are grayed out');
problem = fcn_INTERNAL_viewProblem(browser, browser.Vehicles);
assert(isempty(problem), 'Empty list: %s', problem);
browser.Close();

%% Layout at several window sizes: no control off its box, overlapping, or cut off rows; the table stays usable
% (a hidden window is laid out once it is resized: SetSize)
fig_num = 30006;
fprintf(1, 'Figure %d: layout at several sizes\n', fig_num);
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false);
windowSizes = [1400 900; 800 500; 640 400; 1600 1000; 1024 700];
for ith_size = 1:size(windowSizes, 1)
    browser.SetSize(windowSizes(ith_size, 1), windowSizes(ith_size, 2));
    fcn_INTERNAL_waitForLayout(browser, windowSizes(ith_size, :));
    if ~isempty(fcn_INTERNAL_layoutProblem(browser, windowSizes(ith_size, :)))
        % (on a busy computer a hidden window can be laid out late: one more wait)
        pause(3);
        fcn_INTERNAL_waitForLayout(browser, windowSizes(ith_size, :));
    end
    problems = browser.CheckLayout();
    flagError = strcmp(problems.Severity, 'error') | strcmp(problems.Severity, 'note');
    if any(flagError)
        disp(problems(flagError, :));
    end
    assert(~any(flagError), 'Layout at %dx%d: %d problem(s), the first: %s: %s', windowSizes(ith_size, 1), windowSizes(ith_size, 2), ...
        sum(flagError), problems.Control{find(flagError, 1)}, problems.Problem{find(flagError, 1)});
    % (usable: the table at least about half the width and 150 px tall;
    % the preview at least 240 px wide; the top row's boxes all inside the window)
    tablePosition = getpixelposition(browser.Table, true);
    previewPosition = getpixelposition(findall(browser.Figure, 'Tag', 'previewPanel'), true);
    assert(tablePosition(3) >= 0.45*windowSizes(ith_size, 1) && tablePosition(4) >= 150, ...
        'Layout at %dx%d: the table is only %.0f x %.0f px', windowSizes(ith_size, 1), windowSizes(ith_size, 2), tablePosition(3), tablePosition(4));
    assert(previewPosition(3) >= 230, 'Layout at %dx%d: the preview is only %.0f px wide', windowSizes(ith_size, 1), windowSizes(ith_size, 2), previewPosition(3));
    for thisTag = {'groupBy', 'sortBy', 'sortOrder', 'filterText', 'applyFilter', 'clearFilters', 'done'}
        controlPosition = getpixelposition(findall(browser.Figure, 'Tag', thisTag{1}), true);
        assert(controlPosition(3) >= 40 && controlPosition(1) + controlPosition(3) <= windowSizes(ith_size, 1) + 1, ...
            'Layout at %dx%d: %s is squeezed or off the window (%s)', windowSizes(ith_size, 1), windowSizes(ith_size, 2), thisTag{1}, mat2str(round(controlPosition)));
    end
    problem = fcn_INTERNAL_viewProblem(browser, browser.Vehicles);
    assert(isempty(problem), 'At %dx%d: %s', windowSizes(ith_size, 1), windowSizes(ith_size, 2), problem);
end
browser.Close();

%% The demo vehicle: a star in its row; "Use as demo vehicle"; back to the repo's (Q35/Q36 A)
% (in a local function, so its onCleanup puts the user's own demo vehicle
% preference back even if a check fails)
fig_num = 30007;
fprintf(1, 'Figure %d: the demo vehicle\n', fig_num);
fcn_INTERNAL_testDemoVehicle();

%% No timers left running (after the new tests too)
assert(isempty(timerfindall), 'No timers are left running');

%% Errors
try
    fcn_CarMesh3D_browseLibrary(SortBy='color', FlagVisible=false);
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:badInput'), ME.message);
end
try
    fcn_CarMesh3D_browseLibrary(SortBy='year', Order='A to Z', FlagVisible=false);
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:badInput') && contains(ME.message, 'Newest first'), ME.message);
end

fprintf(1, 'All tests of fcn_CarMesh3D_browseLibrary passed.\n');

%% Functions follow
function text = fcn_INTERNAL_controlText(control)
% A control's text, for messages
text = '';
if isprop(control, 'Text')
    text = char(strjoin(string(control.Text), ' '));
end
end % Ends fcn_INTERNAL_controlText

function [names, rank] = fcn_INTERNAL_groupOf(vehicles, groupKey)
% Each vehicle's group name, and the rank of its group in the groups' own
% order (the test's own copy of the rule, B7)
names = strings(numel(vehicles), 1);
keys = strings(numel(vehicles), 1);
for k = 1:numel(vehicles)
    v = vehicles(k);
    switch groupKey
        case 'class',    names(k) = v.ClassName;  keys(k) = lower(v.ClassName);
        case 'make',     names(k) = v.Make;       keys(k) = lower(v.Make);
        case 'year',     names(k) = string(v.Year); keys(k) = sprintf('%04d', v.Year);
        case 'review'
            names(k) = v.ReviewStatus;
            keys(k) = string(find(strcmp(v.ReviewStatus, {'reviewed','partly reviewed','not reviewed'})));
        case 'exemplar', names(k) = string(~v.IsExemplar); keys(k) = string(double(~v.IsExemplar));
        case 'license',  names(k) = v.License;    keys(k) = lower(v.License);
        otherwise,       names(k) = "";           keys(k) = "";
    end
end
[~, ~, rank] = unique(keys);
rank = rank(:)';
% (the names as the headers show them, for the header check)
if any(strcmp(groupKey, {'review','exemplar'}))
    names = fcn_INTERNAL_headerNames(vehicles, groupKey);
end
end % Ends fcn_INTERNAL_groupOf

function names = fcn_INTERNAL_headerNames(vehicles, groupKey)
% The header words for the review and exemplar groups
names = strings(numel(vehicles), 1);
for k = 1:numel(vehicles)
    v = vehicles(k);
    if strcmp(groupKey, 'exemplar')
        if v.IsExemplar, names(k) = string(char(9733)) + " Exemplars of their class"; else, names(k) = "Other vehicles"; end
    else
        names(k) = upper(extractBefore(string(v.ReviewStatus), 2)) + extractAfter(string(v.ReviewStatus), 1);
    end
end
end % Ends fcn_INTERNAL_headerNames

function values = fcn_INTERNAL_sortValues(vehicles, sortKey)
% The values a sort orders by, as numbers (text by its rank A to Z)
switch sortKey
    case 'make',   [~, ~, values] = unique(lower(string({vehicles.Make})));
    case 'class',  [~, ~, values] = unique(lower(string({vehicles.ClassName})));
    case 'year',   values = [vehicles.Year];
    case 'length', values = [vehicles.Length];
    case 'score',  values = [vehicles.Score];
    case 'review', values = [vehicles.ReviewPercent];
    case 'built',  values = datenum([vehicles.Built]); %#ok<DATNM>
    case 'reviewDate', values = datenum([vehicles.ReviewDate]); %#ok<DATNM>
end
values = double(values(:)');
end % Ends fcn_INTERNAL_sortValues

function message = fcn_INTERNAL_viewProblem(browser, vehicles)
% Every rule the browser's view must keep, whatever was done before it:
% '' when all hold, else what is wrong. The rules are the test's own
% copies (the filter rule, the order rule), not the browser's code
message = '';
if ~isvalid(browser.Figure)
    message = 'the window has closed';
    return;
end
state = browser.State();
values = state.Values;
enabled = state.Enabled;
info = state.Browser;
groupKey = values.groupBy;
sortKey = values.sortBy;
flagDescending = logical(values.sortOrder);
allIDs = {vehicles.ID};

% (1) the table shows exactly the vehicles every filter allows
flagAllowed = true(1, numel(vehicles));
for ith_filter = 1:numel(info.Filters)
    words = lower(split(string(strtrim(info.Filters{ith_filter}))))';
    words = words(strlength(words) > 0);
    for ith_vehicle = 1:numel(vehicles)
        v = vehicles(ith_vehicle);
        haystack = lower(strjoin(string({v.Name, v.ID, v.ClassName, v.ClassKey}), ' '));
        flagAllowed(ith_vehicle) = flagAllowed(ith_vehicle) && all(contains(haystack, words));
    end
end
rowIDs = info.TableRows(:)';
flagGroupRow = cellfun(@isempty, rowIDs);
shownIDs = rowIDs(~flagGroupRow);
if ~isequal(reshape(sort(shownIDs), 1, []), reshape(sort(allIDs(flagAllowed)), 1, []))
    message = sprintf('the table shows %d vehicles, but the filters {%s} allow %d', numel(shownIDs), ...
        strjoin(info.Filters, ', '), sum(flagAllowed));
    return;
end
if ~isequal(reshape(shownIDs, 1, []), reshape(browser.Order(), 1, []))   % (reshape: an empty list may be 0x0 or 1x0)
    message = 'the table''s rows are not in the order Order() gives';
    return;
end
tableData = browser.Table.Data;
if size(tableData, 1) ~= numel(rowIDs)
    message = 'the table has more or fewer rows than State gives';
    return;
end

% (2) the order: the groups in their own order, each with its header row
% just above it; within each group, the order chosen
if ~isempty(shownIDs)
    index = cellfun(@(id) find(strcmp(allIDs, id), 1), shownIDs);
    message = fcn_INTERNAL_orderProblem(vehicles(index), groupKey, sortKey, flagDescending, tableData);
    if ~isempty(message)
        return;
    end
end

% (3) the preview: a vehicle shown (none when none is shown), its row the
% one highlighted, its name and MATLAB name shown
if isempty(shownIDs)
    if ~isempty(info.Previewed) || ~isempty(info.SelectedRow)
        message = 'no vehicle is shown, but one is previewed or a row is highlighted';
        return;
    end
else
    if ~any(strcmp(shownIDs, info.Previewed))
        message = sprintf('the preview shows %s, which is not in the table', info.Previewed);
        return;
    end
    if isempty(info.SelectedRow) || ~strcmp(rowIDs{info.SelectedRow}, info.Previewed)
        message = sprintf('the highlighted row (%s) is not the previewed vehicle''s (%s)', mat2str(info.SelectedRow), info.Previewed);
        return;
    end
    previewed = vehicles(strcmp(allIDs, info.Previewed));
    if ~contains(values.previewName, previewed.Name) || ~strcmp(values.previewID, previewed.ID)
        message = sprintf('the preview''s name (%s) is not the previewed vehicle''s', values.previewName);
        return;
    end
end

% (4) the ticks: the table's, the preview's and Selected() agree
flagTicked = cellfun(@(x) isequal(x, true), tableData(~flagGroupRow, 1))';
if ~isequal(flagTicked, ismember(shownIDs, info.Selected))
    message = 'the table''s Select ticks do not match the selection';
    return;
end
if any(~cellfun(@isempty, tableData(flagGroupRow, 1)))
    message = 'a group row has a Select tick';
    return;
end
if ~isempty(info.Previewed) && values.previewSelect ~= ismember(info.Previewed, info.Selected)
    message = 'the preview''s Select does not match the selection';
    return;
end
selectedShown = shownIDs(ismember(shownIDs, info.Selected));
selectedFirst = info.Selected(1:numel(selectedShown));
if ~isequal(selectedFirst(:)', selectedShown(:)')
    message = sprintf('Selected() (%s) does not list the shown vehicles first, in the order shown (%s)', ...
        strjoin(info.Selected, ', '), strjoin(selectedShown, ', '));
    return;
end

% (5) the buttons: enabled exactly when they can do something
flagPreview = ~isempty(info.Previewed);
expected = struct('view', flagPreview, 'editLabels', flagPreview, 'review', flagPreview, 'previewSelect', flagPreview, ...
    'copyNames', ~isempty(info.Selected), 'useAsDemo', flagPreview && ~strcmp(info.Previewed, info.DemoVehicle), ...
    'useRepoDemo', strcmp(info.DemoSource, 'preference'));
for thisTag = fieldnames(expected)'
    if enabled.(thisTag{1}) ~= expected.(thisTag{1})
        message = sprintf('the %s button is %s, but should be %s', thisTag{1}, fcn_INTERNAL_onOffWord(enabled.(thisTag{1})), ...
            fcn_INTERNAL_onOffWord(expected.(thisTag{1})));
        return;
    end
end

% (6) the demo vehicle's D (in the Status column): on its row, and only there
statusColumn = find(strcmp(browser.Table.ColumnName, 'Status'), 1);
if isempty(statusColumn)
    message = 'the table has no Status column';
    return;
end
flagD = contains(tableData(:, statusColumn), '>D<')';
if ~isequal(flagD, strcmp(rowIDs, info.DemoVehicle) & ~flagGroupRow)
    message = sprintf('the D (demo) is not on the demo vehicle''s row (%s) alone', info.DemoVehicle);
    return;
end

% (7) the texts: the count, and the names returned
if ~startsWith(values.count, sprintf('%d of %d', numel(shownIDs), numel(vehicles)))
    message = sprintf('the count says "%s" but %d of %d are shown', values.count, numel(shownIDs), numel(vehicles));
    return;
end
if isempty(info.Selected)
    if ~contains(values.selection, '(none selected')
        message = 'nothing is selected, but the selection line lists names';
    end
elseif ~all(cellfun(@(id) contains(values.selection, ['''' id '''']), info.Selected))
    message = 'the selection line does not list every selected name';
end
end % Ends fcn_INTERNAL_viewProblem

function word = fcn_INTERNAL_onOffWord(flagValue)
if flagValue
    word = 'enabled';
else
    word = 'grayed out';
end
end % Ends fcn_INTERNAL_onOffWord

function message = fcn_INTERNAL_orderProblem(shownVehicles, groupKey, sortKey, flagDescending, tableData)
% The order rule (B7, B13), checked on the vehicles in the order shown:
% the groups in their own order, one block each, a header row named for
% the group just above it; within each group the sort's order (text sorts
% with ties by make in the same order). '' when it holds
message = '';
[groupNames, groupRank] = fcn_INTERNAL_groupOf(shownVehicles, groupKey);
if ~issorted(groupRank)
    message = 'the groups are out of order';
    return;
end
values = fcn_INTERNAL_sortValues(shownVehicles, sortKey);
if any(strcmp(sortKey, {'make','class'}))
    [~, ~, makeRank] = unique(lower(string({shownVehicles.Make})));
    values = values * 1000 + makeRank(:)';
end
for thisRank = unique(groupRank)
    v = values(groupRank == thisRank);
    v = v(~isnan(v));
    if flagDescending && any(diff(v) > 0)
        message = sprintf('not descending within group %s', groupNames(find(groupRank == thisRank, 1)));
        return;
    elseif ~flagDescending && any(diff(v) < 0)
        message = sprintf('not ascending within group %s', groupNames(find(groupRank == thisRank, 1)));
        return;
    end
end
flagGroupRow = cellfun(@isempty, tableData(:, 1));
if ~isequal(tableData(~flagGroupRow, 3)', {shownVehicles.Name})
    message = 'the table''s vehicle names are not in the order shown';
    return;
end
if strcmp(groupKey, 'none')
    if any(flagGroupRow)
        message = 'group rows with no groups';
    end
    return;
end
groupRowNames = string(regexprep(tableData(flagGroupRow, 3), '\s+\(\d+\)$', ''));
if ~isequal(groupRowNames(:), upper(unique(groupNames, 'stable')))
    message = 'the group rows do not match the groups';
    return;
end
groupRowIndex = find(flagGroupRow);
vehicleRowIndex = cumsum(~flagGroupRow);
for ith_header = 1:numel(groupRowIndex)
    firstOfGroup = find(upper(groupNames) == groupRowNames(ith_header), 1);
    if groupRowIndex(ith_header) + 1 > numel(flagGroupRow) || vehicleRowIndex(groupRowIndex(ith_header) + 1) ~= firstOfGroup
        message = sprintf('the group row %s is not just above its group', groupRowNames(ith_header));
        return;
    end
    counted = regexp(tableData{groupRowIndex(ith_header), 3}, '\((\d+)\)$', 'tokens', 'once');
    if isempty(counted) || str2double(counted{1}) ~= sum(upper(groupNames) == groupRowNames(ith_header))
        message = sprintf('the group row %s gives the wrong count', groupRowNames(ith_header));
        return;
    end
end
end % Ends fcn_INTERNAL_orderProblem

function [actions, invariants] = fcn_INTERNAL_walkActions(browser, vehicles, figuresBefore)
% The user actions a random walk picks from (each a click, through the
% hooks), and the rules checked after every step
groupKeys = {'class','make','year','review','exemplar','license','none'};
sortKeys = {'make','year','class','length','score','review','built','reviewDate'};
actions = struct('Name', {}, 'Do', {}, 'Allowed', {}, 'Weight', {});
for ith_key = 1:numel(groupKeys)
    actions(end+1) = struct('Name', ['group ' groupKeys{ith_key}], 'Do', @() browser.SetState('groupBy', groupKeys{ith_key}), ...
        'Allowed', [], 'Weight', 0.5); %#ok<AGROW>
end
for ith_key = 1:numel(sortKeys)
    actions(end+1) = struct('Name', ['sort ' sortKeys{ith_key}], 'Do', @() browser.SetState('sortBy', sortKeys{ith_key}), ...
        'Allowed', [], 'Weight', 0.5); %#ok<AGROW>
end
actions(end+1) = struct('Name', 'order flip', 'Do', @() fcn_INTERNAL_flipOrder(browser), 'Allowed', [], 'Weight', 2);
for thisTerm = {'honda', '2014', 'coupe', 'sedan', 'toyota prius', 'zzz'}
    actions(end+1) = struct('Name', ['type ' thisTerm{1}], 'Do', @() browser.SetState('filterText', thisTerm{1}), ...
        'Allowed', [], 'Weight', 0.7); %#ok<AGROW>
end
actions(end+1) = struct('Name', 'press Apply filter', 'Do', @() browser.Press('applyFilter'), 'Allowed', [], 'Weight', 0.5);
actions(end+1) = struct('Name', 'press Clear filters', 'Do', @() browser.Press('clearFilters'), 'Allowed', [], 'Weight', 2);
numRows = @() size(browser.Table.Data, 1);
for thisRow = [1 2 4 9 20]
    actions(end+1) = struct('Name', sprintf('click row %d', thisRow), 'Do', @() browser.SelectRow(thisRow), ...
        'Allowed', @() numRows() >= thisRow, 'Weight', 1); %#ok<AGROW>
    actions(end+1) = struct('Name', sprintf('tick row %d', thisRow), 'Do', @() browser.TickRow(thisRow, true), ...
        'Allowed', @() numRows() >= thisRow, 'Weight', 0.6); %#ok<AGROW>
    actions(end+1) = struct('Name', sprintf('untick row %d', thisRow), 'Do', @() browser.TickRow(thisRow, false), ...
        'Allowed', @() numRows() >= thisRow, 'Weight', 0.4); %#ok<AGROW>
end
actions(end+1) = struct('Name', 'click last row', 'Do', @() browser.SelectRow(numRows()), 'Allowed', @() numRows() >= 1, 'Weight', 1);
actions(end+1) = struct('Name', 'preview Select toggle', 'Do', @() fcn_INTERNAL_togglePreviewSelect(browser), ...
    'Allowed', @() fcn_INTERNAL_isEnabled(browser, 'previewSelect'), 'Weight', 1);
actions(end+1) = struct('Name', 'press Select all shown', 'Do', @() browser.Press('selectAllShown'), 'Allowed', [], 'Weight', 0.5);
actions(end+1) = struct('Name', 'press Clear selection', 'Do', @() browser.Press('clearSelection'), 'Allowed', [], 'Weight', 0.5);
actions(end+1) = struct('Name', 'key escape', 'Do', @() browser.Key('escape'), 'Allowed', [], 'Weight', 0.2);
actions(end+1) = struct('Name', 'resize 800x500', 'Do', @() browser.SetSize(800, 500), 'Allowed', [], 'Weight', 0.2);
actions(end+1) = struct('Name', 'resize 1400x900', 'Do', @() browser.SetSize(1400, 900), 'Allowed', [], 'Weight', 0.2);
invariants = struct('Name', {'view rules', 'tree rule'}, ...
    'Check', {@() fcn_INTERNAL_viewProblem(browser, vehicles), @() fcn_INTERNAL_treeRule(figuresBefore)});
end % Ends fcn_INTERNAL_walkActions

function fcn_INTERNAL_flipOrder(browser)
% The Order? drop-down changed to its other choice
state = browser.State();
browser.SetState('sortOrder', 1 - state.Values.sortOrder);
end % Ends fcn_INTERNAL_flipOrder

function fcn_INTERNAL_togglePreviewSelect(browser)
% The preview's Select box clicked
state = browser.State();
browser.SetState('previewSelect', ~state.Values.previewSelect);
end % Ends fcn_INTERNAL_togglePreviewSelect

function flagEnabled = fcn_INTERNAL_isEnabled(browser, tag)
state = browser.State();
flagEnabled = state.Enabled.(tag);
end % Ends fcn_INTERNAL_isEnabled

function message = fcn_INTERNAL_treeRule(figuresBefore)
% The browser opens no window of its own (the tree rule)
message = '';
figuresNow = numel(findall(groot, 'Type', 'figure'));
if figuresNow ~= figuresBefore
    message = sprintf('%d window(s) open, %d before: the browser opened or closed a window', figuresNow, figuresBefore);
end
end % Ends fcn_INTERNAL_treeRule

function fcn_INTERNAL_testDemoVehicle()
% The demo vehicle buttons. The user's own demo vehicle (the preference
% CarMesh3D/DemoVehicle) is put back as found when this function ends,
% even if a check fails (onCleanup)
flagHadPreference = ispref('CarMesh3D', 'DemoVehicle');
savedPreference = '';
if flagHadPreference
    savedPreference = getpref('CarMesh3D', 'DemoVehicle');
end
restorePreference = onCleanup(@() fcn_INTERNAL_restoreDemoPreference(flagHadPreference, savedPreference));
fcn_CarMesh3D_demoVehicle(FlagReset=true, FigNum=-1);   % (start from the repo's choice)
repoDemoID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);

% (a usable vehicle that is not the repo's demo, and one that cannot be the
% demo vehicle: the test's own copy of the rule, script + mesh + photos)
[~, browser] = fcn_CarMesh3D_browseLibrary(FlagVisible=false);
vehicles = browser.Vehicles;
usableID = '';
unusableID = '';
for ith_vehicle = 1:numel(vehicles)
    files = fcn_CarMesh3D_findVehicleFiles(vehicles(ith_vehicle).ID, FigNum=-1);
    photos = [dir(fullfile(files.Folder, 'photos', 'ViewInDegrees_*.jpg')); dir(fullfile(files.Folder, 'photos', 'ViewInDegrees_*.jpeg')); ...
        dir(fullfile(files.Folder, 'photos', 'ViewInDegrees_*.png'))];
    flagUsable = files.Found && files.HasScript && files.HasMesh && ~isempty(photos);
    if flagUsable && isempty(usableID) && ~strcmp(vehicles(ith_vehicle).ID, repoDemoID)
        usableID = vehicles(ith_vehicle).ID;
    elseif ~flagUsable && isempty(unusableID)
        unusableID = vehicles(ith_vehicle).ID;
    end
end
assert(~isempty(usableID), 'No vehicle other than the repo''s demo vehicle could be the demo vehicle');

% (at the start: the repo's demo vehicle has the star; Back is grayed out)
state = browser.State();
assert(strcmp(state.Browser.DemoVehicle, repoDemoID) && strcmp(state.Browser.DemoSource, 'repo'));
assert(~state.Enabled.useRepoDemo, 'Back to the repo''s demo is grayed out while the repo''s is used');
problem = fcn_INTERNAL_viewProblem(browser, vehicles);
assert(isempty(problem), 'Demo, at the start: %s', problem);
browser.SelectRow(repoDemoID);
state = browser.State();
assert(~state.Enabled.useAsDemo && contains(state.Values.previewHint, 'repo''s demo vehicle'), ...
    'The demo vehicle''s preview says so, and Use as demo vehicle is grayed out');

% (Use as demo vehicle: saved, the star moves, the hint says so)
browser.SelectRow(usableID);
browser.Press('useAsDemo');
assert(strcmp(getpref('CarMesh3D', 'DemoVehicle'), usableID), 'Use as demo vehicle saves the preference');
assert(strcmp(fcn_CarMesh3D_demoVehicle(FigNum=-1), usableID), 'The demos now use it');
state = browser.State();
assert(strcmp(state.Browser.DemoVehicle, usableID) && strcmp(state.Browser.DemoSource, 'preference'));
assert(contains(state.Values.previewHint, 'Your demo vehicle') && state.Enabled.useRepoDemo && ~state.Enabled.useAsDemo);
problem = fcn_INTERNAL_viewProblem(browser, vehicles);
assert(isempty(problem), 'Demo, after Use as demo vehicle: %s', problem);
assert(isvalid(browser.Figure), 'Use as demo vehicle keeps the window open');

% (a vehicle that cannot be the demo vehicle: refused, the reason in the
% hint line in red, nothing changed, no error)
if ~isempty(unusableID)
    browser.SelectRow(unusableID);
    browser.Press('useAsDemo');
    state = browser.State();
    assert(contains(state.Values.previewHint, 'cannot be the demo vehicle'), 'The refusal is shown: %s', state.Values.previewHint);
    hint = findall(browser.Figure, 'Tag', 'previewHint');
    assert(hint.FontColor(1) > 0.5 && hint.FontColor(2) < 0.2, 'The refusal is in red');
    assert(strcmp(getpref('CarMesh3D', 'DemoVehicle'), usableID) && strcmp(state.Browser.DemoVehicle, usableID), 'Nothing changed');
    problem = fcn_INTERNAL_viewProblem(browser, vehicles);
    assert(isempty(problem), 'Demo, after a refusal: %s', problem);
    % (the message belongs to that vehicle: another vehicle's preview has none)
    browser.SelectRow(usableID);
    state = browser.State();
    assert(~contains(state.Values.previewHint, 'cannot'), 'The refusal stays with its vehicle');
else
    fprintf(1, '    (every vehicle could be the demo vehicle: the refusal was not tried)\n');
end

% (Back to the repo's demo: the preference removed, the star back)
browser.Press('useRepoDemo');
assert(~ispref('CarMesh3D', 'DemoVehicle'), 'Back to the repo''s demo removes the preference');
state = browser.State();
assert(strcmp(state.Browser.DemoVehicle, repoDemoID) && strcmp(state.Browser.DemoSource, 'repo') && ~state.Enabled.useRepoDemo);
problem = fcn_INTERNAL_viewProblem(browser, vehicles);
assert(isempty(problem), 'Demo, after Back to the repo''s demo: %s', problem);
browser.Close();
end % Ends fcn_INTERNAL_testDemoVehicle

function fcn_INTERNAL_restoreDemoPreference(flagHadPreference, savedPreference)
% The user's own demo vehicle, put back as it was before the test
if flagHadPreference
    setpref('CarMesh3D', 'DemoVehicle', savedPreference);
elseif ispref('CarMesh3D', 'DemoVehicle')
    rmpref('CarMesh3D', 'DemoVehicle');
end
end % Ends fcn_INTERNAL_restoreDemoPreference

function fcn_INTERNAL_waitForLayout(browser, windowSize)
% A hidden window is laid out a little after it is resized (later still
% on a busy computer): wait, up to 15 s, until the window's top grid has
% the new size and the controls have stopped moving
outerGrid = findall(browser.Figure, 'Type', 'uigridlayout');
outerGrid = outerGrid(arrayfun(@(g) isa(g.Parent, 'matlab.ui.Figure'), outerGrid));
watched = [browser.Table; findall(browser.Figure, 'Tag', 'filterText'); findall(browser.Figure, 'Tag', 'clearFilters'); ...
    findall(browser.Figure, 'Tag', 'sortBy'); findall(browser.Figure, 'Tag', 'done')];
lastPositions = [];
numSteady = 0;
for ith_try = 1:150
    drawnow;
    pause(0.1);
    positions = cell2mat(arrayfun(@(c) getpixelposition(c, true), watched, 'UniformOutput', false));
    if isequal(round(outerGrid(1).Position(3:4)), windowSize) && isequal(positions, lastPositions)
        numSteady = numSteady + 1;
        if numSteady >= 10   % (unchanged for 1 s: the inner boxes are laid out after the outer ones)
            return;
        end
    else
        numSteady = 0;
    end
    lastPositions = positions;
end
warning('The window was not laid out at %dx%d within 15 s', windowSize(1), windowSize(2));
end % Ends fcn_INTERNAL_waitForLayout

function message = fcn_INTERNAL_layoutProblem(browser, windowSize)
% A quick look at whether the top row's controls fit the window ('' if so)
message = '';
for thisTag = {'groupBy', 'sortBy', 'sortOrder', 'filterText', 'applyFilter', 'clearFilters', 'done'}
    controlPosition = getpixelposition(findall(browser.Figure, 'Tag', thisTag{1}), true);
    if controlPosition(3) < 40 || controlPosition(1) + controlPosition(3) > windowSize(1) + 1
        message = thisTag{1};
    end
end
end % Ends fcn_INTERNAL_layoutProblem

function copiedNames = fcn_INTERNAL_runCopiedLine(copiedText)
% Runs the copied line, as a user pasting it would, in its own workspace
selectedNames = {}; %#ok<NASGU>
eval(copiedText);
copiedNames = selectedNames;
end % Ends fcn_INTERNAL_runCopiedLine
