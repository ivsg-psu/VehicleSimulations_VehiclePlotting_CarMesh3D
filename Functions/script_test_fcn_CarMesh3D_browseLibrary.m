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

%% Set up the workspace
close all;

%% Basic case: every finished vehicle, with its pictures and details
[selectedNames, browser] = fcn_CarMesh3D_browseLibrary(Visible=false);
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
browser.Select({'2013_Toyota_Prius_Four', '2009_Honda_Fit_Sport'});
assert(isequal(browser.Selected(), {'2009_Honda_Fit_Sport', '2013_Toyota_Prius_Four'}));
browser.SetSort('make', true);
assert(isequal(browser.Selected(), {'2013_Toyota_Prius_Four', '2009_Honda_Fit_Sport'}));
% (selected but hidden by the filter: last)
browser.ApplyFilter('prius');
assert(isequal(browser.Selected(), {'2013_Toyota_Prius_Four', '2009_Honda_Fit_Sport'}));
browser.ClearFilters();
browser.ApplyFilter('fit');
assert(isequal(browser.Selected(), {'2009_Honda_Fit_Sport', '2013_Toyota_Prius_Four'}));
browser.ClearFilters();
browser.Deselect({'2013_Toyota_Prius_Four'});
assert(isequal(browser.Result(), {'2009_Honda_Fit_Sport'}));
browser.Close();
assert(~isvalid(browser.Figure));

%% Nothing selected: a fresh copy of the default test vehicle
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, Selected={'2009_Honda_Fit_Sport'});
browser.Deselect({'2009_Honda_Fit_Sport'});
copyButton = findall(browser.Figure, 'Type', 'uibutton', 'Text', 'Copy names');
assert(strcmp(copyButton.Enable, 'off'), 'Copy names is grayed out while nothing is selected');
result = browser.Result();
assert(isequal(browser.Result(), result), 'The demo copy is made once, not at each call');
browser.Close();
assert(iscell(result) && isscalar(result) && isfolder(result{1}));
assert(contains(result{1}, fullfile(tempdir, 'CarMesh3D_demo')), 'The default is a copy in the temporary folder');
copyFiles = fcn_CarMesh3D_findVehicleFiles(result{1});
assert(strcmp(copyFiles.ID, '2009_Honda_Fit_Sport') && copyFiles.HasMesh);

%% Options given at the start: the order, in words or the older Descending
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, SortBy='length', Order='Shortest first', GroupBy='none');
assert(strcmp(browser.SortOrder(), 'Shortest first'));
lengths = arrayfun(@(id) vehicles(strcmp({vehicles.ID}, id{1})).Length, browser.Order());
assert(all(diff(lengths) >= -1e-9), 'Shortest first');
browser.Close();
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, SortBy='name', Descending=true);
assert(strcmp(browser.SortOrder(), 'Z to A'), 'Old calls: Descending=true still works, and SortBy=''name'' sorts by make');
browser.Close();
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, SortBy='year');
assert(strcmp(browser.SortOrder(), 'Newest first'), 'With no order given, the sort''s own default');
browser.Close();

[selectedNames, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, SortBy='score', Descending=true, ...
    GroupBy='make', Selected={'2009_Honda_Fit_Sport'});
assert(isequal(selectedNames, {'2009_Honda_Fit_Sport'}));
browser.Close();

%% Only the vehicles given: every operation works on them alone
someIDs = {'2013_Toyota_Prius_Four', '2009_Honda_Fit_Sport', '2014_Honda_CRV_EXL'};
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, Vehicles=someIDs, GroupBy='none', SortBy='name');
assert(isequal(sort(browser.Order()), sort(someIDs)));
assert(isequal(browser.Order(), {'2009_Honda_Fit_Sport', '2014_Honda_CRV_EXL', '2013_Toyota_Prius_Four'}), ...
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
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, Vehicles={'2009_Honda_Fit_Sport', '1900_No_Such_Car'});
[~, warningID] = lastwarn();
assert(strcmp(warningID, 'CarMesh3D:notInLibrary'));
assert(isequal(browser.Order(), {'2009_Honda_Fit_Sport'}));
browser.Close();

%% Opening a vehicle from its row: the viewer; the editor and reviewer on a demo copy
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, Vehicles={'2009_Honda_Fit_Sport'});
[viewer, folderUsed] = browser.Open('2009_Honda_Fit_Sport', 'view');
assert(isgraphics(viewer.Figure) && strcmp(folderUsed, browser.Vehicles(1).Folder));
viewer.Close();
[painter, folderUsed] = browser.Open('2009_Honda_Fit_Sport', 'edit');
assert(contains(folderUsed, fullfile(tempdir, 'CarMesh3D_demo')), 'Hidden: the editor opens a demo copy');
assert(contains(painter.EditsFile, fullfile(tempdir, 'CarMesh3D_demo')));
painter.Close();
[reviewWindow, folderUsed] = browser.Open('2009_Honda_Fit_Sport', 'review', true);
assert(isgraphics(reviewWindow) && contains(folderUsed, fullfile(tempdir, 'CarMesh3D_demo')));
delete(reviewWindow);
buttons = findall(browser.Figure, 'Type', 'uibutton');
assert(all(ismember({'View','Edit labels','Review'}, {buttons.Text})));
try
    browser.Open('1900_No_Such_Car', 'view');
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:notInList'), ME.message);
end
browser.Close();

%% A data folder given is named in the subtitle (rule B10)
dataFolder = fullfile(fileparts(fileparts(which('fcn_CarMesh3D_browseVehicles'))), 'Data');   % (the library's own Data folder)
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, Vehicles={'2009_Honda_Fit_Sport'}, DataFolder=dataFolder);
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
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false);
vehicles = browser.Vehicles;
listGrid = findall(browser.Figure, 'Type', 'uigridlayout', 'Scrollable', 'on');
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
            % (the headers as laid out in the list: one per group, in order,
            % each in the row just above its group's first vehicle)
            if ~strcmp(groupKeyList{ith_group}, 'none')
                headers = findall(listGrid, 'Type', 'uilabel', 'FontSize', 16);
                headerRows = arrayfun(@(h) h.Layout.Row, headers);
                [headerRows, byRow] = sort(headerRows);
                headerNames = arrayfun(@(h) string(strtrim(regexprep(h.Text, '\s+\(\d+\)$', ''))), headers(byRow));
                assert(isequal(headerNames(:), unique(groupNames, 'stable')), '%s: the headers do not match the groups', what);
                rowsPanels = findall(listGrid, 'Type', 'uipanel', 'Visible', 'on');
                firstRows = zeros(numel(headerNames), 1);
                for ith_header = 1:numel(headerNames)
                    firstID = order{find(groupNames == headerNames(ith_header), 1)};
                    firstPanel = rowsPanels(arrayfun(@(pnl) ~isempty(findall(pnl, 'Type', 'uilabel', 'Text', firstID)), rowsPanels));
                    firstRows(ith_header) = firstPanel(1).Layout.Row;
                end
                assert(isequal(firstRows, headerRows(:) + 1), '%s: a header is not just above its group', what);
            end
            numChecked = numChecked + 1;
        end
    end
end
assert(numChecked == 112);
assert(strcmp(listGrid.Visible, 'on'), 'The list is shown again after it is arranged');
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

%% Errors
try
    fcn_CarMesh3D_browseLibrary(SortBy='color', Visible=false);
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:badInput'), ME.message);
end
try
    fcn_CarMesh3D_browseLibrary(SortBy='year', Order='A to Z', Visible=false);
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
