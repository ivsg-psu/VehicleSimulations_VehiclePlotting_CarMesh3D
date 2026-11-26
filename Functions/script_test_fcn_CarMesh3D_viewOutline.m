% script_test_fcn_CarMesh3D_viewOutline.m
% Tests fcn_CarMesh3D_viewOutline

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewOutline
%   % * First write

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewOutline
%   % * (none yet)

%% Set up the workspace
close all;
vehicleID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);   % (the repo's demo vehicle)
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
loaded = load(vehicleFiles.OutlineFile, 'vehicleOutline');
fitOutline = loaded.vehicleOutline;
loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
fitMesh = loaded.vehicleMesh;

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _____                              ____   __    _____          _
% |  __ \                            / __ \ / _|  / ____|        | |
% | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
% | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
% | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
% |_____/ \___|_| |_| |_|\___|___/  \____/|_|    \_____\___/ \__,_|\___|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DEMO case: The Fit's 2D outline, from its ID, in its own window (hidden)
fprintf(1,'DEMO case: the Fit''s 2D outline, from its ID, in its own window (hidden)\n');
viewer = fcn_CarMesh3D_viewOutline(vehicleID, FlagVisible=false);
assert(isgraphics(viewer.Figure) && isgraphics(viewer.Axes));
keys = {viewer.Elements.Key};
assert(any(strcmp(keys, 'body')));
assert(any(startsWith(keys, 'wheel')));
assert(any(startsWith(keys, 'lights_')));
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

%% TEST case: The interior is an element (one for all its pieces)
fprintf(1,'TEST case: the interior is an element\n');
viewer = fcn_CarMesh3D_viewOutline(fitOutline, Mesh=fitMesh, FlagVisible=false);
interiorIndex = find(strcmp({viewer.Elements.Key}, 'interior'));
% (since the voxel interior labeling was switched off, Q37 2026-11-24, a vehicle may have
% no interior pieces until its seats and steering wheel are found; then there is no element)
if isfield(fitOutline, 'Interior') && ~isempty(fitOutline.Interior)
    assert(isscalar(interiorIndex));
    assert(numel(viewer.Elements(interiorIndex).Polygons) == numel(fitOutline.Interior));
else
    assert(isempty(interiorIndex), 'No interior element when the outline has no interior pieces');
    fprintf(1, '    (this vehicle''s outline has no interior pieces: none shown)\n');
end

%% TEST case: An element filled in orange, then none
fprintf(1,'TEST case: an element filled, then none\n');
viewer.ShowElement('body');
selected = findobj(viewer.Axes, 'Tag', 'selected');
assert(numel(selected) == 1);
viewer.ShowElement('interior');
assert(numel(findobj(viewer.Axes, 'Tag', 'selected')) == numel(fitOutline.Interior));
viewer.ShowElement('');
assert(isempty(findobj(viewer.Axes, 'Tag', 'selected')));

%% TEST case: The 3D model on and off
fprintf(1,'TEST case: the 3D model on and off\n');
viewer.SetModel3D(true);
assert(numel(findobj(viewer.Axes, 'Tag', 'model3D')) == 1);
assert(~isappdata(viewer.Axes, 'mouse2D'));
viewer.SetModel3D(false);
assert(isempty(findobj(viewer.Axes, 'Tag', 'model3D')));
assert(isappdata(viewer.Axes, 'mouse2D'));
[azimuth, elevation] = view(viewer.Axes);
assert(azimuth == 0 && elevation == 90);
viewer.Close();

%% TEST case: Inside a parent, with no outline
fprintf(1,'TEST case: inside a parent, and with no outline\n');
hostFigure = uifigure('Visible', 'off');
hostPanel = uipanel(hostFigure);
viewer = fcn_CarMesh3D_viewOutline(fitOutline, Mesh=fitMesh, Parent=hostPanel, OnHint=@(textIn) disp(''));
assert(isempty(viewer.Figure) && isgraphics(viewer.Axes));
delete(hostPanel.Children);
viewer = fcn_CarMesh3D_viewOutline([], Parent=hostPanel);
assert(isempty(viewer.Axes) && isempty(viewer.Elements));
viewer.ShowElement('body');   % (nothing to show: no error)
delete(hostFigure);

%% Fail conditions
if 1==0
    %% FAIL case: not an outline
    fcn_CarMesh3D_viewOutline(42);
end

fprintf(1,'All tests of fcn_CarMesh3D_viewOutline passed\n');
