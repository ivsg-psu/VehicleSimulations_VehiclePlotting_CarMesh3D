% script_test_fcn_CarMesh3D_makeDisplayPanels.m
% Tests fcn_CarMesh3D_makeDisplayPanels: the display panels shared by the
% label viewer's own window and the label painter, built here into a
% hidden window of the test's own, around a viewer built into it.

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makeDisplayPanels
%   % * First write
%   % * Driven by script (fcn_CarMesh3D_guiDriver; Sean, 05:03): every
%   %   % control tagged (no layout notes or errors), each radio group set
%   %   % to each value with the viewer followed, the photo options grayed
%   %   % with no photos, the readout after Reset view
%   % * Turn photo with model?; the photo options drive a viewer with
%   %   % photos and are remembered for the next window (the preferences
%   %   % put back as they were)
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In script_test_fcn_CarMesh3D_makeDisplayPanels
%   % * The lamp group named "Lamps" (Q83 (A)), its rows for what each
%   %   % part is (rule P6)

%% Set up the workspace
close all;
vehicleID = fcn_CarMesh3D_demoVehicle(Which='guiTest', FigNum=-1);   % (every lamp type, covers, interior, hidden sets)
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');

%% DEMO case: the three panels beside a viewer, in a window of the test's own (hidden)
figNum = 10001;
fprintf(1,'Figure %.0f: DEMO case: the three display panels beside a viewer\n', figNum);
hostFigure = uifigure('Visible', 'off', 'Position', [50 50 1400 820]);
hostGrid = uigridlayout(hostFigure, [1 4], 'ColumnWidth', {320, 320, 320, '1x'});
overallPanel = uipanel(hostGrid, 'Title', 'Overall Display');
labelsPanel = uipanel(hostGrid, 'Title', 'Labels To Display');
lampsPanel = uipanel(hostGrid, 'Title', 'Lamps To Display');
viewerPanel = uipanel(hostGrid);
changeCount = 0;
[~, viewer] = fcn_CarMesh3D_viewLabels(loaded.vehicleMesh, Parent=viewerPanel, ShowTools=false, FigNum=-1);
panels = fcn_CarMesh3D_makeDisplayPanels(viewer, Overall=overallPanel, Labels=labelsPanel, Lamps=lampsPanel, ...
    OnChange=@() fcn_INTERNAL_count());
assert(all(isfield(panels, {'MarkAll','MarkOverall','MarkLabels','MarkLamps','RebuildLabels','Controls'})));
controls = panels.Controls();
assert(isfield(controls.Overall, 'Colors') && ~isempty(controls.LabelRows) && isfield(controls.LampGroups, 'Tail'));

%% TEST case: the labels in groups, every lamp type listed, none gray on the test vehicle
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: groups and rows\n', figNum);
texts = get(findall(labelsPanel, 'Type', 'uilabel'), 'Text');
assert(all(ismember({'Main body panels', 'Objects within interior', 'Lamps', 'Visibility'}, texts)), 'The four groups');
assert(any(strcmp(texts, 'headlamp')) && ~any(contains(texts, 'low beams')), 'Lamp parts named for what they are (rule P6)');
lampTypes = fcn_CarMesh3D_lampTypes(FigNum=-1);
rowKeys = {controls.LabelRows.Key};
assert(all(ismember(strcat('light_', {lampTypes.Name}), rowKeys)), 'A row for every lamp type');
assert(isempty(findall(lampsPanel, 'Type', 'uilabel', 'FontAngle', 'italic')), 'Every lamp has faces on the test vehicle');

%% TEST case: each panel drives the viewer, and calls OnChange
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: the panels drive the viewer\n', figNum);
changesBefore = fcn_INTERNAL_count(0);
fcn_INTERNAL_pickRadio(findall(overallPanel, 'Tag', 'overallColors'), 'vehicle');
assert(strcmp(viewer.Colors(), 'vehicle'));
fcn_INTERNAL_pickRadio(findall(overallPanel, 'Tag', 'overallColors'), 'labels');
fcn_INTERNAL_pickRadio(findall(labelsPanel, 'Tag', 'colored_part_glass'), false);
assert(any(strcmp(viewer.Uncolored(), 'part_glass')), 'Colored? No');
fcn_INTERNAL_pickRadio(findall(labelsPanel, 'Tag', 'allColored'), true);
assert(isempty(viewer.Uncolored()), 'All labels Colored? Yes');
fcn_INTERNAL_pickRadio(findall(labelsPanel, 'Tag', 'shown_part_trim'), false);
assert(any(strcmp(viewer.Hidden(), 'part_trim')), 'Shown? No');
fcn_INTERNAL_pickRadio(findall(labelsPanel, 'Tag', 'allShown'), true);
assert(~any(strcmp(viewer.Hidden(), 'part_trim')), 'All labels Shown? Yes');
fcn_INTERNAL_pickRadio(findall(lampsPanel, 'Tag', 'lamp_Tail'), 'brake');
assert(strcmp(viewer.NightLights().Tail, 'brake'), 'Tail lights Brake');
fcn_INTERNAL_pickRadio(findall(lampsPanel, 'Tag', 'lamp_All'), false);
assert(strcmp(viewer.NightLights().Tail, 'off') && ~viewer.NightLights().LowBeam, 'All lamps Off');
assert(fcn_INTERNAL_count(0) > changesBefore, 'OnChange called');

