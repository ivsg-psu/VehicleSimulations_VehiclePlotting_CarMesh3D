% script_test_fcn_CarMesh3D_paintLabels.m
% Tests fcn_CarMesh3D_paintLabels

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_paintLabels
%   % * First write
%
% 2026_11_24 (Agent B) by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_paintLabels
%   % * Runs on temporary copies of the vehicles (fcn_CarMesh3D_makeDemoCopy):
%   %   % nothing is saved in a real vehicle's folder any more (it once
%   %   % overwrote the Fit's edits when a run failed)
%   %   % * The vehicles named by fcn_CarMesh3D_demoVehicle (Q35/Q36)
%   %   % * Script-driven tests (Sean, 05:03): every panel and control set
%   %   % through fcn_CarMesh3D_guiDriver; clicks, double-clicks, Ctrl+drags
%   %   % and keys through the window's own handlers; random walks with
%   %   % rules checked after each step; the layout at four window sizes;
%   %   % the saved fixes the painter keeps; closing time
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_paintLabels
%   % * Revert to a timestamped copy (T36): the copies listed newest first,
%   %   % an older copy put back as applied, not saved; Save makes it stick
%   % * Selection as a highlighter (T35): Ctrl+drag over faces already
%   %   % carrying the label picked selects them; the label only previewed;
%   %   % "original"; Undo of an Apply
%   % * The shared menu and Shared GUI settings (the shared-panels design
%   %   % file): Labels To Display over Modify Labels at first, two panels
%   %   % at once (remembered: PainterPanels), the rules for two open
%   %   % panels; Shared GUI settings' Editing rows (timestamped copy at each
%   %   % save, its folder) in place of the old Settings panel, with the
%   %   % preference put back at the end; Review greyed

% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_paintLabels
%   % * Selecting only with Ctrl (Q84 (A)): clicks and double-clicks are
%   %   % made with Ctrl held; plain clicks select nothing; a Ctrl+click
%   %   % selects one face whatever the brush (drafted with Claude)

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_paintLabels
%   % * (none yet)

