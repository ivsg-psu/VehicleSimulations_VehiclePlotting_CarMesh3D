% script_test_fcn_CarMesh3D_addFloorPanel.m
% Tests fcn_CarMesh3D_addFloorPanel

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_addFloorPanel
%   % * First write

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
Nfaces = size(vehicleMesh.Faces,1);

%% Basic call, with a plot
figNum = 10001;
panelMesh = fcn_CarMesh3D_addFloorPanel(vehicleMesh, FigNum=figNum);
assert(isfield(panelMesh,'FloorPanel'));
Npanel = numel(panelMesh.FloorPanel.Faces);
assert(Npanel > 0);
assert(size(panelMesh.Faces,1) == Nfaces + Npanel);
assert(size(panelMesh.FacePartIndex,1) == Nfaces + Npanel);
assert(size(panelMesh.FaceColors,1) == Nfaces + Npanel);
% (at the spec's ground clearance, its edges risen at most MaxRise,
% facing down, labeled trim)
panelCorners = unique(panelMesh.Faces(panelMesh.FloorPanel.Faces,:));
panelHeights = panelMesh.Vertices(panelCorners,3);
assert(abs(min(panelHeights) - vehicleMesh.VehicleSpec.GroundClearance) < 1e-9);
assert(max(panelHeights) <= vehicleMesh.VehicleSpec.GroundClearance + 0.30 + 1e-9);
assert(all(panelMesh.FaceNormals(panelMesh.FloorPanel.Faces,3) < 0));
assert(all(strcmp(panelMesh.PartNames(panelMesh.FacePartIndex(panelMesh.FloorPanel.Faces)),'trim')));
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
panelMesh = fcn_CarMesh3D_addFloorPanel(vehicleMesh, Height=0.25, BlendWidth=0, FigNum=-1);
panelCorners = unique(panelMesh.Faces(panelMesh.FloorPanel.Faces,:));
assert(all(abs(panelMesh.Vertices(panelCorners,3) - 0.25) < 1e-9));

%% FAIL: not a labeled mesh
if 1==0
    fcn_CarMesh3D_addFloorPanel(struct('Vertices',[],'Faces',[]), FigNum=1);
end

fprintf(1,'All tests of fcn_CarMesh3D_addFloorPanel passed\n');
