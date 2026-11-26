% script_test_fcn_CarMesh3D_lampColors.m
% Tests fcn_CarMesh3D_lampColors (and fcn_CarMesh3D_lampSetup)
% How a vehicle's lamps are lit by a set of signals, from its
% lamp-to-function (L2F) matrix.

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampColors
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_lampColors
%   % * (fill in items here)


%% Set up the workspace
fitMesh = fcn_CarMesh3D_meshWithLabelEdits('2009_Honda_Fit_Sport', FigNum=-1);
fitSetup = fcn_CarMesh3D_lampSetup(fitMesh);
unitIndex = @(setup, name) find(strcmp({setup.Units.Name}, name), 1);
allOff = struct('LowBeam', false, 'HighBeam', false, 'Running', false, 'TurnLeft', false, 'TurnRight', false, ...
    'Tail',false, 'Brake', false, 'Backup', false, 'Fog', false, 'Reflectors', 0);

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: the 2009 Fit with its high beams on (the fog lamps stay off: Sean, 00:08)
figNum = 10001;
fprintf(1,'Figure %.0f: DEMO case: the Fit''s high beams\n', figNum);
states = allOff;
states.HighBeam = true;
lit = fcn_CarMesh3D_lampColors(fitSetup, states);
assert(lit.Brightness(unitIndex(fitSetup, 'front-left headlamp')) == 1);
assert(lit.Brightness(unitIndex(fitSetup, 'front-left fog lamp')) == 0, ...
    'The 2009 Fit''s high beams do not light its fog lamps (Sean, 00:08; the painter''s bug, 00:36)');
assert(isequal(lit.UnitColor(unitIndex(fitSetup, 'front-left headlamp'),:), [1 1 1]), 'High beams: white');

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%% TEST case: the setup: units, faces, the matrix from the Fit's file
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: the setup\n', figNum);
assert(size(fitSetup.Matrix,1) == numel(fitSetup.Units) && size(fitSetup.Matrix,2) == numel(fitSetup.SignalNames));
assert(all(fitSetup.FaceUnit(fitMesh.LabelFaceLamp(:) > 0) > 0), 'Every lamp face is in a unit');
assert(~any(fitSetup.FaceUnit > 0 & fitSetup.FaceCoverUnit > 0), 'A face is a lamp face or a cover, not both');
runningColumn = strcmp(fitSetup.SignalNames, 'Running');
assert(fitSetup.Matrix(unitIndex(fitSetup, 'front-left headlamp'), runningColumn) == 0.3, ...
    'The Fit''s file: its headlamps are its running lights, at 0.3 (meshWithLabelEdits adds the file to the mesh)');

%% TEST case: all off: nothing lit
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: all off\n', figNum);
lit = fcn_CarMesh3D_lampColors(fitSetup, allOff);
assert(all(lit.Brightness == 0) && ~any(lit.FlagLit) && all(isnan(lit.UnitColor(:))));
lit = fcn_CarMesh3D_lampColors(fitSetup, struct);
assert(all(lit.Brightness == 0), 'No states given: all off');

%% TEST case: the Fit's running lights are its headlamps, dimmed
figNum = 20003;
fprintf(1,'Figure %.0f: TEST case: running lights, dimmed\n', figNum);
states = allOff;
states.Running = true;
lit = fcn_CarMesh3D_lampColors(fitSetup, states);
headlamp = unitIndex(fitSetup, 'front-left headlamp');
assert(abs(lit.Brightness(headlamp) - 0.3) < 1e-9);
assert(all(lit.UnitColor(headlamp,:) < [1.00 0.96 0.78]) && all(lit.UnitColor(headlamp,:) > 0), 'Dimmed: darker than full');
assert(lit.Brightness(unitIndex(fitSetup, 'front-left marker lamp')) == 1, 'The marker lamps with the running lights');
states.LowBeam = true;
lit = fcn_CarMesh3D_lampColors(fitSetup, states);
assert(lit.Brightness(headlamp) == 1, 'Low beams and running together: the brightest wins');

