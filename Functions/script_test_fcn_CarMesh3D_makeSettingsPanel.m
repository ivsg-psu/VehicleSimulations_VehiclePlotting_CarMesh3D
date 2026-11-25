% script_test_fcn_CarMesh3D_makeSettingsPanel.m
% Tests fcn_CarMesh3D_makeSettingsPanel: the Shared GUI settings panel,
% built here into a hidden window of the test's own. Every preference it
% touches is saved first and put back at the end, as it was (rule G37),
% even if the test stops partway.

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makeSettingsPanel
%   % * First write (the shared-panels design file, sections 4 and 5):
%   %   % each section's controls set and read back as preferences;
%   %   % OnChange; each section's Reset and Reset all; the sections a GUI
%   %   % does not use greyed, never hidden, with why; the Review rows
%   %   % from fcn_CarMesh3D_reviewChecks (required ones fixed On, the
%   %   % ones not built greyed)

% TO-DO:
%
% (none)

%% Set up the workspace
close all;
% (the preferences this test touches: saved, and put back at the end)
prefNames = {'Initials', 'StartViewDial', 'StartViewDown', 'VersionsAtSave', 'VersionFolder', 'ReviewChecksOff', 'DemoVehicle'};
prefsBefore = struct();
for ith_pref = 1:numel(prefNames)
    if ispref('CarMesh3D', prefNames{ith_pref})
        prefsBefore.(prefNames{ith_pref}) = getpref('CarMesh3D', prefNames{ith_pref});
    end
end
cleanupPrefs = onCleanup(@() fcn_INTERNAL_restorePrefs(prefNames, prefsBefore));

%% DEMO case: every section in use, in a hidden window of the test's own
figNum = 10001;
fprintf(1,'Figure %.0f: DEMO case: Shared GUI settings, every section used (hidden)\n', figNum);
hostFigure = uifigure('Visible', 'off', 'Position', [50 50 420 900]);
hostPanel = uipanel(hostFigure, 'Position', [10 10 320 880], 'Scrollable', 'on');
fcn_INTERNAL_changes('reset');
settings = fcn_CarMesh3D_makeSettingsPanel(hostPanel, OnChange=@(name, value) fcn_INTERNAL_changes({name, value}));
assert(all(isfield(settings, {'Value', 'Set', 'Reset', 'ResetAll', 'Mark', 'Used', 'Controls', 'Defaults'})), 'Its functions');
controls = settings.Controls();
assert(all(isfield(controls, {'Initials', 'StartViewDial', 'StartViewDown', 'DemoText', 'RepoDemo', 'VersionsAtSave', ...
    'VersionFolder', 'VersionBrowse', 'Review', 'ResetAll'})), 'Its controls');
texts = arrayfun(@(label) strjoin(cellstr(label.Text), ' '), findall(hostPanel, 'Type', 'uilabel'), 'UniformOutput', false);
assert(all(ismember({'You', 'View', 'Demo vehicle', 'Editing', 'Review'}, texts)), 'The five section headings');
assert(any(contains(texts, 'Changes apply to windows opened from now on.')), 'When changes apply (Q46 (A))');

