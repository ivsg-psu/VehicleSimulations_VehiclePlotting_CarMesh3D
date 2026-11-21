% script_test_fcn_CarMesh3D_makeOutline2D.m
% Tests fcn_CarMesh3D_makeOutline2D
% Makes a vehicle's top-down (2D) outlines from its finished mesh.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makeOutline2D
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_makeOutline2D
%   % * (fill in items here)


%% Set up the workspace
close all

priusFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
loaded = load(priusFiles.MeshFile, 'vehicleMesh', 'vehicleSpec');
priusMesh = loaded.vehicleMesh;
priusSpec = loaded.vehicleSpec;

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

%% DEMO case: The Prius's top-down outlines
figNum = 10001;
titleString = sprintf('DEMO case: The Prius''s top-down outlines');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleOutline = fcn_CarMesh3D_makeOutline2D(priusMesh, FigNum=figNum);

% Check variable types
assert(isstruct(vehicleOutline) && isnumeric(vehicleOutline.Body));

% Check variable sizes
assert(size(vehicleOutline.Body,2)==2 && numel(vehicleOutline.Wheels)==4);

% Check variable values: the body's size is the car's (with mirrors), the
% polygon is closed and counterclockwise, and sparse
assert(abs(vehicleOutline.Length - priusSpec.OverallLength) < 0.01);
assert(abs(vehicleOutline.Width - priusSpec.WidthWithMirrors) < 0.02);
assert(isequal(vehicleOutline.Body(1,:), vehicleOutline.Body(end,:)));
body = vehicleOutline.Body;
assert(0.5*sum(body(1:end-1,1).*body(2:end,2) - body(2:end,1).*body(1:end-1,2)) > 0);
assert(size(body,1) < 400 && vehicleOutline.PointCount < 1500);

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

%% TEST case: Wheels at the axles and tracks; windows inside the body; lights at the ends
figNum = 20001;
titleString = sprintf('TEST case: Wheels at the axles and tracks; windows inside the body; lights at the ends');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

vehicleOutline = fcn_CarMesh3D_makeOutline2D(priusMesh);
wheelNames = {vehicleOutline.Wheels.Name};
assert(isequal(wheelNames, {'FL','FR','RL','RR'}));
centers = reshape([vehicleOutline.Wheels.Center], 2, [])';
assert(max(abs(centers(:,1) - [priusSpec.Wheelbase; priusSpec.Wheelbase; 0; 0])) < 0.02);
assert(abs(centers(1,2) - centers(2,2) - priusSpec.TrackFront) < 0.03);
assert(all([vehicleOutline.Wheels(1:2).Steers]) && ~any([vehicleOutline.Wheels(3:4).Steers]));
assert(all(abs([vehicleOutline.Wheels.Length] - priusSpec.TireDiameter) < 0.02));
assert(numel(vehicleOutline.Windows) >= 2);
for ith_window = 1:numel(vehicleOutline.Windows)
    windowPoints = vehicleOutline.Windows(ith_window).Polygon;
    assert(all(inpolygon(windowPoints(:,1), windowPoints(:,2), vehicleOutline.Body(:,1), vehicleOutline.Body(:,2))));
end
lightTypes = {vehicleOutline.Lights.Type};
headlights = vehicleOutline.Lights(strcmp(lightTypes, 'headlight'));
tails = vehicleOutline.Lights(strcmp(lightTypes, 'tail'));
assert(~isempty(headlights) && ~isempty(tails));
assert(min(arrayfun(@(l) mean(l.Polygon(:,1)), headlights)) > max(arrayfun(@(l) mean(l.Polygon(:,1)), tails)));

%% TEST case: A coarser tolerance gives fewer points; the van's outline
figNum = 20002;
titleString = sprintf('TEST case: A coarser tolerance gives fewer points; the van''s outline');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

