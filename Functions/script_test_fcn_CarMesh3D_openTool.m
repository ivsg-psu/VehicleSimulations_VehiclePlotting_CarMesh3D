% script_test_fcn_CarMesh3D_openTool.m
% Tests fcn_CarMesh3D_openTool: the trunk opens the step asked for in the
% library browser (the tree rule).

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_openTool
%   % * First write

%% Set up the workspace
close all;
vehicleID = '2009_Honda_Fit_Sport';

%% DEMO case: the step from the browser, opened by the trunk (hidden here)
figNum = 10001;
fprintf(1,'Figure %.0f: DEMO case: the browser returns a step; openTool opens it\n', figNum);
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, Vehicles={vehicleID});
figuresBefore = numel(findall(groot, 'Type', 'figure'));
nextStep = browser.Open(vehicleID, 'view');
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore, 'The browser opened a window itself');
assert(strcmp(nextStep.Tool, 'view') && strcmp(nextStep.VehicleID, vehicleID));
assert(isequal(browser.NextStep(), nextStep));
browser.Close();
viewer = fcn_CarMesh3D_openTool(nextStep, Visible=false);
assert(isgraphics(viewer.Figure));
viewer.Close();

%% TEST case: the editor and the reviewer, on a demo copy
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: edit and review steps on a demo copy\n', figNum);
[~, browser] = fcn_CarMesh3D_browseLibrary(Visible=false, Vehicles={vehicleID});
editStep = browser.Open(vehicleID, 'edit');          % (hidden: a demo copy)
reviewStep = browser.Open(vehicleID, 'review', true);
browser.Close();
assert(contains(editStep.Folder, fullfile(tempdir, 'CarMesh3D_demo')), 'Hidden: the editor step uses a demo copy');
painter = fcn_CarMesh3D_openTool(editStep, Visible=false);
assert(contains(painter.EditsFile, fullfile(tempdir, 'CarMesh3D_demo')));
painter.Close();
reviewWindow = fcn_CarMesh3D_openTool(reviewStep, Visible=false);
assert(isgraphics(reviewWindow));
delete(reviewWindow);

%% TEST case: no step (no button pressed): nothing opens
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: no step\n', figNum);
emptyStep = struct('Tool', '', 'VehicleID', '', 'Folder', '');
figuresBefore = numel(findall(groot, 'Type', 'figure'));
assert(isempty(fcn_CarMesh3D_openTool(emptyStep)));
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore);

%% FAST mode cases
figNum = 80001;
fprintf(1,'Figure %.0f: FAST mode cases\n', figNum);
assert(isempty(fcn_CarMesh3D_openTool(emptyStep, FigNum=[])));
assert(isempty(fcn_CarMesh3D_openTool(emptyStep, FigNum=-1)));

%% BUG cases
% (none yet)

%% Fail conditions
if 1==0
    % An unknown tool
    fcn_CarMesh3D_openTool(struct('Tool', 'paint', 'VehicleID', vehicleID, 'Folder', ''));
end

timersLeft = timerfindall;
assert(isempty(timersLeft), 'A timer was left running');
