% script_test_fcn_CarMesh3D_fixFlippedFaces.m
% Tests fcn_CarMesh3D_fixFlippedFaces

% REVISION HISTORY:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fixFlippedFaces
%   % * First write

% TO-DO:
%
% 2026_11_21 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fixFlippedFaces
%   % * (none yet)

%% Set up the workspace
close all;

% A closed box with outward faces (12 triangles)
boxMesh = struct();
boxMesh.Vertices = [0 0 0; 2 0 0; 2 1 0; 0 1 0; 0 0 1; 2 0 1; 2 1 1; 0 1 1];
boxMesh.Faces = [1 3 2; 1 4 3; 5 6 7; 5 7 8; 1 2 6; 1 6 5; 2 3 7; 2 7 6; 3 4 8; 3 8 7; 4 1 5; 4 5 8];
boxMesh.FaceNormals = zeros(12,3);

%% A box already right: nothing flipped
[fixedMesh, numFlipped] = fcn_CarMesh3D_fixFlippedFaces(boxMesh, FigNum=-1);
assert(numFlipped==0);
assert(isequal(fixedMesh.Faces, boxMesh.Faces));

%% Two faces inside out (the top): both flipped back
flippedMesh = boxMesh;
flippedMesh.Faces(3:4,:) = flippedMesh.Faces(3:4,[1 3 2]);
figNum = 10001;
[fixedMesh, numFlipped] = fcn_CarMesh3D_fixFlippedFaces(flippedMesh, FigNum=figNum);
assert(numFlipped==2);
assert(isequal(fixedMesh.Faces, boxMesh.Faces));
assert(all(fixedMesh.FaceNormals(3:4,3) > 0));
assert(ishandle(figNum));

%% FAIL: not a mesh
if 1==0
    fcn_CarMesh3D_fixFlippedFaces(struct('Points',[]), FigNum=1);
end

fprintf(1,'All tests of fcn_CarMesh3D_fixFlippedFaces passed\n');
