% script_test_fcn_CarMesh3D_addFloorPanel.m
% Tests fcn_CarMesh3D_addFloorPanel

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addFloorPanel
%   % * First write
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addFloorPanel
%   % * The Prius's own floor panel is taken off first; the full-outline
%   %   % tests use OnlyWhereOpen=false
%   % * Tests of OnlyWhereOpen: a model with a floor under its rear half
%   %   % gets a panel under the front only; a model closed everywhere
%   %   % gets none

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addFloorPanel
%   % * (none yet)

%% Set up the workspace
close all;

% A finished mesh to test with (the Prius sample)
vehicleFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
load(vehicleFiles.MeshFile, 'vehicleMesh');
vehicleMesh = fcn_INTERNAL_withoutPanel(vehicleMesh);   % (its own panel, from when it was made, taken off)
Nfaces = size(vehicleMesh.Faces,1);

%% Basic call, with a plot
figNum = 10001;
panelMesh = fcn_CarMesh3D_addFloorPanel(vehicleMesh, FlagOnlyWhereOpen=false, FigNum=figNum);
assert(isfield(panelMesh,'FloorPanel'));
Npanel = numel(panelMesh.FloorPanel.Faces);
assert(Npanel > 0);
assert(size(panelMesh.Faces,1) == Nfaces + Npanel);
assert(size(panelMesh.LabelFacePart,1) == Nfaces + Npanel);
assert(size(panelMesh.FaceColors,1) == Nfaces + Npanel);
% (at the spec's ground clearance, its edges risen at most MaxRise,
% facing down, labeled trim)
panelCorners = unique(panelMesh.Faces(panelMesh.FloorPanel.Faces,:));
panelHeights = panelMesh.Vertices(panelCorners,3);
assert(abs(min(panelHeights) - vehicleMesh.VehicleSpec.GroundClearance) < 1e-9);
assert(max(panelHeights) <= vehicleMesh.VehicleSpec.GroundClearance + 0.30 + 1e-9);
assert(all(panelMesh.FaceNormals(panelMesh.FloorPanel.Faces,3) < 0));
assert(all(strcmp(panelMesh.LabelPartNames(panelMesh.LabelFacePart(panelMesh.FloorPanel.Faces)),'trim')));
assert(all(panelMesh.FaceWheelIndex(panelMesh.FloorPanel.Faces) == 0));
% (the wheel footprints are cut out: no panel over a wheel's center)
for ith_wheel = 1:4
    wheelCorners = unique(vehicleMesh.Faces(vehicleMesh.FaceWheelIndex==ith_wheel,:));
    wheelCenter = mean(vehicleMesh.Vertices(wheelCorners,1:2),1);
    assert(~isinterior(panelMesh.FloorPanel.Polygon, wheelCenter(1), wheelCenter(2)));
end
% (the panel's winding faces down: its computed normals point down)
corner1 = panelMesh.Vertices(panelMesh.Faces(panelMesh.FloorPanel.Faces,1),:);
normals = cross(panelMesh.Vertices(panelMesh.Faces(panelMesh.FloorPanel.Faces,2),:) - corner1, ...
    panelMesh.Vertices(panelMesh.Faces(panelMesh.FloorPanel.Faces,3),:) - corner1, 2);
assert(all(normals(:,3) < 0));
assert(ishandle(figNum));

%% A given height, flat (no blend), fast mode
panelMesh = fcn_CarMesh3D_addFloorPanel(vehicleMesh, Height=0.25, BlendWidth=0, FlagOnlyWhereOpen=false, FigNum=-1);
panelCorners = unique(panelMesh.Faces(panelMesh.FloorPanel.Faces,:));
assert(all(abs(panelMesh.Vertices(panelCorners,3) - 0.25) < 1e-9));

%% Only where open: the Prius download has its own closed underside, so it gets (almost) no panel
closedPrius = fcn_CarMesh3D_addFloorPanel(vehicleMesh, FigNum=-1);
assert(closedPrius.FloorPanel.OpenFraction < 0.05);

%% Only where open: with its underside taken off, it gets a panel where it is open
openPrius = fcn_INTERNAL_withoutUnderside(vehicleMesh, 0.4);
openMesh = fcn_CarMesh3D_addFloorPanel(openPrius, FigNum=-1);
fullMesh = fcn_CarMesh3D_addFloorPanel(openPrius, FlagOnlyWhereOpen=false, FigNum=-1);
assert(openMesh.FloorPanel.OpenFraction > 0.3 && openMesh.FloorPanel.OpenFraction <= 1);
assert(~isempty(openMesh.FloorPanel.Faces));
assert(area(openMesh.FloorPanel.Polygon) <= area(fullMesh.FloorPanel.Polygon) + 1e-6);
assert(fullMesh.FloorPanel.OpenFraction == 1);

%% Only where open: a floor under the rear half leaves the panel under the front only
% (a flat opaque plate from behind the car to 1.2 m, across it; at 0.65 m,
% above LowerBodyHeight so it does not change the outline, and below
% CoverHeight=0.7, so it closes the car from below)
lowCorners = openPrius.Vertices(unique(openPrius.Faces(openPrius.FaceWheelIndex==0,:)),:);
plateX = [min(lowCorners(:,1))-0.5 1.2];   % (from behind the car)
plateY = [-1 1];
plateMesh = fcn_INTERNAL_addPlate(openPrius, plateX, plateY, 0.65);
openMesh = fcn_CarMesh3D_addFloorPanel(openPrius, CoverHeight=0.7, FigNum=-1);
halfMesh = fcn_CarMesh3D_addFloorPanel(plateMesh, CoverHeight=0.7, FigNum=-1);
assert(halfMesh.FloorPanel.OpenFraction < openMesh.FloorPanel.OpenFraction);
panelCorners = unique(halfMesh.Faces(halfMesh.FloorPanel.Faces,:));
% (no panel more than Overlap plus a grid step inside the plate's area)
panelX = halfMesh.Vertices(panelCorners,1);
assert(all(panelX > plateX(2) - 0.03 - 0.03 - 1e-6 | abs(halfMesh.Vertices(panelCorners,2)) > 0.9));
assert(any(panelX > 1.5) || ~any(openMesh.Vertices(unique(openMesh.Faces(openMesh.FloorPanel.Faces,:)),1) > 1.5));   % (the front keeps any panel it had)

%% Only where open: a model closed everywhere from below gets no panel
closedMesh = fcn_INTERNAL_addPlate(openPrius, [-3 8], [-3 3], 0.65);
noneMesh = fcn_CarMesh3D_addFloorPanel(closedMesh, CoverHeight=0.7, FigNum=-1);
assert(isempty(noneMesh.FloorPanel.Faces));
assert(size(noneMesh.Faces,1) == size(closedMesh.Faces,1));
assert(noneMesh.FloorPanel.OpenFraction == 0);

%% FAIL: not a labeled mesh
if 1==0
    fcn_CarMesh3D_addFloorPanel(struct('Vertices',[],'Faces',[]), FigNum=1);
end

fprintf(1,'All tests of fcn_CarMesh3D_addFloorPanel passed\n');

%% Functions follow
function vehicleMesh = fcn_INTERNAL_withoutPanel(vehicleMesh)
% The mesh without a floor panel added when it was made
if ~isfield(vehicleMesh,'FloorPanel') || isempty(vehicleMesh.FloorPanel.Faces)
    return;
end
Nfaces = size(vehicleMesh.Faces,1);
keep = true(Nfaces,1);
keep(vehicleMesh.FloorPanel.Faces) = false;
for fieldName = reshape(fieldnames(vehicleMesh),1,[])
    thisValue = vehicleMesh.(fieldName{1});
    if ~strcmp(fieldName{1},'Vertices') && (isnumeric(thisValue) || islogical(thisValue)) && size(thisValue,1)==Nfaces
        vehicleMesh.(fieldName{1}) = thisValue(keep,:);
    end
end
vehicleMesh = rmfield(vehicleMesh,'FloorPanel');
end

function vehicleMesh = fcn_INTERNAL_withoutUnderside(vehicleMesh, belowHeight)
% The mesh without its downward-facing body faces below belowHeight (as a
% download with no underside)
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces;
Nfaces = size(faces,1);
centers = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
normals = cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
normals = normals./max(vecnorm(normals,2,2), eps);
keep = ~(vehicleMesh.FaceWheelIndex(:)==0 & centers(:,3) < belowHeight & normals(:,3) < -0.5);
for fieldName = reshape(fieldnames(vehicleMesh),1,[])
    thisValue = vehicleMesh.(fieldName{1});
    if ~strcmp(fieldName{1},'Vertices') && (isnumeric(thisValue) || islogical(thisValue)) && size(thisValue,1)==Nfaces
        vehicleMesh.(fieldName{1}) = thisValue(keep,:);
    end
end
end

function vehicleMesh = fcn_INTERNAL_addPlate(vehicleMesh, plateX, plateY, plateZ)
% The mesh with a flat opaque body plate added (two faces, facing down)
Nfaces = size(vehicleMesh.Faces,1);
newVertices = [plateX(1) plateY(1) plateZ; plateX(2) plateY(1) plateZ; plateX(2) plateY(2) plateZ; plateX(1) plateY(2) plateZ];
newFaces = [1 3 2; 1 4 3] + size(vehicleMesh.Vertices,1);
for fieldName = reshape(fieldnames(vehicleMesh),1,[])
    thisValue = vehicleMesh.(fieldName{1});
    if any(strcmp(fieldName{1},{'Vertices','Faces'})) || ~(isnumeric(thisValue) || islogical(thisValue)) || size(thisValue,1)~=Nfaces
        continue;
    end
    vehicleMesh.(fieldName{1}) = [thisValue; thisValue([1 1],:)];
end
vehicleMesh.Vertices = [vehicleMesh.Vertices; newVertices];
vehicleMesh.Faces = [vehicleMesh.Faces; newFaces];
vehicleMesh.LabelFacePart(end-1:end) = find(strcmp(vehicleMesh.LabelPartNames,'body'),1);
vehicleMesh.FaceWheelIndex(end-1:end) = 0;
if isfield(vehicleMesh,'FaceAlpha')
    vehicleMesh.FaceAlpha(end-1:end) = 1;
end
end
