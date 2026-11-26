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
headlights = vehicleOutline.Lights(strcmp(lightTypes, 'headlamp'));
tails = vehicleOutline.Lights(strcmp(lightTypes, 'tailBrakeLamp'));
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
tailType = find(strcmp(oneSided.LightTypeNames, 'tailBrakeLamp'));
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
tracedTails = traced.Lights(strcmp({traced.Lights.Type}, 'tailBrakeLamp'));
mirroredTails = mirroredOutline.Lights(strcmp({mirroredOutline.Lights.Type}, 'tailBrakeLamp'));
assert(all(strcmp({tracedTails.Side}, 'left')));
assert(any(strcmp({mirroredTails.Side}, 'right')) && ~isempty(mirroredOutline.Symmetry.Added));
assert(strcmp(warningID, 'CarMesh3D:asymmetricOutline'));                    % (warned even when kept as traced)

%% TEST case: A lamp whose faces share no corners is still one lamp
figNum = 20004;
titleString = sprintf('TEST case: A lamp whose faces share no corners is still one lamp');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% (every light face given its own three corners, as in some downloads: the
% 2009 Honda Fit's lamps came out as 120 to 140 outlines each)
splitMesh = priusMesh;
lightPart = find(strcmp(splitMesh.PartNames, 'light'));
lightRows = find(splitMesh.FacePartIndex==lightPart);
newCorners = splitMesh.Faces(lightRows,:)';
splitMesh.Faces(lightRows,:) = size(splitMesh.Vertices,1) + reshape(1:numel(newCorners), 3, [])';
splitMesh.Vertices = [splitMesh.Vertices; splitMesh.Vertices(newCorners(:),:)];
warningState = warning('off', 'CarMesh3D:asymmetricOutline');
wholeOutline = fcn_CarMesh3D_makeOutline2D(priusMesh);
splitOutline = fcn_CarMesh3D_makeOutline2D(splitMesh);
warning(warningState);

% Check variable values: the same lamps, by type and side
assert(numel(splitOutline.Lights) == numel(wholeOutline.Lights));
lampNames = @(o) sort(arrayfun(@(l) sprintf('%s %s', l.Side, l.Type), o.Lights, 'UniformOutput', false));
assert(isequal(lampNames(splitOutline), lampNames(wholeOutline)));
% (and no more than a few lamps per type and side: front, rear, mirror)
[~, ~, groupOf] = unique(lampNames(splitOutline));
assert(max(accumarray(groupOf(:), 1)) <= 3);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Interior pieces are outlined, inside the body, and not mirrored
figNum = 20005;
titleString = sprintf('TEST case: Interior pieces are outlined, inside the body, and not mirrored');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

warningState = warning('off', 'CarMesh3D:asymmetricOutline');
plainOutline = fcn_CarMesh3D_makeOutline2D(priusMesh);
interiorMesh = fcn_CarMesh3D_labelInterior(priusMesh, FigNum=-1);
interiorOutline = fcn_CarMesh3D_makeOutline2D(interiorMesh);
% (one interior piece on the left only: it must not get a mirrored twin)
oneSided = interiorMesh;
interiorPart = find(strcmp(oneSided.PartNames,'interior'));
oneSided.Vertices(end+1:end+3,:) = [1.5 0.30 0.9; 1.7 0.30 0.9; 1.6 0.50 0.9];
oneSided.Faces(end+1,:) = size(oneSided.Vertices,1) + [-2 -1 0];
for fieldName = {'FacePartIndex','FaceWheelIndex','FaceLightType','FaceMaterialIndex','FaceGroupIndex','FaceAlpha'}
    if isfield(oneSided, fieldName{1})
        oneSided.(fieldName{1})(end+1,:) = 0;
    end
end
oneSided.FacePartIndex(end) = interiorPart;
oneSided.FaceAlpha(end) = 1;
oneSided.FaceColors(end+1,:) = [0.3 0.3 0.3];
oneSidedOutline = fcn_CarMesh3D_makeOutline2D(oneSided);
warning(warningState);

% Check variable values
assert(isempty(plainOutline.Interior));                       % (no interior part)
assert(numel(oneSidedOutline.Interior) == numel(interiorOutline.Interior) + 1);
bodyShape = polyshape(interiorOutline.Body(1:end-1,:));
for ith_piece = 1:numel(interiorOutline.Interior)
    piecePoints = interiorOutline.Interior(ith_piece).Polygon;
    assert(all(isinterior(polybuffer(bodyShape, 0.02), piecePoints(:,1), piecePoints(:,2))));
end
% (the added piece: a 0.02 m^2 triangle around (1.6, 0.37), on the left;
% no such triangle on the right)
pieceArea = arrayfun(@(p) polyarea(p.Polygon(:,1), p.Polygon(:,2)), oneSidedOutline.Interior);
pieceCenter = cell2mat(arrayfun(@(p) mean(p.Polygon(1:end-1,:),1), oneSidedOutline.Interior(:), 'UniformOutput', false));
isAdded = abs(pieceArea(:) - 0.02) < 1e-3 & abs(pieceCenter(:,1) - 1.6) < 0.05 & abs(pieceCenter(:,2) - 0.367) < 0.05;
isMirror = abs(pieceArea(:) - 0.02) < 1e-3 & abs(pieceCenter(:,1) - 1.6) < 0.05 & abs(pieceCenter(:,2) + 0.367) < 0.05;
assert(nnz(isAdded) == 1 && nnz(isMirror) == 0);

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: Interior objects only: driver seat, passenger seat, steering wheel (2026-11-24)
figNum = 20006;
titleString = sprintf('TEST case: Interior objects only: the seats and the steering wheel');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

% (objects as fcn_CarMesh3D_findInteriorObjects gives them: the interior
% part's faces on the left as the driver seat, on the right as the
% passenger seat, and the added one-sided triangle as the steering wheel;
% the rest of the interior part must NOT be outlined)
faceCentersY = (oneSided.Vertices(oneSided.Faces(:,1),2) + oneSided.Vertices(oneSided.Faces(:,2),2) + oneSided.Vertices(oneSided.Faces(:,3),2))/3;
isInterior = oneSided.FacePartIndex(:) == interiorPart;
wheelFace = size(oneSided.Faces,1);
found = struct( ...
    'DriverSeat', struct('Found', true, 'Faces', setdiff(find(isInterior & faceCentersY > 0.15), wheelFace)), ...
    'PassengerSeat', struct('Found', true, 'Faces', find(isInterior & faceCentersY < -0.15)), ...
    'SteeringWheel', struct('Found', true, 'Faces', wheelFace));
warningState = warning('off', 'CarMesh3D:asymmetricOutline');
objectOutline = fcn_CarMesh3D_makeOutline2D(oneSided, InteriorObjects=found);
% (the same objects stored in the mesh itself, as a build will store them)
storedMesh = oneSided;
storedMesh.FaceInteriorObject = zeros(size(storedMesh.Faces,1),1);
storedMesh.FaceInteriorObject(found.DriverSeat.Faces) = 1;
storedMesh.FaceInteriorObject(found.PassengerSeat.Faces) = 2;
storedMesh.FaceInteriorObject(wheelFace) = 3;
storedMesh.InteriorObjectNames = {'driver seat', 'passenger seat', 'steering wheel'};
storedOutline = fcn_CarMesh3D_makeOutline2D(storedMesh);
% (an object not found is left out)
notFound = found;
notFound.SteeringWheel.Found = false;
noWheelOutline = fcn_CarMesh3D_makeOutline2D(oneSided, InteriorObjects=notFound);
warning(warningState);

% Check variable values
assert(isequal({objectOutline.Interior.Name}, {'driver seat', 'passenger seat', 'steering wheel'}), 'One outline per object, in order');
assert(isequal(storedOutline.Interior, objectOutline.Interior), 'Objects stored in the mesh give the same outlines');
assert(isequal({noWheelOutline.Interior.Name}, {'driver seat', 'passenger seat'}), 'An object not found is left out');
wheelPolygon = objectOutline.Interior(3).Polygon;
assert(abs(polyarea(wheelPolygon(:,1), wheelPolygon(:,2)) - 0.02) < 1e-3 && mean(wheelPolygon(1:end-1,2)) > 0.3, 'The steering wheel outlined on its side, not mirrored');
driverCenter = mean(objectOutline.Interior(1).Polygon(1:end-1,:),1);
passengerCenter = mean(objectOutline.Interior(2).Polygon(1:end-1,:),1);
assert(driverCenter(2) > 0 && passengerCenter(2) < 0, 'The seats on their own sides');
bodyShape = polyshape(objectOutline.Body(1:end-1,:));
for ith_piece = 1:numel(objectOutline.Interior)
    piecePoints = objectOutline.Interior(ith_piece).Polygon;
    assert(all(isinterior(polybuffer(bodyShape, 0.02), piecePoints(:,1), piecePoints(:,2))), 'Inside the body');
end

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

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

%% FAIL case: A LampGap that is not positive
if 1==0
    fcn_CarMesh3D_makeOutline2D(priusMesh, LampGap=0);
end

%% FAIL case: A mesh without labels
if 1==0
    fcn_CarMesh3D_makeOutline2D(struct('Vertices',rand(3), 'Faces',[1 2 3]));
end