fine = fcn_CarMesh3D_makeOutline2D(priusMesh, Tolerance=0.005);
coarse = fcn_CarMesh3D_makeOutline2D(priusMesh, Tolerance=0.05);
assert(size(coarse.Body,1) < size(fine.Body,1));
vanFiles = fcn_CarMesh3D_findVehicleFiles('2014_Ford_TransitConnect_XLTCargoLWB');
vanLoaded = load(vanFiles.MeshFile, 'vehicleMesh', 'vehicleSpec');
vanOutline = fcn_CarMesh3D_makeOutline2D(vanLoaded.vehicleMesh, FigNum=figNum);
assert(abs(vanOutline.Length - vanLoaded.vehicleSpec.OverallLength) < 0.01);

%% TEST case: Symmetric outlines; a lamp labeled on one side only gets a mirrored twin
figNum = 20003;
titleString = sprintf('TEST case: Symmetric outlines; a lamp labeled on one side only gets a mirrored twin');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

warningState = warning('off', 'CarMesh3D:asymmetricOutline');
vehicleOutline = fcn_CarMesh3D_makeOutline2D(priusMesh);
body = vehicleOutline.Body;
mirroredBody = sortrows(round([body(1:end-1,1), -body(1:end-1,2)], 9));
assert(isequal(sortrows(round(body(1:end-1,:), 9)), mirroredBody));            % (the body is its own mirror image)
assert(isstruct(vehicleOutline.Symmetry) && vehicleOutline.Symmetry.Symmetric);
assert(numel(vehicleOutline.Symmetry.Windows)==numel(vehicleOutline.Windows));
% (the right tail lamp relabeled as body: the left one is mirrored onto the right)
oneSided = priusMesh;
lightPart = find(strcmp(oneSided.PartNames, 'light'));
tailType = find(strcmp(oneSided.LightTypeNames, 'tail'));
faceCenterY = (oneSided.Vertices(oneSided.Faces(:,1),2) + oneSided.Vertices(oneSided.Faces(:,2),2) + oneSided.Vertices(oneSided.Faces(:,3),2))/3;
rightTail = oneSided.FacePartIndex==lightPart & oneSided.FaceLightType==tailType & faceCenterY < 0;
oneSided.FacePartIndex(rightTail) = find(strcmp(oneSided.PartNames, 'body'));
oneSided.FaceLightType(rightTail) = 0;
lastwarn('');
traced = fcn_CarMesh3D_makeOutline2D(oneSided, Symmetric=false);
[~, warningID] = lastwarn;
warning('on', 'CarMesh3D:asymmetricOutline');
lastwarn('');
warning('off', 'CarMesh3D:asymmetricOutline');
mirroredOutline = fcn_CarMesh3D_makeOutline2D(oneSided);
warning(warningState);
tracedTails = traced.Lights(strcmp({traced.Lights.Type}, 'tail'));
mirroredTails = mirroredOutline.Lights(strcmp({mirroredOutline.Lights.Type}, 'tail'));
assert(all(strcmp({tracedTails.Side}, 'left')));
assert(any(strcmp({mirroredTails.Side}, 'right')) && ~isempty(mirroredOutline.Symmetry.Added));
assert(strcmp(warningID, 'CarMesh3D:asymmetricOutline'));                    % (warned even when kept as traced)

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
vehicleOutline = fcn_CarMesh3D_makeOutline2D(priusMesh, FigNum=[]);
assert(numel(vehicleOutline.Wheels)==4);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
vehicleOutline = fcn_CarMesh3D_makeOutline2D(priusMesh, FigNum=-1);
assert(numel(vehicleOutline.Wheels)==4);

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

%% FAIL case: A SymmetryTolerance that is not positive
if 1==0
    fcn_CarMesh3D_makeOutline2D(priusMesh, SymmetryTolerance=-1);
end

%% FAIL case: A mesh without labels
if 1==0
    fcn_CarMesh3D_makeOutline2D(struct('Vertices',rand(3), 'Faces',[1 2 3]));
end
