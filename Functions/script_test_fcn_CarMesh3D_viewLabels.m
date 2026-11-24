% script_test_fcn_CarMesh3D_viewLabels.m
% Tests fcn_CarMesh3D_viewLabels

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewLabels
%   % * First write
%   % * Tests the see-through body, the rendered glass, and the interior
%   %   % seen through clear glass

% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewLabels
%   % * Its own window in the painter's layout: the menu, one panel at a
%   %   % time, the panels driving the viewer, GUI settings, the ground
%   %   % plane by day and night (Q33 (A)); "Show mesh boundaries" set in
%   %   % Overall Display; GUI settings put back at the end

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
assert(strcmp(viewSettings.Label, 'all') && strcmp(viewSettings.Colors, 'labels'));
assert(isempty(viewSettings.Hidden) || isequal(cellstr(viewSettings.Hidden), {'hidden'}));   % (hidden faces start out of view)
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
if isfield(loaded.vehicleMesh, 'FaceHiddenSet')
    % (hidden faces are out of view: not drawn as rendered)
    flagGlass = flagGlass & loaded.vehicleMesh.FaceHiddenSet(:) == 0;
    flagBody = flagBody & loaded.vehicleMesh.FaceHiddenSet(:) == 0;
end
alphaData = viewer.Patch.FaceVertexAlphaData;
% (a lamp's clear cover is drawn as glass, at least 40% opaque, so it shows: Q29 (A), 2026_11_24)
expectedAlpha = loaded.vehicleMesh.FaceAlpha(:);
if isfield(loaded.vehicleMesh, 'FaceCoverLamp')
    flagCover = loaded.vehicleMesh.FaceCoverLamp(:) > 0;
    expectedAlpha(flagCover) = max(expectedAlpha(flagCover), 0.40);
end
assert(max(abs(alphaData(flagGlass) - expectedAlpha(flagGlass))) < 1e-9, 'Glass as rendered');
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
% (by day: the lamps start off; switched on, they are drawn lit on the model)
loaded = load(meshFile, 'vehicleMesh');
flagLamp = loaded.vehicleMesh.FaceLightType(:) > 0;
assert(~any(viewer.NightLights().LowBeam));
viewer.SetNightLights(struct('Tail', 'brake'));
flagTail = loaded.vehicleMesh.FaceLightType(:) == find(strcmp(loaded.vehicleMesh.LightTypeNames, 'tail'));
assert(all(max(abs(viewer.Patch.FaceVertexCData(flagTail,:) - [1.00 0.12 0.08]), [], 2) < 1e-9), 'Brake lights lit by day');
% (and the clear covers of lit lamps, which glow in the lamp's lit color by day too: 2026_11_24)
if isfield(loaded.vehicleMesh, 'FaceCoverLamp')
    flagLamp = flagLamp | loaded.vehicleMesh.FaceCoverLamp(:) > 0;
end
assert(isequal(viewer.Patch.FaceVertexCData(~flagLamp,:), colorsOff(~flagLamp,:)), 'Only the lamps change');
viewer.SetNightLights(struct('Tail', 'off'));
assert(isequal(viewer.Patch.FaceVertexCData, colorsOff), 'Lamps off: as before');
viewer.SetNightView(true);
assert(strcmp(viewer.Patch.Visible, 'off'), 'The label patch hidden at night');
assert(numel(viewer.Axes.Children) > numBefore, 'The night scene drawn');
assert(max(viewer.Axes.Color) < 0.1, 'A dark sky');
assert(max(abs(viewer.Axes.CameraPosition - cameraBefore)) < 1e-9, 'The camera kept');
% (lamps switched: the low beams off, then the high beams off)
viewer.SetNightLights(struct('LowBeam', false, 'HighBeam', true));
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
% (the Show boxes work at night: glass taken off, the scene drawn again)
childrenBefore = numel(findobj(viewer.Axes, 'Type', 'patch'));
viewer.SetHidden({'part_glass'});
assert(viewer.NightView() && numel(findobj(viewer.Axes, 'Type', 'patch')) > 0);
viewer.SetHidden({});
assert(numel(findobj(viewer.Axes, 'Type', 'patch')) == childrenBefore);
viewer.SetNightView(false);
assert(strcmp(viewer.Patch.Visible, 'on'));
assert(numel(viewer.Axes.Children) == numBefore, 'The night scene removed');
viewer.SetNightLights(struct('LowBeam', false, 'HighBeam', false, 'Running', false, 'TurnLeft', false, ...
    'TurnRight', false, 'Tail', 'off', 'Backup', false));
assert(isequal(viewer.Patch.FaceVertexCData, colorsOff), 'Night off, lamps off: as before');
viewer.Close();
[~, viewer] = fcn_CarMesh3D_viewLabels(meshFile, Visible=false, Wait=false, ...
    ViewSettings=struct('NightView', true, 'NightLights', struct('Backup', false)));
assert(viewer.NightView() && strcmp(viewer.Patch.Visible, 'off'), 'Nighttime view opened from view settings');
assert(~viewer.NightLights().Backup);
viewer.Close();

%% TEST case: Hidden faces start out of view; ticking "hidden" shows them
fprintf(1,'TEST case: hidden faces\n');
loaded = load(meshFile, 'vehicleMesh');
someFaces = (1:50)';
hiddenMesh = fcn_CarMesh3D_editLabels(loaded.vehicleMesh, Edits={struct('FaceIndices',someFaces,'Hide','test set')}, FigNum=-1);
[viewSettings, viewer] = fcn_CarMesh3D_viewLabels(hiddenMesh, Visible=false, Wait=false);
assert(any(strcmp(viewSettings.Hidden, 'hidden')));
alphaData = viewer.Patch.FaceVertexAlphaData;
assert(all(alphaData(someFaces) == 0), 'Hidden faces out of view');
viewer.SetHidden({});
alphaData = viewer.Patch.FaceVertexAlphaData;
assert(all(alphaData(someFaces) > 0), 'Shown when "hidden" is ticked');
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

%% TEST case: Its own window in the painter's layout: the menu, the panels, GUI settings, the ground (Q33 (A); Sean, 2026-11-24 02:41 and 02:43)
fprintf(1,'TEST case: its own window: menu, panels, GUI settings, ground\n');
% (the GUI settings it keeps, put back at the end, even if the test stops)
prefsBefore = struct();
for prefName = {'ShowGround', 'StartViewDial', 'StartViewDown'}
    if ispref('CarMesh3D', prefName{1})
        prefsBefore.(prefName{1}) = getpref('CarMesh3D', prefName{1});
    end
end
cleanupPrefs = onCleanup(@() fcn_INTERNAL_restorePrefs(prefsBefore));
[~, viewer] = fcn_CarMesh3D_viewLabels(meshFile, Visible=false, Wait=false);
% (the top bar: the menu and Exit; no old tool row or label list in sight)
assert(~isempty(findall(viewer.Figure, 'Type', 'uibutton', 'Tag', 'viewerMenu')), 'The Menu button');
assert(~isempty(findall(viewer.Figure, 'Type', 'uibutton', 'Text', 'Exit')), 'The Exit button');
assert(isempty(findall(viewer.Figure, 'Type', 'uibuttongroup', 'Title', 'Labels')), 'No old label list');
% (it opens at Overall Display; each panel opens alone; the open one picked again closes it)
assert(strcmp(viewer.Panel(), 'Overall Display'));
for panelName = {'Labels To Display', 'Lamps To Display', 'GUI settings', 'Overall Display'}
    viewer.OpenPanel(panelName{1});
    assert(strcmp(viewer.Panel(), panelName{1}));
    shownPanels = findall(viewer.Figure, 'Type', 'uipanel', 'Visible', 'on', '-regexp', 'Tag', '(Display|settings)$');
    assert(isscalar(shownPanels) && strcmp(shownPanels.Tag, panelName{1}), 'One panel at a time');
end
% (Overall Display drives the viewer: the colors)
colorsGroup = findall(viewer.Figure, 'Type', 'uibuttongroup', 'Tag', 'overallColors');
fcn_INTERNAL_pickRadio(colorsGroup, 'vehicle');
assert(strcmp(viewer.Colors(), 'vehicle'), 'Colors? Vehicle');
fcn_INTERNAL_pickRadio(colorsGroup, 'labels');
% (Labels To Display: Shown? No for glass hides it; the row follows the viewer)
shownGlass = findall(viewer.Figure, 'Type', 'uibuttongroup', 'Tag', 'shown_part_glass');
fcn_INTERNAL_pickRadio(shownGlass, false);
assert(any(strcmp(viewer.Hidden(), 'part_glass')), 'Shown? No hides the label');
fcn_INTERNAL_pickRadio(shownGlass, true);
assert(~any(strcmp(viewer.Hidden(), 'part_glass')));
% (one label shown alone shows as that label Colored? Yes, the rest No)
viewer.ShowLabel('part_body');
panels = viewer.Panels();
panels.MarkLabels();
coloredGlass = findall(viewer.Figure, 'Type', 'uibuttongroup', 'Tag', 'colored_part_glass');
assert(isequal(coloredGlass.SelectedObject.UserData, false), 'One label alone: the others Colored? No');
viewer.ShowLabel('all');
% (Lamps To Display: Left turn On, then Hazards Off: both turn signals off)
fcn_INTERNAL_pickRadio(findall(viewer.Figure, 'Type', 'uibuttongroup', 'Tag', 'lamp_TurnLeft'), true);
assert(viewer.NightLights().TurnLeft, 'Left turn signal on');
fcn_INTERNAL_pickRadio(findall(viewer.Figure, 'Type', 'uibuttongroup', 'Tag', 'lamp_Hazards'), false);
assert(~viewer.NightLights().TurnLeft && ~viewer.NightLights().TurnRight, 'Hazards Off: both off');
% (the ground: shown by day by default; Show ground? Off hides it, at night too)
viewer.SetGround(true);
dayGround = findall(viewer.Axes, 'Type', 'patch', 'Tag', 'dayGround');
assert(isscalar(dayGround) && strcmp(dayGround.Visible, 'on'), 'The ground by day');
fcn_INTERNAL_pickRadio(findall(viewer.Figure, 'Type', 'uibuttongroup', 'Tag', 'showGround'), false);
assert(~viewer.Ground() && strcmp(dayGround.Visible, 'off'), 'Show ground? Off');
groundRow = findall(viewer.Figure, 'Type', 'uibuttongroup', 'Tag', 'showGround');
assert(isscalar(groundRow), 'Show ground? is one row (in Overall Display; GUI settings has none now)');
assert(isequal(groundRow.SelectedObject.UserData, false), 'Show ground? row follows the viewer');
viewer.SetNightView(true);
patchesNoGround = numel(findobj(viewer.Axes, 'Type', 'patch'));
viewer.SetGround(true);
assert(numel(findobj(viewer.Axes, 'Type', 'patch')) == patchesNoGround + 1, 'The night ground follows the setting');
assert(strcmp(dayGround.Visible, 'off'), 'No day ground at night');
% (Sean's T6: the same ground by day and at night, squares of exactly 1 m on whole meters)
nightGround = findall(viewer.Axes, 'Type', 'patch', 'Tag', 'nightGround');
assert(isscalar(nightGround), 'The night ground, tagged');
assert(isequal(size(nightGround.Vertices), size(dayGround.Vertices)) && ...
    max(abs(nightGround.Vertices(:) - dayGround.Vertices(:))) < 1e-9, 'Day and night grounds: the same squares, the same extent');
squareX = dayGround.Vertices(dayGround.Faces(:,2),1) - dayGround.Vertices(dayGround.Faces(:,1),1);
assert(all(abs(squareX - 1) < 1e-9) && all(reshape(abs(dayGround.Vertices(:,1:2) - round(dayGround.Vertices(:,1:2))), [], 1) < 1e-9), ...
    'Ground squares exactly 1 m, on whole meters');
% (Sean's T3: Colors? and see-through grayed at night)
seeThrough = findall(viewer.Figure, 'Tag', 'overallSeeThrough');
assert(all(strcmp({colorsGroup.Children.Enable}, 'off')), 'Colors? grayed at night');
if ~isempty(seeThrough)
    assert(strcmp(seeThrough(1).Enable, 'off'), 'See-through grayed at night');
end
viewer.SetNightView(false);
assert(strcmp(dayGround.Visible, 'on'), 'The day ground back by day');
assert(all(strcmp({colorsGroup.Children.Enable}, 'on')), 'Colors? back by day');
% (Sean's T7: the camera's angles and distance in Overall Display)
camera = viewer.CameraInfo();
assert(all(isfield(camera, {'DialAngle','DownAngle','Distance'})) && camera.Distance > 0, 'CameraInfo');
cameraReadout = findall(viewer.Figure, 'Tag', 'cameraReadout');
panels.MarkCamera();
assert(isscalar(cameraReadout) && contains(cameraReadout.Text, sprintf('%.0f', camera.DialAngle)), 'Camera readout');
% (Sean's T8: the photo options in Overall Display, none under the photo)
assert(isscalar(findall(viewer.Figure, 'Type', 'uibuttongroup', 'Tag', 'turnWithPhoto')), 'Turn model with photo? once, in Overall Display');
assert(isscalar(findall(viewer.Figure, 'Type', 'uibuttongroup', 'Tag', 'photoSize')), 'Photo size? once, in Overall Display');
% (the starting view: GUI settings; Reset view goes there)
viewer.SetStartView(90, 30);
viewer.ResetView();
% (the camera's own angles, in meters: view() reads them in the plot box's
% units, which differ once the axes are framed on the vehicle)
camera = viewer.CameraInfo();
assert(abs(mod(camera.DialAngle - 90 + 180, 360) - 180) < 0.01 && abs(camera.DownAngle - 30) < 0.01, ...
    sprintf('Reset view at the starting view (got %.6f, %.6f)', camera.DialAngle, camera.DownAngle));
assert(isequal(viewer.StartView(), [90 30]));
% (framed on the vehicle, not the 10 m of ground around it)
meshNow = viewer.Patch.Vertices;
xLimits = viewer.Axes.XLim;
assert(xLimits(1) > min(meshNow(:,1)) - 1 && xLimits(2) < max(meshNow(:,1)) + 1, 'The view framed on the vehicle');
viewer.Close();
clear cleanupPrefs;   % (the GUI settings put back)

%% Fail conditions
if 1==0
    %% FAIL case: not a mesh file or a mesh
    fcn_CarMesh3D_viewLabels(42);

    %% FAIL case: a file that does not exist
    fcn_CarMesh3D_viewLabels('noSuchMesh.mat');

    %% FAIL case: colors not known
    fcn_CarMesh3D_viewLabels(meshFile, Colors='rainbow');
end

assert(isempty(timerfindall), 'A timer was left running');   % (a window's timer must not outlive it)
fprintf(1,'All tests of fcn_CarMesh3D_viewLabels passed\n');

%% Functions follow
function callText = fcn_INTERNAL_callOf(settings)
% The view call for these settings (as the viewer's "Copy view call" makes it)
[~, viewer] = fcn_CarMesh3D_viewLabels(settings.MeshFile, ViewSettings=settings, Visible=false);
callText = viewer.ViewCall();
viewer.Close();
end % Ends fcn_INTERNAL_callOf

function fcn_INTERNAL_tickBoundaries(viewer, flagOn)
% Sets "Show mesh boundaries?" Off or On in Overall Display, as a person
% would (its own window's menu panel, since 2026_11_24)
group = findall(viewer.Figure, 'Type', 'uibuttongroup', 'Tag', 'overallBoundaries');
fcn_INTERNAL_pickRadio(group, logical(flagOn));
end % Ends fcn_INTERNAL_tickBoundaries

function fcn_INTERNAL_pickRadio(group, value)
% Picks the radio button of this value in a button group, as a click
% does (setting SelectedObject in code does not run the callback)
assert(isscalar(group), 'The button group');
radios = findobj(group.Children, 'flat', 'Type', 'uiradiobutton');
radio = radios(arrayfun(@(r) isequal(r.UserData, value), radios));
assert(isscalar(radio), 'The radio button');
oldRadio = group.SelectedObject;
group.SelectedObject = radio;
group.SelectionChangedFcn(group, struct('NewValue', radio, 'OldValue', oldRadio));
end % Ends fcn_INTERNAL_pickRadio

function fcn_INTERNAL_restorePrefs(prefsBefore)
% Puts the GUI settings back as they were before the test
for prefName = {'ShowGround', 'StartViewDial', 'StartViewDown'}
    if isfield(prefsBefore, prefName{1})
        setpref('CarMesh3D', prefName{1}, prefsBefore.(prefName{1}));
    elseif ispref('CarMesh3D', prefName{1})
        rmpref('CarMesh3D', prefName{1});
    end
end
end % Ends fcn_INTERNAL_restorePrefs
