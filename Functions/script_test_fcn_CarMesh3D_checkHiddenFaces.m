% script_test_fcn_CarMesh3D_checkHiddenFaces.m
% Tests fcn_CarMesh3D_checkHiddenFaces
% Warns about hidden faces that could mislead: many hidden faces, hidden
% faces that change a dimension, and hidden faces outside the shown
% vehicle's bounding box.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_checkHiddenFaces
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_23 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_checkHiddenFaces
%   % * (fill in items here)


%% Set up the workspace
close all

% The sample, fit to an example spec, with a hidden "muffler": a box
% under the rear that hangs 6 cm below the body and sticks 10 cm out
% behind it (Sean's example, 04:17)
vehicleSpec = fcn_CarMesh3D_fillVehicleSpec(Name='Example compact car', ...
    OverallLength=4.55, OverallWidth=1.80, OverallHeight=1.42, Wheelbase=2.70, TrackFront=1.55, TrackRear=1.56, ...
    TireSize='205/55R16', FrontOverhang=0.88, GroundClearance=0.14, FigNum=-1);
sampleMesh = fcn_CarMesh3D_labelParts(fcn_CarMesh3D_fillSampleMesh(FigNum=-1), FigNum=-1);
sampleMesh = fcn_CarMesh3D_fitMeshToSpec(sampleMesh, vehicleSpec, FigNum=-1);
bodyFaces = find(sampleMesh.LabelFacePart==find(strcmp(sampleMesh.LabelPartNames,'body')) & sampleMesh.FaceWheelIndex==0);
bodyVertices = sampleMesh.Vertices(unique(sampleMesh.Faces(bodyFaces,:)),:);
rearX = min(bodyVertices(:,1));
lowZ = min(bodyVertices(:,3));
[mufflerMesh, mufflerFaces] = fcn_INTERNAL_addBox(sampleMesh, bodyFaces(1), [rearX-0.10 rearX+0.50 -0.45 -0.30 lowZ-0.06 lowZ+0.05]);
hiddenMesh = fcn_CarMesh3D_editLabels(mufflerMesh, Edits={struct('FaceIndices',mufflerFaces,'Hide','muffler')}, FigNum=-1);

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

%% DEMO case: A hidden muffler that hangs low and sticks out behind
figNum = 10001;
titleString = sprintf('DEMO case: A hidden muffler that hangs low and sticks out behind');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

warningState = warning('off', 'CarMesh3D:hiddenChangesDimension');
warning('off', 'CarMesh3D:hiddenOutsideBox');
report = fcn_CarMesh3D_checkHiddenFaces(hiddenMesh, vehicleSpec, FigNum=figNum);
warning(warningState);
sgtitle(titleString, 'Interpreter','none');
fprintf(1, '%s\n\n', report.Messages{:});

% Check variable types
assert(isstruct(report) && istable(report.Sets) && istable(report.Dimensions) && istable(report.OutsideBox));

% Check variable sizes
assert(height(report.Sets) == 1);

% Check variable values
assert(report.NumHidden == numel(mufflerFaces) && report.Sets.Name == "muffler");
assert(any(report.Dimensions.Quantity == "GroundClearance"), 'The muffler changes the ground clearance');
row = find(report.Dimensions.Quantity == "GroundClearance");
assert(report.Dimensions.WithHidden_m(row) < report.Dimensions.Shown_m(row) - 0.05);
% (out past the rear; not past the bottom: the tires reach the ground)
assert(any(report.OutsideBox.Side == "rear") && ~any(report.OutsideBox.Side == "bottom"));
assert(abs(report.OutsideBox.Distance_m(report.OutsideBox.Side == "rear") - 0.10) < 1e-6);
assert(numel(report.Messages) == 2);   % (not many hidden faces)

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

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

%% TEST case: The warnings are printed, with their IDs; FlagVerbose=false prints none
figNum = 20001;
titleString = sprintf('TEST case: The warnings are printed, with their IDs; FlagVerbose=false prints none');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

lastwarn('');
warningState = warning('off', 'CarMesh3D:hiddenChangesDimension');
fcn_CarMesh3D_checkHiddenFaces(hiddenMesh, vehicleSpec);
warning(warningState);
[~, warningID] = lastwarn;
assert(strcmp(warningID, 'CarMesh3D:hiddenOutsideBox'));
lastwarn('');
fcn_CarMesh3D_checkHiddenFaces(hiddenMesh, vehicleSpec, FlagVerbose=false);
assert(isempty(lastwarn));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Many hidden faces; hidden faces inside the vehicle give no warning
figNum = 20002;
titleString = sprintf('TEST case: Many hidden faces; hidden faces inside the vehicle give no warning');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% (the interior-side half of the body faces near the middle: inside the box)
faceCenters = (sampleMesh.Vertices(sampleMesh.Faces(:,1),:) + sampleMesh.Vertices(sampleMesh.Faces(:,2),:) + ...
    sampleMesh.Vertices(sampleMesh.Faces(:,3),:))/3;
insideFaces = find(abs(faceCenters(:,1) - mean(faceCenters(:,1))) < 0.5 & sampleMesh.FaceWheelIndex==0);
manyMesh = fcn_CarMesh3D_editLabels(sampleMesh, Edits={struct('FaceIndices',insideFaces,'Hide','middle')}, FigNum=-1);
report = fcn_CarMesh3D_checkHiddenFaces(manyMesh, [], ManyFraction=0.01, FlagVerbose=false);
assert(isempty(report.OutsideBox) || all(report.OutsideBox.Distance_m > 0.01));
assert(any(contains(report.Messages, 'are hidden')), 'Many hidden faces reported');
assert(isempty(report.Dimensions));   % (no spec: no dimensions)
% (no hidden faces: nothing to report)
report = fcn_CarMesh3D_checkHiddenFaces(sampleMesh, vehicleSpec, FlagVerbose=false);
assert(report.NumHidden == 0 && isempty(report.Messages));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% Fast Mode Tests

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
figure(figNum); close(figNum);
report = fcn_CarMesh3D_checkHiddenFaces(hiddenMesh, [], FlagVerbose=false, FigNum=-1);
assert(report.NumHidden == numel(mufflerFaces));
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

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
if 1==0
    %% FAIL case: Not a mesh
    fcn_CarMesh3D_checkHiddenFaces(42, []);

    %% FAIL case: A negative tolerance
    fcn_CarMesh3D_checkHiddenFaces(hiddenMesh, [], Tolerance=-1);
end

fprintf(1,'All tests of fcn_CarMesh3D_checkHiddenFaces passed\n');

%% Functions follow
function [boxMesh, newFaces] = fcn_INTERNAL_addBox(vehicleMesh, likeFace, box)
% Adds a closed box [xmin xmax ymin ymax zmin zmax] of 12 triangles, each
% with the per-face fields of the face likeFace
corners = [box(1) box(3) box(5); box(2) box(3) box(5); box(2) box(4) box(5); box(1) box(4) box(5); ...
    box(1) box(3) box(6); box(2) box(3) box(6); box(2) box(4) box(6); box(1) box(4) box(6)];
boxFaces = [1 3 2; 1 4 3; 5 6 7; 5 7 8; 1 2 6; 1 6 5; 2 3 7; 2 7 6; 3 4 8; 3 8 7; 4 1 5; 4 5 8];
numFaces = size(vehicleMesh.Faces,1);
boxMesh = vehicleMesh;
for name = fieldnames(vehicleMesh)'
    value = vehicleMesh.(name{1});
    if ~strcmp(name{1}, 'Faces') && (isnumeric(value) || islogical(value)) && size(value,1) == numFaces && numFaces > 1
        boxMesh.(name{1}) = [value; repmat(value(likeFace,:), 12, 1)];
    end
end
boxMesh.Faces = [vehicleMesh.Faces; boxFaces + size(vehicleMesh.Vertices,1)];
boxMesh.Vertices = [vehicleMesh.Vertices; corners];
newFaces = (numFaces+1 : numFaces+12)';
end % Ends fcn_INTERNAL_addBox