%% TEST case: tail, brake, and the turn signals (and Hazards)
figNum = 20004;
fprintf(1,'Figure %.0f: TEST case: tail, brake, turns\n', figNum);
tail = unitIndex(fitSetup, 'rear-left tail/brake lamp');
states = allOff;
states.Tail = true;
litTail = fcn_CarMesh3D_lampColors(fitSetup, states);
states.Brake = true;
litBrake = fcn_CarMesh3D_lampColors(fitSetup, states);
assert(abs(litTail.Brightness(tail) - 0.4) < 1e-9 && litBrake.Brightness(tail) == 1);
assert(litBrake.UnitColor(tail,1) > litTail.UnitColor(tail,1), 'Brake brighter red than tail');
states = allOff;
states.Brake = true;
assert(fcn_CarMesh3D_lampColors(fitSetup, states).Brightness(tail) == 1, 'Brake as a field of its own');
states = allOff;
states.TurnLeft = true;
litLeft = fcn_CarMesh3D_lampColors(fitSetup, states);
assert(litLeft.Brightness(unitIndex(fitSetup, 'front-left turn-signal lamp')) == 1 && ...
    litLeft.Brightness(unitIndex(fitSetup, 'front-right turn-signal lamp')) == 0);
states = allOff;
states.Hazards = true;
litHazards = fcn_CarMesh3D_lampColors(fitSetup, states);
assert(litHazards.Brightness(unitIndex(fitSetup, 'front-left turn-signal lamp')) == 1 && ...
    litHazards.Brightness(unitIndex(fitSetup, 'front-right turn-signal lamp')) == 1, 'Hazards: both turn signals');

%% TEST case: a lamp that fails (LampFaults) answers no signal
figNum = 20005;
fprintf(1,'Figure %.0f: TEST case: LampFaults\n', figNum);
states = allOff;
states.Tail = true;
states.Brake = true;
litFault = fcn_CarMesh3D_lampColors(fitSetup, states, LampFaults={'rear-left tail/brake lamp'});
assert(litFault.Brightness(tail) == 0 && litFault.Brightness(unitIndex(fitSetup, 'rear-right tail/brake lamp')) == 1);
assert(~any(litFault.FlagLit(fitSetup.FaceUnit == tail)), 'Its faces stay unlit');

%% TEST case: a matrix given wins over the mesh's (the fog lamps lit with the high beams, as some makers do)
figNum = 20006;
fprintf(1,'Figure %.0f: TEST case: a matrix given\n', figNum);
fogTable = fcn_CarMesh3D_lampFunctions(fitMesh, FigNum=-1);
fogTable.HighBeam(contains(fogTable.Unit, 'fog lamp')) = 1;
fogSetup = fcn_CarMesh3D_lampSetup(fitMesh, LampFunctions=fogTable);
states = allOff;
states.HighBeam = true;
assert(fcn_CarMesh3D_lampColors(fogSetup, states).Brightness(unitIndex(fogSetup, 'front-left fog lamp')) == 1);

%% TEST case: lamps that glow in their own colors (reflectors), brighter with the outside light
figNum = 20007;
fprintf(1,'Figure %.0f: TEST case: reflectors\n', figNum);
reflector = unitIndex(fitSetup, 'rear-left reflector');
states = allOff;
states.Reflectors = 0.5;
litHalf = fcn_CarMesh3D_lampColors(fitSetup, states);
states.Reflectors = 1;
litFull = fcn_CarMesh3D_lampColors(fitSetup, states);
assert(abs(litHalf.Brightness(reflector) - 0.5) < 1e-9 && litFull.Brightness(reflector) == 1);
assert(sum(litFull.UnitColor(reflector,:)) >= sum(litHalf.UnitColor(reflector,:)), 'Brighter with more light');

%% TEST case: a mesh with no lamps
figNum = 20008;
fprintf(1,'Figure %.0f: TEST case: no lamps\n', figNum);
noLamps = fitMesh;
noLamps.LabelFaceLamp(:) = 0;
noLamps.LabelFaceCoverLamp(:) = 0;
noSetup = fcn_CarMesh3D_lampSetup(noLamps);
noLit = fcn_CarMesh3D_lampColors(noSetup, allOff);
assert(isempty(noLit.Brightness) && ~any(noLit.FlagLit));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______        _     __  __           _        _______        _
%  |  ____|      | |   |  \/  |         | |      |__   __|      | |
%  | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
%  |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
%  | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
%  |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% Speed: once per animation frame
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, the time per call\n',figNum);
states = allOff;
states.LowBeam = true;
states.Tail = true;
states.Brake = true;
Niterations = 200;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_lampColors(fitSetup, states, FigNum=-1);
end
fprintf(1,'The Fit: %.2f ms per call (fast mode)\n', 1000*toc/Niterations);

%% BUG cases
% (none yet)

%% Fail conditions
if 1==0
    %% Not a setup
    fcn_CarMesh3D_lampColors(42, struct);
end
