% script_test_fcn_CarMesh3D_lampFunctions.m
% Tests fcn_CarMesh3D_lampFunctions (and the signal list,
% fcn_CarMesh3D_lampSignals)
% A vehicle's lamp-to-function (L2F) matrix: defaults, the migration from
% the mesh, and the vehicle's file, lampFunctions_<ID>.csv.
%
% The file tests run on a temporary copy of a vehicle (never the real
% one); figures are made hidden and closed by their handles.

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampFunctions
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampFunctions
%   % * (fill in items here)


%% Set up the workspace
fitMesh = fcn_CarMesh3D_meshWithLabelEdits('2009_Honda_Fit_Sport', FigNum=-1);
signals = fcn_CarMesh3D_lampSignals();
signalNames = {signals.Name};
% (a temporary copy of the Fit, for the file: put back through onCleanup)
copyFolder = fullfile(tempname, '2009_Honda_Fit_Sport');
demoCopy = fcn_CarMesh3D_makeDemoCopy('2009_Honda_Fit_Sport', DemoFolder=fileparts(copyFolder), FigNum=-1); %#ok<NASGU>
cleanupCopy = onCleanup(@() rmdir(fileparts(copyFolder), 's'));
% (the copy starts with no lamp-functions file: the Fit's own, saved
% since, is taken out of the temporary copy)
copiedFile = fullfile(copyFolder, 'lampFunctions_2009_Honda_Fit_Sport.csv');
if isfile(copiedFile)
    delete(copiedFile);
end

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: the 2009 Fit's matrix, from a mesh (no file), plotted
figNum = 10001;
titleString = sprintf('DEMO case: the 2009 Fit''s lamp-to-function matrix');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figureHandle = figure(figNum); clf(figureHandle); figureHandle.Visible = 'off';
[fitMatrix, fitUnits, fitInfo] = fcn_CarMesh3D_lampFunctions(fitMesh, FigNum=figNum);
assert(height(fitMatrix) == numel(fitUnits) && isempty(fitInfo.File) && ~fitInfo.FromFile);
assert(isequal(fitMatrix.Properties.VariableNames, [{'Unit','Kind','Position'}, signalNames, {'Default','Source'}]));
close(figureHandle);

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _______        _
%  |__   __|      | |
%     | | ___  ___| |_ ___
%     | |/ _ \/ __| __/ __|
%     | |  __/\__ \ |_\__ \
%     |_|\___||___/\__|___/
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

fprintf(1,'Figure: 2XXXXXX: TEST mode cases\n');

%% TEST case: the signal list
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: the signal list\n', figNum);
assert(all(ismember({'LowBeam','HighBeam','Running','Parking','TurnLeft','TurnRight','Tail','Brake','Backup','FogLights','Reflectors'}, signalNames)));
assert(~ismember('Hazards', signalNames), 'Hazards is not a signal (Q80 (A)): it is the two turn signals');
assert(numel(unique(signalNames)) == numel(signalNames) && all(~cellfun(@isempty, {signals.Label})));

%% TEST case: the defaults (the design file, section 4), on the Fit
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: the defaults\n', figNum);
row = @(name) fitMatrix(strcmp(fitMatrix.Unit, name), :);
headlamp = row('front-left headlamp');
assert(headlamp.LowBeam == 1 && headlamp.HighBeam == 1 && headlamp.FogLights == 0, 'A headlamp: low and high beams');
assert(row('front-left turn-signal lamp').TurnLeft == 1 && row('front-left turn-signal lamp').TurnRight == 0, 'Left turn on the left');
assert(row('front-right turn-signal lamp').TurnRight == 1 && row('front-right turn-signal lamp').TurnLeft == 0, 'Right turn on the right');
marker = row('front-left marker lamp');
assert(marker.Running == 1 && marker.Parking == 1 && marker.Tail == 1);
tail = row('rear-left tail/brake lamp');
assert(tail.Tail == 0.4 && tail.Parking == 0.4 && tail.Brake == 1 && tail.TurnLeft == 0, ...
    'A tail/brake lamp: tail and parking 0.4, brake 1; not the turn (the Fit has rear turn-signal lamps)');
