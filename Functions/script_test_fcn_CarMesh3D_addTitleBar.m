% script_test_fcn_CarMesh3D_addTitleBar.m
% Tests fcn_CarMesh3D_addTitleBar
%
% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addTitleBar
%   % * First write of the test script

%% Basic case: the function's name, and its file's last change
figureHandle = uifigure('Visible', 'off');
cleanupFigure = onCleanup(@() delete(figureHandle));
[contentPanel, titleBar] = fcn_CarMesh3D_addTitleBar(figureHandle, 'fcn_CarMesh3D_viewLabels', Subtitle='2009 Honda Fit Sport');
assert(isgraphics(contentPanel) && strcmp(contentPanel.Type, 'uipanel'));
assert(strcmp(titleBar.NameLabel.Text, 'fcn_CarMesh3D_viewLabels'));
fileInfo = dir(which('fcn_CarMesh3D_viewLabels'));
expected = char(datetime(fileInfo.datenum, 'ConvertFrom', 'datenum', 'Format', 'yyyy-MM-dd HH:mm'));
assert(strcmp(titleBar.Modified, expected));
assert(contains(titleBar.VersionLabel.Text, expected) && contains(titleBar.VersionLabel.Text, '2009 Honda Fit Sport'));

%% The subtitle can be changed
titleBar.SetSubtitle('2013 Toyota Prius Four');
assert(contains(titleBar.VersionLabel.Text, '2013 Toyota Prius Four') && ~contains(titleBar.VersionLabel.Text, 'Fit'));

%% A function that does not exist: no date
otherFigure = uifigure('Visible', 'off');
cleanupOther = onCleanup(@() delete(otherFigure));
[~, titleBar] = fcn_CarMesh3D_addTitleBar(otherFigure, 'fcn_CarMesh3D_noSuchFunction', FigNum=-1);
assert(contains(titleBar.Modified, 'not found'));

%% Every CarMesh3D window has the title bar, with its own function's name
[~, viewer] = fcn_CarMesh3D_viewLabels(fcn_CarMesh3D_findVehicleFiles('2009_Honda_Fit_Sport').MeshFile, Visible=false, Wait=false);
labels = findall(viewer.Figure, 'Type', 'uilabel');
assert(any(strcmp({labels.Text}, 'fcn_CarMesh3D_viewLabels')));
assert(startsWith(viewer.Figure.Name, 'fcn_CarMesh3D_viewLabels'));
viewer.Close();

%% Errors
try
    fcn_CarMesh3D_addTitleBar(42, 'fcn_CarMesh3D_viewLabels');
    error('should have failed');
catch ME
    assert(strcmp(ME.identifier, 'CarMesh3D:badInput'), ME.message);
end

fprintf(1, 'All tests of fcn_CarMesh3D_addTitleBar passed.\n');