%% TEST case: each setting, set in the panel, is the preference, and OnChange hears it
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: each setting\n', figNum);
fcn_INTERNAL_type(controls.Initials, ' abc ');
assert(strcmp(getpref('CarMesh3D', 'Initials'), 'ABC') && strcmp(settings.Value('Initials'), 'ABC'), 'Initials: trimmed, upper case');
fcn_INTERNAL_type(controls.Initials, '');
assert(strcmp(settings.Value('Initials'), 'SBB'), 'Initials left empty: the default, SBB');
fcn_INTERNAL_type(controls.StartViewDial, 120);
fcn_INTERNAL_type(controls.StartViewDown, 35);
assert(getpref('CarMesh3D', 'StartViewDial') == 120 && getpref('CarMesh3D', 'StartViewDown') == 35, 'The starting view');
fcn_INTERNAL_pick(controls.VersionsAtSave, false);
assert(isequal(getpref('CarMesh3D', 'VersionsAtSave'), false), 'Timestamped copy at each save? Off');
folderNow = fullfile(tempdir, 'carMeshSettingsTest');
fcn_INTERNAL_type(controls.VersionFolder, folderNow);
assert(strcmp(getpref('CarMesh3D', 'VersionFolder'), folderNow), 'The folder for timestamped copies');
fcn_INTERNAL_type(controls.VersionFolder, '');
assert(~ispref('CarMesh3D', 'VersionFolder'), 'An empty folder: the default (no preference)');
fcn_INTERNAL_pick(controls.Review.levels, false);
fcn_INTERNAL_pick(controls.Review.outline, false);
assert(isequal(sort(getpref('CarMesh3D', 'ReviewChecksOff')), {'levels', 'outline'}), 'Two optional checks off');
fcn_INTERNAL_pick(controls.Review.levels, true);
assert(isequal(getpref('CarMesh3D', 'ReviewChecksOff'), {'outline'}), 'One back on');
checkList = fcn_CarMesh3D_reviewChecks(FigNum=-1);
assert(~checkList.On(checkList.Key == "outline") && checkList.On(checkList.Key == "levels"), 'The reviewer''s list follows');
changes = fcn_INTERNAL_changes();
changedNames = cellfun(@(change) change{1}, changes, 'UniformOutput', false);
assert(all(ismember({'Initials', 'StartViewDial', 'StartViewDown', 'VersionsAtSave', 'VersionFolder', 'ReviewChecksOff'}, changedNames)), ...
    'OnChange heard every setting');
settings.Set('Initials', 'xy');
assert(strcmp(controls.Initials.Value, 'XY'), 'Set: the panel shows it');

%% TEST case: Review: required checks fixed On, checks not built greyed
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: the Review rows\n', figNum);
for ith_check = 1:height(checkList)
    key = char(checkList.Key(ith_check));
    group = controls.Review.(key);
    if checkList.Required(ith_check)
        assert(isa(group, 'matlab.ui.control.Label') && contains(group.Text, 'required'), 'A required check shows "On (required)": %s', key);
        continue;
    end
    flagCanClick = strcmp(group.Children(1).Enable, 'on');
    assert(flagCanClick == checkList.Built(ith_check), 'The Review row for %s', key);
end
settings.Set('ReviewChecksOff', {'orientation', 'levels'});
assert(isequal(getpref('CarMesh3D', 'ReviewChecksOff'), {'levels'}), 'A required check cannot be turned off');

%% TEST case: each section's Reset, and Reset all
figNum = 20003;
fprintf(1,'Figure %.0f: TEST case: Reset\n', figNum);
controls.ResetView.ButtonPushedFcn(controls.ResetView, []);
assert(~ispref('CarMesh3D', 'StartViewDial') && settings.Value('StartViewDial') == 60 && controls.StartViewDial.Value == 60, ...
    'View''s Reset: the defaults');
assert(strcmp(settings.Value('Initials'), 'XY'), 'View''s Reset leaves You alone');
controls.ResetAll.ButtonPushedFcn(controls.ResetAll, []);
for name = {'Initials', 'StartViewDial', 'StartViewDown', 'VersionsAtSave', 'VersionFolder', 'ReviewChecksOff'}
    assert(~ispref('CarMesh3D', name{1}), 'Reset all: %s back to its default', name{1});
end
defaults = settings.Defaults();
assert(strcmp(controls.Initials.Value, defaults.Initials) && isequal(controls.VersionsAtSave.SelectedObject.UserData, true), ...
    'Reset all: the panel shows the defaults');
delete(hostFigure);

%% TEST case: the sections a GUI does not use: greyed, never hidden, with why (rule G26)
figNum = 20004;
fprintf(1,'Figure %.0f: TEST case: sections greyed\n', figNum);
hostFigure = uifigure('Visible', 'off', 'Position', [50 50 420 900]);
hostPanel = uipanel(hostFigure, 'Position', [10 10 320 880], 'Scrollable', 'on');
settings = fcn_CarMesh3D_makeSettingsPanel(hostPanel, Used={'View', 'Demo vehicle'});   % (as the viewer)
controls = settings.Controls();
assert(isequal(settings.Used(), {'View', 'Demo vehicle'}));
for control = {controls.Initials, controls.VersionFolder, controls.VersionBrowse, controls.ResetYou, controls.ResetEditing, controls.ResetReview}
    assert(strcmp(control{1}.Enable, 'off') && strcmp(control{1}.Visible, 'on'), 'Greyed, never hidden');
    assert(contains(control{1}.Tooltip, 'Used by') && contains(control{1}.Tooltip, 'not this window'), 'The tooltip says why');
