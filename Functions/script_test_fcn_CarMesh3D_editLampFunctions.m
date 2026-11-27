% script_test_fcn_CarMesh3D_editLampFunctions.m
% Tests: fcn_CarMesh3D_editLampFunctions (the lamp-to-function matrix
% window). It runs on a temporary demo copy of the GUI test vehicle, so
% saving never changes a real vehicle; the window is built hidden and
% worked through its own functions (editor) and controls.

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_editLampFunctions
%   % * First write (drafted with Claude)

% TO-DO:
%
% (none)

%% Set up the workspace
close all
vehicleID = '2026_CarMesh3D_Sample_GUITestVehicle';
demoFolder = tempname;
copyFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID, DemoFolder=demoFolder, FigNum=-1);
cleanupDemo = onCleanup(@() rmdir(demoFolder, 's'));
functionsFile = fullfile(copyFiles.Folder, sprintf('lampFunctions_%s.csv', vehicleID));
if isfile(functionsFile)
    delete(functionsFile);   % (the copy starts with the defaults)
end

%% DEMO case: the window on its own, with its viewer
fprintf(1, 'DEMO case: the window, with its viewer\n');
[startMatrix, editor] = fcn_CarMesh3D_editLampFunctions(copyFiles.Folder, Who='ZZT', FlagVisible=false);
assert(istable(startMatrix) && height(startMatrix) == numel(editor.Units()));
assert(isgraphics(editor.Figure) && isstruct(editor.Viewer));
assert(strcmp(editor.Signal(), 'LowBeam') && strcmp(editor.Mode(), 'table'));
assert(~isempty(findall(editor.Figure, 'Tag', 'lampTable')), 'The table is drawn');
% (its own top bar, with the viewer's Mesh, Grid and sun/moon at the right:
% Sean 10:41)
zzBar = findall(editor.Figure, 'Tag', 'lampTopBar');
assert(isscalar(zzBar) && isscalar(findall(zzBar, 'Tag', 'dayNightButton')) && isscalar(findall(zzBar, 'Tag', 'meshToggle')) ...
    && isscalar(findall(zzBar, 'Tag', 'groundToggle')), 'The top bar has Mesh, Grid and the sun/moon');
% (the lamp names stay while the signals' columns scroll sideways; picking a
% signal brings its column to the middle: Sean, T89 BUG)
assert(~isempty(findall(editor.Figure, 'Tag', 'lampTableNames')), 'The lamp names have a column of their own');
editor.SetSignal('Reflectors');
drawnow;
zzView = editor.ColumnView();
zzCenter = (find(strcmp({fcn_CarMesh3D_lampSignals().Name}, 'Reflectors')) - 0.5)*26;
assert(zzCenter >= zzView.Offset && zzCenter <= zzView.Offset + zzView.Width, 'The Reflectors column is in view once picked');
editor.SetSignal('LowBeam');
drawnow;
zzView = editor.ColumnView();
assert(13 >= zzView.Offset && 13 <= zzView.Offset + zzView.Width, 'The LowBeam column is in view once picked');
if zzView.Sideways
    editor.SetColumnOffset(40);
    zzTableAxes = findall(editor.Figure, 'Tag', 'lampTable');
    assert(abs(zzTableAxes(1).XLim(1) - 40) < 1e-9 && strcmp(findall(editor.Figure, 'Tag', 'lampColumnScroll').Visible, 'on'), ...
        'The slider scrolls the columns, not the names');
    zzRight = findall(editor.Figure, 'Tag', 'lampColumnsRight');
    zzRight.ButtonPushedFcn(zzRight, []);
    assert(editor.ColumnView().Offset > 40, 'The right arrow scrolls the columns along');
    zzLeft = findall(editor.Figure, 'Tag', 'lampColumnsLeft');
    for zzStep = 1:20
        zzLeft.ButtonPushedFcn(zzLeft, []);
    end
    assert(editor.ColumnView().Offset == 0, 'The left arrow reaches the first column (Low beam)');
