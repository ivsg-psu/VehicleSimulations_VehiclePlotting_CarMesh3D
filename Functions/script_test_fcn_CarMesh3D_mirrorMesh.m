% script_test_fcn_CarMesh3D_mirrorMesh
% Tests of fcn_CarMesh3D_mirrorMesh on a small made-up mesh: a closed box
% (outward faces) with a "steering wheel" block on its right side (-y), as
% in a right-hand-drive download, which must end up on the left (+y).
%
% This script was written on 2026_11_24 by S. Brennan (drafted with Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_24 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_mirrorMesh
%   % * First write of the tests

%% Set up the workspace
close all;

% (a box 4 x 1.8 x 1.4 m, centered in y, its 12 faces pointing outward,
% plus a small block at y = -0.4: the right-hand-drive wheel)
[boxVertices, boxFaces] = fcn_INTERNAL_box([-2 2 -0.9 0.9 0 1.4]);
[wheelVertices, wheelFaces] = fcn_INTERNAL_box([0.5 0.6 -0.5 -0.3 0.9 1.1]);
testMesh = struct('Vertices', [boxVertices; wheelVertices], 'Faces', [boxFaces; wheelFaces + size(boxVertices,1)]);
testMesh.FacePartIndex = [ones(12,1); 2*ones(12,1)];
testMesh.FaceNormals = fcn_INTERNAL_faceNormals(testMesh.Vertices, testMesh.Faces);
assert(all(fcn_INTERNAL_outward(testMesh)), '(set-up) the made-up faces point outward');

%% DEMO case: a right-hand-drive mesh mirrored
fig_num = 10001;
fprintf(1,'Figure %d: DEMO case: a right-hand-drive mesh mirrored\n', fig_num);
mirrored = fcn_CarMesh3D_mirrorMesh(testMesh, FigNum=fig_num);
assert(ishandle(fig_num), 'The plot was made');
wheelCenter = mean(mirrored.Vertices(unique(mirrored.Faces(mirrored.FacePartIndex==2,:)),:), 1);
assert(abs(wheelCenter(2) - 0.4) < 1e-12, 'The wheel block is now on the left (+y)');

%% TEST case: faces still point outward; normals and labels follow
fig_num = 20001;
fprintf(1,'Figure %d: TEST case: outward faces, normals, labels\n', fig_num);
assert(all(fcn_INTERNAL_outward(mirrored)), 'Every face still points outward (corner order reversed)');
recomputed = fcn_INTERNAL_faceNormals(mirrored.Vertices, mirrored.Faces);
assert(max(abs(recomputed(:) - mirrored.FaceNormals(:))) < 1e-12, 'The stored normals match the mirrored faces');
assert(isequal(mirrored.FacePartIndex, testMesh.FacePartIndex), 'Labels stay with their faces');
assert(isequal(mirrored.Vertices(:,[1 3]), testMesh.Vertices(:,[1 3])), 'x and z are unchanged');
assert(isfield(mirrored, 'MirrorInfo') && mirrored.MirrorInfo.Mirrored, 'MirrorInfo is recorded');

%% TEST case: mirroring twice gives back the mesh
fig_num = 20002;
fprintf(1,'Figure %d: TEST case: twice is the original\n', fig_num);
twice = fcn_CarMesh3D_mirrorMesh(mirrored, FigNum=-1);
assert(isequal(twice.Vertices, testMesh.Vertices) && isequal(twice.Faces, testMesh.Faces) ...
    && isequal(twice.FaceNormals, testMesh.FaceNormals), 'Mirroring twice gives back the original');

%% FAST mode cases
fig_num = 80001;
fprintf(1,'Figure %d: FAST mode cases\n', fig_num);
Niterations = 100;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_mirrorMesh(testMesh, FigNum=[]);
end
slowTime = toc;
tic;
for ith_test = 1:Niterations
    fcn_CarMesh3D_mirrorMesh(testMesh, FigNum=-1);
end
fastTime = toc;
fprintf(1, 'Average time per call: normal %.5f s, fast mode %.5f s\n', slowTime/Niterations, fastTime/Niterations);
assert(isempty(findall(0, 'Type', 'figure', 'Number', fig_num)), 'Fast mode makes no plot');
close all;
fprintf(1, 'All tests of fcn_CarMesh3D_mirrorMesh passed\n');

%% Fail conditions
if 1==0
    %% FAIL case: not a mesh
    fcn_CarMesh3D_mirrorMesh(struct('Vertices', [0 0 0]));
end

%% Functions follow
function [vertices, faces] = fcn_INTERNAL_box(limits)
% A closed box [xmin xmax ymin ymax zmin zmax] of 12 triangles, corners
% counterclockwise seen from outside
[x, y, z] = ndgrid(limits(1:2), limits(3:4), limits(5:6));
vertices = [x(:) y(:) z(:)];
faces = [1 3 4; 1 4 2;  5 6 8; 5 8 7;  1 2 6; 1 6 5;  3 7 8; 3 8 4;  1 5 7; 1 7 3;  2 4 8; 2 8 6];
end % Ends fcn_INTERNAL_box

function normals = fcn_INTERNAL_faceNormals(vertices, faces)
normals = cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
normals = normals./vecnorm(normals, 2, 2);
end % Ends fcn_INTERNAL_faceNormals

function flags = fcn_INTERNAL_outward(mesh)
% Each face points away from the center of its own closed box (12 faces each)
normals = fcn_INTERNAL_faceNormals(mesh.Vertices, mesh.Faces);
flags = false(size(mesh.Faces,1),1);
for ith_box = 1:size(mesh.Faces,1)/12
    rows = (ith_box-1)*12 + (1:12);
    boxCenter = mean(mesh.Vertices(unique(mesh.Faces(rows,:)),:), 1);
    faceCenters = (mesh.Vertices(mesh.Faces(rows,1),:) + mesh.Vertices(mesh.Faces(rows,2),:) + mesh.Vertices(mesh.Faces(rows,3),:))/3;
    flags(rows) = sum(normals(rows,:).*(faceCenters - boxCenter), 2) > 0;
end
end % Ends fcn_INTERNAL_outward
