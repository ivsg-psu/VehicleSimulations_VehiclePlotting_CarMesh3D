% script_test_fcn_CarMesh3D_viewDimensions.m
% Tests fcn_CarMesh3D_viewDimensions

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewDimensions
%   % * First write

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewDimensions
%   % * (none yet)

%% Set up the workspace
close all;
vehicleID = fcn_CarMesh3D_demoVehicle(UsePreference=false, FigNum=-1);   % (the repo's demo vehicle)
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
fitMesh = loaded.vehicleMesh;
stage3 = load(fullfile(vehicleFiles.Folder, 'cache', 'stage3_checks.mat'), 'cacheOutputs');
validationTable = stage3.cacheOutputs.checkResults.ValidationTable;

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _____                              ____   __    _____          _
% |  __ \                            / __ \ / _|  / ____|        | |
% | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
% | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
% | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
% |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DEMO case: The Fit's dimensions, from its ID, in its own window (hidden)
fprintf(1,'DEMO case: the Fit''s dimensions, from its ID, in its own window (hidden)\n');
viewer = fcn_CarMesh3D_viewDimensions(vehicleID, Visible=false);
assert(isgraphics(viewer.Figure) && numel(viewer.Axes) == 3 && all(isgraphics(viewer.Axes)));
assert(numel(viewer.Quantities) == height(validationTable));
assert(isempty(viewer.Shown()));
viewer.Close();
assert(~isvalid(viewer.Figure));

%% Test cases start here. These are very simple, usually trivial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______ ______  _____ _______ _____
% |__   __|  ____|/ ____|__   __/ ____|
%    | |  | |__  | (___    | | | (___
%    | |  |  __|  \___ \   | |  \___ \
%    | |  | |____ ____) |  | |  ____) |
%    |_|  |______|_____/   |_| |_____/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=TESTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TEST case: Every dimension draws, in one view, with its title bold
fprintf(1,'TEST case: every dimension draws, in one view, with its title bold\n');
viewer = fcn_CarMesh3D_viewDimensions(fitMesh, DimensionTable=validationTable, Visible=false);
for ith_quantity = 1:numel(viewer.Quantities)
    viewer.ShowDimension(viewer.Quantities{ith_quantity});
    assert(strcmp(viewer.Shown(), viewer.Quantities{ith_quantity}));
    drawn = arrayfun(@(a) ~isempty(findobj(a, 'Tag', 'dimension')), viewer.Axes);
    assert(nnz(drawn) == 1, 'dimension %s drawn in %d views', viewer.Quantities{ith_quantity}, nnz(drawn));
    boldTitles = arrayfun(@(a) strcmp(a.Title.FontWeight, 'bold'), viewer.Axes);
    assert(isequal(boldTitles, drawn));
end
viewer.ShowDimension('');
assert(isempty(viewer.Shown()));
assert(all(arrayfun(@(a) isempty(findobj(a, 'Tag', 'dimension')), viewer.Axes)));

%% TEST case: Reset views
fprintf(1,'TEST case: reset views\n');
startPosition = viewer.Axes(1).CameraPosition;
camdolly(viewer.Axes(1), 0.2, 0.1, 0);
viewer.ResetViews();
assert(max(abs(viewer.Axes(1).CameraPosition - startPosition)) < 1e-9);
viewer.Close();

%% TEST case: Inside a parent; a table click goes to OnSelect
fprintf(1,'TEST case: inside a parent; a table click goes to OnSelect\n');
hostFigure = uifigure('Visible', 'off');
hostPanel = uipanel(hostFigure);
setappdata(0, 'testDimensionSelect', '');
viewer = fcn_CarMesh3D_viewDimensions(fitMesh, DimensionTable=validationTable, Parent=hostPanel, ...
    OnSelect=@(quantity) setappdata(0, 'testDimensionSelect', quantity), OnHint=@(textIn) disp(''));
assert(isempty(viewer.Figure));
viewer.Table.CellSelectionCallback(viewer.Table, struct('Indices', [2 1]));
assert(strcmp(getappdata(0, 'testDimensionSelect'), viewer.Quantities{2}));
assert(isempty(viewer.Shown()));   % (the parent decides: nothing drawn yet)
rmappdata(0, 'testDimensionSelect');
delete(hostFigure);

%% Fail conditions
if 1==0
    %% FAIL case: a mesh with no dimensions
    fcn_CarMesh3D_viewDimensions(fitMesh);
end

fprintf(1,'All tests of fcn_CarMesh3D_viewDimensions passed\n');
