% script_test_fcn_CarMesh3D_applyFaceFlips.m
% Tests fcn_CarMesh3D_applyFaceFlips
% Turns faces to the directions saved for them by the face-direction
% window, matching them by position; safe to repeat.

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_applyFaceFlips
%   % * First write (drafted with Claude)

% TO-DO:
%
% (none)

%% Set up the workspace
close all;

%% DEMO case: two flipped faces of a square turned back up
figNum = 10001;
titleString = sprintf('DEMO case: two flipped faces of a square turned back up');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

[vertices, faces] = fcn_INTERNAL_grid(4);   % (32 faces at z = 0, facing up)
testMesh = struct('Vertices', vertices, 'Faces', faces, 'FaceNormals', repmat([0 0 1], size(faces,1), 1));
wrongFaces = [5; 12];
testMesh.Faces(wrongFaces,:) = testMesh.Faces(wrongFaces, [1 3 2]);
testMesh.FaceNormals(wrongFaces,:) = -testMesh.FaceNormals(wrongFaces,:);
centers = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
faceFlips = struct('Points', centers(wrongFaces,:), 'Normals', repmat([0 0 1], 2, 1));
[fixedMesh, info] = fcn_CarMesh3D_applyFaceFlips(testMesh, faceFlips, FigNum=figNum);
sgtitle(titleString, 'Interpreter','none');

% Check variable types and sizes
assert(isstruct(fixedMesh) && isequal(size(fixedMesh.Faces), size(testMesh.Faces)));
assert(all(isfield(info, {'NumSaved','NumMatched','NumTurned','NumMissing','Turned'})));

% Check variable values: both turned; every face up; normals follow
assert(info.NumSaved == 2 && info.NumMatched == 2 && info.NumTurned == 2 && info.NumMissing == 0);
assert(isequal(sort(info.Turned), wrongFaces));
assert(isequal(fixedMesh.Faces, faces));
assert(all(fixedMesh.FaceNormals(:,3) == 1));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: applying again changes nothing; a face already right is left
figNum = 20001;
fprintf(1,'Figure %.0f: TEST case: safe to repeat\n', figNum);
[againMesh, againInfo] = fcn_CarMesh3D_applyFaceFlips(fixedMesh, faceFlips);
assert(isequal(againMesh, fixedMesh) && againInfo.NumMatched == 2 && againInfo.NumTurned == 0);
assert(isempty(findobj('Number',figNum)));

%% TEST case: a point with no face near it is missing; positions within the tolerance match
figNum = 20002;
fprintf(1,'Figure %.0f: TEST case: tolerance\n', figNum);
farFlips = struct('Points', [centers(wrongFaces(1),:) + [0 0 0.003]; 5 5 5], 'Normals', [0 0 1; 0 0 1]);
[~, farInfo] = fcn_CarMesh3D_applyFaceFlips(testMesh, farFlips);
assert(farInfo.NumMatched == 1 && farInfo.NumMissing == 1 && isequal(farInfo.Turned, wrongFaces(1)));
[~, tightInfo] = fcn_CarMesh3D_applyFaceFlips(testMesh, farFlips, Tolerance=0.001);
assert(tightInfo.NumMatched == 0);
assert(isempty(findobj('Number',figNum)));

%% TEST case: from a file; a file that does not exist is no flips
figNum = 20003;
fprintf(1,'Figure %.0f: TEST case: files\n', figNum);
flipsFile = fullfile(tempdir, 'faceFlips_test_applyFaceFlips.mat');
save(flipsFile, 'faceFlips');
[fileMesh, fileInfo] = fcn_CarMesh3D_applyFaceFlips(testMesh, flipsFile);
assert(isequal(fileMesh.Faces, faces) && fileInfo.NumTurned == 2);
delete(flipsFile);
[sameMesh, noneInfo] = fcn_CarMesh3D_applyFaceFlips(testMesh, flipsFile);
assert(isequal(sameMesh, testMesh) && noneInfo.NumSaved == 0);
assert(isempty(findobj('Number',figNum)));

%% Fast Mode Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ______        _     __  __           _        _______        _
% |  ____|      | |   |  \/  |         | |      |__   __|      | |
% | |__ __ _ ___| |_  | \  / | ___   __| | ___     | | ___  ___| |_ ___
% |  __/ _` / __| __| | |\/| |/ _ \ / _` |/ _ \    | |/ _ \/ __| __/ __|
% | | | (_| \__ \ |_  | |  | | (_) | (_| |  __/    | |  __/\__ \ |_\__ \
% |_|  \__,_|___/\__| |_|  |_|\___/ \__,_|\___|    |_|\___||___/\__|___/
%
%
% See: http://patorjk.com/software/taag/#p=display&f=Big&t=Fast%20Mode%20Tests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Basic fast mode - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
fastMesh = fcn_CarMesh3D_applyFaceFlips(testMesh, faceFlips, FigNum=[]);
assert(isequal(fastMesh.Faces, faces));
assert(isempty(findobj('Number',figNum)));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
fastMesh = fcn_CarMesh3D_applyFaceFlips(testMesh, faceFlips, FigNum=-1);
assert(isequal(fastMesh.Faces, faces));
assert(isempty(findobj('Number',figNum)));

%% Fail conditions
if 1==0
    %% Not a mesh
    fcn_CarMesh3D_applyFaceFlips(3, faceFlips);
end

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_grid
function [vertices, faces] = fcn_INTERNAL_grid(numSide)
% A 1 m square at z = 0, numSide x numSide cells of two triangles, facing up
[x, y] = ndgrid(linspace(0, 1, numSide+1));
vertices = [x(:) y(:) zeros(numel(x),1)];
faces = zeros(0,3);
for ith_x = 1:numSide
    for ith_y = 1:numSide
        corner = ith_x + (ith_y - 1)*(numSide + 1);
        faces(end+1,:) = [corner, corner + 1, corner + numSide + 2]; %#ok<AGROW>
        faces(end+1,:) = [corner, corner + numSide + 2, corner + numSide + 1]; %#ok<AGROW>
    end
end
end % Ends fcn_INTERNAL_grid
