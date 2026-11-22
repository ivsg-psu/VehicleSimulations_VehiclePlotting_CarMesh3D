% script_test_fcn_CarMesh3D_restoreGroundClearance.m
% Tests fcn_CarMesh3D_restoreGroundClearance
% Putting the lowest body point back at the ground clearance after a
% reduction raised it.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_restoreGroundClearance
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_restoreGroundClearance
%   % * (fill in items here)


%% Set up the workspace
close all

% (the sample car, labeled and fit, then its lowest body points raised
% 5 mm, as a reduction might)
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
sampleMesh = fcn_CarMesh3D_fillSampleMesh(VehicleSpec=vehicleSpec, FigNum=-1);
sampleMesh = fcn_CarMesh3D_labelParts(sampleMesh, FigNum=-1);
sampleMesh = fcn_CarMesh3D_fitMeshToSpec(sampleMesh, vehicleSpec, FigNum=-1);
bodyVertices = unique(sampleMesh.Faces(sampleMesh.FacePartIndex==1,:));
wheelVertices = unique(sampleMesh.Faces(sampleMesh.FacePartIndex==3,:));
raisedMesh = sampleMesh;
lowBody = bodyVertices(raisedMesh.Vertices(bodyVertices,3) < vehicleSpec.GroundClearance + 0.004);
raisedMesh.Vertices(lowBody,3) = raisedMesh.Vertices(lowBody,3) + 0.005;

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

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: A raised bottom edge is put back at the ground clearance
figNum = 10001;
titleString = sprintf('DEMO case: A raised bottom edge is put back at the ground clearance');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[restoredMesh, shiftDistance] = fcn_CarMesh3D_restoreGroundClearance(raisedMesh, vehicleSpec.GroundClearance, FigNum=figNum);

% Check variable types
assert(isstruct(restoredMesh) && isnumeric(shiftDistance));

% Check variable sizes
assert(isequal(size(restoredMesh.Vertices), size(raisedMesh.Vertices)) && isscalar(shiftDistance));

% Check variable values: the body bottom is at the clearance, the roof
% and the wheels have not moved, the shift is about -5 mm
assert(abs(min(restoredMesh.Vertices(bodyVertices,3)) - vehicleSpec.GroundClearance) < 1e-9);
assert(abs(max(restoredMesh.Vertices(:,3)) - max(raisedMesh.Vertices(:,3))) < 1e-9);
assert(isequal(restoredMesh.Vertices(wheelVertices,:), raisedMesh.Vertices(wheelVertices,:)));
assert(abs(shiftDistance + 0.005) < 1e-3);

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_
%    | |/ _ \/ __| __|
%    | |  __/\__ \ |_
%    |_|\___||___/\__|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: A mesh already at the clearance is not changed
figNum = 20001;
titleString = sprintf('TEST case: A mesh already at the clearance is not changed');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[sameMesh, shiftDistance] = fcn_CarMesh3D_restoreGroundClearance(sampleMesh, vehicleSpec.GroundClearance, FigNum=figNum);
assert(shiftDistance==0 && isequal(sameMesh.Vertices, sampleMesh.Vertices));

%% TEST case: A small difference within Tolerance is left alone
figNum = 20002;
titleString = sprintf('TEST case: A small difference within Tolerance is left alone');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[~, shiftDistance] = fcn_CarMesh3D_restoreGroundClearance(raisedMesh, vehicleSpec.GroundClearance, Tolerance=0.01);
assert(shiftDistance==0);

%% Fast Mode Tests





%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
restoredMesh = fcn_CarMesh3D_restoreGroundClearance(raisedMesh, vehicleSpec.GroundClearance, FigNum=[]);
assert(isstruct(restoredMesh));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
restoredMesh = fcn_CarMesh3D_restoreGroundClearance(raisedMesh, vehicleSpec.GroundClearance, FigNum=-1);
assert(isstruct(restoredMesh));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: A negative ground clearance
if 1==0
    fcn_CarMesh3D_restoreGroundClearance(raisedMesh, -0.1);
end