assert(row('front-left fog lamp').FogLights == 1 && row('front-left fog lamp').HighBeam == 0, 'The Fit''s fog lamps: the fog signal only (Sean, 00:08)');
assert(row('rear-left backup lamp').Backup == 1 && row('rear-left reflector').Reflectors == 1);
assert(all(strcmp(fitMatrix.Default, 'yes')), 'No file and nothing to migrate: every row the default');

%% TEST case: a tail/brake lamp is the rear turn signal when the vehicle has none (US red rear turns)
figNum = 20003;
fprintf(1,'Figure %.0f: TEST case: red rear turns\n', figNum);
noRearTurns = fitMesh;
turnIndex = find(strcmp(cellstr(noRearTurns.LightTypeNames), 'turnsignal'));
faceCenters = (noRearTurns.Vertices(noRearTurns.Faces(:,1),:) + noRearTurns.Vertices(noRearTurns.Faces(:,2),:) + noRearTurns.Vertices(noRearTurns.Faces(:,3),:))/3;
noRearTurns.FaceLightType(noRearTurns.FaceLightType == turnIndex & faceCenters(:,1) < 1) = 0;
redTurns = fcn_CarMesh3D_lampFunctions(noRearTurns);
redLeft = redTurns(strcmp(redTurns.Unit, 'rear-left tail/brake lamp'), :);
redRight = redTurns(strcmp(redTurns.Unit, 'rear-right tail/brake lamp'), :);
assert(redLeft.TurnLeft == 1 && redLeft.TurnRight == 0 && redRight.TurnRight == 1 && redRight.TurnLeft == 0);
assert(redTurns.TurnLeft(strcmp(redTurns.Unit, 'rear-center tail/brake lamp')) == 0, 'The high brake lamp is no turn signal');

%% TEST case: the migration from the mesh (LampSwitching; FaceLightFunctions)
figNum = 20004;
fprintf(1,'Figure %.0f: TEST case: migration\n', figNum);
switched = fitMesh;
switched.LampSwitching = struct('fog', {{'FogLights', 'HighBeam'}});   % (a maker that lights the fog lamps with the high beams)
migrated = fcn_CarMesh3D_lampFunctions(switched);
fogRow = migrated(strcmp(migrated.Unit, 'front-left fog lamp'), :);
assert(fogRow.FogLights == 1 && fogRow.HighBeam == 1 && strcmp(fogRow.Default, 'edited') && contains(fogRow.Source, 'LampSwitching'));
functionsMesh = fitMesh;
runningIndex = find(strcmp(cellstr(functionsMesh.LightTypeNames), 'running'));
headlampFaces = fitUnits(strcmp({fitUnits.Name}, 'front-left headlamp')).Faces;
functionsMesh.FaceLightFunctions(headlampFaces, runningIndex) = true;   % (the headlamp also lights as a running lamp)
migrated = fcn_CarMesh3D_lampFunctions(functionsMesh);
headRow = migrated(strcmp(migrated.Unit, 'front-left headlamp'), :);
assert(headRow.Running == 1 && strcmp(headRow.Default, 'edited') && contains(headRow.Source, 'running'));

