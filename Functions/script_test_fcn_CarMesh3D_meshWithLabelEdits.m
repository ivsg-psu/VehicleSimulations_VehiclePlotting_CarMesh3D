% script_test_fcn_CarMesh3D_meshWithLabelEdits.m
% Tests fcn_CarMesh3D_meshWithLabelEdits: a vehicle's mesh with its saved
% label fixes, with no window.

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_meshWithLabelEdits
%   % * First write
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_meshWithLabelEdits
%   % * OrientFaces (Q87 (A))

%% Set up the workspace
close all;
vehicleID = fcn_CarMesh3D_demoVehicle(UsePreference=false, FigNum=-1);   % (the repo's demo vehicle: it has label fixes and a stage-1 cache)
assert(isfile(fullfile(fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1).Folder, ['labelEdits_' vehicleID '.mat'])), 'These tests need a demo vehicle with saved label fixes (the 2009 Fit has 13): see fcn_CarMesh3D_demoVehicle');

%% DEMO case: the mesh with its saved label fixes, plotted
figNum = 10001;
titleString = sprintf('DEMO case: %s with its saved label fixes', vehicleID);
fprintf(1,'Figure %.0f: %s\n', figNum, titleString);
figure(figNum); clf;

[vehicleMesh, info] = fcn_CarMesh3D_meshWithLabelEdits(vehicleID, FigNum=figNum);
sgtitle(titleString, 'Interpreter', 'none');

assert(isstruct(vehicleMesh) && isfield(vehicleMesh, 'Faces'));
assert(numel(vehicleMesh.FaceAlpha) == size(vehicleMesh.Faces,1));
assert(isstruct(info) && all(isfield(info, {'Source','NumEdits','EditsFile','MeshFile'})));
assert(info.NumEdits > 0);
assert(isequal(get(gcf,'Number'), figNum));

%% TEST case: Always=true gives the same labels as the mesh file (the script's own result)
figNum = 20001;
titleString = sprintf('TEST case: %s, fixes applied to the stage-1 mesh agree with the mesh file', vehicleID);
fprintf(1,'Figure %.0f: %s\n', figNum, titleString);

[appliedMesh, appliedInfo] = fcn_CarMesh3D_meshWithLabelEdits(vehicleID, Always=true, FigNum=[]);
files = fcn_CarMesh3D_findVehicleFiles(vehicleID, FigNum=-1);
loaded = load(files.MeshFile, 'vehicleMesh');
assert(strcmp(appliedInfo.Source, 'stage-1 mesh with the saved edits'));
assert(size(appliedMesh.Faces,1) == size(loaded.vehicleMesh.Faces,1));
assert(isequal(appliedMesh.FaceLightType(:), loaded.vehicleMesh.FaceLightType(:)));
assert(isequal(appliedMesh.FacePartIndex(:), loaded.vehicleMesh.FacePartIndex(:)));
assert(isequal(appliedMesh.FaceCoverLamp(:) > 0, loaded.vehicleMesh.FaceCoverLamp(:) > 0));
assert(isempty(findobj('Type','figure','Number',figNum)));   % (no plot asked for)

%% TEST case: no window is made (the tree rule)
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: no window is made\n', figNum);
figuresBefore = findall(groot, 'Type', 'figure');
fcn_CarMesh3D_meshWithLabelEdits(vehicleID, Always=true, FigNum=-1);
figuresAfter = findall(groot, 'Type', 'figure');
assert(numel(figuresAfter) == numel(figuresBefore));

%% TEST case: OrientFaces (Q87 (A), 2026_11_26): faces turned by default, as saved with false
figNum = 20003;
fprintf(1,'Figure %.0f: TEST case: OrientFaces\n', figNum);
[savedMesh, savedInfo] = fcn_CarMesh3D_meshWithLabelEdits(vehicleID, OrientFaces=false, FigNum=-1);
[turnedMesh, turnedInfo] = fcn_CarMesh3D_meshWithLabelEdits(vehicleID, FigNum=-1);
[expectedMesh, expectedInfo] = fcn_CarMesh3D_orientFaces(savedMesh, FigNum=-1);
assert(savedInfo.NumFacesTurned == 0);
assert(turnedInfo.NumFacesTurned == expectedInfo.NumFlipped && turnedInfo.NumFacesTurned > 0, 'The demo vehicle has faces to turn');
assert(isequal(turnedMesh.Faces, expectedMesh.Faces), 'The default is the mesh after fcn_CarMesh3D_orientFaces');
assert(isequal(sort(turnedMesh.Faces, 2), sort(savedMesh.Faces, 2)), 'Only the order of each face''s corners changes');
assert(isequal(turnedMesh.FacePartIndex, savedMesh.FacePartIndex) && isequal(turnedMesh.FaceLightType, savedMesh.FaceLightType), ...
    'The labels are unchanged');

%% FAST mode cases
figNum = 80001;
fprintf(1,'Figure %.0f: FAST mode cases\n', figNum);

% Empty FigNum
fastMesh = fcn_CarMesh3D_meshWithLabelEdits(vehicleID, FigNum=[]);
assert(isfield(fastMesh, 'Faces'));

% FigNum = -1
fastMesh = fcn_CarMesh3D_meshWithLabelEdits(vehicleID, FigNum=-1);
assert(isfield(fastMesh, 'Faces'));

% Speed comparison
Niterations = 3;
tic; for ith = 1:Niterations, fcn_CarMesh3D_meshWithLabelEdits(vehicleID, FigNum=[]); end; slowTime = toc;
tic; for ith = 1:Niterations, fcn_CarMesh3D_meshWithLabelEdits(vehicleID, FigNum=-1); end; fastTime = toc;
fprintf(1,'Normal mode: %.3f s per call; fast mode: %.3f s per call\n', slowTime/Niterations, fastTime/Niterations);

%% BUG cases
% (none yet)

%% Fail conditions
if 1==0
    % vehicleInput must be text
    fcn_CarMesh3D_meshWithLabelEdits(42);
end
