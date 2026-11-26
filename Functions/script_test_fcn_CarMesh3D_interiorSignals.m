% script_test_fcn_CarMesh3D_interiorSignals.m
% Tests fcn_CarMesh3D_interiorSignals

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_interiorSignals
%   % * First write

% TO-DO:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_interiorSignals
%   % * (none yet)

%% Set up the workspace
close all;

%% TEST case: the list, one of each, with every field
interiorKinds = fcn_CarMesh3D_interiorSignals(FigNum=-1);
names = {interiorKinds.Name};
assert(numel(names) == 10 && numel(unique(names)) == numel(names), 'Ten interior signals, each once');
assert(all(ismember({'Dome','Ambient','DoorOpen','Instruments'}, names)));
assert(all(ismember({interiorKinds.Values}, {'on/off', '0 to 1'})), 'Each is on/off or 0 to 1');
% (DoorOpen is shared with the exterior signals; no other name is)
exteriorNames = {fcn_CarMesh3D_lampSignals().Name};
assert(isequal(intersect(names, exteriorNames), {'DoorOpen'}), 'Only DoorOpen is in both lists');

%% TEST case: plotVehicle takes InteriorSignals, and refuses a field not on the list
testMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
figure(20001); clf;
plotHandles = fcn_CarMesh3D_plotVehicle(testMesh, InteriorSignals=struct('Dome', true, 'Ambient', 0.5), FigNum=20001);
assert(isequal(plotHandles.InteriorSignals, struct('Dome', true, 'Ambient', 0.5)), 'Kept with the plot handles');
flagRefused = false;
try
    fcn_CarMesh3D_plotVehicle(testMesh, InteriorSignals=struct('Disco', true), FigNum=20001);
catch
    flagRefused = true;
end
assert(flagRefused, 'An unknown interior signal is refused');
close(20001);

fprintf(1,'All tests of fcn_CarMesh3D_interiorSignals passed\n');