%% TEST case: the file: saved, read back, an edited row kept, a default row remade
figNum = 20005;
fprintf(1,'Figure %.0f: TEST case: the file\n', figNum);
[saved, ~, savedInfo] = fcn_CarMesh3D_lampFunctions(copyFolder, Save=true);
assert(isfile(savedInfo.File) && ~savedInfo.FromFile);
[readBack, ~, readInfo] = fcn_CarMesh3D_lampFunctions(copyFolder);
assert(readInfo.FromFile && isequal(readBack{:, signalNames}, saved{:, signalNames}), 'Read back as saved');
% (edit the file by hand, as a student may: the headlamp's DRL dimmed, marked edited; a default row changed but not marked)
fileTable = readtable(savedInfo.File, 'TextType', 'char', 'Delimiter', ',');
headIndex = find(strcmp(fileTable.Unit, 'front-left headlamp'));
fileTable.Running(headIndex) = 0.3;
fileTable.Default{headIndex} = 'edited';
fileTable.Source{headIndex} = 'Honda: DRL is the high-beam filament, dimmed';
fogIndex = find(strcmp(fileTable.Unit, 'front-left fog lamp'));
fileTable.HighBeam(fogIndex) = 1;   % (not marked edited: the default comes back)
writetable(fileTable, savedInfo.File, 'Delimiter', ',', 'QuoteStrings', 'all');
edited = fcn_CarMesh3D_lampFunctions(copyFolder);
assert(edited.Running(strcmp(edited.Unit, 'front-left headlamp')) == 0.3 && ...
    strcmp(edited.Default{strcmp(edited.Unit, 'front-left headlamp')}, 'edited') && ...
    contains(edited.Source{strcmp(edited.Unit, 'front-left headlamp')}, 'Honda'), 'An edited row is kept, with its source');
assert(edited.HighBeam(strcmp(edited.Unit, 'front-left fog lamp')) == 0, 'A row marked yes is the default again');

%% TEST case: a unit the file names that the mesh no longer has is left out, and said so
figNum = 20006;
fprintf(1,'Figure %.0f: TEST case: a unit no longer in the mesh\n', figNum);
fileTable = readtable(savedInfo.File, 'TextType', 'char', 'Delimiter', ',');
fileTable(end+1,:) = fileTable(1,:);
fileTable.Unit{end} = 'front-left work lamp';
writetable(fileTable, savedInfo.File, 'Delimiter', ',', 'QuoteStrings', 'all');
lastwarn('');
warningState = warning('off', 'CarMesh3D:lampFunctionsDropped');
[~, ~, droppedInfo] = fcn_CarMesh3D_lampFunctions(copyFolder);
warning(warningState);
[~, warningID] = lastwarn;
assert(isequal(droppedInfo.Dropped, {'front-left work lamp'}) && strcmp(warningID, 'CarMesh3D:lampFunctionsDropped'));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   ______        _     __  __           _        _______        _
%  |  ____|      | |   |  \/  |         | |      |__   __|      | |
%  | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
%  |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
%  | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
%  |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty fig_num\n',figNum);
figuresBefore = findall(groot, 'Type', 'figure');
fastMatrix = fcn_CarMesh3D_lampFunctions(fitMesh, FigNum=[]);
assert(isequal(fastMatrix{:, signalNames}, fitMatrix{:, signalNames}));
assert(numel(findall(groot, 'Type', 'figure')) == numel(figuresBefore), 'No figure opened');

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, fig_num=-1\n',figNum);
fastMatrix = fcn_CarMesh3D_lampFunctions(fitMesh, FigNum=-1);
assert(isequal(fastMatrix{:, signalNames}, fitMatrix{:, signalNames}));
assert(numel(findall(groot, 'Type', 'figure')) == numel(figuresBefore), 'No figure opened');

%% Compare speeds of pre-calculation versus post-calculation versus a fast variant
figNum = 80003;
fprintf(1,'Figure: %.0f: FAST mode comparisons\n',figNum);
Niterations = 5;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_lampFunctions(fitMesh, FigNum=[]);
end
slowMethod = toc;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_lampFunctions(fitMesh, FigNum=-1);
end
fastMethod = toc;
fprintf(1,'The Fit, %.0f calls: normal %.3f s, fast %.3f s\n', Niterations, slowMethod, fastMethod);

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

% (none yet)

%% Fail conditions
if 1==0
    %% Save with a mesh only (no file to save to)
    fcn_CarMesh3D_lampFunctions(fitMesh, Save=true);
    %% Not a vehicle or a mesh
    fcn_CarMesh3D_lampFunctions(42);
end
