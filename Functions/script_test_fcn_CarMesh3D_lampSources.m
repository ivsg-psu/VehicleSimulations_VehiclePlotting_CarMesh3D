% script_test_fcn_CarMesh3D_lampSources.m
% Tests fcn_CarMesh3D_lampSources, and how fcn_CarMesh3D_lampFunctions and
% the lamp-functions window use the sourced cells (Q98 (A))

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampSources
%   % * First write (drafted with Claude)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampSources
%   % * (none yet)

%% Set up the workspace
close all;

% (a temporary copy of the GUI test vehicle: the test writes nothing in a
% real vehicle's folder)
vehicleID = '2026_CarMesh3D_Sample_GUITestVehicle';
demoFolder = tempname;
copyFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID, DemoFolder=demoFolder, FigNum=-1);
cleanupDemo = onCleanup(@() rmdir(demoFolder, 's'));
for oldFile = {sprintf('lampFunctions_%s.csv', vehicleID), sprintf('lampFunctionsSources_%s.csv', vehicleID)}
    if isfile(fullfile(copyFiles.Folder, oldFile{1}))
        delete(fullfile(copyFiles.Folder, oldFile{1}));
    end
end

%% TEST case: no file: an empty table with every column
[lampSources, sourcesFile] = fcn_CarMesh3D_lampSources(copyFiles.Folder, FigNum=-1);
assert(istable(lampSources) && height(lampSources) == 0);
assert(all(ismember({'Unit','Signal','Value','Status','MakerName','Source','Page','Accessed','Note','VerifiedBy','VerifiedOn'}, ...
    lampSources.Properties.VariableNames)), 'Every column, even with no file');
assert(endsWith(sourcesFile, sprintf('lampFunctionsSources_%s.csv', vehicleID)));

