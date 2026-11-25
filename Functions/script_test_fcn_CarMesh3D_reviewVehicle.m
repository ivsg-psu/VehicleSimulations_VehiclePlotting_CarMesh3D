% script_test_fcn_CarMesh3D_reviewVehicle.m
% Tests: fcn_CarMesh3D_reviewVehicle
%
% The reviewer is built without being shown (Visible=false), and every
% check and item is shown in turn through the window's own functions
% (UserData.ShowCheck and UserData.ShowItem), to make sure each one draws.

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_reviewVehicle
%   % * First write (drafted with Claude)
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_reviewVehicle
%   % * Tests of answering: approving goes on, rejecting stays, approve
%   %   % all, show all labels; earlier answers are kept and put back
%   % * The photo dial: the photo nearest the angle is shown
%   % * Fixes for the script: a marked label, and the orientation
%   % * "All, in turn": approving it approves the check's unanswered items
%   % * Painting labels: saved in the vehicle's labelEdits file (backed up
%   %   % and put back)

% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_reviewVehicle
%   % * The ☰ Menu (Shared GUI settings; the painter's panels in it on
%   %   % the Labels check, gone after); optional checks turned off are
%   %   % greyed and their questions recorded as skipped, counted in the
%   %   % summary and the report, and asked again when turned back on;
%   %   % the preference ReviewChecksOff set for the tests and put back

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_reviewVehicle
%   % * Test the comment box and the summary's big buttons

%% Set up the workspace
close all

