% script_test_fcn_CarMesh3D_paintLabels.m
% Tests fcn_CarMesh3D_paintLabels

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_paintLabels
%   % * First write

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_paintLabels
%   % * (none yet)

%% Set up the workspace
close all;
vehicleID = '2009_Honda_Fit_Sport';
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
% (the vehicle's edits file is backed up, and put back at the end)
editsFile = fullfile(vehicleFiles.Folder, sprintf('labelEdits_%s.mat', vehicleID));
backupFolder = tempname;
mkdir(backupFolder);
flagHadEdits = isfile(editsFile);
if flagHadEdits
    copyfile(editsFile, backupFolder);
end
cleanupBackup = onCleanup(@() fcn_INTERNAL_restore(editsFile, backupFolder, flagHadEdits));
% (the vehicle's change log is backed up too, and put back at the end:
% the tests' saves add rows to it)
historyFile = fullfile(vehicleFiles.Folder, sprintf('meshHistory_%s.csv', vehicleID));
historyBackup = [tempname '.csv'];
flagHadHistory = isfile(historyFile);
if flagHadHistory
    copyfile(historyFile, historyBackup);
end
cleanupHistory = onCleanup(@() fcn_INTERNAL_restoreHistory(historyFile, historyBackup, flagHadHistory));
% (the timestamped copies the tests make go to a temporary folder: the folder
% remembered for them is set to it, and put back at the end)
versionFolder = fullfile(tempname, 'meshVersions');
flagHadFolderPref = ispref('CarMesh3D', 'VersionFolder');
folderPrefBefore = '';
if flagHadFolderPref
    folderPrefBefore = getpref('CarMesh3D', 'VersionFolder');
end
setpref('CarMesh3D', 'VersionFolder', versionFolder);
cleanupVersions = onCleanup(@() fcn_INTERNAL_restoreFolderPref(flagHadFolderPref, folderPrefBefore, versionFolder));

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

%% DEMO case: The painter for the 2009 Honda Fit, in its own window (hidden)
fprintf(1,'DEMO case: the painter for the 2009 Honda Fit, in its own window (hidden)\n');
if isfile(editsFile)
    delete(editsFile);   % (start from no edits)
end
[editedMesh, labelEdits, painter] = fcn_CarMesh3D_paintLabels(vehicleID, Visible=false);
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
bodyFaces = find(baseMesh.FacePartIndex == find(strcmp(baseMesh.PartNames,'body')));
picks = bodyFaces([10 200 400 600]);
mirrorBox = findobj(painter.Figure, 'Type', 'uicheckbox', 'Text', 'Mirror to the other side');
mirrorBox.Value = false;
% (four separate selections, each saved: as backup lights)
for ith_pick = 1:4
    painter.Paint('backup', centers(picks(ith_pick),:), false);
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
backupType = find(strcmp(editedMesh.LightTypeNames, 'backup'));
assert(all(editedMesh.FaceLightType(picks(1:2)) == backupType));
% (Revert to start: no edits, not saved; Revert to save: back to two)
painter.RevertToStart();
assert(isempty(painter.Edits()) && ~painter.Status().Saved);
painter.RevertToSaved();
assert(numel(painter.Edits()) == 1 && painter.Status().Saved);
mirrorBox.Value = true;

%% TEST case: Saved paint becomes the working mesh (painted trim looks like the rest of the trim)
fprintf(1,'TEST case: saved paint becomes the working mesh\n');
mirrorBox.Value = false;
trimPick = bodyFaces(300);
painter.SetTool('trim');
painter.Paint('trim', centers(trimPick,:), false);   % (Paint saves)
workingMesh = painter.WorkingMesh();
trimPart = find(strcmp(workingMesh.PartNames, 'trim'));
assert(workingMesh.FacePartIndex(trimPick) == trimPart);          % (it is trim in the working mesh)
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
savedHistory = fcn_CarMesh3D_meshHistory(vehicleID);
assert(strcmp(savedHistory.LastChange.Action, 'label edits saved'));
finePrint = findobj(painter.Figure, 'Tag', 'finePrint');
assert(contains(finePrint.Text, 'Last change: label edits saved') && contains(finePrint.Text, 'License'));
% (Undo still reaches back past the save)
painter.Undo();
assert(painter.Status().Pending == 0 && ~painter.Status().Saved);
painter.Save();
assert(painter.WorkingMesh().FacePartIndex(trimPick) ~= trimPart);
mirrorBox.Value = true;

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
versionsCheck = findobj(painter.Figure, 'Type', 'uicheckbox', 'Text', 'Timestamped copy at each save');
versionsCheck.Value = false;
pause(1.1);
painter.Save();
assert(strcmp(painter.LastVersionFile(), versionFile));          % (box off: no new copy)
versionsCheck.Value = true;
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

%% TEST case: Hidden faces stay in the edited mesh, in a named set, out of view; unhide shows them again
fprintf(1,'TEST case: hiding, and unhiding\n');
hideFaces = bodyFaces(800:805);
statusBefore = painter.Status();
hideField = findall(painter.Figure, 'Type', 'uieditfield', 'Value', 'hidden');
hideField.Value = 'rear wiper';
painter.Paint('hide', centers(hideFaces,:), false);   % (Paint saves)
meshAfter = painter.EditedMesh();
assert(size(meshAfter.Faces,1) == size(baseMesh.Faces,1));                       % (nothing deleted)
assert(any(strcmp(meshAfter.HiddenSetNames, 'rear wiper')));
setIndex = find(strcmp(meshAfter.HiddenSetNames, 'rear wiper'));
assert(all(meshAfter.FaceHiddenSet(hideFaces) == setIndex));
assert(isequal(meshAfter.FacePartIndex(hideFaces), baseMesh.FacePartIndex(hideFaces)));   % (labels kept)
assert(painter.Status().Hidden >= numel(hideFaces));
assert(painter.Status().Applied > statusBefore.Applied);
alphaNow = painter.Patch.FaceVertexAlphaData;
assert(all(alphaNow(hideFaces) == 0), 'Hidden faces out of view');
loaded = load(editsFile, 'labelEditsAfterSimplify');
assert(any(cellfun(@(e) isfield(e,'Hide') && strcmp(e.Hide,'rear wiper'), loaded.labelEditsAfterSimplify)));
% (unhide: shown again)
painter.Paint('unhide', centers(hideFaces,:), false);
meshAfter = painter.EditedMesh();
assert(all(meshAfter.FaceHiddenSet(hideFaces) == 0));
hideField.Value = 'hidden';

%% TEST case: Show boxes hide a label's faces (they cannot be painted)
fprintf(1,'TEST case: Show boxes hide a label''s faces\n');
painter.SetHidden({'part_glass'});
glassFaces = baseMesh.FacePartIndex == find(strcmp(baseMesh.PartNames,'glass'));
alphaShown = painter.Patch.FaceVertexAlphaData;
assert(all(alphaShown(glassFaces) == 0));
painter.SetHidden({});
assert(any(painter.Patch.FaceVertexAlphaData(glassFaces) > 0));
painter.ShowLabel('part_trim');
painter.ShowLabel('all');

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
embedded.Paint('tail', centers(bodyFaces(50),:), false);
assert(paintCount >= 1 && ~isempty(changedMesh));
tailType = find(strcmp(changedMesh.LightTypeNames, 'tail'));
assert(changedMesh.FaceLightType(bodyFaces(50)) == tailType);
embedded.Stop();
delete(hostFigure);

%% Fail conditions
if 1==0
    %% FAIL case: not a vehicle ID or a mesh
    fcn_CarMesh3D_paintLabels(42);
end

clear cleanupBackup cleanupVersions cleanupHistory;   % (puts the vehicle's edits file back, and takes out the tests' timestamped copies)
fprintf(1,'All tests of fcn_CarMesh3D_paintLabels passed\n');

%% Functions follow
function fcn_INTERNAL_restoreHistory(historyFile, historyBackup, flagHadHistory)
% Puts the vehicle's change log back as it was
if flagHadHistory
    copyfile(historyBackup, historyFile);
    delete(historyBackup);
elseif isfile(historyFile)
    delete(historyFile);
end
end % Ends fcn_INTERNAL_restoreHistory

function fcn_INTERNAL_restoreFolderPref(flagHadFolderPref, folderPrefBefore, versionFolder)
% Puts back the folder remembered for timestamped copies, and takes out the
% temporary one the tests used
if flagHadFolderPref
    setpref('CarMesh3D', 'VersionFolder', folderPrefBefore);
elseif ispref('CarMesh3D', 'VersionFolder')
    rmpref('CarMesh3D', 'VersionFolder');
end
if isfolder(fileparts(versionFolder))
    rmdir(fileparts(versionFolder), 's');
end
end % Ends fcn_INTERNAL_restoreFolderPref

function fcn_INTERNAL_restore(editsFile, backupFolder, flagHadEdits)
% Puts the vehicle's edits file back as it was
[~, name, extension] = fileparts(editsFile);
if flagHadEdits
    copyfile(fullfile(backupFolder, [name extension]), editsFile);
elseif isfile(editsFile)
    delete(editsFile);
end
if isfolder(backupFolder)
    rmdir(backupFolder, 's');
end
end % Ends fcn_INTERNAL_restore