%% TEST case: written and read back; dates stay text
[startMatrix, units] = fcn_CarMesh3D_lampFunctions(copyFiles.Folder, FigNum=-1);
% (units whose rows are not edited: a migrated row, such as the test
% vehicle's tail lights that are also turn signals, counts as edited)
flagDefault = strcmp(startMatrix.Default, 'yes');
tailUnit = startMatrix.Unit{find(flagDefault & strcmp(startMatrix.Kind, 'backupLamp'), 1)};
markerUnit = startMatrix.Unit{find(flagDefault & strcmp(startMatrix.Kind, 'markerLamp'), 1)};
assert(startMatrix.Tail(strcmp(startMatrix.Unit, tailUnit)) ~= 0.25, 'The test needs a value other than the default');
newSources = table({tailUnit; markerUnit; markerUnit}, {'Tail'; 'Running'; 'Parking'}, [0.25; 0; 1], ...   % (tailUnit: a backup lamp, given a tail value)
    {'auto'; 'auto'; 'verified'}, {'Taillights'; 'Daytime Running Lights'; 'Parking lights'}, ...
    {'https://example.com/manual.pdf'; 'https://example.com/manual.pdf'; 'https://example.com/manual.pdf'}, ...
    {'p. 1'; 'p. 2'; 'p. 3'}, {'2026-11-26'; '2026-11-26'; '2026-11-26'}, {'a note'; ''; ''}, {''; ''; 'ZZT'}, {''; ''; '2026-11-26'}, ...
    'VariableNames', {'Unit','Signal','Value','Status','MakerName','Source','Page','Accessed','Note','VerifiedBy','VerifiedOn'});
fcn_CarMesh3D_lampSources(copyFiles.Folder, Sources=newSources, FlagSave=true, FigNum=-1);
lampSources = fcn_CarMesh3D_lampSources(copyFiles.Folder, FigNum=-1);
assert(height(lampSources) == 3 && iscell(lampSources.Accessed) && strcmp(lampSources.Accessed{1}, '2026-11-26'), ...
    'Read back, with the dates as text');
assert(isequal(lampSources.Value, [0.25; 0; 1]) && strcmp(lampSources.Status{3}, 'verified'));
assert(iscell(lampSources.VerifiedBy) && isempty(lampSources.VerifiedBy{1}), 'An empty text column stays text');

%% TEST case: the matrix takes the sourced values (rows not edited by hand)
[matrixNow, ~, info] = fcn_CarMesh3D_lampFunctions(copyFiles.Folder, FigNum=-1);
assert(abs(matrixNow.Tail(strcmp(matrixNow.Unit, tailUnit)) - 0.25) < 1e-9, 'A sourced value goes into the matrix');
assert(matrixNow.Running(strcmp(matrixNow.Unit, markerUnit)) == 0, 'Another');
assert(istable(info.Sources) && all(info.Sources.Applied), 'Applied: all three');
% (a row edited by hand keeps the person's values)
edited = matrixNow;
rowIndex = strcmp(edited.Unit, tailUnit);
edited.Tail(rowIndex) = 0.6;
edited.Default{rowIndex} = 'edited';
edited.Source{rowIndex} = '(edited by ZZT)';
[matrixEdited, ~, infoEdited] = fcn_CarMesh3D_lampFunctions(copyFiles.Folder, Table=edited, FigNum=-1);
assert(abs(matrixEdited.Tail(rowIndex) - 0.6) < 1e-9, 'A person''s edit wins over a source');
assert(~infoEdited.Sources.Applied(1) && infoEdited.Sources.Applied(2), 'Applied: not in the edited row');

%% TEST case: the window: orange cells, the source strip, Mark verified, Save
[~, editor] = fcn_CarMesh3D_editLampFunctions(copyFiles.Folder, Who='ZZT', FlagVisible=false);
assert(editor.IsOrange(tailUnit, 'Tail') && editor.IsOrange(markerUnit, 'Running'), 'Auto cells are orange');
assert(~editor.IsOrange(markerUnit, 'Parking'), 'A verified cell is not');
assert(~editor.IsOrange(markerUnit, 'Brake'), 'A cell with no source is not');
strip = editor.SourceStrip();
assert(strip.Visible && contains(strip.Text, 'Orange cells (2)') && ~strip.CanVerify, 'The strip, before a click');
editor.SetSignal('Tail');
drawnow;
assert(~isempty(findall(editor.Figure, 'Tag', 'lampCellAuto')), 'Orange cells drawn');
editor.ClickCell(tailUnit, 'Tail');
strip = editor.SourceStrip();
assert(contains(strip.Text, 'Taillights') && contains(strip.Text, 'p. 1') && contains(strip.Text, 'accessed 2026-11-26') ...
    && strcmp(strip.URL, 'https://example.com/manual.pdf') && strip.CanVerify, 'The clicked cell''s source');
editor.MarkVerified();
assert(~editor.IsOrange(tailUnit, 'Tail') && ~editor.SourceStrip().CanVerify, 'Verified: no longer orange');
editor.ClickCell(markerUnit, 'Brake');
assert(contains(editor.SourceStrip().Text, 'no source') && isempty(editor.SourceStrip().URL), 'A cell with no source');
editor.Save();
lampSources = fcn_CarMesh3D_lampSources(copyFiles.Folder, FigNum=-1);
rowIndex = strcmp(lampSources.Unit, tailUnit) & strcmp(lampSources.Signal, 'Tail');
assert(strcmp(lampSources.Status{rowIndex}, 'verified') && strcmp(lampSources.VerifiedBy{rowIndex}, 'ZZT') ...
    && ~isempty(lampSources.VerifiedOn{rowIndex}), 'Save writes who verified it, and when');
editor.Close();

%% TEST case: a cell that names its bulb: its value from the bulb's lumens (cube root)
bulbSources = fcn_CarMesh3D_lampSources(copyFiles.Folder, FigNum=-1);
bulbSources = bulbSources(1,:);
bulbSources.Value(1) = 0.9;   % (a value given by hand: replaced by the bulb's)
bulbSources.Bulb{1} = 'W21/5W';
bulbSources.Filament{1} = 'tail';
fcn_CarMesh3D_lampSources(copyFiles.Folder, Sources=bulbSources, FlagSave=true, FigNum=-1);
lampSources = fcn_CarMesh3D_lampSources(copyFiles.Folder, FigNum=-1);
assert(height(lampSources) == 1 && abs(lampSources.Value(1) - 0.43) < 1e-9 && strcmp(lampSources.Bulb{1}, 'W21/5W'), ...
    'The tail filament of a 21/5 W bulb: (35/440)^(1/3) = 0.43');
lastwarn('');
warning('off', 'CarMesh3D:lampSourcesBulb');
bulbSources.Bulb{1} = 'not a bulb';
lampSources = fcn_CarMesh3D_lampSources(copyFiles.Folder, Sources=bulbSources, FigNum=-1);
warning('on', 'CarMesh3D:lampSourcesBulb');
assert(abs(lampSources.Value(1) - 0.9) < 1e-9, 'An unknown bulb: the value given is kept');

%% TEST case: a vehicle with no sources: no strip
delete(fullfile(copyFiles.Folder, sprintf('lampFunctionsSources_%s.csv', vehicleID)));
[~, editor] = fcn_CarMesh3D_editLampFunctions(copyFiles.Folder, Who='ZZT', FlagVisible=false);
assert(~editor.SourceStrip().Visible && isempty(findall(editor.Figure, 'Tag', 'lampCellAuto')), 'No sources: no strip, nothing orange');
editor.Close();

fprintf(1, 'script_test_fcn_CarMesh3D_lampSources: all tests passed\n');
