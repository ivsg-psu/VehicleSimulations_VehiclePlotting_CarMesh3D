% script_test_fcn_CarMesh3D_viewLabels.m
% Tests fcn_CarMesh3D_viewLabels

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewLabels
%   % * First write
%   % * Tests the see-through body, the rendered glass, and the interior
%   %   % seen through clear glass

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewLabels
%   % * (none yet)

%% Set up the workspace
close all;
vehicleID = '2009_Honda_Fit_Sport';
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
meshFile = vehicleFiles.MeshFile;   % (the viewer is given the file to show)
flagPhotos = ~isempty(dir(fullfile(fileparts(meshFile), 'photos', 'ViewInDegrees_*')));

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

%% DEMO case: The Fit's mesh file, with its labels and photos (hidden, so it does not wait)
fprintf(1,'DEMO case: the Fit''s mesh file, labels and photos (hidden)\n');
[viewSettings, viewer] = fcn_CarMesh3D_viewLabels(meshFile, Outline=vehicleFiles.OutlineFile, Visible=false);
assert(isgraphics(viewer.Figure) && isgraphics(viewer.Axes));
assert(strcmp(viewSettings.MeshFile, meshFile));
assert(strcmp(viewSettings.Label, 'all') && strcmp(viewSettings.Colors, 'labels') && isempty(viewSettings.Hidden));
assert(all(isfield(viewSettings.Camera, {'CameraPosition','CameraTarget','CameraUpVector','CameraViewAngle','Projection'})));
if flagPhotos
    assert(~isnan(viewSettings.PhotoAngle));
end

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

%% TEST case: A view changed, closed, and opened again from its settings: the same view
fprintf(1,'TEST case: a view, closed and opened again: the same\n');
camorbit(viewer.Axes, 40, 15);
camzoom(viewer.Axes, 2.5);
camdolly(viewer.Axes, 0.1, 0.05, 0);
viewer.ShowLabel('part_trim');
viewer.SetHidden({'part_glass'});
viewer.SetColors('vehicle');
if flagPhotos
    viewer.SetPhotoAngle(180);
end
expected = viewer.GetView();
viewer.Close();
assert(~isvalid(viewer.Figure));
closedView = viewer.GetView();                       % (kept from when it closed)
assert(isequal(closedView, expected));
[reopened, viewer2] = fcn_CarMesh3D_viewLabels(meshFile, ViewSettings=closedView, Visible=false);
assert(strcmp(reopened.Label, 'part_trim') && isequal(reopened.Hidden, {'part_glass'}) && strcmp(reopened.Colors, 'vehicle'));
for name = {'CameraPosition', 'CameraTarget', 'CameraUpVector', 'CameraViewAngle', 'XLim', 'YLim', 'ZLim'}
    assert(max(abs(reopened.Camera.(name{1}) - expected.Camera.(name{1}))) < 1e-9, 'camera %s differs', name{1});
end
if flagPhotos
    assert(reopened.PhotoAngle == expected.PhotoAngle);
end
viewer2.Close();

%% TEST case: The view call, run, opens the same view
fprintf(1,'TEST case: the view call opens the same view\n');
callText = fcn_INTERNAL_callOf(expected);
assert(startsWith(callText, sprintf('fcn_CarMesh3D_viewLabels(''%s'', ViewSettings=struct(', meshFile)));
callText = strrep(callText, ');', ', Visible=false);');    % (hidden, for the test)
[fromCall, viewer3] = eval(strrep(callText, ';', ''));
for name = {'CameraPosition', 'CameraTarget', 'CameraUpVector', 'CameraViewAngle'}
    assert(max(abs(fromCall.Camera.(name{1}) - expected.Camera.(name{1}))) < 1e-6, 'camera %s differs', name{1});
end
assert(strcmp(fromCall.Label, expected.Label) && isequal(fromCall.Hidden, expected.Hidden));
viewer3.Close();

%% TEST case: Options win over the view settings given
fprintf(1,'TEST case: options win over the view settings\n');
[optionsView, viewer4] = fcn_CarMesh3D_viewLabels(meshFile, ViewSettings=expected, Label='all', Colors='labels', ...
    Hidden={}, Visible=false);
assert(strcmp(optionsView.Label, 'all') && strcmp(optionsView.Colors, 'labels'));
viewer4.Close();

