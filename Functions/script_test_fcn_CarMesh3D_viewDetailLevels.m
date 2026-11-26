% script_test_fcn_CarMesh3D_viewDetailLevels.m
% Tests fcn_CarMesh3D_viewDetailLevels

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewDetailLevels
%   % * First write

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewDetailLevels
%   % * (none yet)

%% Set up the workspace
close all;
vehicleID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);   % (the repo's demo vehicle)
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
loaded = load(vehicleFiles.LevelsFile, 'detailLevels');
fitLevels = loaded.detailLevels;
loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
fitMesh = loaded.vehicleMesh;
Nlevels = numel(fitLevels.Levels);

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

%% DEMO case: The Fit's detail levels, from its ID, in its own window (hidden)
fprintf(1,'DEMO case: the Fit''s detail levels, from its ID, in its own window (hidden)\n');
viewer = fcn_CarMesh3D_viewDetailLevels(vehicleID, FlagVisible=false);
assert(isgraphics(viewer.Figure) && isgraphics(viewer.LineupAxes) && isgraphics(viewer.SceneAxes));
% (the line-up: the full mesh and each level; the scene: a pair per level)
assert(numel(viewer.Transforms) == (1 + Nlevels) + 2*Nlevels);
assert(viewer.IsTurning());
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

%% TEST case: The vehicles turn, and stop
fprintf(1,'TEST case: the vehicles turn, and stop\n');
viewer = fcn_CarMesh3D_viewDetailLevels(fitLevels, Mesh=fitMesh, FlagVisible=false);
matrixBefore = viewer.Transforms(1).Matrix;
pause(1);
assert(~isequal(viewer.Transforms(1).Matrix, matrixBefore));   % (turned)
viewer.Stop();
assert(~viewer.IsTurning());
matrixStopped = viewer.Transforms(1).Matrix;
pause(0.5);
assert(isequal(viewer.Transforms(1).Matrix, matrixStopped));   % (and stays put)
viewer.StartTurning();
assert(viewer.IsTurning());
viewer.Close();

%% TEST case: Reset views
fprintf(1,'TEST case: reset views\n');
viewer = fcn_CarMesh3D_viewDetailLevels(fitLevels, Mesh=fitMesh, FlagTurn=false, FlagVisible=false);
startPosition = viewer.SceneAxes.CameraPosition;
camdolly(viewer.SceneAxes, 0.3, 0.2, 0);
assert(~isequal(viewer.SceneAxes.CameraPosition, startPosition));
viewer.ResetViews();
assert(max(abs(viewer.SceneAxes.CameraPosition - startPosition)) < 1e-9);
viewer.Close();

%% TEST case: Inside a parent; stopped when the parent is cleared; no levels
fprintf(1,'TEST case: inside a parent, stopped when cleared, and with no levels\n');
hostFigure = uifigure('Visible', 'off');
hostPanel = uipanel(hostFigure);
viewer = fcn_CarMesh3D_viewDetailLevels(fitLevels, Mesh=fitMesh, Parent=hostPanel, OnHint=@(textIn) disp(''));
assert(isempty(viewer.Figure) && viewer.IsTurning());
delete(hostPanel.Children);
assert(~viewer.IsTurning());   % (its timer stopped with its views)
viewer = fcn_CarMesh3D_viewDetailLevels([], Parent=hostPanel);
assert(isempty(viewer.LineupAxes) && isempty(viewer.Transforms));
delete(hostFigure);

%% Fail conditions
if 1==0
    %% FAIL case: levels with no mesh
    fcn_CarMesh3D_viewDetailLevels(fitLevels);
end

fprintf(1,'All tests of fcn_CarMesh3D_viewDetailLevels passed\n');
