% script_test_fcn_CarMesh3D_browseLibrary.m
% Tests fcn_CarMesh3D_browseLibrary
%
% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_browseLibrary
%   % * First write of the test script

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
% (the controls' callbacks work: they once named controls not yet made)
groupControl = findall(browser.Figure, 'Type', 'uidropdown');
for ith_control = 1:numel(groupControl)
    groupControl(ith_control).ValueChangedFcn(groupControl(ith_control), []);
end
descendingControl = findall(browser.Figure, 'Type', 'uicheckbox', 'Text', 'Descending');
descendingControl.Value = true;
descendingControl.ValueChangedFcn(descendingControl, []);

%% Selecting: names returned in the order shown
browser.SetGroup('none');
browser.SetSort('name', false);
browser.Select({'2013_Toyota_Prius_Four', '2009_Honda_Fit_Sport'});
assert(isequal(browser.Selected(), {'2009_Honda_Fit_Sport', '2013_Toyota_Prius_Four'}));
browser.SetSort('name', true);
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
result = browser.Result();
browser.Close();
assert(iscell(result) && isscalar(result) && isfolder(result{1}));
assert(contains(result{1}, fullfile(tempdir, 'CarMesh3D_demo')), 'The default is a copy in the temporary folder');
copyFiles = fcn_CarMesh3D_findVehicleFiles(result{1});
assert(strcmp(copyFiles.ID, '2009_Honda_Fit_Sport') && copyFiles.HasMesh);

%% Options given at the start
[selectedNames, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, SortBy='score', Descending=true, ...
    GroupBy='make', Selected={'2009_Honda_Fit_Sport'});
assert(isequal(selectedNames, {'2009_Honda_Fit_Sport'}));
browser.Close();

%% Only the vehicles given: every operation works on them alone
someIDs = {'2013_Toyota_Prius_Four', '2009_Honda_Fit_Sport', '2014_Honda_CRV_EXL'};
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, Vehicles=someIDs, GroupBy='none', SortBy='name');
assert(isequal(sort(browser.Order()), sort(someIDs)));
assert(isequal(browser.Order(), {'2009_Honda_Fit_Sport', '2013_Toyota_Prius_Four', '2014_Honda_CRV_EXL'}));
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
browser.Close();

%% Errors
try
    fcn_CarMesh3D_browseLibrary(SortBy='color', Visible=false);
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:badInput'), ME.message);
end

fprintf(1, 'All tests of fcn_CarMesh3D_browseLibrary passed.\n');