%% TEST case: A mesh variable, inside a parent, with a host's colors, hidden faces and hints
fprintf(1,'TEST case: a mesh variable, inside a parent, with a host''s hooks\n');
loaded = load(meshFile, 'vehicleMesh');
hostFigure = uifigure('Visible', 'off', 'Position', [50 50 1400 850]);
hostGrid = uigridlayout(hostFigure, [1 2], 'ColumnWidth', {'1x', 230});
hostPanel = uipanel(hostGrid);
listPanel = uipanel(hostGrid);
numFaces = size(loaded.vehicleMesh.Faces,1);
setappdata(0, 'testViewerHint', '');
[meshView, viewer5] = fcn_CarMesh3D_viewLabels(loaded.vehicleMesh, Parent=hostPanel, LabelListParent=listPanel, ...
    ColorFilter=@(colors, alpha) deal([ones(1,3); colors(2:end,:)], alpha), ...      % (face 1 painted white)
    HiddenFaces=@(keys) [~isempty(keys); false(numFaces-1,1)], ...                    % (face 1 hidden when any label is)
    OnHint=@(textIn) setappdata(0, 'testViewerHint', textIn));                         % (in a parent: does not wait)
assert(isempty(meshView.MeshFile) && isnan(meshView.PhotoAngle));
assert(contains(viewer5.ViewCall(), 'fcn_CarMesh3D_viewLabels(vehicleMesh, ViewSettings='));
assert(~isempty(getappdata(0, 'testViewerHint')));
assert(isequal(viewer5.Patch.FaceVertexCData(1,:), [1 1 1]));                         % (the host's colors)
assert(~isempty(findobj(listPanel, 'Type', 'uiradiobutton')));                       % (the list, where the host put it)
viewer5.SetHidden({'part_glass'});
assert(viewer5.Patch.FaceVertexAlphaData(1) == 0 && isequal(viewer5.Hidden(), {'part_glass'}));
% (a new mesh with the same faces: face 2 relabeled as a tail light)
relabeled = loaded.vehicleMesh;
lightPart = find(strcmp(relabeled.PartNames, 'light'), 1);
tailType = find(strcmp(relabeled.LightTypeNames, 'tail'), 1);
relabeled.FacePartIndex(2) = lightPart;
relabeled.FaceLightType(2) = tailType;
viewer5.SetMesh(relabeled, viewer5.Patch.FaceVertexCData, ones(numFaces,1));
viewer5.ShowLabel('light_tail');
assert(strcmp(viewer5.Label(), 'light_tail'));
viewer5.Stop();
rmappdata(0, 'testViewerHint');
delete(hostFigure);

%% TEST case: See-through body, rendered glass, and the interior seen through clear glass
fprintf(1,'TEST case: see-through body, rendered glass, interior\n');
[~, viewer] = fcn_CarMesh3D_viewLabels(meshFile, Visible=false, Wait=false);
loaded = load(meshFile, 'vehicleMesh');
partNames = loaded.vehicleMesh.PartNames;
flagGlass = loaded.vehicleMesh.FacePartIndex == find(strcmp(partNames, 'glass'));
flagBody = loaded.vehicleMesh.FacePartIndex == find(strcmp(partNames, 'body'));
alphaData = viewer.Patch.FaceVertexAlphaData;
assert(max(abs(alphaData(flagGlass) - loaded.vehicleMesh.FaceAlpha(flagGlass))) < 1e-9, 'Glass as rendered');
viewer.SetSeeThrough(0.6);
alphaData = viewer.Patch.FaceVertexAlphaData;
assert(all(abs(alphaData(flagBody) - 0.4) < 1e-9), 'Body 60% see-through');
settings = viewer.GetView();
assert(abs(settings.SeeThrough - 0.6) < 1e-12);
assert(contains(viewer.ViewCall(), '''SeeThrough'',0.6'));
viewer.SetSeeThrough(0);
if any(strcmp(partNames, 'interior'))
    viewer.ShowLabel('part_interior');
    alphaData = viewer.Patch.FaceVertexAlphaData;
    assert(all(alphaData(flagGlass) < 0.2), 'Interior shown: the glass nearly clear');
end
viewer.Close();
[~, viewer] = fcn_CarMesh3D_viewLabels(meshFile, Visible=false, Wait=false, ViewSettings=struct('SeeThrough', 0.5));
assert(abs(viewer.SeeThrough() - 0.5) < 1e-12, 'See-through opened from view settings');
viewer.Close();

%% TEST case: Nighttime view: the night scene, lamps switched, boundaries; off again: the labels as before
fprintf(1,'TEST case: nighttime view\n');
[~, viewer] = fcn_CarMesh3D_viewLabels(meshFile, Visible=false, Wait=false);
colorsOff = viewer.Patch.FaceVertexCData;
numBefore = numel(viewer.Axes.Children);
cameraBefore = viewer.Axes.CameraPosition;
viewer.SetNightView(true);
assert(strcmp(viewer.Patch.Visible, 'off'), 'The label patch hidden at night');
assert(numel(viewer.Axes.Children) > numBefore, 'The night scene drawn');
assert(max(viewer.Axes.Color) < 0.1, 'A dark sky');
assert(max(abs(viewer.Axes.CameraPosition - cameraBefore)) < 1e-9, 'The camera kept');
% (lamps switched: the low beams off, then the high beams off)
viewer.SetNightLights(struct('LowBeam', false));
assert(~viewer.NightLights().LowBeam && viewer.NightLights().HighBeam, 'Each beam switched alone');
viewer.SetNightLights(struct('LowBeam', true, 'HighBeam', false, 'Tail', 'brake'));
assert(strcmp(viewer.NightLights().Tail, 'brake'));
% (mesh boundaries in the nighttime view)
patchesBefore = findobj(viewer.Axes, 'Type', 'patch', 'EdgeColor', 'none');
fcn_INTERNAL_tickBoundaries(viewer, true);
assert(numel(findobj(viewer.Axes, 'Type', 'patch', 'EdgeColor', 'none')) < numel(patchesBefore), 'Boundaries drawn at night');
fcn_INTERNAL_tickBoundaries(viewer, false);
settings = viewer.GetView();
assert(settings.NightView && settings.NightLights.LowBeam && ~settings.NightLights.HighBeam);
callText = viewer.ViewCall();
assert(contains(callText, '''NightView'',true') && contains(callText, '''HighBeam'',false'));
viewer.SetNightView(false);
assert(strcmp(viewer.Patch.Visible, 'on'));
assert(numel(viewer.Axes.Children) == numBefore, 'The night scene removed');
assert(isequal(viewer.Patch.FaceVertexCData, colorsOff), 'Night off again: as before');
viewer.Close();
[~, viewer] = fcn_CarMesh3D_viewLabels(meshFile, Visible=false, Wait=false, ...
    ViewSettings=struct('NightView', true, 'NightLights', struct('Backup', false)));
assert(viewer.NightView() && strcmp(viewer.Patch.Visible, 'off'), 'Nighttime view opened from view settings');
assert(~viewer.NightLights().Backup);
viewer.Close();

%% TEST case: A file that holds no mesh
fprintf(1,'TEST case: a file that holds no mesh\n');
emptyFile = [tempname '.mat'];
nothing = 1; %#ok<NASGU>
save(emptyFile, 'nothing');
try
    fcn_CarMesh3D_viewLabels(emptyFile, Visible=false);
    error('test:noError', 'A file with no mesh was not refused');
catch err
    assert(contains(err.message, 'holds no labeled CarMesh3D mesh'));
end
delete(emptyFile);

%% Fail conditions
if 1==0
    %% FAIL case: not a mesh file or a mesh
    fcn_CarMesh3D_viewLabels(42);

    %% FAIL case: a file that does not exist
    fcn_CarMesh3D_viewLabels('noSuchMesh.mat');

    %% FAIL case: colors not known
    fcn_CarMesh3D_viewLabels(meshFile, Colors='rainbow');
end

fprintf(1,'All tests of fcn_CarMesh3D_viewLabels passed\n');

%% Functions follow
function callText = fcn_INTERNAL_callOf(settings)
% The view call for these settings (as the viewer's "Copy view call" makes it)
[~, viewer] = fcn_CarMesh3D_viewLabels(settings.MeshFile, ViewSettings=settings, Visible=false);
callText = viewer.ViewCall();
viewer.Close();
end % Ends fcn_INTERNAL_callOf

function fcn_INTERNAL_tickBoundaries(viewer, flagOn)
% Ticks (or unticks) "Show mesh boundaries", as a person would
boundaryBox = findall(viewer.Figure, 'Type', 'uicheckbox', 'Text', 'Show mesh boundaries');
boundaryBox.Value = flagOn;
boundaryBox.ValueChangedFcn(boundaryBox, []);
end % Ends fcn_INTERNAL_tickBoundaries