end
% (nothing reaches past the table panel's right edge: the panel itself
% never scrolls sideways, which would move the names too; T89 BUG, 15:46)
zzContent = findall(editor.Figure, 'Tag', 'lampContent');
zzTableAxes = findall(editor.Figure, 'Tag', 'lampTable');
zzPanelWidth = getpixelposition(zzContent(1));
assert(sum(zzTableAxes(1).OuterPosition([1 3])) <= zzPanelWidth(3), 'The table fits its panel''s width');
% (readable at any number of lamps: T80, T81 BUG; names at 11 pt, rows of
% at least 20 px, however short the panel)
zzNames = findall(editor.Figure, 'Tag', 'lampRowName');
assert(~isempty(zzNames) && all([zzNames.FontSize] >= 11), 'The lamp names are at least 11 pt');
zzTable = findall(editor.Figure, 'Tag', 'lampTable');
zzCells = findall(zzTable, 'Tag', 'lampCell');
zzPos = vertcat(zzCells.Position);
zzScale = zzTable.InnerPosition(4)/diff(zzTable.YLim);   % (pixels per data unit)
assert(min(zzPos(:,4))*zzScale >= 15, 'Each cell is at least 15 px tall on screen');
assert(editor.Viewer.FlagNight(), 'The view is at night while the matrix is edited');
outline = findall(editor.Figure, 'Tag', 'lampOutline');
units = editor.Units();
lowBeamUnits = find(startMatrix.LowBeam > 0);
assert(~isempty(lowBeamUnits) && isscalar(outline) && size(outline.Faces, 1) == numel(vertcat(units(lowBeamUnits).Faces)), ...
    'The lamps the edited signal lights are outlined in cyan');

%% TEST case: also on, as chips; Hazards
fprintf(1, 'TEST case: also on\n');
editor.AddAlsoOn('Brake');
assert(isequal(editor.AlsoOn(), {'Brake'}) && ~isempty(findall(editor.Figure, 'Tag', 'lampChip_Brake')));
nightLamps = editor.Viewer.NightLights();
assert(nightLamps.LowBeam && isfield(nightLamps, 'Brake') && nightLamps.Brake, 'The view lights both signals');
chip = findall(editor.Figure, 'Tag', 'lampChip_Brake');
chip.ButtonPushedFcn(chip, []);
assert(isempty(editor.AlsoOn()) && isempty(findall(editor.Figure, 'Tag', 'lampChip_Brake')), 'A click on a chip takes it off');
editor.Hazards();
assert(isequal(sort(editor.AlsoOn()), {'TurnLeft', 'TurnRight'}), 'Hazards: both turn signals also on');
editor.Hazards();
assert(isempty(editor.AlsoOn()));
editor.AddAlsoOn('LowBeam');
assert(isempty(editor.AlsoOn()), 'The edited signal is never also on');

%% TEST case: a cell set; its row edited; the checks
fprintf(1, 'TEST case: values and checks\n');
fogRow = find(strcmp(startMatrix.Kind, 'fogLamp'), 1);
targetUnit = lowBeamUnits(1);
editor.SetValue(targetUnit, 'Running', 0.33);
matrixNow = editor.Table();
assert(abs(matrixNow.Running(targetUnit) - 0.35) < 1e-12, 'Steps of 0.05');
assert(strcmp(matrixNow.Default{targetUnit}, 'edited') && contains(matrixNow.Source{targetUnit}, 'ZZT'), 'Marked edited, with who');
checks = editor.Checks();
assert(iscellstr(checks) && any(contains(checks, 'lights the')), 'A lamp lit on one side only is a check');
% (a double-click switches a cell; a click makes its signal the edited one)
editor.ClickCell(targetUnit, 'Brake', false);
assert(strcmp(editor.Signal(), 'Brake'), 'A click edits its signal');
editor.ClickCell(targetUnit, 'Brake', true);
assert(editor.Table().Brake(targetUnit) == 1, 'A double-click switches it on');
assert(any(contains(editor.Checks(), 'both ends')), 'Brakes lit at the front: a check');
editor.ClickCell(targetUnit, 'Brake', true);
assert(editor.Table().Brake(targetUnit) == 0, 'And off');
if ~isempty(fogRow)
    editor.SetSignal('Fog');
