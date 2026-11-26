% script_test_fcn_CarMesh3D_viewOrientation.m
% Tests fcn_CarMesh3D_viewOrientation

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewOrientation
%   % * First write

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewOrientation
%   % * (none yet)

%% Set up the workspace
close all;
vehicleID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);   % (the repo's demo vehicle)
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
fitMesh = loaded.vehicleMesh;

%% DEMO case: The Fit, from its ID, in its own window (hidden)
fprintf(1,'DEMO case: the Fit, from its ID, in its own window (hidden)\n');
viewer = fcn_CarMesh3D_viewOrientation(vehicleID, FlagVisible=false);
assert(isgraphics(viewer.Figure) && isgraphics(viewer.Axes));
arrowNames = get(findobj(viewer.Axes, 'Type', 'text'), 'String');
assert(all(ismember({'FRONT (+X)', 'UP (+Z)', '+Y (left)'}, arrowNames)));
viewer.Close();
assert(~isvalid(viewer.Figure));

%% TEST case: Reset view
fprintf(1,'TEST case: reset view\n');
viewer = fcn_CarMesh3D_viewOrientation(fitMesh, FlagVisible=false);
startPosition = viewer.Axes.CameraPosition;
camorbit(viewer.Axes, 30, 10);
assert(~isequal(viewer.Axes.CameraPosition, startPosition));
viewer.ResetView();
assert(max(abs(viewer.Axes.CameraPosition - startPosition)) < 1e-9);
viewer.Close();

%% TEST case: Inside a parent, a mesh with no colors
fprintf(1,'TEST case: inside a parent, a mesh with no colors\n');
hostFigure = uifigure('Visible', 'off');
hostPanel = uipanel(hostFigure);
plainMesh = struct('Vertices', fitMesh.Vertices, 'Faces', fitMesh.Faces);
viewer = fcn_CarMesh3D_viewOrientation(plainMesh, Parent=hostPanel, OnHint=@(textIn) disp(''));
assert(isempty(viewer.Figure) && isgraphics(viewer.Axes));
delete(hostFigure);

%% Fail conditions
if 1==0
    %% FAIL case: not a mesh
    fcn_CarMesh3D_viewOrientation(42);
end

fprintf(1,'All tests of fcn_CarMesh3D_viewOrientation passed\n');
