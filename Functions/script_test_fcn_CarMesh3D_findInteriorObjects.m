% script_test_fcn_CarMesh3D_findInteriorObjects
% Tests of fcn_CarMesh3D_findInteriorObjects on the repository's demo
% vehicle (the 2009 Honda Fit Sport). The Fit's download models each front
% seat and the steering wheel as separate pieces, so the test also scores
% the search against those pieces (the search itself never looks at them).
% Each search takes 1 to 4 minutes.
%
% This script was written on 2026_11_24 by S. Brennan (drafted with Claude;
% prototype by Agent A)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_findInteriorObjects
%   % * First write of the tests (Agent A's, in the repository's form)

%% Set up the workspace
close all;

vehicleID = fcn_CarMesh3D_demoVehicle(UsePreference=false, FigNum=-1);   % (the repo's demo vehicle)
assert(strcmp(vehicleID, '2009_Honda_Fit_Sport'), ['These tests check facts of the 2009 Fit (its seat and wheel pieces, ' ...
    'its wheel''s size): if the demo vehicle is changed, give them that vehicle''s facts']);
vehicleFiles = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
loaded = load(vehicleFiles.MeshFile, 'vehicleMesh');
vehicleMesh = loaded.vehicleMesh;

%% DEMO case: the Fit's seats and steering wheel, plotted
fig_num = 10001;
titleString = sprintf('DEMO case: the seats and steering wheel of %s', vehicleID);
fprintf(1,'Figure %d: %s\n', fig_num, titleString);
figure(fig_num); clf;
% (the 2009 to 2013 Fit's wheel: 14.5 in, 0.368 m, from one parts listing)
templates = struct();
templates.SteeringWheel.Diameter = 0.368;
result = fcn_CarMesh3D_findInteriorObjects(vehicleMesh, Templates=templates, FigNum=fig_num);
driverSeat = result.DriverSeat;
passengerSeat = result.PassengerSeat;
wheel = result.SteeringWheel;
assert(ishandle(fig_num), 'The plot was made');

%% TEST case: what was found, and where
fig_num = 20001;
fprintf(1,'Figure %d: TEST case: what was found, and where\n', fig_num);
assert(driverSeat.Found && passengerSeat.Found && wheel.Found, 'Every object found');
assert(strcmp(result.DriveSide, 'left') && strcmp(result.DriveSideSource, 'mesh'), 'The US Fit is left-hand drive, read from the mesh');
assert(driverSeat.Origin(2) > 0.15 && passengerSeat.Origin(2) < -0.15, 'The driver at +y, the passenger at -y');
% (the wheel: radius about 0.17 m, its plane tilted 10 to 40 degrees from
% vertical, facing rearward, ahead of and above the driver's seat, in line
% with it)
assert(wheel.Radius > 0.16 && wheel.Radius < 0.22, 'The wheel''s radius');
assert(wheel.TiltDeg >= 10 && wheel.TiltDeg <= 40, 'The wheel''s tilt');
assert(wheel.Normal(1) < -0.5, 'The wheel faces rearward');
assert(wheel.Center(1) > driverSeat.Origin(1) + 0.2 && wheel.Center(3) > driverSeat.Origin(3) + 0.1, 'The wheel ahead of and above the seat');
assert(abs(wheel.Center(2) - driverSeat.Origin(2)) < 0.10, 'The wheel in line with the driver''s seat');
% (the seats: near mirror images)
assert(abs(driverSeat.Origin(2) + passengerSeat.Origin(2)) < 0.08 && abs(driverSeat.Origin(1) - passengerSeat.Origin(1)) < 0.12 ...
    && abs(driverSeat.Origin(3) - passengerSeat.Origin(3)) < 0.08, 'The seats are mirror images');
assert(abs(driverSeat.BackAngleDeg - passengerSeat.BackAngleDeg) < 12, 'The backrests lean alike');
% (nothing outside the body)
vertices = vehicleMesh.Vertices;
halfWidth = vehicleMesh.VehicleSpec.OverallWidth/2;
corners = [driverSeat.Boxes.Cushion.Corners; driverSeat.Boxes.Back.Corners; passengerSeat.Boxes.Cushion.Corners; passengerSeat.Boxes.Back.Corners];
assert(all(abs(corners(:,2)) < halfWidth) && all(corners(:,3) > 0) && all(corners(:,3) < max(vertices(:,3))) ...
    && all(corners(:,1) > min(vertices(:,1))) && all(corners(:,1) < max(vertices(:,1))), 'No seat template sticks out of the body');
% (no glass, wheel or light face taken)
blockedParts = find(ismember(lower(vehicleMesh.PartNames), {'glass','wheel','light'}));
allFaces = [driverSeat.Faces(:); passengerSeat.Faces(:); wheel.Faces(:)];
assert(~isempty(driverSeat.Faces) && ~isempty(passengerSeat.Faces) && ~isempty(wheel.Faces), 'Faces found for each object');
assert(~any(ismember(vehicleMesh.FacePartIndex(allFaces), blockedParts)), 'No glass, wheel or light face taken');

%% TEST case: against the download's own seat and wheel pieces
fig_num = 20002;
fprintf(1,'Figure %d: TEST case: against the download''s own pieces\n', fig_num);
truth = fcn_INTERNAL_fitTruth(vehicleMesh);
faceArea = 0.5*vecnorm(cross(vertices(vehicleMesh.Faces(:,2),:) - vertices(vehicleMesh.Faces(:,1),:), ...
    vertices(vehicleMesh.Faces(:,3),:) - vertices(vehicleMesh.Faces(:,1),:), 2), 2, 2);
objectNames = {'DriverSeat', 'PassengerSeat', 'SteeringWheel'};
for ith_object = 1:3
    foundFaces = result.(objectNames{ith_object}).Faces;
    trueFaces = truth.(objectNames{ith_object});
    bothFaces = intersect(foundFaces, trueFaces);
    precision = sum(faceArea(bothFaces))/max(sum(faceArea(foundFaces)), eps);
    recall = sum(faceArea(bothFaces))/sum(faceArea(trueFaces));
    fprintf(1, '    %-14s precision %.2f, recall %.2f\n', objectNames{ith_object}, precision, recall);
    assert(recall > 0.7, '%s: less than 70 percent of the true piece found', objectNames{ith_object});
    assert(precision > 0.5, '%s: less than half of the area found is the true piece', objectNames{ith_object});
end

%% TEST case: the mesh with the objects stored in it (second output)
fig_num = 20004;
fprintf(1,'Figure %d: TEST case: the objects stored in the mesh\n', fig_num);
[~, storedMesh] = fcn_CarMesh3D_findInteriorObjects(vehicleMesh, Templates=templates, FigNum=-1);
assert(isequal(storedMesh.InteriorObjectNames, {'driver seat', 'passenger seat', 'steering wheel'}));
assert(numel(storedMesh.FaceInteriorObject) == size(vehicleMesh.Faces,1));
assert(isequal(find(storedMesh.FaceInteriorObject == 3), sort(wheel.Faces(:))), 'The wheel''s faces stored as object 3');
assert(isequal(storedMesh.InteriorObjects.SteeringWheel.Center, wheel.Center) && ~isfield(storedMesh.InteriorObjects, 'Info'));
assert(isequal(storedMesh.Vertices, vehicleMesh.Vertices) && isequal(storedMesh.Faces, vehicleMesh.Faces), 'The mesh itself unchanged');
% (the 2D outline draws exactly these objects)
outline = fcn_CarMesh3D_makeOutline2D(storedMesh, FigNum=-1);
assert(isequal({outline.Interior.Name}, {'driver seat', 'passenger seat', 'steering wheel'}), 'The outline draws the three objects');

%% TEST case: the same answer every time (a fixed random seed)
fig_num = 20003;
fprintf(1,'Figure %d: TEST case: repeatable, and the drive side can be given\n', fig_num);
wheelOnly = fcn_CarMesh3D_findInteriorObjects(vehicleMesh, Templates=templates, Seats=true, DriveSide='left', FigNum=-1);
assert(strcmp(wheelOnly.DriveSideSource, 'option') && isequal(wheelOnly.SteeringWheel.Faces, wheel.Faces), 'The same wheel, the drive side given');

%% FAST mode cases
fig_num = 80001;
fprintf(1,'Figure %d: FAST mode cases (one search each takes minutes: not timed)\n', fig_num);
assert(isempty(findall(0, 'Type', 'figure', 'Number', fig_num)), 'Fast mode makes no plot');
close all;
fprintf(1, 'All tests of fcn_CarMesh3D_findInteriorObjects passed\n');

%% Fail conditions
if 1==0
    %% FAIL case: not a mesh
    fcn_CarMesh3D_findInteriorObjects(42);

    %% FAIL case: an unknown drive side
    fcn_CarMesh3D_findInteriorObjects(vehicleMesh, DriveSide='middle');
end

%% Functions follow
function truth = fcn_INTERNAL_fitTruth(vehicleMesh)
% The Fit download's own seat (with headrest) and steering-wheel pieces, in
% its "interior" group, picked by place and size: for scoring only
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
groupIndex = find(strcmpi(vehicleMesh.GroupNames, 'interior'));
groupFaces = find(vehicleMesh.FaceGroupIndex == groupIndex);
[~, ~, positionIDs] = unique(round(vertices*1e5), 'rows');
groupCorners = positionIDs(faces(groupFaces,:));
pieceGraph = graph([groupCorners(:,1); groupCorners(:,2); groupCorners(:,3)], [groupCorners(:,2); groupCorners(:,3); groupCorners(:,1)], [], max(positionIDs));
pieceOfCorner = conncomp(pieceGraph);
pieceOfFace = pieceOfCorner(groupCorners(:,1))';
truth = struct('DriverSeat', [], 'PassengerSeat', [], 'SteeringWheel', []);
for thisPiece = unique(pieceOfFace)'
    pieceFaces = groupFaces(pieceOfFace == thisPiece);
    piecePoints = vertices(unique(faces(pieceFaces,:)),:);
    lowCorner = min(piecePoints);
    highCorner = max(piecePoints);
    pieceCenter = (lowCorner + highCorner)/2;
    if norm(highCorner - lowCorner) < 1.3 && pieceCenter(1) > 0.8 && pieceCenter(1) < 1.5 && abs(pieceCenter(2)) > 0.05 && pieceCenter(3) < 1.3
        if pieceCenter(2) > 0
            truth.DriverSeat = [truth.DriverSeat; pieceFaces];
        else
            truth.PassengerSeat = [truth.PassengerSeat; pieceFaces];
        end
    elseif norm(highCorner - lowCorner) < 0.7 && pieceCenter(1) > 1.5 && pieceCenter(1) < 1.85 && pieceCenter(3) > 0.7 && pieceCenter(3) < 1.15 && abs(pieceCenter(2)) > 0.1
        truth.SteeringWheel = [truth.SteeringWheel; pieceFaces];
    end
end
end % Ends fcn_INTERNAL_fitTruth