end

%% TEST case: the tuner, and the filters
fprintf(1, 'TEST case: tuner and filters\n');
editor.SetSignal('LowBeam');
editor.SetMode('tuner');
sliders = findall(editor.Figure, '-regexp', 'Tag', '^lampSlider_');
assert(numel(sliders) == numel(editor.ShownUnits()) && all(strcmp({sliders.Orientation}, 'vertical')), 'One vertical slider per lamp');
slider = findall(editor.Figure, 'Tag', sprintf('lampSlider_%d', targetUnit));
slider.Value = 0.62;
slider.ValueChangedFcn(slider, struct('Value', 0.62));
assert(abs(editor.Table().LowBeam(targetUnit) - 0.6) < 1e-12, 'The slider sets the cell, in steps of 0.05');
editor.AddAlsoOn('Running');
alsoLabel = findall(editor.Figure, 'Tag', sprintf('lampAlso_%d', targetUnit));
assert(contains(alsoLabel.Text, '0.35'), 'Under each slider, what the also-on signals light it to');
editor.SetOnlyLit(true);
assert(all(editor.Table().LowBeam(editor.ShownUnits()) > 0), 'Only the lamps the signal lights');
editor.SetOnlyLit(false);
editor.SetGroups({'Rear'});
shown = editor.ShownUnits();
assert(all(startsWith({units(shown).Position}, 'rear')), 'Only the rear group');
editor.SetGroups({'Front', 'Side', 'Rear'});
% (the boxes themselves, as a click runs them: Sean's 23:01 bug, a callback
% that held the boxes before all three were made)
for groupName = {'Front', 'Side', 'Rear'}
    groupBox = findall(editor.Figure, 'Tag', ['lampGroup' groupName{1}]);
    groupBox.Value = ~strcmp(groupName{1}, 'Front');
    groupBox.ValueChangedFcn(groupBox, []);
end
shown = editor.ShownUnits();
assert(~any(startsWith({units(shown).Position}, 'front')) && any(startsWith({units(shown).Position}, 'rear')), ...
    'Clicking the Front box off hides the front lamps');
frontBox = findall(editor.Figure, 'Tag', 'lampGroupFront');
frontBox.Value = true;
frontBox.ValueChangedFcn(frontBox, []);
assert(numel(editor.ShownUnits()) == numel(units), 'And on again');
editor.SetMode('table');

%% TEST case: Save writes the vehicle's file, with the edited rows; Revert
fprintf(1, 'TEST case: save and revert\n');
editor.Save();
assert(isfile(functionsFile), 'Saved');
[readBack, ~, readInfo] = fcn_CarMesh3D_lampFunctions(copyFiles.Folder, FigNum=-1);
assert(readInfo.FromFile && abs(readBack.Running(targetUnit) - 0.35) < 1e-12 && abs(readBack.LowBeam(targetUnit) - 0.6) < 1e-12, ...
    'The file holds the edited row');
editor.SetValue(targetUnit, 'Backup', 1);
editor.Revert();
assert(editor.Table().Backup(targetUnit) == readBack.Backup(targetUnit), 'Revert goes back to the save');
editor.Close();
assert(~isvalid(editor.Figure));

%% TEST case: a mesh given as a variable: nothing to save
fprintf(1, 'TEST case: a mesh variable\n');
meshOnly = fcn_CarMesh3D_meshWithLabelEdits(vehicleID, FigNum=-1);
[~, editor] = fcn_CarMesh3D_editLampFunctions(meshOnly, FlagVisible=false);
assert(strcmp(findall(editor.Figure, 'Tag', 'lampSave').Enable, 'off'));
editor.Close();

%% Testing errors
fprintf(1, 'Testing errors\n');
try
    fcn_CarMesh3D_editLampFunctions(42);
    error('should have failed');
catch inputError
    assert(strcmp(inputError.identifier, 'CarMesh3D:badInput'));
end

clear cleanupDemo;
fprintf(1, 'All tests of fcn_CarMesh3D_editLampFunctions passed.\n');
