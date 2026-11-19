% script_CarMesh3D_checkGroundContact.m
% Tests fcn_CarMesh3D_checkGroundContact
% Checks whether the body's roll, pitch, and heave push any part of it to
% the road (possible body damage).

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_checkGroundContact
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_CarMesh3D_checkGroundContact
%   % * (fill in items here)


%% Set up the workspace
close all

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

%% DEMO case: Hard braking in a right turn pushes the front right down
figNum = 10001;
titleString = sprintf('DEMO case: Hard braking in a right turn pushes the front right down');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_fittedSample;
% Made-up (very large) body motion over 2 s: rolls toward the right and
% pitches nose down, while the body drops
timeValues = (0:0.05:2)';
bodyRoll = deg2rad(8)*sin(pi*timeValues/2);
bodyPitch = deg2rad(6)*sin(pi*timeValues/2);
bodyHeave = -0.06*sin(pi*timeValues/2);
[flagContact, clearance, lowestPoint] = fcn_CarMesh3D_checkGroundContact(vehicleMesh, ...
    bodyRoll, bodyPitch, bodyHeave, Time=timeValues, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types
assert(islogical(flagContact));
assert(isnumeric(clearance));

% Check variable sizes
N = length(timeValues);
assert(isequal(size(flagContact),[N 1]));
assert(isequal(size(clearance),[N 1]));
assert(isequal(size(lowestPoint),[N 3]));

% Check variable values: at rest the clearance is the body's ground
% clearance; at the worst moment the lowest point is at the front right
bodyFaces = vehicleMesh.Faces(vehicleMesh.FaceWheelIndex==0,:);
restClearance = min(vehicleMesh.Vertices(unique(bodyFaces(:)),3));
assert(abs(clearance(1) - restClearance) < 1e-9);
[~, worstIndex] = min(clearance);
assert(lowestPoint(worstIndex,1) > mean(vehicleMesh.AxleX) && lowestPoint(worstIndex,2) < 0);
assert(any(flagContact) && ~flagContact(1));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_    ___ __ _ ___  ___  ___
%    | |/ _ \/ __| __|  / __/ _` / __|/ _ \/ __|
%    | |  __/\__ \ |_  | (_| (_| \__ \  __/\__ \
%    |_|\___||___/\__|  \___\__,_|___/\___||___/
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: Heave alone: contact exactly when the body drops by its ground clearance
figNum = 20001;
titleString = sprintf('TEST case: Heave alone: contact exactly when the body drops by its ground clearance');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

vehicleMesh = fcn_INTERNAL_fittedSample;
bodyFaces = vehicleMesh.Faces(vehicleMesh.FaceWheelIndex==0,:);
restClearance = min(vehicleMesh.Vertices(unique(bodyFaces(:)),3));
heaveValues = -restClearance + [0.01; 0; -0.01];
[flagContact, clearance] = fcn_CarMesh3D_checkGroundContact(vehicleMesh, zeros(3,1), zeros(3,1), heaveValues, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable values
assert(max(abs(clearance - [0.01; 0; -0.01])) < 1e-9);
assert(isequal(flagContact, [false; true; true]));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: Same answer as moving the body the way plotVehicle does
figNum = 20002;
titleString = sprintf('TEST case: Same answer as moving the body the way plotVehicle does');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

roll = deg2rad(5); pitch = deg2rad(-3); heave = 0.02;
plotHandles = fcn_CarMesh3D_plotVehicle(vehicleMesh, BodyRoll=roll, BodyPitch=pitch, BodyHeave=heave, FigNum=figNum);
title(titleString, 'Interpreter','none');
bodyVertices = vehicleMesh.Vertices(unique(bodyFaces(:)),:);
movedVertices = (plotHandles.BodyTransform.Matrix*[bodyVertices ones(size(bodyVertices,1),1)]')';
[~, clearance] = fcn_CarMesh3D_checkGroundContact(vehicleMesh, roll, pitch, heave);
assert(abs(clearance - min(movedVertices(:,3))) < 1e-9);

% A safety margin: flagged when closer than 5 cm
flagMargin = fcn_CarMesh3D_checkGroundContact(vehicleMesh, roll, pitch, -clearance + 0.04, MinimumClearance=0.05);
assert(flagMargin);

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ______        _     __  __           _        _______        _
% |  ____|      | |   |  \/  |         | |      |__   __|      | |
% | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
% |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
% | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
% |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 8

close all;
fprintf(1,'Figure: 8XXXXXX: FAST mode cases\n');

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
figure(figNum); close(figNum);

flagContact = fcn_CarMesh3D_checkGroundContact(vehicleMesh, zeros(5,1), zeros(5,1), 0, FigNum=[]);
assert(~any(flagContact));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Basic fast mode - FigNum of -1 skips the input checks and the warning
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);

[flagFast, clearanceFast] = fcn_CarMesh3D_checkGroundContact(vehicleMesh, deg2rad(30)*ones(2,1), zeros(2,1), 0, FigNum=-1);
assert(all(flagFast) && all(clearanceFast < 0));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% All bug case figures start with the number 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: Roll and pitch of different lengths
if 1==0
    fcn_CarMesh3D_checkGroundContact(fcn_INTERNAL_fittedSample, zeros(3,1), zeros(2,1), 0);
end

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_fittedSample
function vehicleMesh = fcn_INTERNAL_fittedSample
% The built-in sample car, prepared and fitted to the sedan preset
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Preset='genericSedan', FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fillSampleMesh(FigNum=-1);
vehicleMesh = fcn_CarMesh3D_normalizeMesh(vehicleMesh, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_labelParts(vehicleMesh, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_fitMeshToSpec(vehicleMesh, vehicleSpec, FigNum=-1);
vehicleMesh = fcn_CarMesh3D_simplifyMesh(vehicleMesh, FigNum=-1);
end % Ends fcn_INTERNAL_fittedSample