end
assert(all(strcmp({controls.VersionsAtSave.Children.Enable}, 'off')), 'A greyed radio row');
assert(strcmp(controls.StartViewDial.Enable, 'on') && strcmp(controls.ResetView.Enable, 'on'), 'View: used');
initialsBefore = settings.Value('Initials');
settings.Set('StartViewDial', 90);
controls.ResetAll.ButtonPushedFcn(controls.ResetAll, []);
assert(settings.Value('StartViewDial') == 60, 'Reset all: the sections in use');
assert(strcmp(settings.Value('Initials'), initialsBefore), 'Reset all leaves a greyed section alone');
% (the layout: no errors, in a window of this size)
problems = fcn_CarMesh3D_guiDriver(hostFigure, 'checkLayout');
assert(~any(strcmp(problems.Severity, 'error')), 'Layout errors: %s', strjoin(problems.Problem(strcmp(problems.Severity, 'error')), '; '));
delete(hostFigure);

%% FAST mode cases
figNum = 30001;
fprintf(1,'Figure %.0f: FAST mode: FigNum=-1\n', figNum);
hostFigure = uifigure('Visible', 'off');
settings = fcn_CarMesh3D_makeSettingsPanel(uipanel(hostFigure), Used={'Review'}, FigNum=-1);
assert(isequal(settings.Used(), {'Review'}));
delete(hostFigure);

%% BUG cases
% (none yet)

%% Fail conditions
hostFigure = uifigure('Visible', 'off');
fcn_INTERNAL_expectError(@() fcn_CarMesh3D_makeSettingsPanel(42), 'container must be');
fcn_INTERNAL_expectError(@() fcn_CarMesh3D_makeSettingsPanel(uipanel(hostFigure), Used={'Nope'}), 'Used must name');
settings = fcn_CarMesh3D_makeSettingsPanel(uipanel(hostFigure));
fcn_INTERNAL_expectError(@() settings.Set('Nope', 1), 'No setting named');
fcn_INTERNAL_expectError(@() settings.Reset('Nope'), 'No section named');
delete(hostFigure);

clear cleanupPrefs;   % (the preferences put back as they were)
fprintf(1,'All tests of fcn_CarMesh3D_makeSettingsPanel passed\n');

%% Functions follow
function fcn_INTERNAL_type(field, value)
% A value typed into a field, as a person does (its callback runs)
field.Value = value;
field.ValueChangedFcn(field, []);
end % Ends fcn_INTERNAL_type

function fcn_INTERNAL_pick(group, value)
% A radio button picked, as a person does
radios = findobj(group.Children, 'flat', 'Type', 'uiradiobutton');
for ith_radio = 1:numel(radios)
    if isequal(radios(ith_radio).UserData, value)
        group.SelectedObject = radios(ith_radio);
        group.SelectionChangedFcn(group, struct('NewValue', radios(ith_radio)));
        return;
    end
end
error('test:noRadio', 'No radio button with that value');
end % Ends fcn_INTERNAL_pick

function changesOut = fcn_INTERNAL_changes(change)
% OnChange's calls, kept: with a change, one more; 'reset' to start again
persistent changes
if nargin > 0
    if ischar(change) && strcmp(change, 'reset')
        changes = {};
    else
        changes{end+1} = change;
    end
end
changesOut = changes;
end % Ends fcn_INTERNAL_changes

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

function fcn_INTERNAL_expectError(callIt, expected)
% The call must fail, with this in its message
try
    callIt();
catch caughtError
    assert(contains(caughtError.message, expected), 'Expected "%s", got: %s', expected, caughtError.message);
    return;
end
error('test:noError', 'Expected an error with "%s"', expected);
end % Ends fcn_INTERNAL_expectError