%% TEST case: the panels show changes made elsewhere (the viewer's hooks), once marked
figNum = 20003;
fprintf(1,'Figure %.0f: TEST case: marking\n', figNum);
viewer.SetBoundaries(true);
viewer.SetNightLights(struct('LowBeam', true));
panels.MarkAll();
boundaries = findall(overallPanel, 'Tag', 'overallBoundaries');
assert(isequal(boundaries.SelectedObject.UserData, true), 'Boundaries marked On');
lowBeam = findall(lampsPanel, 'Tag', 'lamp_LowBeam');
assert(isequal(lowBeam.SelectedObject.UserData, true), 'Low beams marked On');
allLamps = findall(lampsPanel, 'Tag', 'lamp_All');
assert(isnan(allLamps.SelectedObject.UserData), 'All lamps mixed');
viewer.SetBoundaries(false);

%% TEST case: driven by script (fcn_CarMesh3D_guiDriver): every control tagged, each value set, the viewer follows
figNum = 20005;
fprintf(1,'Figure %.0f: TEST case: driven by script\n', figNum);
for panelHandle = [overallPanel, labelsPanel, lampsPanel]
    problems = fcn_CarMesh3D_guiDriver(panelHandle, 'checkLayout');
    assert(~any(strcmp(problems.Severity, 'note')), 'Untagged controls in %s: %s', panelHandle.Title, strjoin(problems.Control(strcmp(problems.Severity, 'note')), '; '));
    assert(~any(strcmp(problems.Severity, 'error')), 'Layout errors in %s', panelHandle.Title);
end
state = fcn_CarMesh3D_guiDriver(overallPanel, 'state');
assert(all(isfield(state.Values, {'overallResetView', 'overallCopyViewCall', 'overallPhotoBrowse', 'overallPhotoFolder', 'cameraReadout'})), 'The Overall Display''s Tags');
assert(~state.Enabled.turnWithPhoto && ~state.Enabled.turnPhotoWithModel && ~state.Enabled.photoSize, 'No photos given: the photo options grayed');
% (each radio group set to each of its values; the panels then show the viewer's state)
for panelHandle = [overallPanel, labelsPanel, lampsPanel]
    groups = findall(panelHandle, 'Type', 'uibuttongroup');
    for ith_group = 1:numel(groups)
        radios = findobj(groups(ith_group).Children, 'flat', 'Type', 'uiradiobutton', 'Visible', 'on', 'Enable', 'on');
        for ith_radio = 1:numel(radios)
            fcn_CarMesh3D_guiDriver(panelHandle, 'set', groups(ith_group).Tag, radios(ith_radio).UserData);
            stateNow = fcn_CarMesh3D_guiDriver(hostFigure, 'state');
            assert(isequal(stateNow.Values.overallNight, viewer.NightView()) && isequal(stateNow.Values.overallColors, viewer.Colors()) ...
                && isequal(stateNow.Values.lamp_Hazards, logical(viewer.NightLights().TurnLeft) && logical(viewer.NightLights().TurnRight)) ...
                && isequal(stateNow.Values.shown_part_glass, ~any(strcmp(viewer.Hidden(), 'part_glass'))), ...
                'After %s = %s the panels differ from the viewer', groups(ith_group).Tag, mat2str(radios(ith_radio).UserData));
        end
    end
end
fcn_CarMesh3D_guiDriver(overallPanel, 'set', 'overallNight', false);
fcn_CarMesh3D_guiDriver(overallPanel, 'press', 'overallResetView');
camera = viewer.CameraInfo();
readout = cellstr(fcn_CarMesh3D_guiDriver(overallPanel, 'state').Values.cameraReadout);
assert(numel(readout) == 4 && strcmp(readout{1}, 'Camera view:') && contains(readout{2}, sprintf('yaw angle: %.0f', camera.DialAngle)), 'The readout after Reset view');

%% TEST case: the photo options, with photos: they drive the viewer and are remembered (preferences put back)
figNum = 20006;
fprintf(1,'Figure %.0f: TEST case: the photo options, remembered\n', figNum);
photoPrefNames = {'TurnWithPhoto', 'TurnPhotoWithModel', 'PhotoHeight'};
photoPrefsBefore = struct();
for ith_pref = 1:numel(photoPrefNames)
    if ispref('CarMesh3D', photoPrefNames{ith_pref})
        photoPrefsBefore.(photoPrefNames{ith_pref}) = getpref('CarMesh3D', photoPrefNames{ith_pref});
    end
end
cleanupPhotoPrefs = onCleanup(@() fcn_INTERNAL_restorePrefs(photoPrefNames, photoPrefsBefore));
photoFigure = uifigure('Visible', 'off', 'Position', [50 50 1200 820]);
photoGrid = uigridlayout(photoFigure, [1 2], 'ColumnWidth', {320, '1x'});
photoOverall = uipanel(photoGrid, 'Title', 'Overall Display');
photoViewerPanel = uipanel(photoGrid);
[~, photoViewer] = fcn_CarMesh3D_viewLabels(vehicleFiles.MeshFile, Parent=photoViewerPanel, ShowTools=false, FigNum=-1);
fcn_CarMesh3D_makeDisplayPanels(photoViewer, Overall=photoOverall);
state = fcn_CarMesh3D_guiDriver(photoOverall, 'state');
assert(state.Enabled.turnWithPhoto && state.Enabled.turnPhotoWithModel && state.Enabled.photoSize, 'With photos: the options can be picked');
fcn_CarMesh3D_guiDriver(photoOverall, 'set', 'turnPhotoWithModel', false);
assert(~photoViewer.TurnPhotoWithModel() && isequal(getpref('CarMesh3D', 'TurnPhotoWithModel'), false), 'Turn photo with model? Off, remembered');
fcn_CarMesh3D_guiDriver(photoOverall, 'set', 'turnWithPhoto', false);
assert(~photoViewer.TurnWithPhoto() && isequal(getpref('CarMesh3D', 'TurnWithPhoto'), false), 'Turn model with photo? Off, remembered');
fcn_CarMesh3D_guiDriver(photoOverall, 'set', 'photoSize', 420);
assert(photoViewer.PhotoHeight() == 420 && getpref('CarMesh3D', 'PhotoHeight') == 420, 'Photo size? Large, remembered');
photoViewer.Stop();
delete(photoFigure);
% (a viewer opened now starts with the remembered options)
[~, photoViewer] = fcn_CarMesh3D_viewLabels(vehicleFiles.MeshFile, Visible=false, Wait=false, FigNum=-1);
assert(~photoViewer.TurnPhotoWithModel() && ~photoViewer.TurnWithPhoto(), 'The next window starts with them');
photoViewer.Close();
clear cleanupPhotoPrefs;   % (the photo options' preferences put back as they were)

%% TEST case: a host keeps the hidden faces' setting (as the painter does)
figNum = 20004;
fprintf(1,'Figure %.0f: TEST case: a host''s ShowHidden\n', figNum);
hostLabelsPanel = uipanel(hostGrid);
fcn_INTERNAL_setHostFlag(false);
panels2 = fcn_CarMesh3D_makeDisplayPanels(viewer, Labels=hostLabelsPanel, ...
    ShowHidden=@() fcn_INTERNAL_setHostFlag(), SetShowHidden=@(flag) fcn_INTERNAL_setHostFlag(flag)); %#ok<NASGU>
shownHidden = findall(hostLabelsPanel, 'Tag', 'shown_hidden');   % (this panel's row)
fcn_INTERNAL_pickRadio(shownHidden, true);
assert(fcn_INTERNAL_setHostFlag() == true, 'The host''s SetShowHidden called');

viewer.Close();
delete(hostFigure);

%% FAST mode cases
figNum = 80001;
fprintf(1,'Figure %.0f: FAST mode cases\n', figNum);
hostFigure = uifigure('Visible', 'off');
[~, viewer] = fcn_CarMesh3D_viewLabels(loaded.vehicleMesh, Parent=uipanel(hostFigure), ShowTools=false, FigNum=-1);
panelsFast = fcn_CarMesh3D_makeDisplayPanels(viewer, Overall=uipanel(hostFigure), FigNum=-1);
assert(isfield(panelsFast, 'MarkAll'));
panelsNone = fcn_CarMesh3D_makeDisplayPanels(viewer, FigNum=[]);   % (no panels: nothing built)
panelsNone.MarkAll();
viewer.Close();
delete(hostFigure);

%% BUG cases
% (none yet)

%% Fail conditions
if 1==0
    % Not a viewer
    fcn_CarMesh3D_makeDisplayPanels(struct('a', 1));
end

assert(isempty(timerfindall), 'A timer was left running');
fprintf(1,'All tests of fcn_CarMesh3D_makeDisplayPanels passed\n');

%% Functions follow
function countOut = fcn_INTERNAL_count(flagAdd)
% Counts OnChange calls (called with no input by the panels; with 0 to read)
persistent numCalls
if isempty(numCalls)
    numCalls = 0;
end
if nargin == 0
    numCalls = numCalls + 1;
end
countOut = numCalls;
end % Ends fcn_INTERNAL_count

function flagOut = fcn_INTERNAL_setHostFlag(flagIn)
% A host's own "show hidden faces" setting (set with an input, read without)
persistent flagKept
if isempty(flagKept)
    flagKept = false;
end
if nargin > 0
    flagKept = logical(flagIn);
end
flagOut = flagKept;
end % Ends fcn_INTERNAL_setHostFlag

function fcn_INTERNAL_restorePrefs(prefNames, prefsBefore)
% The preferences put back as they were: their values, or none
for ith_pref = 1:numel(prefNames)
    name = prefNames{ith_pref};
    if isfield(prefsBefore, name)
        setpref('CarMesh3D', name, prefsBefore.(name));
    elseif ispref('CarMesh3D', name)
        rmpref('CarMesh3D', name);
    end
end
end % Ends fcn_INTERNAL_restorePrefs

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
