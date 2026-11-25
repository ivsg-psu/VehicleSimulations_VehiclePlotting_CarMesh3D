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
%   % * Driven by script (Sean, 05:03; fcn_CarMesh3D_guiDriver and
%   %   % fcn_CarMesh3D_guiRandomWalk): every control set to each value,
%   %   % the night x colors x see-through x ground x boundaries
%   %   % permutations, the menu, GUI settings, the mouse, wheel and dial,
%   %   % resizing (framing and zoom kept), layout at several sizes, random
%   %   % walks with the rules checked after every step, closing time and
%   %   % the timer; on a copy of the GUI test vehicle
%   % * Turn photo with model? Off and On; the photo options' preferences
%   %   % cleared for the tests and put back
%   % * The shared menu and Shared GUI settings (the shared-panels design
%   %   % file): up to two panels at once, through the menu's own buttons
%   %   % and in the rules; Shared GUI settings' View Reset; the sections
%   %   % the viewer does not use greyed

% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewLabels
%   % * Exit is the ☰ Menu's last line (Q62 (A))

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_viewLabels
%   % * (none yet)

%% Set up the workspace
close all;
vehicleID = fcn_CarMesh3D_demoVehicle(UsePreference=false, FigNum=-1);   % (the repo's demo vehicle: the Fit)
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
for prefName = {'ShowGround', 'StartViewDial', 'StartViewDown', 'TurnWithPhoto', 'TurnPhotoWithModel', 'PhotoHeight'}
    if ispref('CarMesh3D', prefName{1})
        prefsBefore.(prefName{1}) = getpref('CarMesh3D', prefName{1});
    end
end
cleanupPrefs = onCleanup(@() fcn_INTERNAL_restorePrefs(prefsBefore));
fcn_INTERNAL_clearPhotoPrefs();   % (the photo options at their defaults for this test; put back at the end)
[~, viewer] = fcn_CarMesh3D_viewLabels(meshFile, Visible=false, Wait=false);
% (the top bar: the menu; Exit is the menu's last line, Q62 (A), Sean
% 2026-11-25 14:31; no old tool row or label list in sight)
assert(~isempty(findall(viewer.Figure, 'Type', 'uibutton', 'Tag', 'viewerMenu')), 'The Menu button');
exitItem = findall(viewer.Figure, 'Type', 'uibutton', 'Tag', 'viewerExit');
assert(isscalar(exitItem) && strcmp(strtrim(exitItem.Text), 'Exit'), 'Exit, in the menu''s list');
assert(strcmp(ancestor(exitItem, 'uipanel').Tag, 'viewerMenuList'), 'Exit is in the menu''s list, not the top bar');
assert(isempty(findall(viewer.Figure, 'Type', 'uibuttongroup', 'Title', 'Labels')), 'No old label list');
% (it opens at Overall Display; each panel opens alone; two at once, the
% second under the first (the shared menu, fcn_CarMesh3D_makePanelMenu))
assert(strcmp(viewer.Panel(), 'Overall Display'));
for panelName = {'Labels To Display', 'Lamps To Display', 'Shared GUI settings', 'Overall Display'}
    viewer.OpenPanels(panelName);
    assert(strcmp(viewer.Panel(), panelName{1}));
    shownPanels = findall(viewer.Figure, 'Type', 'uipanel', 'Visible', 'on', '-regexp', 'Tag', '(Display|settings)$');
    assert(isscalar(shownPanels) && strcmp(shownPanels.Tag, panelName{1}), 'One panel alone');
end
viewer.OpenPanel('Lamps To Display');
assert(isequal(viewer.OpenNames(), {'Overall Display', 'Lamps To Display'}), 'Two panels at once, the second under the first');
shownPanels = findall(viewer.Figure, 'Type', 'uipanel', 'Visible', 'on', '-regexp', 'Tag', '(Display|settings)$');
assert(numel(shownPanels) == 2, 'Two panels shown');
viewer.OpenPanels({'Overall Display'});
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
readoutText = strjoin(cellstr(cameraReadout.Text), newline);
assert(isscalar(cameraReadout) && contains(readoutText, sprintf('yaw angle: %.0f', camera.DialAngle)) && ...
    contains(readoutText, sprintf('altitude angle: %.0f', -camera.DownAngle)) && contains(readoutText, 'distance from center'), 'Camera readout');
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

%% TEST case: driven by script, as a person would (Sean, 2026-11-24 05:03: "the GUI must go to that state")
% (fcn_CarMesh3D_guiDriver through the viewer's hooks State, SetState,
% Press, CheckLayout, and the mouse, dial and resize hooks; on a fresh copy
% of the GUI test vehicle, which has every label, lamp and hidden set, so
% nothing is written to a real vehicle; GUI settings put back at the end)
fprintf(1,'TEST case: driven by script: every control, permutations, random walks, layout\n');
prefsBefore = struct();
for prefName = {'ShowGround', 'StartViewDial', 'StartViewDown', 'TurnWithPhoto', 'TurnPhotoWithModel', 'PhotoHeight'}
    if ispref('CarMesh3D', prefName{1})
        prefsBefore.(prefName{1}) = getpref('CarMesh3D', prefName{1});
    end
end
cleanupPrefs = onCleanup(@() fcn_INTERNAL_restorePrefs(prefsBefore));
fcn_INTERNAL_clearPhotoPrefs();   % (the photo options at their defaults for this test; put back at the end)
demoRoot = tempname;
testFiles = fcn_CarMesh3D_makeDemoCopy(fcn_CarMesh3D_demoVehicle(Which='guiTest', FigNum=-1), DemoFolder=demoRoot, FigNum=-1);
[~, viewer] = fcn_CarMesh3D_viewLabels(testFiles.MeshFile, Outline=testFiles.OutlineFile, Visible=false, Wait=false);
assert(all(isfield(viewer, {'State','SetState','Press','Key','CheckLayout','Controls','MouseDrag','Scroll','DialDrag','Resize','Tick','FitInfo','PhotoCount'})), 'The test hooks');
assert(viewer.PhotoCount() > 0, 'The GUI test vehicle has photos');
message = fcn_INTERNAL_invariants(viewer);
assert(isempty(message), message);

% (every control a user can click has a Tag, in every panel: no 'note'; no 'error')
for panelName = {'Overall Display', 'Labels To Display', 'Lamps To Display', 'Shared GUI settings'}
    viewer.OpenPanels(panelName);
    viewer.Settle();
    problems = viewer.CheckLayout();
    assert(~any(strcmp(problems.Severity, 'note')), 'Untagged controls in %s: %s', panelName{1}, strjoin(problems.Control(strcmp(problems.Severity, 'note')), '; '));
    assert(~any(strcmp(problems.Severity, 'error')), 'Layout errors in %s: %s', panelName{1}, strjoin(strcat(problems.Control(strcmp(problems.Severity, 'error')), ': ', problems.Problem(strcmp(problems.Severity, 'error'))), '; '));
end

% (the menu, through its own buttons: up to two panels at once, the
% second under the first; a third replaces the lower one; an open one
% picked again closes, and the one under it moves up)
viewer.OpenPanels({});
expected = {{'Labels To Display'}, {'Labels To Display', 'Lamps To Display'}, {'Labels To Display', 'Shared GUI settings'}, ...
    {'Shared GUI settings'}, {'Shared GUI settings', 'Overall Display'}};
picks = {'Labels To Display', 'Lamps To Display', 'Shared GUI settings', 'Labels To Display', 'Overall Display'};
for ith_pick = 1:numel(picks)
    state = viewer.Press('viewerMenu');
    assert(state.OnScreen.viewerMenuList, 'The menu''s list opens');
    state = viewer.Press(['menu_' strrep(picks{ith_pick}, ' ', '')]);
    assert(~state.OnScreen.viewerMenuList, 'The menu''s list closes when a panel is picked');
    assert(isequal(viewer.OpenNames(), expected{ith_pick}), 'After picking %s: %s', picks{ith_pick}, strjoin(viewer.OpenNames(), ', '));
    message = fcn_INTERNAL_invariants(viewer);
    assert(isempty(message), message);
end
% (every open panel picked again: the column closes; picked again, it opens)
viewer.Press('viewerMenu');
viewer.Press('menu_SharedGUIsettings');
viewer.Press('viewerMenu');
viewer.Press('menu_OverallDisplay');
assert(isempty(viewer.Panel()), 'The open panels picked again close');
viewer.Press('viewerMenu');
viewer.Press('menu_OverallDisplay');
assert(strcmp(viewer.Panel(), 'Overall Display'));
try
    viewer.OpenPanel('No Such Panel');
    error('test:noError', 'An unknown panel was opened');
catch caughtError
    assert(contains(caughtError.message, 'No panel named'), caughtError.message);
end

% (every radio group in every panel set to each of its values, as clicks; the rules after each)
for panelName = {'Overall Display', 'Labels To Display', 'Lamps To Display'}
    viewer.OpenPanels(panelName);
    panelHandle = findall(viewer.Figure, 'Type', 'uipanel', 'Tag', panelName{1});
    groups = findall(panelHandle, 'Type', 'uibuttongroup');
    for ith_group = 1:numel(groups)
        group = groups(ith_group);
        radios = findobj(group.Children, 'flat', 'Type', 'uiradiobutton', 'Visible', 'on');
        for ith_radio = numel(radios):-1:1
            if ~strcmp(radios(ith_radio).Enable, 'on') || ~strcmp(group.Enable, 'on')
                continue;   % (grayed: a person cannot click it; checked by the rules)
            end
            viewer.SetState(group.Tag, radios(ith_radio).UserData);
            message = fcn_INTERNAL_invariants(viewer);
            assert(isempty(message), 'After %s = %s: %s', group.Tag, mat2str(radios(ith_radio).UserData), message);
        end
    end
end

% (permutations that interact: night x colors x see-through x ground x boundaries)
viewer.OpenPanels({'Overall Display'});
viewer.SetState('overallNight', false);
for flagNight = [false true]
    for colorsName = {'labels', 'vehicle'}
        for seeThroughValue = [0 60]
            for flagGround = [false true]
                for flagEdges = [false true]
                    viewer.SetState('overallNight', false);   % (Colors? and see-through are set by day)
                    viewer.SetState(struct('overallColors', colorsName{1}, 'overallSeeThrough', seeThroughValue, ...
                        'showGround', flagGround, 'overallBoundaries', flagEdges));
                    viewer.SetState('overallNight', flagNight);
                    caseText = sprintf('night %d, %s, see-through %d, ground %d, edges %d', flagNight, colorsName{1}, seeThroughValue, flagGround, flagEdges);
                    message = fcn_INTERNAL_invariants(viewer);
                    assert(isempty(message), '%s: %s', caseText, message);
                    assert(viewer.NightView() == flagNight && strcmp(viewer.Colors(), colorsName{1}) && ...
                        abs(viewer.SeeThrough() - seeThroughValue/100) < 1e-9 && viewer.Ground() == flagGround && viewer.Boundaries() == flagEdges, caseText);
                    if flagNight
                        assert(strcmp(viewer.Patch.Visible, 'off'), '%s: the label patch hidden', caseText);
                        % (grayed at night: a person cannot click Colors? or the see-through slider)
                        try
                            viewer.SetState('overallSeeThrough', 30);
                            error('test:noError', 'The see-through slider was clicked at night');
                        catch caughtError
                            assert(contains(caughtError.message, 'disabled'), caughtError.message);
                        end
                    else
                        assert(strcmp(viewer.Patch.Visible, 'on'), caseText);
                        assert(strcmp(char(viewer.Patch.EdgeColor), 'none') ~= flagEdges, '%s: the edges', caseText);
                    end
                end
            end
        end
    end
end
viewer.SetState('overallNight', false);
viewer.SetState(struct('overallSeeThrough', 0, 'showGround', true, 'overallBoundaries', false, 'overallColors', 'labels'));

% (one label alone, as Label= or a view call gives it: that label Colored? Yes, the others No)
kinds = viewer.LabelKinds();
for ith_key = 1:numel(kinds.Keys)
    viewer.ShowLabel(kinds.Keys{ith_key});
    message = fcn_INTERNAL_invariants(viewer);
    assert(isempty(message), 'Label %s alone: %s', kinds.Keys{ith_key}, message);
end
viewer.ShowLabel('all');

% (Hazards and the two turn signals)
viewer.OpenPanels({'Lamps To Display'});
viewer.SetState('lamp_All', false);
viewer.SetState('lamp_TurnLeft', true);
assert(~viewer.NightLights().Hazards, 'One turn signal: no hazards');
viewer.SetState('lamp_TurnRight', true);
assert(viewer.NightLights().Hazards, 'Both turn signals: hazards');
viewer.SetState('lamp_TurnLeft', false);
assert(~viewer.NightLights().Hazards && viewer.NightLights().TurnRight, 'One off again: no hazards');
viewer.SetState('lamp_Hazards', true);
assert(viewer.NightLights().TurnLeft && viewer.NightLights().TurnRight, 'Hazards: both turn signals');
message = fcn_INTERNAL_invariants(viewer);
assert(isempty(message), message);

% (Shared GUI settings: the starting view; its Reset gives 60 and 20; Reset view goes there)
viewer.OpenPanels({'Shared GUI settings'});
viewer.SetState('startViewDial', 120);
viewer.SetState('startViewDown', 35);
assert(isequal(viewer.StartView(), [120 35]), 'Both angles kept (each field once put the other back)');
viewer.SetState('startViewDial', 100);
assert(isequal(viewer.StartView(), [100 35]), 'The angle down kept when the dial angle is typed');
viewer.OpenPanels({'Overall Display'});
viewer.Press('overallResetView');
camera = viewer.CameraInfo();
assert(abs(camera.DialAngle - 100) < 0.01 && abs(camera.DownAngle - 35) < 0.01, 'Reset view at the starting view');
viewer.OpenPanels({'Shared GUI settings'});
viewer.Press('settingsResetView');
assert(isequal(viewer.StartView(), [60 20]), 'View''s Reset: the defaults');
% (the sections the viewer does not use are greyed, never hidden: rule G26)
assert(strcmp(findall(viewer.Figure, 'Tag', 'settingsInitials').Enable, 'off'), 'You: greyed in the viewer');
assert(strcmp(findall(viewer.Figure, 'Tag', 'settingsResetEditing').Enable, 'off'), 'Editing: greyed in the viewer');
assert(strcmp(findall(viewer.Figure, 'Tag', 'startViewDial').Enable, 'on'), 'View: used by the viewer');
viewer.OpenPanels({'Overall Display'});
viewer.Press('overallResetView');
camera = viewer.CameraInfo();
assert(abs(camera.DialAngle - 60) < 0.01 && abs(camera.DownAngle - 20) < 0.01, 'Reset view at the defaults: 60 on the dial, 20 down');
assert(fcn_INTERNAL_vehicleInView(viewer), 'Reset view: the whole vehicle in view');
% (BUG case, found by a random walk: a new starting view, the model turned,
% night on, Reset view went to where the camera was when night fell)
viewer.SetStartView(90, 30);
viewer.MouseDrag('left', [], fcn_INTERNAL_axesCenter(viewer) + [150 0], 5);
viewer.SetState('overallNight', true);
viewer.Press('overallResetView');
camera = viewer.CameraInfo();
assert(abs(camera.DialAngle - 90) < 0.01 && abs(camera.DownAngle - 30) < 0.01, 'Reset view at night: the starting view (got %.2f, %.2f)', camera.DialAngle, camera.DownAngle);
viewer.SetState('overallNight', false);
viewer.SetStartView(60, 20);
viewer.Press('overallResetView');
message = fcn_INTERNAL_invariants(viewer);
assert(isempty(message), message);

% (the mouse, the wheel and the dial, through their own code: the readout follows each)
cameraBefore = viewer.CameraInfo();
viewer.MouseDrag('left', [], fcn_INTERNAL_axesCenter(viewer) + [80 0], 6);
cameraAfter = viewer.CameraInfo();
assert(abs(mod(cameraAfter.DialAngle - cameraBefore.DialAngle + 180, 360) - 180) > 5, 'A left drag turns the model');
message = fcn_INTERNAL_invariants(viewer);
assert(isempty(message), 'After a mouse turn: %s', message);
targetBefore = viewer.Axes.CameraTarget;
viewer.MouseDrag('right', [], fcn_INTERNAL_axesCenter(viewer) + [40 30], 3);
assert(norm(viewer.Axes.CameraTarget - targetBefore) > 1e-6, 'A right drag pans');
zoomBefore = viewer.FitInfo().Zoom;
viewer.Scroll(-2);
assert(viewer.FitInfo().Zoom > 1.2*zoomBefore, 'The wheel zooms in');
viewer.Scroll(2);
assert(viewer.DialDrag([30 60 100 150]), 'The dial dragged');
camera = viewer.CameraInfo();
assert(abs(mod(camera.DialAngle - viewer.PhotoAngle() + 180, 360) - 180) < 0.5, 'Let go: the model at the photo''s angle (Turn model with photo? On)');
message = fcn_INTERNAL_invariants(viewer);
assert(isempty(message), 'After a dial turn (T32): %s', message);
viewer.SetState('turnWithPhoto', false);
cameraBefore = viewer.CameraInfo();
viewer.DialDrag(250);
assert(abs(viewer.CameraInfo().DialAngle - cameraBefore.DialAngle) < 1e-6, 'Turn model with photo? Off: the model stays');
viewer.SetState('turnWithPhoto', true);
% (Turn photo with model? Off: turning the model leaves the dial and the
% photo where they are; On again: they follow)
viewer.SetState('turnPhotoWithModel', false);
assert(~viewer.TurnPhotoWithModel() && isequal(getpref('CarMesh3D', 'TurnPhotoWithModel'), false), 'Turn photo with model? Off, remembered');
angleBefore = viewer.PhotoAngle();
viewer.MouseDrag('left', [], fcn_INTERNAL_axesCenter(viewer) + [300 0], 6);
viewer.Settle();
assert(isequal(viewer.PhotoAngle(), angleBefore), 'Turn photo with model? Off: the photo stays');
viewer.SetState('turnPhotoWithModel', true);
viewer.MouseDrag('left', [], fcn_INTERNAL_axesCenter(viewer) + [300 0], 6);
viewer.Settle();
assert(~isequal(viewer.PhotoAngle(), angleBefore), 'Turn photo with model? On: the photo follows the model');
message = fcn_INTERNAL_invariants(viewer);
assert(isempty(message), message);

% (resizing keeps the whole vehicle in view, and keeps a zoom: T33)
for windowSize = {[1500 860], [800 500], [640 400], [1600 1000], [1100 700]}
    viewer.Resize(windowSize{1});
    viewer.Settle();
    viewer.Press('overallResetView');
    assert(fcn_INTERNAL_vehicleInView(viewer), 'Reset view at %s: the whole vehicle in view', mat2str(windowSize{1}));
    for otherSize = {[900 600], [1500 860]}
        viewer.Resize(otherSize{1});
        viewer.Settle();   % (once more: a hidden window in a busy batch MATLAB can lay out late; the view timer would refit within 0.25 s)
        assert(fcn_INTERNAL_vehicleInView(viewer), 'Resized from %s to %s: the whole vehicle in view', mat2str(windowSize{1}), mat2str(otherSize{1}));
    end
    viewer.Scroll(-3);
    zoomBefore = viewer.FitInfo().Zoom;
    viewer.Resize(windowSize{1});
    viewer.Settle();
    assert(abs(viewer.FitInfo().Zoom/zoomBefore - 1) < 0.01, 'Zoomed in, resized to %s: the zoom kept (%.3f, was %.3f)', mat2str(windowSize{1}), viewer.FitInfo().Zoom, zoomBefore);
    message = fcn_INTERNAL_invariants(viewer);
    assert(isempty(message), message);
    % (layout: no errors at this size, in every panel)
    for panelName = {'Overall Display', 'Labels To Display', 'Lamps To Display', 'Shared GUI settings'}
        viewer.OpenPanels(panelName);
        viewer.Settle();
        problems = viewer.CheckLayout();
        flagErrors = strcmp(problems.Severity, 'error');
        assert(~any(flagErrors), 'Layout at %s, %s: %s', mat2str(windowSize{1}), panelName{1}, strjoin(strcat(problems.Control(flagErrors), ': ', problems.Problem(flagErrors)), '; '));
    end
    viewer.OpenPanels({'Overall Display'});
end
viewer.Resize([1500 860]);

% (random walks: seeded sequences of every action, the rules after each step; failures saved to replay)
for seed = 1:3
    if ~strcmp(viewer.Panel(), 'Overall Display')   % (picked when open, with the menu's list open, it would close)
        viewer.OpenPanels({'Overall Display'});
    end
    viewer.Press('overallResetView');
    [actions, invariants] = fcn_INTERNAL_walkActions(viewer, seed);
    report = fcn_CarMesh3D_guiRandomWalk(actions, invariants, Steps=200, Seed=seed, Name='viewLabelsWalk', LogFolder=fullfile(demoRoot, 'walks'), FigNum=-1);
    if ~report.Passed
        fprintf(1, '    walk seed %d failed at step %d (%s, %s): %s\n    saved: %s\n    steps: %s\n', seed, report.Failures(1).Step, ...
            report.Failures(1).Action, report.Failures(1).Kind, report.Failures(1).Message, report.FailureFile, strjoin(report.Steps, ', '));
        error('test:walk', 'Random walk %d: %s', seed, report.Failures(1).Message);
    end
    fprintf(1, '    walk seed %d: %d steps, every rule held\n', seed, numel(report.Steps));
end

% (close: quick, the timer gone)
tic;
fcn_INTERNAL_exitByMenu(viewer);   % (Exit is the menu's last line: opened from the menu, as a user would)
closeTime = toc;
assert(~isvalid(viewer.Figure), 'Exit closes the window');
assert(closeTime < 1, 'Closing took %.2f s', closeTime);
assert(isempty(timerfindall), 'The view timer stopped with its window');

% (a random walk on the demo vehicle too: a real mesh, with its photos)
fitFiles = fcn_CarMesh3D_makeDemoCopy(fcn_CarMesh3D_demoVehicle(UsePreference=false, FigNum=-1), DemoFolder=demoRoot, FigNum=-1);
[~, viewer] = fcn_CarMesh3D_viewLabels(fitFiles.MeshFile, Outline=fitFiles.OutlineFile, Visible=false, Wait=false);
[actions, invariants] = fcn_INTERNAL_walkActions(viewer, 4);
report = fcn_CarMesh3D_guiRandomWalk(actions, invariants, Steps=150, Seed=4, Name='viewLabelsWalkDemo', LogFolder=fullfile(demoRoot, 'walks'), FigNum=-1);
if ~report.Passed
    fprintf(1, '    demo vehicle walk failed at step %d (%s, %s): %s\n    steps: %s\n', report.Failures(1).Step, ...
        report.Failures(1).Action, report.Failures(1).Kind, report.Failures(1).Message, strjoin(report.Steps, ', '));
    error('test:walk', 'Random walk on the demo vehicle: %s', report.Failures(1).Message);
end
fprintf(1, '    demo vehicle walk: %d steps, every rule held\n', numel(report.Steps));
tic;
fcn_INTERNAL_exitByMenu(viewer);   % (Exit is the menu's last line: opened from the menu, as a user would)
assert(toc < 1 && ~isvalid(viewer.Figure) && isempty(timerfindall), 'The demo vehicle''s viewer closed quickly, its timer gone');

% (a mesh with no photos: the photo options grayed, the dial hook says so)
loaded = load(testFiles.MeshFile, 'vehicleMesh');
[~, viewer] = fcn_CarMesh3D_viewLabels(loaded.vehicleMesh, Visible=false, Wait=false);
state = viewer.State();
assert(viewer.PhotoCount() == 0 && ~state.Enabled.turnWithPhoto && ~state.Enabled.photoSize, 'No photos: the photo options grayed');
assert(~viewer.DialDrag(90), 'No dial with no photos');
message = fcn_INTERNAL_invariants(viewer);
assert(isempty(message), message);
viewer.Close();
emptyPhotos = fullfile(demoRoot, 'noPhotosHere');
mkdir(emptyPhotos);
[~, viewer] = fcn_CarMesh3D_viewLabels(loaded.vehicleMesh, PhotoFolder=emptyPhotos, Visible=false, Wait=false);
state = viewer.State();
assert(~state.Enabled.turnWithPhoto, 'A folder with no ViewInDegrees photos: the photo options grayed');
viewer.Close();

% (in a visible window: the text checks and the layout as drawn, at several
% sizes; run when CARMESH3D_TEST_VISIBLE is set, since a window shows)
if ~isempty(getenv('CARMESH3D_TEST_VISIBLE'))
    [~, viewer] = fcn_CarMesh3D_viewLabels(testFiles.MeshFile, Outline=testFiles.OutlineFile, Visible=true, Wait=false);
    cleanupWindow = onCleanup(@() fcn_INTERNAL_closeViewer(viewer));
    for windowSize = {[1500 860], [800 500], [640 400], [1600 1000]}
        viewer.Resize(windowSize{1});
        pause(0.5);
        for panelName = {'Overall Display', 'Labels To Display', 'Lamps To Display', 'Shared GUI settings'}
            viewer.OpenPanels(panelName);
            pause(0.3);
            problems = viewer.CheckLayout();
            for ith_problem = 1:height(problems)
                fprintf(1, '    visible %s, %s: %s | %s | %s\n', mat2str(windowSize{1}), panelName{1}, problems.Severity{ith_problem}, ...
                    problems.Control{ith_problem}, problems.Problem{ith_problem});
            end
            assert(~any(strcmp(problems.Severity, 'error')), 'Visible layout errors at %s in %s', mat2str(windowSize{1}), panelName{1});
        end
        viewer.Press('overallResetView');
        assert(fcn_INTERNAL_vehicleInView(viewer), 'Visible, %s: the whole vehicle in view', mat2str(windowSize{1}));
    end
    clear cleanupWindow;
end
clear cleanupPrefs;   % (the GUI settings put back; the copy is in the temporary folder)

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

function fcn_INTERNAL_clearPhotoPrefs()
% The photo options remembered from Overall Display, taken away so the
% test starts from their defaults (they are put back by restorePrefs)
for prefName = {'TurnWithPhoto', 'TurnPhotoWithModel', 'PhotoHeight'}
    if ispref('CarMesh3D', prefName{1})
        rmpref('CarMesh3D', prefName{1});
    end
end
end % Ends fcn_INTERNAL_clearPhotoPrefs

function fcn_INTERNAL_restorePrefs(prefsBefore)
% Puts the GUI settings back as they were before the test
for prefName = {'ShowGround', 'StartViewDial', 'StartViewDown', 'TurnWithPhoto', 'TurnPhotoWithModel', 'PhotoHeight'}
    if isfield(prefsBefore, prefName{1})
        setpref('CarMesh3D', prefName{1}, prefsBefore.(prefName{1}));
    elseif ispref('CarMesh3D', prefName{1})
        rmpref('CarMesh3D', prefName{1});
    end
end
end % Ends fcn_INTERNAL_restorePrefs

function message = fcn_INTERNAL_invariants(viewer)
% The rules that must hold after any action in the viewer's own window
% ('' when all hold, else what is wrong): the camera readout, the panels
% mirroring the viewer, the graying at night, the ground, one panel at a
% time, the status line, one timer
viewer.Tick();   % (the view timer's check, at once: it runs every 0.25 s)
state = viewer.State();
values = state.Values;
problems = {};
% (the camera readout: four lines, equal to CameraInfo)
camera = viewer.CameraInfo();
altitude = -camera.DownAngle;
if altitude < -0.5
    upDown = 'down';
elseif altitude > 0.5
    upDown = 'up';
else
    upDown = 'level';
end
sideNames = {'from the front', 'from the front, left', 'from the left side', 'from behind, left', ...
    'from behind', 'from behind, right', 'from the right side', 'from the front, right'};
side = sideNames{mod(round(mod(camera.DialAngle, 360)/45), 8) + 1};
if camera.Distance < 10
    distanceText = sprintf('%.1f m', camera.Distance);
else
    distanceText = sprintf('%.0f m', camera.Distance);
end
expectedReadout = {'Camera view:', sprintf('   yaw angle: %.0f%s (%s)', camera.DialAngle, char(176), side), ...
    sprintf('   altitude angle: %.0f%s (%s)', altitude, char(176), upDown), sprintf('   distance from center: %s', distanceText)};
if ~isequal(cellstr(values.cameraReadout)', expectedReadout) && ~isequal(cellstr(values.cameraReadout), expectedReadout)
    problems{end+1} = sprintf('the readout says "%s" but the camera is "%s"', strjoin(cellstr(values.cameraReadout), ' / '), strjoin(expectedReadout, ' / '));
end
% (Overall Display mirrors the viewer; Colors? and see-through grayed exactly at night)
flagNight = viewer.NightView();
if ~isequal(values.overallColors, viewer.Colors()), problems{end+1} = 'Colors? differs from the viewer'; end
if ~isequal(values.overallBoundaries, viewer.Boundaries()), problems{end+1} = 'Show mesh boundaries? differs'; end
if ~isequal(values.overallNight, flagNight), problems{end+1} = 'Nighttime view? differs'; end
if ~isequal(values.showGround, viewer.Ground()), problems{end+1} = 'Show ground? differs'; end
if abs(values.overallSeeThrough - 100*viewer.SeeThrough()) > 1e-6, problems{end+1} = 'the see-through slider differs'; end
colorsRadios = findall(viewer.Figure, 'Type', 'uiradiobutton', 'Parent', findall(viewer.Figure, 'Tag', 'overallColors'));
if any(strcmp({colorsRadios.Enable}, 'on') == flagNight) || state.Enabled.overallColors == flagNight || state.Enabled.overallSeeThrough == flagNight
    problems{end+1} = sprintf('Colors? or see-through not grayed exactly at night (night %d)', flagNight);
end
flagPhotos = viewer.PhotoCount() > 0;
if state.Enabled.turnWithPhoto ~= flagPhotos || state.Enabled.photoSize ~= flagPhotos
    problems{end+1} = 'the photo options not grayed exactly when there are no photos';
end
if ~isequal(values.turnWithPhoto, viewer.TurnWithPhoto()), problems{end+1} = 'Turn model with photo? differs'; end
% (the ground: by day the light one, at night the dark one, each only when shown)
dayGround = findall(viewer.Axes, 'Tag', 'dayGround');
nightGround = findall(viewer.Axes, 'Tag', 'nightGround');
if strcmp(dayGround.Visible, 'on') ~= (viewer.Ground() && ~flagNight)
    problems{end+1} = 'the day ground shown when it should not be, or not shown';
end
if numel(nightGround) ~= double(viewer.Ground() && flagNight)
    problems{end+1} = sprintf('%d night grounds (ground %d, night %d)', numel(nightGround), viewer.Ground(), flagNight);
end
% (Labels To Display mirrors Hidden, Uncolored and Label: one label alone is that label colored)
hidden = viewer.Hidden();
kinds = viewer.LabelKinds();
labelTags = state.Tags(startsWith(state.Tags, 'colored_') & ~strcmp(state.Tags, 'colored_'));
rowKeys = erase(labelTags, 'colored_');
if strcmp(viewer.Label(), 'all')
    uncolored = viewer.Uncolored();
else
    uncolored = setdiff(rowKeys, {viewer.Label()});
end
coloredFlags = [];
shownFlags = [];
for ith_key = 1:numel(rowKeys)
    key = rowKeys{ith_key};
    colored = values.(matlab.lang.makeValidName(['colored_' key]));
    shown = values.(matlab.lang.makeValidName(['shown_' key]));
    if ~isequal(colored, ~any(strcmp(uncolored, key)))
        problems{end+1} = sprintf('Colored? of %s differs', key); %#ok<AGROW>
    end
    if ~isequal(shown, ~any(strcmp(hidden, key)))
        problems{end+1} = sprintf('Shown? of %s differs', key); %#ok<AGROW>
    end
    coloredFlags(end+1) = ~any(strcmp(uncolored, key)); %#ok<AGROW>
    shownFlags(end+1) = ~any(strcmp(hidden, key)); %#ok<AGROW>
end
if ~isequal(values.shown_hidden, ~any(strcmp(hidden, 'hidden'))), problems{end+1} = 'Shown? of hidden faces differs'; end
if ~fcn_INTERNAL_sameCommon(values.allColored, coloredFlags), problems{end+1} = 'All labels Colored? differs'; end
if ~fcn_INTERNAL_sameCommon(values.allShown, shownFlags), problems{end+1} = 'All labels Shown? differs'; end
if ~all(ismember(setdiff(kinds.Keys, {'hidden'}), rowKeys)), problems{end+1} = 'a label of the mesh has no row'; end
% (Lamps To Display mirrors NightLights; Hazards exactly when both turn signals)
lamps = viewer.NightLights();
for lampName = {'LowBeam', 'HighBeam', 'Running', 'TurnLeft', 'TurnRight', 'Backup', 'FogLights'}
    if ~isequal(values.(['lamp_' lampName{1}]), logical(lamps.(lampName{1})))
        problems{end+1} = sprintf('the %s row differs', lampName{1}); %#ok<AGROW>
    end
end
if ~isequal(values.lamp_Tail, lower(char(lamps.Tail))), problems{end+1} = 'the tail lights row differs'; end
if ~isequal(values.lamp_Reflectors, lamps.Reflectors > 0), problems{end+1} = 'the reflectors row differs'; end
if ~isequal(values.lamp_Hazards, logical(lamps.TurnLeft) && logical(lamps.TurnRight)) || ...
        logical(lamps.Hazards) ~= (logical(lamps.TurnLeft) && logical(lamps.TurnRight))
    problems{end+1} = 'Hazards is not exactly both turn signals';
end
% (one or two panels open, those the viewer says, top first; the menu's
% mark on each open one, and on no other)
panelNames = {'OverallDisplay', 'LabelsToDisplay', 'LampsToDisplay', 'SharedGUIsettings'};
panelTitles = {'Overall Display', 'Labels To Display', 'Lamps To Display', 'Shared GUI settings'};
openNow = {};
openSaid = viewer.OpenNames();
for ith_panel = 1:numel(panelNames)
    if values.(matlab.lang.makeValidName(panelTitles{ith_panel}))
        openNow{end+1} = panelTitles{ith_panel}; %#ok<AGROW>
    end
    menuButton = findall(viewer.Figure, 'Tag', ['menu_' panelNames{ith_panel}]);
    menuText = char(menuButton.Text);
    if startsWith(menuText, char(10003)) ~= any(strcmp(openSaid, panelTitles{ith_panel}))
        problems{end+1} = sprintf('the menu''s mark on %s is wrong', panelTitles{ith_panel}); %#ok<AGROW>
    end
end
if numel(openSaid) > 2 || ~isempty(setxor(openNow, openSaid)) || (isempty(openSaid) ~= isempty(viewer.Panel())) || ...
        (~isempty(openSaid) && ~strcmp(openSaid{1}, viewer.Panel()))
    problems{end+1} = sprintf('panels open: %s; the viewer says "%s"', strjoin(openNow, ', '), strjoin(openSaid, ', '));
end
% (the status line: the colors, day or night, the labels not shown)
statusText = values.viewerStatus;
colorsText = 'label colors';
if strcmp(viewer.Colors(), 'vehicle'), colorsText = 'vehicle colors'; end
timeText = 'by day';
if flagNight, timeText = 'at night'; end
numHidden = numel(setdiff(hidden, {'hidden'}));
if ~contains(statusText, [colorsText ', ' timeText]) || (numHidden > 0) ~= contains(statusText, sprintf('| %d label(s) not shown', numHidden))
    problems{end+1} = sprintf('the status line "%s" is not %s, %s, %d not shown', statusText, colorsText, timeText, numHidden);
end
% (one timer: the view timer of this window)
if numel(timerfindall) ~= 1
    problems{end+1} = sprintf('%d timers running', numel(timerfindall));
end
message = strjoin(problems, '; ');
end % Ends fcn_INTERNAL_invariants

function flagSame = fcn_INTERNAL_sameCommon(value, flags)
% An "All" row's value: true or false when every row agrees, else the
% unseen mixed button (NaN)
if all(flags)
    flagSame = isequal(value, true);
elseif ~any(flags)
    flagSame = isequal(value, false);
else
    flagSame = isnumeric(value) && isscalar(value) && isnan(value);
end
end % Ends fcn_INTERNAL_sameCommon

function flagIn = fcn_INTERNAL_vehicleInView(viewer)
% Whether the vehicle's box, as the camera projects it, is inside the
% model's axes (orthographic or perspective; MATLAB's view angle spans
% the axes' shorter side, measured 2026-11-24)
axesHandle = viewer.Axes;
vertices = viewer.Patch.Vertices;
lowCorner = min(vertices, [], 1);
highCorner = max(vertices, [], 1);
[cornerX, cornerY, cornerZ] = ndgrid([lowCorner(1) highCorner(1)], [lowCorner(2) highCorner(2)], [lowCorner(3) highCorner(3)]);
corners = [cornerX(:) cornerY(:) cornerZ(:)];
forward = axesHandle.CameraTarget - axesHandle.CameraPosition;
distance = norm(forward);
forward = forward/distance;
rightward = cross(forward, axesHandle.CameraUpVector);
rightward = rightward/norm(rightward);
upward = cross(rightward, forward);
offsets = corners - axesHandle.CameraPosition;
if strcmp(axesHandle.Projection, 'perspective')
    depth = offsets*forward(:);
else
    depth = distance*ones(size(corners,1),1);
end
halfShort = tand(axesHandle.CameraViewAngle/2);
axesSize = axesHandle.InnerPosition(3:4);
halfAcross = halfShort*max(1, axesSize(1)/axesSize(2));
halfUp = halfShort*max(1, axesSize(2)/axesSize(1));
% (measured from the view's center: the line from the camera to its target)
across = offsets*rightward(:)./depth;
up = offsets*upward(:)./depth;
flagIn = all(abs(across) <= halfAcross*1.001) && all(abs(up) <= halfUp*1.001) && all(axesSize > 20);
end % Ends fcn_INTERNAL_vehicleInView

function [actions, invariants] = fcn_INTERNAL_walkActions(viewer, seed)
% Every kind of user action in the viewer's own window, for random walks:
% each with the rule of when a person could do it (its panel open, the
% control not grayed)
randomStream = RandStream('mt19937ar', 'Seed', 1000 + seed);
pick = @(list) list{randi(randomStream, numel(list))};
state = viewer.State();
labelTags = state.Tags(startsWith(state.Tags, {'colored_', 'shown_'}));
lampTags = state.Tags(startsWith(state.Tags, 'lamp_') & ~strcmp(state.Tags, 'lamp_Tail'));
kinds = viewer.LabelKinds();
isOpen = @(name) any(strcmp(viewer.OpenNames(), name));
isDay = @() ~viewer.NightView();
hasPhotos = @() viewer.PhotoCount() > 0;
sizes = {[1500 860], [800 500], [640 400], [1600 1000], [1100 700]};
actionList = {
    'colors labels',      @() viewer.SetState('overallColors', 'labels'),        @() isOpen('Overall Display') && isDay(), 1
    'colors vehicle',     @() viewer.SetState('overallColors', 'vehicle'),       @() isOpen('Overall Display') && isDay(), 1
    'boundaries on',      @() viewer.SetState('overallBoundaries', true),        @() isOpen('Overall Display'), 1
    'boundaries off',     @() viewer.SetState('overallBoundaries', false),       @() isOpen('Overall Display'), 1
    'night on',           @() viewer.SetState('overallNight', true),             @() isOpen('Overall Display'), 1
    'night off',          @() viewer.SetState('overallNight', false),            @() isOpen('Overall Display'), 2
    'ground on',          @() viewer.SetState('showGround', true),               @() isOpen('Overall Display'), 1
    'ground off',         @() viewer.SetState('showGround', false),              @() isOpen('Overall Display'), 1
    'see-through',        @() viewer.SetState('overallSeeThrough', 90*rand(randomStream)), @() isOpen('Overall Display') && isDay(), 1
    'reset view',         @() fcn_INTERNAL_resetAndCheck(viewer),                @() isOpen('Overall Display'), 1
    'turn with photo on', @() viewer.SetState('turnWithPhoto', true),            @() isOpen('Overall Display') && hasPhotos(), 0.5
    'turn with photo off',@() viewer.SetState('turnWithPhoto', false),           @() isOpen('Overall Display') && hasPhotos(), 0.5
    'photo size',         @() viewer.SetState('photoSize', pick({220, 300, 420})), @() isOpen('Overall Display') && hasPhotos(), 0.5
    'turn photo w/ model',@() viewer.SetState('turnPhotoWithModel', rand(randomStream) > 0.3), @() isOpen('Overall Display') && hasPhotos(), 0.5
    'label row',          @() viewer.SetState(pick(labelTags), rand(randomStream) > 0.5), @() isOpen('Labels To Display'), 4
    'all colored',        @() viewer.SetState('allColored', rand(randomStream) > 0.5), @() isOpen('Labels To Display'), 1
    'all shown',          @() viewer.SetState('allShown', rand(randomStream) > 0.5),   @() isOpen('Labels To Display'), 1
    'lamp row',           @() viewer.SetState(pick(lampTags), rand(randomStream) > 0.5), @() isOpen('Lamps To Display'), 4
    'tail lights',        @() viewer.SetState('lamp_Tail', pick({'off', 'on', 'brake'})), @() isOpen('Lamps To Display'), 1
    'start view',         @() viewer.SetState(pick({'startViewDial', 'startViewDown'}), round(80*rand(randomStream))), @() isOpen('Shared GUI settings'), 1
    'reset settings',     @() viewer.Press('settingsResetView'),                 @() isOpen('Shared GUI settings'), 0.5
    'menu',               @() viewer.Press('viewerMenu'),                        [], 2
    'menu pick',          @() viewer.Press(pick({'menu_OverallDisplay', 'menu_LabelsToDisplay', 'menu_LampsToDisplay', 'menu_SharedGUIsettings'})), ...
                                                                                 @() fcn_INTERNAL_onScreen(viewer, 'viewerMenuList'), 3
    'one label alone',    @() viewer.ShowLabel(pick([{'all'}, kinds.Keys])),     [], 1
    'mouse turn',         @() viewer.MouseDrag('left', [], fcn_INTERNAL_axesCenter(viewer) + 120*(rand(randomStream,1,2) - 0.5), 4), [], 2
    'mouse pan',          @() viewer.MouseDrag('right', [], fcn_INTERNAL_axesCenter(viewer) + 60*(rand(randomStream,1,2) - 0.5), 2), [], 1
    'wheel',              @() viewer.Scroll(pick({-2, -1, 1, 2})),               [], 1
    'dial drag',          @() viewer.DialDrag(360*rand(randomStream,1,3)),       hasPhotos, 2
    'resize',             @() fcn_INTERNAL_resizeAndCheck(viewer, pick(sizes)),  [], 1
    'copy view call',     @() fcn_INTERNAL_copyQuietly(viewer),                  [], 0.2
    };
actions = struct('Name', actionList(:,1)', 'Do', actionList(:,2)', 'Allowed', actionList(:,3)', 'Weight', actionList(:,4)');
invariants = struct('Name', {'viewer rules'}, 'Check', {@() fcn_INTERNAL_invariants(viewer)});
end % Ends fcn_INTERNAL_walkActions

function center = fcn_INTERNAL_axesCenter(viewer)
% The model's middle, in the window's pixels (where a drag starts)
box = getpixelposition(viewer.Axes, true);
center = box(1:2) + box(3:4)/2;
end % Ends fcn_INTERNAL_axesCenter

function flagOn = fcn_INTERNAL_onScreen(viewer, tag)
state = viewer.State();
flagOn = state.OnScreen.(tag);
end % Ends fcn_INTERNAL_onScreen

function fcn_INTERNAL_resetAndCheck(viewer)
% Reset view: the starting view, the whole vehicle in view
viewer.Press('overallResetView');
camera = viewer.CameraInfo();
startView = viewer.StartView();
expectedDown = min(max(startView(2), -89), 89);
if abs(mod(camera.DialAngle - startView(1) + 180, 360) - 180) > 0.01 || abs(camera.DownAngle - expectedDown) > 0.01
    error('test:resetView', 'Reset view went to %.2f, %.2f, not the starting view %.2f, %.2f', camera.DialAngle, camera.DownAngle, startView(1), startView(2));
end
if ~fcn_INTERNAL_vehicleInView(viewer)
    error('test:resetView', 'Reset view does not show the whole vehicle (window %s)', mat2str(viewer.Figure.Position(3:4)));
end
end % Ends fcn_INTERNAL_resetAndCheck

function fcn_INTERNAL_resizeAndCheck(viewer, windowSize)
% Resized: the zoom kept (against "the whole vehicle just fits" from the
% camera now); if the whole vehicle was in view, it still is
viewer.Settle();   % (measured once the window has laid itself out)
flagInBefore = fcn_INTERNAL_vehicleInView(viewer);
zoomBefore = viewer.FitInfo().Zoom;
viewer.Resize(windowSize);
zoomAfter = viewer.FitInfo().Zoom;
if flagInBefore && ~fcn_INTERNAL_vehicleInView(viewer)
    error('test:resize', 'Resized to %s: the whole vehicle was in view, and is not now', mat2str(windowSize));
end
if abs(zoomAfter/zoomBefore - 1) > 0.01
    error('test:resize', 'Resized to %s: the zoom went from %.3f to %.3f', mat2str(windowSize), zoomBefore, zoomAfter);
end
end % Ends fcn_INTERNAL_resizeAndCheck

function fcn_INTERNAL_copyQuietly(viewer)
% Copy view call, with the call it prints kept out of the test's output
evalc('viewer.CopyViewCall()');
end % Ends fcn_INTERNAL_copyQuietly

function fcn_INTERNAL_closeViewer(viewer)
% (a viewer window closed, if still open)
if isvalid(viewer.Figure)
    viewer.Close();
end
end % Ends fcn_INTERNAL_closeViewer

function fcn_INTERNAL_exitByMenu(viewer)
% Exit as a user does it: open the ☰ Menu's list if it is closed, then
% press Exit, its last line (Q62 (A))
if ~strcmp(findall(viewer.Figure, 'Tag', 'viewerMenuList').Visible, 'on')
    viewer.Press('viewerMenu');
end
viewer.Press('viewerExit');
end % Ends fcn_INTERNAL_exitByMenu