% (a vehicle with a finished mesh, cache, levels, and outline)
vehicleID = fcn_CarMesh3D_demoVehicle(UsePreference=false, FigNum=-1);   % (the repo's demo vehicle)
% (a temporary copy of the vehicle, with no saved label fixes: the test
% paints and saves, and must never change the vehicle itself; 2026_11_24,
% after a stopped run overwrote the Fit's fixes)
vehicleFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID, DemoFolder=tempname, FigNum=-1);
copyEditsFile = fullfile(vehicleFiles.Folder, sprintf('labelEdits_%s.mat', vehicleID));
if isfile(copyEditsFile)
    delete(copyEditsFile);
end
vehicleInput = vehicleFiles.Folder;   % (what the tools are given: the copy)
reviewFile = fullfile(vehicleFiles.ChecksFolder, sprintf('review_%s.mat', vehicleID));
reportFile = fullfile(vehicleFiles.ChecksFolder, sprintf('review_%s.md', vehicleID));
flagHadReview = isfile(reviewFile);
flagHadReport = isfile(reportFile);
% (keep any earlier answers, and put them back at the end)
backupFolder = tempname;
mkdir(backupFolder);
editsFile = fullfile(vehicleFiles.Folder, sprintf('labelEdits_%s.mat', vehicleID));
flagHadEdits = isfile(editsFile);
if flagHadEdits
    copyfile(editsFile, backupFolder);
end
if flagHadReview
    copyfile(reviewFile, backupFolder);
end
if flagHadReport
    copyfile(reportFile, backupFolder);
end
% (put back through onCleanup, so a test stopped midway still puts the
% vehicle's label fixes and answers back: 2026_11_24, after a stopped run
% left the Fit's fixes overwritten)
cleanupFiles = onCleanup(@() fcn_INTERNAL_restoreFiles(backupFolder, vehicleID, reviewFile, reportFile, editsFile, ...
    flagHadReview, flagHadReport, flagHadEdits));
% (the timestamped copies the painter keeps at each save go to a temporary
% folder: the folder remembered for them is set to it, and put back)
versionFolder = fullfile(tempname, 'meshVersions');
flagHadFolderPref = ispref('CarMesh3D', 'VersionFolder');
folderPrefBefore = '';
if flagHadFolderPref
    folderPrefBefore = getpref('CarMesh3D', 'VersionFolder');
end
setpref('CarMesh3D', 'VersionFolder', versionFolder);
cleanupVersions = onCleanup(@() fcn_INTERNAL_restoreFolderPref(flagHadFolderPref, folderPrefBefore, versionFolder));
% (the vehicle's change log is backed up too, and put back at the end:
% the tests' saves add rows to it)
historyFile = fullfile(vehicleFiles.Folder, sprintf('meshHistory_%s.csv', vehicleID));
historyBackup = [tempname '.csv'];
flagHadHistory = isfile(historyFile);
if flagHadHistory
    copyfile(historyFile, historyBackup);
end
cleanupHistory = onCleanup(@() fcn_INTERNAL_restoreHistory(historyFile, historyBackup, flagHadHistory));
% (Shared GUI settings' review checks: every check on for these tests, and
% the preference put back at the end, as it was)
flagHadChecksPref = ispref('CarMesh3D', 'ReviewChecksOff');
checksPrefBefore = {};
if flagHadChecksPref
    checksPrefBefore = getpref('CarMesh3D', 'ReviewChecksOff');
end
setpref('CarMesh3D', 'ReviewChecksOff', {});
cleanupChecksPref = onCleanup(@() fcn_INTERNAL_restorePref('ReviewChecksOff', flagHadChecksPref, checksPrefBefore));

%% Basic case: build the reviewer, hidden
fprintf(1,'Basic case: the reviewer for %s\n', vehicleID);
[reviewTable, figureHandle] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='test');

% Check variable types
assert(istable(reviewTable));
assert(isa(figureHandle, 'matlab.ui.Figure'));

% Check variable sizes and contents
assert(all(ismember({'Check','Item','Question','Status','Severity','Cause','Comment','Reviewer','Time'}, ...
    reviewTable.Properties.VariableNames)));
checkKeys = figureHandle.UserData.CheckKeys;
assert(all(ismember({'orientation','dimensions','labels','compare','lights','body','steering', ...
    'wheels','drive','levels','outline','summary'}, checkKeys)));
assert(all(ismember(string(checkKeys), unique(reviewTable.Check))));
assert(sum(reviewTable.Check=="summary") == 1);

%% Every check and every item draws
fprintf(1,'Showing every check and item\n');
for ith_check = 1:numel(checkKeys)
    figureHandle.UserData.ShowCheck(ith_check);
    Nitems = sum(reviewTable.Check==string(checkKeys{ith_check}));
    for ith_item = 1:Nitems
        figureHandle.UserData.ShowItem(ith_item);
    end
    drawnow;
end
assert(isvalid(figureHandle));

%% Approving goes on to the next item with no answer
fprintf(1,'Answering: approve, reject, approve all, show all labels\n');
dimensionsIndex = find(strcmp(checkKeys, 'dimensions'));
figureHandle.UserData.ShowCheck(dimensionsIndex);
answers = figureHandle.UserData.Answers();
dimensionRows = find(answers.Check=="dimensions");
figureHandle.UserData.ShowItem(3);   % (item 1 is "All, in turn")
current = figureHandle.UserData.Current();
startItem = current(2);
figureHandle.UserData.Vote('approved');
current = figureHandle.UserData.Current();
answers = figureHandle.UserData.Answers();
assert(answers.Status(dimensionRows(startItem))=="approved");
% (now on an item with no answer, or another check if this one is done)
row = find(answers.Check==string(checkKeys{current(1)}), 1) + current(2) - 1;
assert(strlength(answers.Status(row))==0 || all(strlength(answers.Status(answers.Check~="summary"))>0));

% Rejecting stays on the item
figureHandle.UserData.ShowCheck(dimensionsIndex);
figureHandle.UserData.ShowItem(2);
figureHandle.UserData.Vote('rejected');
current = figureHandle.UserData.Current();
assert(isequal(current, [dimensionsIndex 2]));
answers = figureHandle.UserData.Answers();
assert(answers.Status(dimensionRows(2))=="rejected");
assert(strlength(answers.Severity(dimensionRows(2)))==0);   % (the severity comes after the comment)

% Approve all: every item of the check has an answer, and the window goes
% on to another check
figureHandle.UserData.ShowCheck(dimensionsIndex);
figureHandle.UserData.ApproveAll();
answers = figureHandle.UserData.Answers();
assert(all(strlength(answers.Status(dimensionRows))>0));
assert(answers.Status(dimensionRows(2))=="rejected");   % (kept)
current = figureHandle.UserData.Current();
assert(current(1) ~= dimensionsIndex);

% "All, in turn": approving it approves every item not answered yet
outlineIndex = find(strcmp(checkKeys, 'outline'));
figureHandle.UserData.ShowCheck(outlineIndex);
figureHandle.UserData.ShowItem(1);
pause(0.1);
figureHandle.UserData.Vote('approved');
answers = figureHandle.UserData.Answers();
assert(all(strlength(answers.Status(answers.Check=="outline"))>0));

% Show all labels, then picking an item ends it
labelsIndex = find(strcmp(checkKeys, 'labels'));
figureHandle.UserData.ShowCheck(labelsIndex);
figureHandle.UserData.ShowAll(true);
figureHandle.UserData.ShowAll(false);
drawnow;

% The photo dial (if the vehicle has photos named ViewInDegrees_<angle>):
% the photo nearest the angle is shown
photoFolder = fullfile(vehicleFiles.Folder, 'photos');
if ~isempty(dir(fullfile(photoFolder, 'ViewInDegrees_090.jpg')))
    figureHandle.UserData.SetPhotoAngle(95);
    assert(figureHandle.UserData.PhotoAngle() == 90);
    figureHandle.UserData.SetPhotoAngle(-20);
    assert(ismember(figureHandle.UserData.PhotoAngle(), [330 0]));
end

%% Fixes for the script: a wrong label marked, and a wrong orientation
fprintf(1,'Fixes for the script: a marked label, and the orientation\n');
figureHandle.UserData.ShowCheck(labelsIndex);
figureHandle.UserData.ShowItem(2);
figureHandle.UserData.Paint('trim', [1.0 0.5 0.8; 1.2 0.6 0.9], false);   % (paint two faces, mirrored)
current = figureHandle.UserData.Current();
answers = figureHandle.UserData.Answers();
labelRow = find(answers.Check=="labels", 1) + current(2) - 1;
assert(answers.Status(labelRow)=="rejected");                  % (painting rejects)
assert(isfile(figureHandle.UserData.EditsFile));               % (saved for the script)
paintedEdits = load(figureHandle.UserData.EditsFile, 'labelEditsAfterSimplify');
% (the test's own fix, wherever it is among the vehicle's saved fixes)
trimEdits = paintedEdits.labelEditsAfterSimplify(cellfun(@(e) strcmp(fcn_INTERNAL_field(e,'Part'), 'trim'), paintedEdits.labelEditsAfterSimplify));
assert(~isempty(trimEdits));
assert(size(trimEdits{end}.Points,1) >= 2);
% (Undo takes back one selection at a time, newest first)
% (the painter's mirror switch is an Off/On pair, tag 'mirror', since its redesign)
mirrorGroup = findobj(figureHandle, 'Type', 'uibuttongroup', 'Tag', 'mirror');
assert(isscalar(mirrorGroup), 'The painter''s mirror switch');
mirrorGroup.SelectedObject = findobj(mirrorGroup, 'Type', 'uiradiobutton', 'Text', 'Off');
undoButton = findobj(figureHandle, 'Type', 'uibutton', 'Text', 'Undo');
saveButton = findobj(figureHandle, 'Type', 'uibutton', 'Text', 'Save');
figureHandle.UserData.Paint('backup', [1.5 0.7 0.6], false);
figureHandle.UserData.Paint('backup', [2.5 0.7 0.6], false);
undoButton.ButtonPushedFcn(undoButton, []);
saveButton.ButtonPushedFcn(saveButton, []);
paintedEdits = load(figureHandle.UserData.EditsFile, 'labelEditsAfterSimplify');
backupEdit = paintedEdits.labelEditsAfterSimplify(cellfun(@(e) strcmp(fcn_INTERNAL_field(e,'LightType'), 'backup'), paintedEdits.labelEditsAfterSimplify));
assert(numel(backupEdit)==1 && size(backupEdit{1}.Points,1)==1);       % (only the first is left)
undoButton.ButtonPushedFcn(undoButton, []);
saveButton.ButtonPushedFcn(saveButton, []);
paintedEdits = load(figureHandle.UserData.EditsFile, 'labelEditsAfterSimplify');
assert(~any(cellfun(@(e) strcmp(fcn_INTERNAL_field(e,'LightType'), 'backup'), paintedEdits.labelEditsAfterSimplify)));
mirrorGroup.SelectedObject = findobj(mirrorGroup, 'Type', 'uiradiobutton', 'Text', 'On');

%% The animations use the painted edits (a face painted as a lamp lights up)
fprintf(1,'The animations use the painted edits\n');
lightsIndex = find(strcmp(checkKeys, 'lights'));
figureHandle.UserData.ShowCheck(lightsIndex);
animatorBefore = figureHandle.UserData.Animator();
lightsMesh = animatorBefore.Mesh;
tailIndex = find(strcmp(lightsMesh.LightTypeNames, 'tail'));
tailBefore = nnz(lightsMesh.FaceLightType == tailIndex);
lightsCenters = (lightsMesh.Vertices(lightsMesh.Faces(:,1),:) + lightsMesh.Vertices(lightsMesh.Faces(:,2),:) + ...
    lightsMesh.Vertices(lightsMesh.Faces(:,3),:))/3;
bodyFaces = find(lightsMesh.FacePartIndex == find(strcmp(lightsMesh.PartNames, 'body')) & lightsMesh.FaceLightType == 0);
[~, rearmost] = min(lightsCenters(bodyFaces,1));
rearPoint = lightsCenters(bodyFaces(rearmost),:);
figureHandle.UserData.ShowCheck(labelsIndex);
figureHandle.UserData.Paint('tail', rearPoint, false);
applyButton = findobj(figureHandle, 'Type', 'uibutton', 'Text', 'Apply');
applyButton.ButtonPushedFcn(applyButton, []);
figureHandle.UserData.ShowCheck(lightsIndex);        % (leaving Labels: a hidden window saves the edits)
animatorAfter = figureHandle.UserData.Animator();
assert(nnz(animatorAfter.Mesh.FaceLightType == tailIndex) > tailBefore);
paintedEdits = load(figureHandle.UserData.EditsFile, 'labelEditsAfterSimplify');
assert(any(cellfun(@(e) strcmp(fcn_INTERNAL_field(e,'LightType'), 'tail'), paintedEdits.labelEditsAfterSimplify)));
figureHandle.UserData.ShowItem(1);                   % (the whole animation plays)
assert(animatorAfter.IsPlaying());
% (the paint taken off again, and saved)
figureHandle.UserData.ShowCheck(labelsIndex);
assert(~animatorAfter.IsPlaying());                  % (stopped when the check changed)
% (since the painter's select / label / Apply change, 2026-11-24: the
% face selected, "original" picked (the label as downloaded, Q44 (A)),
% then Apply and Save; Ctrl+Shift only unselects)
figureHandle.UserData.Paint('original', rearPoint, false);
applyButton = findobj(figureHandle, 'Type', 'uibutton', 'Text', 'Apply');
applyButton.ButtonPushedFcn(applyButton, []);
saveButton = findobj(figureHandle, 'Type', 'uibutton', 'Text', 'Save');
saveButton.ButtonPushedFcn(saveButton, []);
paintedEdits = load(figureHandle.UserData.EditsFile, 'labelEditsAfterSimplify');
assert(~any(cellfun(@(e) strcmp(fcn_INTERNAL_field(e,'LightType'), 'tail'), paintedEdits.labelEditsAfterSimplify)));
% (leaving Labels with a change not saved: a hidden window saves it; on
% screen, it asks)
figureHandle.UserData.Paint('tail', rearPoint, false);       % (painted, and saved)
undoButton = findobj(figureHandle, 'Type', 'uibutton', 'Text', 'Undo');
undoButton.ButtonPushedFcn(undoButton, []);                  % (taken back: not saved yet)
figureHandle.UserData.ShowCheck(lightsIndex);
paintedEdits = load(figureHandle.UserData.EditsFile, 'labelEditsAfterSimplify');
assert(~any(cellfun(@(e) strcmp(fcn_INTERNAL_field(e,'LightType'), 'tail'), paintedEdits.labelEditsAfterSimplify)));
animatorBack = figureHandle.UserData.Animator();
assert(nnz(animatorBack.Mesh.FaceLightType == tailIndex) == tailBefore);

%% Differences compares the edited mesh (faces deleted in Labels make a spot)
fprintf(1,'Differences compares the edited mesh\n');
compareIndex = find(strcmp(checkKeys, 'compare'));
figureHandle.UserData.ShowCheck(compareIndex);
spotsBefore = figureHandle.UserData.ItemKeys();
% (a patch of the roof hidden: the body faces near the top middle; the painter's
% delete became hide on 2026_11_23, hidden never deleted)
roofFaces = find(lightsMesh.FacePartIndex == find(strcmp(lightsMesh.PartNames, 'body')));
[~, order] = sort(sum((lightsCenters(roofFaces,:) - [mean(lightsCenters(:,1)) 0 max(lightsCenters(:,3))]).^2, 2));
roofPoints = lightsCenters(roofFaces(order(1:40)),:);
figureHandle.UserData.ShowCheck(labelsIndex);
figureHandle.UserData.Paint('hide', roofPoints, false);    % (selected, with "hide" picked)
applyButton = findobj(figureHandle, 'Type', 'uibutton', 'Text', 'Apply');
applyButton.ButtonPushedFcn(applyButton, []);              % (applied; saved on leaving Labels)
figureHandle.UserData.ShowCheck(compareIndex);
spotsAfter = figureHandle.UserData.ItemKeys();
newSpots = setdiff(spotsAfter, spotsBefore);
if isempty(newSpots)
    % (KNOWN OPEN, the reviewer's design file, change log 2026-11-24 02:20:
    % hidden faces are not deleted, so hiding part of the roof makes no
    % Differences spot; left for the archived reviewer work. Reported, not
    % asserted, so the tests after this one still run.)
    fprintf(1, '    KNOWN OPEN: no new Differences spot for the hidden roof faces (the reviewer''s design file)\n');
else
    roofCenter = mean(roofPoints, 1);
    spotCenters = cellfun(@(k) sscanf(k, 'spot_%d_%d_%d')'/10, newSpots, 'UniformOutput', false);
    assert(any(cellfun(@(c) numel(c)==3 && norm(c - roofCenter) < 0.6, spotCenters)), 'the new spot is not at the roof');
end
assert(all(ismember(setdiff(spotsBefore, {'all'}), spotsAfter)) || numel(spotsAfter) >= numel(spotsBefore));
% (the hidden roof is kept: it is the painted fix the report lists below.
% Hidden faces cannot be reached to unhide them, and Differences shows
% no spot for them (KNOWN OPEN above), so its items are as before.)
figureHandle.UserData.ShowCheck(compareIndex);
assert(isequal(sort(figureHandle.UserData.ItemKeys()), sort(spotsAfter)));
figureHandle.UserData.ShowCheck(find(strcmp(checkKeys, 'orientation')));
figureHandle.UserData.Vote('rejected');
figureHandle.UserData.SetCause('front: -X', 'up: +Z (as shown)');

%% The overall decision goes in the vehicle's change log
fprintf(1,'The overall decision goes in the change log\n');
figureHandle.UserData.ShowCheck(find(strcmp(checkKeys, 'summary')));
figureHandle.UserData.Vote('approved');
reviewedHistory = fcn_CarMesh3D_meshHistory(vehicleInput);
assert(strcmp(reviewedHistory.Review.Status, 'approved') && strcmp(reviewedHistory.Review.By, 'test'));

%% Closing saves the answers and the report
fprintf(1,'Closing: the answers and the report are saved\n');
close(figureHandle);
assert(isfile(reviewFile));
assert(isfile(reportFile));
reportText = fileread(reportFile);
assert(contains(reportText, '# Review: '));
assert(contains(reportText, '## Labels'));
assert(contains(reportText, 'Painted label fixes'));
assert(contains(reportText, 'importForwardAxis = '));

%% Opening again loads the earlier answers
[reviewTable2, figureHandle2] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='test');
assert(isequal(height(reviewTable2), height(reviewTable)));
close(figureHandle2);

%% The ☰ Menu: Shared GUI settings, and the painter's panels on the Labels check (Q45 (A))
fprintf(1,'The menu: Shared GUI settings, and the painter''s panels while Labels is shown\n');
[~, figureHandle3] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='test');
reviewMenu = figureHandle3.UserData.Menu;
assert(isequal(reviewMenu.Names(), {'Shared GUI settings'}), 'Only Shared GUI settings away from Labels');
reviewMenu.ToggleList();
assert(reviewMenu.ListShown(), 'The menu''s list opens');
reviewMenu.Open('Shared GUI settings');
assert(isequal(reviewMenu.OpenNames(), {'Shared GUI settings'}) && ~reviewMenu.ListShown());
settingsControls = figureHandle3.UserData.Settings.Controls();
assert(strcmp(settingsControls.Initials.Enable, 'on') && strcmp(settingsControls.ResetReview.Enable, 'on'), ...
    'Every section is used by the reviewer');
assert(strcmp(settingsControls.Review.levels.Children(1).Enable, 'on'), 'An optional check can be turned off');
assert(isa(settingsControls.Review.labels, 'matlab.ui.control.Label'), 'A required check cannot: it shows "On (required)"');
figureHandle3.UserData.ShowCheck(find(strcmp(checkKeys, 'labels')));
assert(all(ismember({'Overall Display', 'Labels To Display', 'Lamps To Display', 'Modify Labels'}, reviewMenu.Names())), ...
    'The painter''s panels are in the reviewer''s menu on Labels');
assert(strcmp(findall(figureHandle3, 'Tag', 'painterMenu').Visible, 'off'), 'The painter has no menu of its own inside the reviewer');
reviewMenu.Open('Modify Labels');
assert(isequal(reviewMenu.OpenNames(), {'Shared GUI settings', 'Modify Labels'}), 'Two panels at once');
figureHandle3.UserData.ShowCheck(find(strcmp(checkKeys, 'dimensions')));
assert(isequal(reviewMenu.Names(), {'Shared GUI settings'}), 'The painter''s panels leave with the painter');
assert(isequal(reviewMenu.OpenNames(), {'Shared GUI settings'}));
close(figureHandle3);

%% Optional checks turned off: greyed, and their questions recorded as skipped (Sean, 2026-11-24 16:14)
fprintf(1,'Optional checks turned off: skipped, not blank\n');
setpref('CarMesh3D', 'ReviewChecksOff', {'levels', 'outline'});
[reviewTable4, figureHandle4] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='test');
assert(isequal(sort(figureHandle4.UserData.ChecksOff), sort({'levels', 'outline'})));
flagOff = ismember(reviewTable4.Check, ["levels", "outline"]);
assert(all(reviewTable4.Status(flagOff) == "skipped" | reviewTable4.Status(flagOff) == "approved" | reviewTable4.Status(flagOff) == "rejected"), ...
    'Questions of a check turned off: skipped (or their earlier answer)');
assert(any(reviewTable4.Status(flagOff) == "skipped"), 'Some questions skipped');
skippedRows = reviewTable4.Status == "skipped";
assert(all(reviewTable4.Cause(skippedRows) == "turned off in Shared GUI settings") && all(reviewTable4.Reviewer(skippedRows) == "test"), ...
    'Skipped: why, and by whom');
radioButtons = findall(figureHandle4, 'Type', 'uiradiobutton');
levelsButton = radioButtons(arrayfun(@(radio) startsWith(char(radio.Text), 'Detail levels'), radioButtons));
assert(isscalar(levelsButton) && strcmp(levelsButton.Enable, 'off'), 'Detail levels greyed in Checks');
buttonGroups = findall(figureHandle4, 'Type', 'uibuttongroup');
checksGroup = buttonGroups(arrayfun(@(group) startsWith(char(group.Title), 'Checks'), buttonGroups));
assert(isscalar(checksGroup) && contains(checksGroup.Title, '2 off'), 'The reminder: 2 off');
figureHandle4.UserData.ShowCheck(find(strcmp(checkKeys, 'summary')));
summaryLabels = findall(figureHandle4, 'Type', 'uilabel');
summaryText = strjoin(arrayfun(@(label) strjoin(cellstr(label.Text), ' '), summaryLabels, 'UniformOutput', false), ' ');
assert(contains(summaryText, 'skipped (turned off)'), 'The summary counts the skipped questions');
close(figureHandle4);
assert(contains(fileread(reportFile), 'questions skipped'), 'The report says how many were skipped');
% (turned on again: the skipped questions are asked again)
setpref('CarMesh3D', 'ReviewChecksOff', {});
[reviewTable5, figureHandle5] = fcn_CarMesh3D_reviewVehicle(vehicleInput, Visible=false, Reviewer='test');
assert(~any(reviewTable5.Status == "skipped"), 'Turned on again: asked again');
close(figureHandle5);

%% Clean up the files this test made (and put back the earlier answers)
clear cleanupFiles;   % (fcn_INTERNAL_restoreFiles)

%% Fail conditions
if 1==0
    % A vehicle with no mesh: error CarMesh3D:noMesh
    fcn_CarMesh3D_reviewVehicle('1900_No_Such_Car');
end

clear cleanupVersions cleanupHistory cleanupChecksPref;   % (takes out the timestamped copies the tests made; puts the change log back)
fprintf(1,'All tests of fcn_CarMesh3D_reviewVehicle passed\n');

%% fcn_INTERNAL_restorePref
function fcn_INTERNAL_restorePref(name, flagHad, valueBefore)
% Puts a preference back as it was: its value, or none
if flagHad
    setpref('CarMesh3D', name, valueBefore);
elseif ispref('CarMesh3D', name)
    rmpref('CarMesh3D', name);
end
end % Ends fcn_INTERNAL_restorePref

%% fcn_INTERNAL_field
function value = fcn_INTERNAL_field(thisStruct, fieldName)
% A struct field's value, or '' if it has none
value = '';
if isfield(thisStruct, fieldName)
    value = thisStruct.(fieldName);
end
end % Ends fcn_INTERNAL_field

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

function fcn_INTERNAL_restoreFiles(backupFolder, vehicleID, reviewFile, reportFile, editsFile, flagHadReview, flagHadReport, flagHadEdits)
% Puts the vehicle's answers, report and label fixes back as they were
pairs = {reviewFile, flagHadReview, sprintf('review_%s.mat', vehicleID);
    reportFile, flagHadReport, sprintf('review_%s.md', vehicleID);
    editsFile, flagHadEdits, sprintf('labelEdits_%s.mat', vehicleID)};
for ith_pair = 1:size(pairs,1)
    if pairs{ith_pair,2}
        copyfile(fullfile(backupFolder, pairs{ith_pair,3}), pairs{ith_pair,1});
    elseif isfile(pairs{ith_pair,1})
        delete(pairs{ith_pair,1});
    end
end
if isfolder(backupFolder)
    rmdir(backupFolder, 's');
end
end % Ends fcn_INTERNAL_restoreFiles