%% Set up the workspace
close all;
vehicleID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);   % (the repo's demo vehicle: the 2009 Fit)
guiTestID = fcn_CarMesh3D_demoVehicle(Which='guiTest', FigNum=-1);       % (the GUI test vehicle: every feature)
% (every vehicle used is a temporary copy: nothing is saved in a real
% vehicle's folder; the copies are taken away at the end)
demoRoot = tempname;
cleanupDemo = onCleanup(@() fcn_INTERNAL_removeFolder(demoRoot));
demoFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID, DemoFolder=fullfile(demoRoot, 'fit'), FigNum=-1);
vehicleFiles = demoFiles;
editsFile = fullfile(vehicleFiles.Folder, sprintf('labelEdits_%s.mat', vehicleFiles.ID));
originalEdits = [];
if isfile(editsFile)
    originalEdits = load(editsFile, 'labelEditsAfterSimplify');   % (for the kept-fixes test below)
end
% (the timestamped copies the tests make go to a temporary folder: the folder
% remembered for them is set to it, and put back at the end)
versionFolder = fullfile(demoRoot, 'versions', 'meshVersions');
flagHadFolderPref = ispref('CarMesh3D', 'VersionFolder');
folderPrefBefore = '';
if flagHadFolderPref
    folderPrefBefore = getpref('CarMesh3D', 'VersionFolder');
end
setpref('CarMesh3D', 'VersionFolder', versionFolder);
cleanupVersions = onCleanup(@() fcn_INTERNAL_restoreFolderPref(flagHadFolderPref, folderPrefBefore));
% (the panels the painter opens with are remembered, and Shared GUI
% settings' timestamped copies at each save: put back after the tests)
flagHadPanelPref = ispref('CarMesh3D', 'PainterPanels');
panelPrefBefore = '';
if flagHadPanelPref
    panelPrefBefore = getpref('CarMesh3D', 'PainterPanels');
end
cleanupPanel = onCleanup(@() fcn_INTERNAL_restorePanelPref(flagHadPanelPref, panelPrefBefore));
flagHadVersionsPref = ispref('CarMesh3D', 'VersionsAtSave');
versionsPrefBefore = true;
if flagHadVersionsPref
    versionsPrefBefore = getpref('CarMesh3D', 'VersionsAtSave');
end
cleanupVersionsPref = onCleanup(@() fcn_INTERNAL_restorePref('VersionsAtSave', flagHadVersionsPref, versionsPrefBefore));
% (the painter's own controls: every one has a Tag)
painterTags = {'painterMenu', 'painterUndo', 'painterSave', 'painterRevert', 'painterExit', 'painterStatus', 'painterHint', ...
    'menu_OverallDisplay', 'menu_LabelsToDisplay', 'menu_LampsToDisplay', 'menu_ModifyLabels', 'menu_SharedGUIsettings', ...
    'paintAs', 'hideAs', 'mirror', 'showHidden', 'paintApply', 'paintHowTo', ...
    'saveVersion', 'revertToStart', 'editsFileText'};

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

%% DEMO case: The painter for the demo vehicle (a copy), in its own window (hidden)
fprintf(1,'DEMO case: the painter for the demo vehicle (a copy), in its own window (hidden)\n');
if isfile(editsFile)
    delete(editsFile);   % (start from no edits: the copy's file)
end
[editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels(vehicleFiles.Folder, FlagVisible=false);
assert(isgraphics(painter.Figure) && isgraphics(painter.Axes));
assert(isempty(labelEdits));                              % (no edits yet)
assert(size(editedMesh.Faces,1) == size(painter.Patch.Faces,1));
assert(strcmp(painter.EditsFile, editsFile));

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

%% TEST case: Paint, Apply, Undo by steps, Save, Revert
fprintf(1,'TEST case: paint, Apply, Undo by steps, Save, Revert\n');
baseMesh = editedMesh;
centers = (baseMesh.Vertices(baseMesh.Faces(:,1),:) + baseMesh.Vertices(baseMesh.Faces(:,2),:) + baseMesh.Vertices(baseMesh.Faces(:,3),:))/3;
bodyFaces = find(baseMesh.LabelFacePart == find(strcmp(baseMesh.LabelPartNames,'body')));
picks = bodyFaces([10 200 400 600]);
painter.SetFlagMirror(false);
% (four separate selections, each saved: as backup lights)
for ith_pick = 1:4
    painter.Paint('backupLamp', centers(picks(ith_pick),:), false);
end
statusNow = painter.Status();
assert(statusNow.Applied == 4 && statusNow.Pending == 0 && statusNow.Saved && statusNow.UndoSteps == 4);
% (Undo twice: the last two come off, newest first)
painter.Undo();
painter.Undo();
edits = painter.Edits();
assert(numel(edits) == 1 && size(edits{1}.Points,1) == 2);
assert(all(ismember(round(edits{1}.Points,5), round(centers(picks(1:2),:),5), 'rows')));
assert(~painter.Status().Saved);                         % (undone after the save)
painter.Save();
loaded = load(editsFile, 'labelEditsAfterSimplify');
assert(size(loaded.labelEditsAfterSimplify{1}.Points,1) == 2);
% (the edited mesh: the two faces are backup lights)
editedMesh = painter.EditedMesh();
backupType = find(strcmp(editedMesh.LabelLampNames, 'backupLamp'));
assert(all(editedMesh.LabelFaceLamp(picks(1:2)) == backupType));
% (Revert to start: no edits, not saved; Revert to save: back to two)
painter.RevertToStart();
assert(isempty(painter.Edits()) && ~painter.Status().Saved);
painter.RevertToSaved();
assert(numel(painter.Edits()) == 1 && painter.Status().Saved);
painter.SetFlagMirror(true);

%% TEST case: Saved paint becomes the working mesh (painted trim looks like the rest of the trim)
fprintf(1,'TEST case: saved paint becomes the working mesh\n');
painter.SetFlagMirror(false);
trimPick = bodyFaces(300);
painter.SetTool('trim');
painter.Paint('trim', centers(trimPick,:), false);   % (Paint saves)
workingMesh = painter.WorkingMesh();
trimPart = find(strcmp(workingMesh.LabelPartNames, 'trim'));
assert(workingMesh.LabelFacePart(trimPick) == trimPart);          % (it is trim in the working mesh)
% (its color is the one the labels view gives it as trim, not the paint
% color, and it is not drawn as an overlay any more)
expected = fcn_CarMesh3D_plotLabels(painter.EditedMesh(), FigNum=-1);
editedCenters = (expected.Vertices(expected.Faces(:,1),:) + expected.Vertices(expected.Faces(:,2),:) + expected.Vertices(expected.Faces(:,3),:))/3;
[~, editedIndex] = min(sum((editedCenters - centers(trimPick,:)).^2, 2));
assert(max(abs(workingMesh.LabelColors(trimPick,:) - expected.FaceColors(editedIndex,:))) < 1e-9);
assert(max(abs(painter.Patch.FaceVertexCData(trimPick,:) - expected.FaceColors(editedIndex,:))) < 1e-9);
appliedOverlay = findobj(painter.Axes, 'Tag', 'appliedPaint');
assert(isempty(appliedOverlay.Faces));                             % (saved: no overlay)
% (the save is in the vehicle's change log, and the viewer's fine print)
savedHistory = fcn_CarMesh3D_meshHistory(vehicleFiles.Folder);
assert(strcmp(savedHistory.LastChange.Action, 'label edits saved'));
finePrint = findobj(painter.Figure, 'Tag', 'finePrint');
assert(contains(finePrint.Text, 'Last change: label edits saved') && contains(finePrint.Text, 'License'));
% (Undo still reaches back past the save)
painter.Undo();
assert(painter.Status().Pending == 0 && ~painter.Status().Saved);
painter.Save();
assert(painter.WorkingMesh().LabelFacePart(trimPick) ~= trimPart);
painter.SetFlagMirror(true);

%% TEST case: Timestamped copies: Save as version, and at each save with the box ticked
fprintf(1,'TEST case: timestamped copies\n');
assert(strcmp(painter.VersionFolder(), versionFolder));        % (the remembered folder)
versionFile = painter.SaveVersion();
assert(isfile(versionFile));
assert(strcmp(fileparts(versionFile), versionFolder));
[~, versionName] = fileparts(versionFile);
[~, meshName] = fileparts(vehicleFiles.MeshFile);
assert(~isempty(regexp(versionName, ['^' regexptranslate('escape', meshName) '_\d{14}$'], 'once')));
saved = load(versionFile);
assert(isfield(saved, 'vehicleMesh') && isfield(saved, 'labelEditsAfterSimplify'));
assert(isequal(size(saved.vehicleMesh.Faces), size(painter.EditedMesh().Faces)));
painter.SetVersions(false);
pause(1.1);
painter.Save();
assert(strcmp(painter.LastVersionFile(), versionFile));          % (box off: no new copy)
painter.SetVersions(true);
pause(1.1);
painter.Save();
assert(~strcmp(painter.LastVersionFile(), versionFile) && isfile(painter.LastVersionFile()));
% (a folder typed into the window: used, and remembered)
otherFolder = fullfile(fileparts(versionFolder), 'otherCopies');
folderField = findobj(painter.Figure, 'Type', 'uieditfield', 'Value', versionFolder);
folderField.Value = otherFolder;
folderField.ValueChangedFcn(folderField, []);
assert(strcmp(painter.VersionFolder(), otherFolder) && strcmp(getpref('CarMesh3D', 'VersionFolder'), otherFolder));
versionFile = painter.SaveVersion();
assert(strcmp(fileparts(versionFile), otherFolder) && isfile(versionFile));
painter.SetVersionFolder(versionFolder);

%% TEST case: Revert to a timestamped copy (T36, Sean 2026-11-24 15:14: Revert lists the saves to go back to)
fprintf(1,'TEST case: revert to a timestamped copy\n');
pause(1.1);
copyA = painter.SaveVersion();
paintA = painter.Layers().Paint;
pause(1.1);   % (the save below keeps its own timestamped copy: in the same second it would replace copyA; a flaky failure, 2026-11-24)
painter.SetFlagMirror(false);
painter.Paint('backupLamp', centers(picks(3),:), false);   % (one more face, saved)
pause(1.1);
copyB = painter.SaveVersion();
paintB = painter.Layers().Paint;
assert(~isequal(paintA, paintB), '(set-up) the two copies differ');
copies = painter.SavedCopies();
assert(height(copies) >= 2 && issorted(copies.Saved, 'descend') && strcmp(copies.File{1}, copyB) && any(strcmp(copies.File, copyA)), ...
    'The copies are listed, newest first');
painter.RevertToCopy(copyA);
assert(isequal(painter.Layers().Paint, paintA) && isequal(painter.Layers().Applied, paintA), 'Back to the older copy''s paint, applied');
assert(painter.IsUnsaved() && ~painter.Status().Saved, 'A copy put back is not saved yet');
painter.RevertToSaved();
assert(isequal(painter.Layers().Paint, paintB) && ~painter.IsUnsaved(), 'Revert to the last save still works');
painter.RevertToCopy(copyA);
painter.Save();
loaded = load(editsFile, 'labelEditsAfterSimplify');
assert(isequal(painter.Layers().Saved, paintA) && ~isempty(loaded.labelEditsAfterSimplify), 'Saving makes the older copy stick');
painter.SetFlagMirror(true);

%% TEST case: Hidden faces stay in the edited mesh, in a named set, out of view; unhide shows them again
fprintf(1,'TEST case: hiding, and unhiding\n');
hideFaces = bodyFaces(800:805);
statusBefore = painter.Status();
hideField = findall(painter.Figure, 'Type', 'uieditfield', 'Value', 'hidden');
hideField.Value = 'rear wiper';
painter.Paint('hide', centers(hideFaces,:), false);   % (Paint saves)
meshAfter = painter.EditedMesh();
assert(size(meshAfter.Faces,1) == size(baseMesh.Faces,1));                       % (nothing deleted)
assert(any(strcmp(meshAfter.LabelHiddenSetNames, 'rear wiper')));
setIndex = find(strcmp(meshAfter.LabelHiddenSetNames, 'rear wiper'));
assert(all(meshAfter.LabelFaceHiddenSet(hideFaces) == setIndex));
assert(isequal(meshAfter.LabelFacePart(hideFaces), baseMesh.LabelFacePart(hideFaces)));   % (labels kept)
assert(painter.Status().Hidden >= numel(hideFaces));
assert(painter.Status().Applied > statusBefore.Applied);
alphaNow = painter.Patch.FaceVertexAlphaData;
assert(all(alphaNow(hideFaces) == 0), 'Hidden faces out of view');
loaded = load(editsFile, 'labelEditsAfterSimplify');
assert(any(cellfun(@(e) isfield(e,'Hide') && strcmp(e.Hide,'rear wiper'), loaded.labelEditsAfterSimplify)));
% (unhide: shown again)
painter.Paint('unhide', centers(hideFaces,:), false);
meshAfter = painter.EditedMesh();
assert(all(meshAfter.LabelFaceHiddenSet(hideFaces) == 0));
hideField.Value = 'hidden';

%% TEST case: Show boxes hide a label's faces (they cannot be painted)
fprintf(1,'TEST case: Show boxes hide a label''s faces\n');
painter.SetHidden({'part_glass'});
glassFaces = baseMesh.LabelFacePart == find(strcmp(baseMesh.LabelPartNames,'glass'));
alphaShown = painter.Patch.FaceVertexAlphaData;
assert(all(alphaShown(glassFaces) == 0));
painter.SetHidden({});
assert(any(painter.Patch.FaceVertexAlphaData(glassFaces) > 0));
painter.ShowLabel('part_trim');
painter.ShowLabel('all');

%% TEST case: The menu and the panels (the design file's layout; the shared menu, two panels at once)
fprintf(1,'TEST case: the menu and the panels\n');
panelNames = {'Overall Display', 'Labels To Display', 'Lamps To Display', 'Modify Labels', 'Lamp Functions', 'Shared GUI settings'};
assert(isequal(painter.OpenNames(), {'Labels To Display', 'Modify Labels'}) || flagHadPanelPref, ...
    'It opens with Labels To Display over Modify Labels');
for ith_panel = 1:numel(panelNames)
    painter.OpenPanels(panelNames(ith_panel));
    assert(strcmp(painter.Panel(), panelNames{ith_panel}));
    shownPanels = findall(painter.Figure, 'Type', 'uipanel', 'Visible', 'on', 'Tag', panelNames{ith_panel});
    assert(numel(shownPanels) == 1);
    for ith_other = setdiff(1:numel(panelNames), ith_panel)
        assert(isempty(findall(painter.Figure, 'Type', 'uipanel', 'Visible', 'on', 'Tag', panelNames{ith_other})));
    end
end
assert(isequal(cellstr(getpref('CarMesh3D', 'PainterPanels')), {'Shared GUI settings'}));    % (remembered)
painter.OpenPanel('Modify Labels');
assert(isequal(painter.OpenNames(), {'Shared GUI settings', 'Modify Labels'}), 'Two panels at once, the second under the first');
assert(isequal(cellstr(getpref('CarMesh3D', 'PainterPanels')), {'Shared GUI settings', 'Modify Labels'}));    % (both remembered)
% (Shared GUI settings in the painter: Review greyed, Editing used)
assert(strcmp(findall(painter.Figure, 'Tag', 'settingsResetReview').Enable, 'off'), 'Review: greyed in the painter');
assert(strcmp(findall(painter.Figure, 'Tag', 'settingsResetEditing').Enable, 'on'), 'Editing: used by the painter');
% (check boxes only where one click on or off is wanted: the lamps in
% Lamps To Display (Sean's Fit feedback); every other on/off choice is a pair
% of radio buttons)
for ith_panel = 1:numel(panelNames)
    boxes = findall(findall(painter.Figure, 'Type', 'uipanel', 'Tag', panelNames{ith_panel}), 'Type', 'uicheckbox');
    assert(isempty(boxes) || all(startsWith({boxes.Tag}, {'lamp_', 'lampOnlyLit', 'lampGroup'})), 'Check boxes only for the lamps');
end
% (the Lamp Functions panel: the matrix window, made when first opened,
% driving the painter's view; the lamp-functions plan, item 5)
painter.OpenPanels({'Lamp Functions'});
lampEditor = painter.LampEditor();
assert(isstruct(lampEditor) && height(lampEditor.Table()) == numel(lampEditor.Units()), 'The matrix window in its panel');
assert(~isempty(findall(painter.Figure, 'Tag', 'lampTable')), 'Its table drawn');
lampEditor.SetSignal('TurnLeft');
assert(~isempty(findall(painter.Axes, 'Tag', 'lampOutline')), 'The edited signal''s lamps outlined on the painter''s model');
painter.Viewer.SetFlagNight(false);
% (Labels To Display: Colored? No draws a label plain gray)
glassIndex = find(strcmp(baseMesh.LabelPartNames, 'glass'));
glassFaces = find(baseMesh.LabelFacePart == glassIndex);
coloredGroup = findall(painter.Figure, 'Tag', 'colored_part_glass');
noButton = findobj(coloredGroup.Children, 'flat', 'UserData', false);
coloredGroup.SelectedObject = noButton;
coloredGroup.SelectionChangedFcn(coloredGroup, struct('NewValue', noButton));
assert(isequal(painter.Viewer.Uncolored(), {'part_glass'}));
assert(all(abs(painter.Patch.FaceVertexCData(glassFaces(1),:) - [0.88 0.88 0.88]) < 1e-9));
allColored = findall(painter.Figure, 'Tag', 'allColored');
assert(isnan(allColored.SelectedObject.UserData));                     % (the rows differ: none shown)
yesButton = findobj(allColored.Children, 'flat', 'UserData', true);
allColored.SelectionChangedFcn(allColored, struct('NewValue', yesButton));
assert(isempty(painter.Viewer.Uncolored()));
% (Lamps To Display: the tail lights on, and the buttons follow the viewer)
tailGroup = findall(painter.Figure, 'Tag', 'lamp_Tail');
onButton = findobj(tailGroup.Children, 'flat', 'UserData', 'on');
tailGroup.SelectionChangedFcn(tailGroup, struct('NewValue', onButton));
assert(painter.Viewer.NightLights().Tail && ~painter.Viewer.NightLights().Brake);
painter.Viewer.SetNightLamp('All', false);
assert(strcmp(tailGroup.SelectedObject.UserData, 'off'));
% (the viewer's sun/moon button, pressed: the painter's Nighttime view?
% follows; Q89 (A), 2026-11-26)
dayNightButton = findall(painter.Figure, 'Type', 'uibutton', 'Tag', 'dayNightButton');
assert(isscalar(dayNightButton), 'The sun/moon button is in the painter too');
painterMenuButton = findall(painter.Figure, 'Type', 'uibutton', 'Tag', 'painterMenu');
assert(dayNightButton.Parent == painterMenuButton.Parent && ...
    dayNightButton.Layout.Column == numel(dayNightButton.Parent.ColumnWidth), ...
    'The sun/moon button at the top right, in the bar with the Menu (T86)');
nightBefore = painter.Viewer.FlagNight();
dayNightButton.ButtonPushedFcn(dayNightButton, []);
assert(painter.Viewer.FlagNight() ~= nightBefore, 'One click switches day and night');
nightRow = findall(painter.Figure, 'Type', 'uibuttongroup', 'Tag', 'overallNight');
if isscalar(nightRow)
    assert(isequal(nightRow.SelectedObject.UserData, painter.Viewer.FlagNight()), 'Nighttime view? follows the button');
end
dayNightButton.ButtonPushedFcn(dayNightButton, []);
assert(painter.Viewer.FlagNight() == nightBefore, 'Another click switches back');
% (Modify Labels: the tool picked shows as its radio button)
painter.SetTool('trim');
paintGroup = findall(painter.Figure, 'Tag', 'paintAs');
assert(strcmp(paintGroup.SelectedObject.UserData, 'trim'));
painter.SetTool('');
assert(isempty(paintGroup.SelectedObject.UserData));
painter.OpenPanels({'Modify Labels'});

%% TEST case: The GUI test vehicle (every lamp type, covers, interior objects, two hidden sets, photos)
fprintf(1,'TEST case: the GUI test vehicle\n');
guiTestFiles = fcn_CarMesh3D_makeDemoCopy(guiTestID, DemoFolder=fullfile(demoRoot, 'guiTest1'), FigNum=-1);   % (a temporary copy: the test saves nothing in the vehicle)
[~, ~, testPainter] = fcn_CarMesh3D_paintLabels(guiTestFiles.Folder, FlagVisible=false);
assert(all(ismember({'headlamp','highBeamLamp','turnSignalLamp','runningLamp','tailBrakeLamp','backupLamp'}, testPainter.Viewer.LampTypes())));
for panelName = {'Labels To Display', 'Lamps To Display'}
    thisPanel = findall(testPainter.Figure, 'Type', 'uipanel', 'Tag', panelName{1});
    assert(isempty(findall(thisPanel, 'Type', 'uilabel', 'FontAngle', 'italic')), 'A gray (no faces) name in %s', panelName{1});
end
testMesh = testPainter.EditedMesh();
assert(all(ismember({'hidden','hard top'}, testMesh.LabelHiddenSetNames)));
flagHiddenFaces = testMesh.LabelFaceHiddenSet(:) > 0;
assert(all(testPainter.Patch.FaceVertexAlphaData(flagHiddenFaces) == 0));      % (hidden: out of view)
testPainter.SetFlagShowHidden(true);
assert(all(testPainter.Patch.FaceVertexAlphaData(flagHiddenFaces) > 0));       % (shown, to unhide)
testPainter.SetFlagShowHidden(false);
interiorIndex = find(strcmp(testMesh.LabelPartNames, 'interior'));
assert(any(testMesh.LabelFacePart == interiorIndex));
assert(any(sum(testMesh.LabelFaceAlsoLamps, 2) > 1));                           % (a lamp with two functions)
testPainter.SetPhotoAngle(95);
assert(testPainter.PhotoAngle() == 90);                                         % (its own photos, every 30 degrees)
testPainter.Close();
assert(~isgraphics(testPainter.Figure));

%% TEST case: The photo dial
fprintf(1,'TEST case: the photo dial\n');
if isfolder(fullfile(vehicleFiles.Folder, 'photos')) && ~isempty(dir(fullfile(vehicleFiles.Folder, 'photos', 'ViewInDegrees_090.jpg')))
    painter.SetPhotoAngle(95);
    assert(painter.PhotoAngle() == 90);
end
painter.Close();
assert(~isgraphics(painter.Figure));

%% TEST case: Inside a parent panel (as the Model Reviewer uses it), with a mesh given
fprintf(1,'TEST case: inside a parent panel, with a mesh given\n');
hostFigure = uifigure('Visible', 'off', 'Position', [50 50 1400 850]);
hostPanel = uipanel(hostFigure, 'Position', [10 10 1380 830]);
paintCount = 0;
changedMesh = [];
[~, ~, embedded] = fcn_CarMesh3D_paintLabels(baseMesh, Parent=hostPanel, ...
    OnPaint=@() evalin('base', 'paintCount = paintCount + 1;'), OnChange=@(meshNow) assignin('base', 'changedMesh', meshNow));
assert(isequal(embedded.Figure, hostFigure));
assert(isempty(embedded.EditsFile));                      % (a mesh given: no edits file)
embedded.Paint('tailBrakeLamp', centers(bodyFaces(50),:), false);
assert(paintCount >= 1 && ~isempty(changedMesh));
tailType = find(strcmp(changedMesh.LabelLampNames, 'tailBrakeLamp'));
assert(changedMesh.LabelFaceLamp(bodyFaces(50)) == tailType);
embedded.Stop();
delete(hostFigure);

%% TEST case: Script-driven: every control of the painter's own has a Tag; the hooks drive the window
fprintf(1,'TEST case: Tags, and the window driven by script\n');
guiFiles = fcn_CarMesh3D_makeDemoCopy(guiTestID, DemoFolder=fullfile(demoRoot, 'guiTest2'), FigNum=-1);
[~, ~, gp] = fcn_CarMesh3D_paintLabels(guiFiles.Folder, FlagVisible=false);
state = gp.State();
missingTags = setdiff(painterTags, state.Tags);
assert(isempty(missingTags), 'Controls missing their Tags: %s', strjoin(missingTags, ', '));
% (every clickable control in the painter's own parts has a Tag; the
% display panels and the viewer are fcn_CarMesh3D_makeDisplayPanels' and
% fcn_CarMesh3D_viewLabels')
parts = gp.Parts();
ownPanels = parts.Panels(ismember(parts.PanelNames, {'Modify Labels', 'Shared GUI settings'}));
untagged = {};
for container = [{parts.TopBar, parts.MenuList}, num2cell(ownPanels)]
    for control = reshape(findall(container{1}), 1, [])
        flagClickable = isa(control, 'matlab.ui.control.Button') || isa(control, 'matlab.ui.container.ButtonGroup') ...
            || isa(control, 'matlab.ui.control.EditField') || isa(control, 'matlab.ui.control.StateButton');
        if flagClickable && isempty(control.Tag)
            untagged{end+1} = sprintf('%s "%s"', class(control), char(string(control.Text))); %#ok<SAGROW>
        end
    end
end
assert(isempty(untagged), 'Untagged controls: %s', strjoin(untagged, '; '));
problems = gp.CheckLayout();
notes = problems(strcmp(problems.Severity, 'note'), :);
fprintf(1, '    untagged controls the layout check notes (all outside the painter''s own parts): %d\n', height(notes));

%% TEST case: Script-driven: the menu opens, each panel opens from it, and the panel opened again closes
fprintf(1,'TEST case: the menu and every panel, through the menu''s buttons\n');
gp.OpenPanels({});
for ith_panel = 1:numel(parts.PanelNames)
    panelName = parts.PanelNames{ith_panel};
    if ~gp.MenuOpen()
        state = gp.Press('painterMenu');
    end
    assert(gp.MenuOpen(), 'The menu opened');
    menuTag = ['menu_' strrep(panelName, ' ', '')];
    assert(state.OnScreen.(menuTag), 'The menu''s %s is on screen', panelName);
    state = gp.Press(menuTag);
    assert(any(strcmp(gp.OpenNames(), panelName)) && numel(gp.OpenNames()) <= 2 && ~gp.MenuOpen(), ...
        'The panel %s opened (up to two open) and the menu closed', panelName);
    fcn_INTERNAL_checkPanels(gp);
end
% (the open panel picked again from the menu: it closes)
gp.Press('painterMenu');
gp.Press(['menu_' strrep(parts.PanelNames{end}, ' ', '')]);
assert(~any(strcmp(gp.OpenNames(), parts.PanelNames{end})), 'Picking an open panel again closes it');
fcn_INTERNAL_checkPanels(gp);
% (the menu button twice: open, then closed)
gp.Press('painterMenu');
assert(gp.MenuOpen());
gp.Press('painterMenu');
assert(~gp.MenuOpen());
gp.OpenPanels({'Modify Labels'});

%% TEST case: Script-driven: every control of Modify Labels and Settings set to each value
fprintf(1,'TEST case: every value of every control in Modify Labels and Settings\n');
paintGroup = findall(gp.Figure, 'Tag', 'paintAs');
radios = findall(paintGroup, 'Type', 'uiradiobutton');
for ith_radio = 1:numel(radios)
    value = radios(ith_radio).UserData;
    if isempty(value)
        gp.SetState('paintAs', radios(ith_radio).Text);   % ("none": by its text)
    else
        gp.SetState('paintAs', value);
    end
    assert(strcmp(gp.Status().Tool, value), 'Paint as %s', radios(ith_radio).Text);
    fcn_INTERNAL_checkRules(gp);
end
for flagOn = [false true false true]
    gp.SetState('mirror', flagOn);
    assert(gp.FlagMirror() == flagOn);
    gp.SetState('showHidden', flagOn);
    assert(gp.FlagShowHidden() == flagOn);
    fcn_INTERNAL_checkRules(gp);
end
gp.SetState('showHidden', false);
gp.OpenPanels({'Shared GUI settings'});
for flagOn = [false true]
    gp.SetState('settingsVersionsAtSave', flagOn);   % (Shared GUI settings: kept as the preference, put back at the end)
    assert(gp.Versions() == flagOn);
end
otherFolder = fullfile(demoRoot, 'versions', 'typedFolder');
gp.SetState('settingsVersionFolder', otherFolder);
assert(strcmp(gp.VersionFolder(), otherFolder));
gp.SetVersionFolder(versionFolder);
gp.OpenPanels({'Modify Labels'});

%% TEST case: Mouse (the window's own handlers): clicks, a click elsewhere fast, double-clicks
fprintf(1,'TEST case: mouse clicks and double-clicks\n');
gp.SetFlagMirror(false);
gp.SetTool('body');
testMesh = gp.WorkingMesh();
seen = fcn_INTERNAL_seenFaces(gp, testMesh);
assert(numel(seen) >= 20, 'Enough faces in view to click');
face = seen(1);
gp.ClickAt(face, {'control'});
layers = gp.Layers();
assert(layers.Paint(face) == "body" && any(layers.PendingFaces == face), 'A click paints the face under the mouse');
fcn_INTERNAL_checkRules(gp);
gp.ClickAt(face, {'control'});
assert(gp.Layers().Paint(face) == "", 'A second click takes it off');
% (a quick second click on another piece: the system calls it a
% double-click; it paints only the face clicked)
pieceIndex = fcn_INTERNAL_pieceOf(testMesh);
otherFace = seen(find(pieceIndex(seen) ~= pieceIndex(face), 1));
gp.ClickAt(face, {'control'});
gp.MouseDownAt(otherFace, {'control'}, 'open');
gp.MouseUpAt(otherFace);
layers = gp.Layers();
assert(layers.Paint(otherFace) == "body" && nnz(layers.Paint ~= "") == 2, 'A fast click on another piece paints one face, not the piece');
gp.ClearPending();
% (a double-click paints the whole piece; another takes it off)
gp.DoubleClickAt(face, {'control'});
piece = find(pieceIndex == pieceIndex(face));
layers = gp.Layers();
assert(all(layers.Paint(piece) == "body") && nnz(layers.Paint ~= "") == numel(piece), 'A double-click paints the whole piece');
gp.DoubleClickAt(face, {'control'});
assert(nnz(gp.Layers().Paint ~= "") == 0, 'A second double-click takes it off');
% (a click off the model paints nothing)
gp.ClickAt(NaN, {'control'});
assert(nnz(gp.Layers().Paint ~= "") == 0);
fcn_INTERNAL_checkRules(gp);
% (Q84 (A): selecting only with Ctrl. A plain click, or a plain
% double-click, selects nothing; a Ctrl+click selects exactly one face,
% whatever the brush; Ctrl+Shift+click unselects it)
gp.ClickAt(face);
gp.DoubleClickAt(face);
assert(nnz(gp.Layers().Paint ~= "") == 0, 'Plain clicks only turn the model: nothing selected (Q84 (A))');
flagHadBrush = ispref('CarMesh3D', 'PaintBrush');   % (the brush is remembered: put back after)
if flagHadBrush
    brushBefore = getpref('CarMesh3D', 'PaintBrush');
end
brushGroup = findall(gp.Figure, 'Type', 'uibuttongroup', 'Tag', 'paintBrush');
brushLarge = findobj(brushGroup.Children, 'flat', 'Text', 'Large');
brushGroup.SelectedObject = brushLarge;
brushGroup.SelectionChangedFcn(brushGroup, struct('NewValue', brushLarge));
gp.ClickAt(face, {'control'});
assert(isequal(find(gp.Layers().Paint ~= ""), face), 'A Ctrl+click selects exactly one face, even with the large brush');
gp.ClickAt(face, {'control', 'shift'});
assert(nnz(gp.Layers().Paint ~= "") == 0, 'Ctrl+Shift+click unselects it');
% (the brush is a cone from the eye: zoomed in twice as far, it spans half
% the meters, the same on the screen; T86)
brushMetersBefore = gp.BrushMeters();
camzoom(gp.Viewer.Axes, 2);
assert(abs(gp.BrushMeters()/brushMetersBefore - 0.5) < 0.02, 'The brush halves in meters when the view zooms in 2x');
camzoom(gp.Viewer.Axes, 0.5);
brushFine = findobj(brushGroup.Children, 'flat', 'Text', 'Fine');
brushGroup.SelectedObject = brushFine;
brushGroup.SelectionChangedFcn(brushGroup, struct('NewValue', brushFine));
if flagHadBrush
    setpref('CarMesh3D', 'PaintBrush', brushBefore);
else
    rmpref('CarMesh3D', 'PaintBrush');
end

%% TEST case: Mouse: Ctrl+drag paints every face passed over; Ctrl+Shift+drag erases them
fprintf(1,'TEST case: Ctrl+drag and Ctrl+Shift+drag\n');
centers = fcn_INTERNAL_centers(testMesh);
[~, farthest] = max(vecnorm(centers(seen,:) - centers(face,:), 2, 2));
endFace = seen(farthest);
% (only two points: the drag's start and end; the faces between are painted
% too, so a fast drag leaves no gaps)
undoBefore = gp.Status().UndoSteps;
gp.DragAt([centers(face,:); centers(endFace,:)], {'control'});
painted = find(gp.Layers().Paint ~= "");
assert(numel(painted) > 10, 'A Ctrl+drag paints along the drag (%d faces)', numel(painted));
middleFace = gp.FaceAt((centers(face,:) + centers(endFace,:))/2);
if ~isempty(middleFace)
    assert(ismember(middleFace, painted), 'The face under the middle of the drag is painted');
end
statusNow = gp.Status();
assert(statusNow.UndoSteps == undoBefore + 1, 'A stroke is one Undo step');
gp.DragAt([centers(face,:); centers(endFace,:)], {'control', 'shift'});
assert(nnz(gp.Layers().Paint ~= "") == 0, 'Ctrl+Shift+drag over the same faces erases them');
gp.Undo();
assert(isequal(sort(find(gp.Layers().Paint ~= "")), sort(painted)), 'Undo puts the erased stroke back');
gp.ClearPending();
% (a plain drag turns the model, and paints nothing)
viewBefore = gp.Axes.CameraPosition;
gp.DragAt([centers(face,:); centers(endFace,:)]);
assert(~isequal(viewBefore, gp.Axes.CameraPosition) && nnz(gp.Layers().Paint ~= "") == 0, 'A drag turns the model');
gp.Viewer.ResetView();
seen = fcn_INTERNAL_seenFaces(gp, testMesh);
fcn_INTERNAL_checkRules(gp);

%% TEST case: Mouse: faces can be picked after Apply; glass with the glass tool
fprintf(1,'TEST case: picking after Apply; glass\n');
gp.ClickAt(seen(2), {'control'});
gp.Apply();
gp.ClickAt(seen(3), {'control'});
layers = gp.Layers();
assert(layers.Paint(seen(3)) == "body" && any(layers.PendingFaces == seen(3)), 'A click after Apply paints');
assert(layers.Applied(seen(2)) == "body");
gp.DragAt([centers(seen(4),:); centers(seen(5),:)], {'control'});
assert(gp.Layers().Paint(seen(4)) == "body", 'A Ctrl+drag after Apply paints');
fcn_INTERNAL_checkRules(gp);
% (T35, Sean 2026-11-24 15:14 to 15:24: selection is a highlighter, apart
% from labels: a Ctrl+drag over faces that already carry the label picked
% selects them; another label previews on them; Apply puts it on;
% "original" puts back the label as downloaded)
gp.Apply();
appliedNow = find(gp.Layers().Applied == "body");
assert(numel(appliedNow) >= 2 && gp.Status().Pending == 0, '(set-up) faces applied as body');
gp.DragAt([centers(seen(4),:); centers(seen(5),:)], {'control'});
assert(all(ismember(seen([4 5]), gp.Layers().Selected)) && gp.Status().Pending > 0, ...
    'A Ctrl+drag over faces that already carry the label picked selects them (T35)');
gp.SetTool('trim');
assert(gp.Layers().Paint(seen(4)) == "trim" && gp.Layers().Applied(seen(4)) == "body", ...
    'Another label is only previewed on the selection');
gp.ClearPending();
assert(gp.Layers().Paint(seen(4)) == "body", 'Unselected, the faces keep their label');
gp.DragAt([centers(seen(4),:); centers(seen(5),:)], {'control'});
gp.SetTool('original');
gp.Apply();
assert(gp.Layers().Applied(seen(4)) == "" && gp.Status().Pending == 0, '"original" puts back the label as downloaded');
undoNow = gp.Status().UndoSteps;
gp.Undo();
assert(gp.Layers().Applied(seen(4)) == "body" && gp.Status().UndoSteps == undoNow - 1, 'Undo takes back the Apply');
gp.SetTool('body');
fcn_INTERNAL_checkRules(gp);
gp.RevertToStart();
glassIndex = find(strcmp(testMesh.LabelPartNames, 'glass'));
gp.SetTool('glass');
glassSeen = fcn_INTERNAL_seenFaces(gp, testMesh, find(testMesh.LabelFacePart == glassIndex));
assert(~isempty(glassSeen), 'Glass in view');
gp.DoubleClickAt(glassSeen(1), {'control'});
glassPiece = find(pieceIndex == pieceIndex(glassSeen(1)));
assert(all(gp.Layers().Paint(glassPiece) == "glass"), 'A double-click on glass, with the glass tool, paints the window');
gp.ClearPending();
gp.SetTool('body');
assert(~isequal(gp.FaceAt(glassSeen(1)), glassSeen(1)), 'Other tools see through glass (the design)');
gp.ClearPending();

%% TEST case: Keys: Ctrl+Z, Ctrl+S, Esc; the top bar's Revert to save
fprintf(1,'TEST case: keys, and Revert to save\n');
undoBefore = gp.Status().UndoSteps;
gp.ClickAt(seen(1), {'control'});
gp.ClickAt(seen(6), {'control'});
assert(gp.Status().UndoSteps == undoBefore + 2);
gp.Key('z', {'control'});
assert(gp.Status().UndoSteps == undoBefore + 1 && gp.Layers().Paint(seen(6)) == "", 'Ctrl+Z undoes');
gp.Key('s', {'control'});
assert(gp.Status().Saved && ~gp.IsUnsaved(), 'Ctrl+S saves');
savedStatus = gp.Status();
gp.ClickAt(seen(7), {'control'});
gp.Key('escape');
assert(gp.Status().Pending == 0, 'Esc unselects the pending paint');
gp.ClickAt(seen(8), {'control'});
gp.Apply();
gp.Press('painterRevert');   % (hidden: no question)
statusNow = gp.Status();
assert(statusNow.Applied == savedStatus.Applied && statusNow.Pending == 0 && statusNow.Saved, 'Revert to save, from the top bar');
fcn_INTERNAL_checkRules(gp);

%% TEST case: Random walks: every action, in random orders; the rules checked after every step
fprintf(1,'TEST case: random walks\n');
gp.RevertToStart();
gp.Save();
actions = fcn_INTERNAL_walkActions(gp, seen, centers, parts.PanelNames);
rules = struct('Name', {'drawn paint matches the layers', 'status line matches', 'open panel matches', 'the window title'}, ...
    'Check', {@() fcn_INTERNAL_ruleDrawn(gp), @() fcn_INTERNAL_ruleStatus(gp), @() fcn_INTERNAL_rulePanel(gp), @() fcn_INTERNAL_ruleTitle(gp)});
for seed = [1 2 3]
    report = fcn_CarMesh3D_guiRandomWalk(actions, rules, Steps=150, Seed=seed, Name='paintLabels', ...
        LogFolder=fullfile(demoRoot, 'walks'), FigNum=-1);
    if ~report.Passed
        fprintf(1, '    seed %d failed at step %d (%s): %s\n', seed, report.Failures(1).Step, report.Failures(1).Action, report.Failures(1).Message);
        fprintf(1, '    steps: %s\n', strjoin(report.Steps, ' | '));
    end
    assert(report.Passed, 'Random walk %d', seed);
    % (save, then a new painter on the saved file: the same edited mesh)
    gp.Save();
    meshSaved = gp.EditedMesh();
    [reloadedMesh, ~, reloaded] = fcn_CarMesh3D_paintLabels(guiFiles.Folder, FlagVisible=false);
    assert(isequal(reloadedMesh.LabelFacePart, meshSaved.LabelFacePart) && isequal(reloadedMesh.LabelFaceLamp, meshSaved.LabelFaceLamp), ...
        'Walk %d: the saved edits give the same mesh when loaded again', seed);
    if isfield(meshSaved, 'LabelFaceHiddenSet')
        assert(isequal(reloadedMesh.LabelFaceHiddenSet > 0, meshSaved.LabelFaceHiddenSet > 0), 'Walk %d: the same hidden faces', seed);
    end
    reloaded.Close();
end

%% TEST case: Layout at four window sizes, every panel open
fprintf(1,'TEST case: layout at four window sizes\n');
sizes = [1500 900; 800 500; 640 400; 1600 1000];
for ith_size = 1:size(sizes,1)
    gp.SetSize(sizes(ith_size,1), sizes(ith_size,2));
    for ith_panel = 1:numel(parts.PanelNames)
        gp.OpenPanels(parts.PanelNames(ith_panel));
        problems = gp.CheckLayout();
        errors = problems(strcmp(problems.Severity, 'error'), :);
        ownErrors = errors(fcn_INTERNAL_isOwn(errors.Control, painterTags), :);
        if height(errors) > height(ownErrors)
            fprintf(1, '    %dx%d, %s: %d layout errors outside the painter''s own parts (not this test''s to fix)\n', ...
                sizes(ith_size,:), parts.PanelNames{ith_panel}, height(errors) - height(ownErrors));
        end
        if height(ownErrors) > 0
            disp(ownErrors);
        end
        assert(height(ownErrors) == 0, 'Layout errors in the painter''s own parts at %dx%d, %s: %s', sizes(ith_size,1), sizes(ith_size,2), ...
            parts.PanelNames{ith_panel}, strjoin(strcat(ownErrors.Control, ': ', ownErrors.Problem), ' | '));   % (each argument a scalar: a row of sizes broke the message)
    end
end
% (the panels the painter builds scroll, so their last rows can be reached)
for panelName = {'Modify Labels', 'Shared GUI settings'}
    panelHandle = parts.Panels(strcmp(parts.PanelNames, panelName{1}));
    grid = findall(panelHandle, 'Type', 'uigridlayout');
    assert(strcmp(char(grid(end).Scrollable), 'on') || strcmp(char(panelHandle.Scrollable), 'on'), '%s scrolls', panelName{1});
end
gp.SetSize(1500, 900);

%% TEST case: Closing: fast, and no timer left
fprintf(1,'TEST case: closing\n');
closeTimer = tic;
gp.Close();
closeTime = toc(closeTimer);
fprintf(1, '    closed in %.2f s\n', closeTime);
assert(closeTime < 1, 'Closing took %.2f s', closeTime);
assert(~isgraphics(gp.Figure));

%% TEST case: Saved fixes the painter cannot draw (Material, Color, ...) are kept exactly when it saves
fprintf(1,'TEST case: saved fixes kept exactly\n');
assert(~isempty(originalEdits) && numel(originalEdits.labelEditsAfterSimplify) >= 2, ...
    'This test needs a demo vehicle with saved label fixes (the 2009 Fit has 13)');
keptFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID, DemoFolder=fullfile(demoRoot, 'fitKept'), FigNum=-1);
keptEditsFile = fullfile(keptFiles.Folder, sprintf('labelEdits_%s.mat', keptFiles.ID));
before = load(keptEditsFile, 'labelEditsAfterSimplify');
flagScripted = cellfun(@(e) any(ismember(fieldnames(e), {'Material', 'Color', 'AlsoLightTypes', 'AlsoParts', 'Region', 'FaceIndices'})), ...
    before.labelEditsAfterSimplify);
[meshBefore, ~, kp] = fcn_CarMesh3D_paintLabels(keptFiles.Folder, FlagVisible=false);
kp.SetFlagMirror(false);
bodyIndex = find(strcmp(meshBefore.LabelPartNames, 'body'));
bodyFace = find(meshBefore.LabelFacePart == bodyIndex, 1);
kp.Paint('trim', fcn_INTERNAL_centers(meshBefore, bodyFace), false);   % (Paint saves)
after = load(keptEditsFile, 'labelEditsAfterSimplify');
keptAfter = after.labelEditsAfterSimplify(1:nnz(flagScripted));
assert(isequaln(keptAfter, before.labelEditsAfterSimplify(flagScripted)), 'The scripted fixes are saved again exactly, first');
meshAfter = kp.EditedMesh();
others = setdiff(1:size(meshBefore.Faces,1), bodyFace);
assert(isequal(meshAfter.LabelFaceLamp(others), meshBefore.LabelFaceLamp(others)) && isequal(meshAfter.LabelFacePart(others), meshBefore.LabelFacePart(others)), ...
    'Only the painted face changed');
if isfield(meshBefore, 'FaceColors')
    assert(isequal(meshAfter.FaceColors(others,:), meshBefore.FaceColors(others,:)), 'The fixes'' colors are kept');
end
kp.Close();

%% Fail conditions
if 1==0
    %% FAIL case: not a vehicle ID or a mesh
    fcn_CarMesh3D_paintLabels(42);
end

assert(isempty(timerfindall), 'A timer was left running');   % (a window's timer must not outlive it)
clear cleanupVersions cleanupPanel cleanupDemo;   % (puts the preferences back, and takes away the temporary copies)
fprintf(1,'All tests of fcn_CarMesh3D_paintLabels passed\n');

%% Functions follow
function fcn_INTERNAL_removeFolder(folder)
% Takes away the tests' temporary copies (in the computer's temp folder)
if isfolder(folder)
    rmdir(folder, 's');
end
end % Ends fcn_INTERNAL_removeFolder

function fcn_INTERNAL_restoreFolderPref(flagHadFolderPref, folderPrefBefore)
% Puts back the folder remembered for timestamped copies
if flagHadFolderPref
    setpref('CarMesh3D', 'VersionFolder', folderPrefBefore);
elseif ispref('CarMesh3D', 'VersionFolder')
    rmpref('CarMesh3D', 'VersionFolder');
end
end % Ends fcn_INTERNAL_restoreFolderPref

function fcn_INTERNAL_restorePanelPref(flagHadPanelPref, panelPrefBefore)
% Puts back the panels the painter opens with
fcn_INTERNAL_restorePref('PainterPanels', flagHadPanelPref, panelPrefBefore);
end % Ends fcn_INTERNAL_restorePanelPref

function fcn_INTERNAL_restorePref(name, flagHad, valueBefore)
% Puts a preference back as it was: its value, or none
if flagHad
    setpref('CarMesh3D', name, valueBefore);
elseif ispref('CarMesh3D', name)
    rmpref('CarMesh3D', name);
end
end % Ends fcn_INTERNAL_restorePref

function centers = fcn_INTERNAL_centers(vehicleMesh, faceList)
% Face centers (of the listed faces, or all)
if nargin < 2
    faceList = 1:size(vehicleMesh.Faces,1);
end
corners = vehicleMesh.Faces(faceList,:);
centers = (vehicleMesh.Vertices(corners(:,1),:) + vehicleMesh.Vertices(corners(:,2),:) + vehicleMesh.Vertices(corners(:,3),:))/3;
end % Ends fcn_INTERNAL_centers

function seen = fcn_INTERNAL_seenFaces(painter, vehicleMesh, candidates)
% Faces a click on their center picks (in view, not behind others)
if nargin < 3
    candidates = 1:size(vehicleMesh.Faces,1);
end
candidates = candidates(:)';
candidates = candidates(round(linspace(1, numel(candidates), min(numel(candidates), 300))));
flagSeen = arrayfun(@(face) isequal(painter.FaceAt(face), face), candidates);
seen = candidates(flagSeen);
end % Ends fcn_INTERNAL_seenFaces

function pieceIndex = fcn_INTERNAL_pieceOf(vehicleMesh)
% Each face's piece, as the painter's double-click finds it: faces with
% the same label that share a corner
labelCode = double(vehicleMesh.LabelFacePart(:));
flagLight = vehicleMesh.LabelFaceLamp(:) > 0;
labelCode(flagLight) = 100 + double(vehicleMesh.LabelFaceLamp(flagLight));
numFaces = size(vehicleMesh.Faces,1);
faceList = repmat((1:numFaces)', 3, 1);
vertexList = vehicleMesh.Faces(:);
[vertexList, order] = sort(vertexList);
faceList = faceList(order);
flagPair = vertexList(2:end) == vertexList(1:end-1) & labelCode(faceList(2:end)) == labelCode(faceList(1:end-1));
links = graph(faceList([false; flagPair]), faceList([flagPair; false]), [], numFaces);
pieceIndex = conncomp(links)';
end % Ends fcn_INTERNAL_pieceOf

function fcn_INTERNAL_checkRules(painter)
% Every rule of the random walks, now
messages = {fcn_INTERNAL_ruleDrawn(painter), fcn_INTERNAL_ruleStatus(painter), fcn_INTERNAL_rulePanel(painter), fcn_INTERNAL_ruleTitle(painter)};
messages = messages(~cellfun(@isempty, messages));
assert(isempty(messages), strjoin(messages, '; '));
end % Ends fcn_INTERNAL_checkRules

function fcn_INTERNAL_checkPanels(painter)
message = fcn_INTERNAL_rulePanel(painter);
assert(isempty(message), message);
end % Ends fcn_INTERNAL_checkPanels

function message = fcn_INTERNAL_ruleDrawn(painter)
% The yellow-edged (pending) and filled (applied) paint drawn: the faces
% the layers say
message = '';
layers = painter.Layers();
if layers.PendingDrawn ~= numel(layers.PendingFaces)
    message = sprintf('%d pending faces drawn, %d pending', layers.PendingDrawn, numel(layers.PendingFaces));
elseif layers.AppliedDrawn ~= numel(layers.AppliedFaces)
    message = sprintf('%d applied faces drawn, %d applied and not in the working mesh', layers.AppliedDrawn, numel(layers.AppliedFaces));
end
end % Ends fcn_INTERNAL_ruleDrawn

function message = fcn_INTERNAL_ruleStatus(painter)
% The status line says what Status() says
message = '';
statusNow = painter.Status();
text = painter.Layers().StatusText;
expected = {sprintf('%d faces selected, not applied', statusNow.Pending), sprintf('%d changed (%d hidden)', statusNow.Applied, statusNow.Hidden), ...
    sprintf('%d undo steps', statusNow.UndoSteps)};
for ith = 1:numel(expected)
    if ~contains(text, expected{ith})
        message = sprintf('the status line "%s" does not say "%s"', text, expected{ith});
        return;
    end
end
if contains(text, 'not saved') == statusNow.Saved && ~contains(text, 'no edits file')
    message = sprintf('the status line "%s" and Saved = %d disagree', text, statusNow.Saved);
end
end % Ends fcn_INTERNAL_ruleStatus

function message = fcn_INTERNAL_rulePanel(painter)
% The panels shown are those OpenNames() names (at most two), the top one Panel()
message = '';
parts = painter.Parts();
shown = parts.PanelNames(arrayfun(@(p) strcmp(char(p.Visible), 'on'), parts.Panels));
openNames = painter.OpenNames();
if numel(openNames) > 2 || ~isempty(setxor(shown, openNames)) || (~isempty(openNames) && ~strcmp(openNames{1}, painter.Panel()))
    message = sprintf('OpenNames() is "%s" but shown: %s', strjoin(openNames, ', '), strjoin(shown, ', '));
end
end % Ends fcn_INTERNAL_rulePanel

function message = fcn_INTERNAL_ruleTitle(painter)
message = '';
if ~contains(painter.Figure.Name, 'fcn_CarMesh3D_paintLabels')
    message = sprintf('the window''s title is "%s"', painter.Figure.Name);
end
end % Ends fcn_INTERNAL_ruleTitle

function flagOwn = fcn_INTERNAL_isOwn(controlNames, painterTags)
% Layout problems in the painter's own parts (its Tags, or controls in
% Modify Labels, Settings or the menu's list)
flagOwn = ismember(controlNames, painterTags) | contains(controlNames, {'Modify Labels', 'Settings', 'painterMenuList'});
end % Ends fcn_INTERNAL_isOwn

function fcn_INTERNAL_openByMenu(painter, panelName)
% A panel opened as a user does: the menu button, then the panel's name
if ~painter.MenuOpen()
    painter.Press('painterMenu');
end
painter.Press(['menu_' strrep(panelName, ' ', '')]);
end % Ends fcn_INTERNAL_openByMenu

function fcn_INTERNAL_undoCheck(painter, seen)
% A click, then Undo: the layers and the status are as before the click
statusBefore = painter.Status();
layersBefore = painter.Layers();
painter.ClickAt(seen(randi(numel(seen))), {'control'});
if painter.Status().UndoSteps > statusBefore.UndoSteps
    painter.Undo();
    statusAfter = painter.Status();
    layersAfter = painter.Layers();
    assert(isequal(statusAfter, statusBefore) && isequal(layersAfter.Paint, layersBefore.Paint) && isequal(layersAfter.Applied, layersBefore.Applied), ...
        'Undo after a click did not restore the status before it');
end
end % Ends fcn_INTERNAL_undoCheck

function actions = fcn_INTERNAL_walkActions(painter, seen, centers, panelNames)
% Every kind of user action, for the random walks
pick = @() seen(randi(numel(seen)));
pickTwo = @() centers(seen(randi(numel(seen), 2, 1)),:);
modifyOpen = @() any(strcmp(painter.OpenNames(), 'Modify Labels'));
list = cell(0,3);   % (name, what it does, when it can be done: [] for always)
list(end+1,:) = {'click', @() painter.ClickAt(pick(), {'control'}), []};
list(end+1,:) = {'double-click', @() painter.DoubleClickAt(pick(), {'control'}), []};
list(end+1,:) = {'Ctrl+drag', @() painter.DragAt(pickTwo(), {'control'}), []};
list(end+1,:) = {'Ctrl+Shift+drag', @() painter.DragAt(pickTwo(), {'control', 'shift'}), []};
list(end+1,:) = {'click off the model', @() painter.ClickAt(NaN, {'control'}), []};
list(end+1,:) = {'plain click (turns only)', @() painter.ClickAt(pick()), []};
list(end+1,:) = {'Ctrl+Shift+click', @() painter.ClickAt(pick(), {'control', 'shift'}), []};
list(end+1,:) = {'Apply', @() painter.Press('paintApply'), modifyOpen};
list(end+1,:) = {'Undo button', @() painter.Press('painterUndo'), []};
list(end+1,:) = {'Ctrl+Z', @() painter.Key('z', {'control'}), []};
list(end+1,:) = {'Ctrl+S', @() painter.Key('s', {'control'}), []};
list(end+1,:) = {'Save button', @() painter.Press('painterSave'), []};
list(end+1,:) = {'Esc', @() painter.Key('escape'), []};
list(end+1,:) = {'Revert to save button', @() painter.Press('painterRevert'), []};
list(end+1,:) = {'Revert to start', @() painter.RevertToStart(), []};
list(end+1,:) = {'a click, then Undo', @() fcn_INTERNAL_undoCheck(painter, seen), []};
for tool = {'body', 'glass', 'trim', 'wheel', 'tailBrakeLamp', 'headlamp', 'hide', 'unhide'}
    list(end+1,:) = {['paint as ' tool{1}], @() painter.SetState('paintAs', tool{1}), modifyOpen};
end
list(end+1,:) = {'paint as none', @() painter.SetState('paintAs', 'none (rotate only)'), modifyOpen};
list(end+1,:) = {'mirror on', @() painter.SetState('mirror', true), modifyOpen};
list(end+1,:) = {'mirror off', @() painter.SetState('mirror', false), modifyOpen};
list(end+1,:) = {'show hidden on', @() painter.SetState('showHidden', true), modifyOpen};
list(end+1,:) = {'show hidden off', @() painter.SetState('showHidden', false), modifyOpen};
for ith_panel = 1:numel(panelNames)
    panelName = panelNames{ith_panel};
    list(end+1,:) = {['open ' panelName ' (menu)'], @() fcn_INTERNAL_openByMenu(painter, panelName), []};
end
list(end+1,:) = {'menu button', @() painter.Press('painterMenu'), []};
names = list(:,1)'; dos = list(:,2)'; alloweds = list(:,3)';
weights = ones(1, numel(names));
weights(ismember(names, {'click', 'double-click', 'Ctrl+drag', 'paint as body', 'paint as tail', 'open Modify Labels (menu)'})) = 3;
actions = struct('Name', names, 'Do', dos, 'Allowed', alloweds, 'Weight', num2cell(weights));
end % Ends fcn_INTERNAL_walkActions
