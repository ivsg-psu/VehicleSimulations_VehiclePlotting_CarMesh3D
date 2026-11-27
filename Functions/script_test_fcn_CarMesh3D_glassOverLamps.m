% script_test_fcn_CarMesh3D_glassOverLamps.m
% Small meshes of a lamp under glass, built here, to see whether finding
% lamp covers (fcn_CarMesh3D_findLampCovers) and lifting overlays
% (fcn_CarMesh3D_separateOverlays) depend on the direction faces point
% (Sean, 2026-11-27 02:16 to 02:39: glass built with thickness, or with
% zero thickness very close to the lamp, and faces pointing either way).
%
% Each case is a 10 cm square lamp at height 0, facing up (+Z is outside),
% with glass above it:
%   1  zero-thickness glass 1 mm above, facing out
%   2  the same, facing in (flipped)
%   3  zero-thickness glass at the lamp's height (coincident), facing out
%   4  thick glass (2 and 5 mm up), both skins facing out of the glass
%      (the outer skin up, the inner skin down: a correctly built solid)
%   5  thick glass, both skins facing the wrong way
%   6  a lamp with no glass
% Each is run with the faces' directions taken from their corner order (a
% mesh not yet simplified) and with stored FaceNormals (a simplified mesh,
% as in a vehicle's build).
%
% (Step 1 of Sean's plan, 2026-11-27: first a table of what happens today;
% the pass/fail checks follow once the fixes are agreed.)

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_glassOverLamps
%   % * First write: the cases, and a table of today's results (drafted
%   %   % with Claude)

% TO-DO:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_glassOverLamps
%   % * Turn the table into pass/fail checks once the fixes are agreed

%% Set up the workspace
close all;

caseNames = {'1 thin glass 1 mm above, out', '2 thin glass 1 mm above, flipped', ...
    '3 thin glass coincident, out', '4 thick glass, correct solid', '5 thick glass, both skins wrong', '6 lamp, no glass'};
results = table('Size', [0 7], 'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'Case', 'Normals', 'GlassFaces', 'CoverFaces', 'LiftedGlassFaces', 'LiftedLampFaces', 'GlassMovedLampMoved'});

for ith_case = 1:numel(caseNames)
    for flagStored = [false true]
        testMesh = fcn_INTERNAL_caseMesh(ith_case);
        normalsText = "corner order";
        if flagStored
            testMesh.FaceNormals = fcn_INTERNAL_normals(testMesh);
            normalsText = "stored";
        end
        glassIndex = find(strcmp(testMesh.LabelPartNames, 'glass'));
        lightIndex = find(strcmp(testMesh.LabelPartNames, 'light'));
        flagGlass = testMesh.LabelFacePart == glassIndex;
        flagLamp = testMesh.LabelFacePart == lightIndex;

        % Covers
        coveredMesh = fcn_CarMesh3D_findLampCovers(testMesh, FigNum=-1);
        numCover = nnz(coveredMesh.LabelFaceCoverLamp > 0);

        % Overlays lifted (on the mesh before covers, as in a build)
        [liftedMesh, ~] = fcn_CarMesh3D_separateOverlays(testMesh, FigNum=-1);
        moved = liftedMesh.Vertices - testMesh.Vertices;
        faceMoveZ = (moved(testMesh.Faces(:,1),3) + moved(testMesh.Faces(:,2),3) + moved(testMesh.Faces(:,3),3))/3;
        liftedGlass = nnz(flagGlass & abs(faceMoveZ) > 0);
        liftedLamp = nnz(flagLamp & abs(faceMoveZ) > 0);
        directionText = sprintf('glass %s, lamp %s', fcn_INTERNAL_way(faceMoveZ(flagGlass)), fcn_INTERNAL_way(faceMoveZ(flagLamp)));

        results(end+1,:) = {string(caseNames{ith_case}), normalsText, nnz(flagGlass), numCover, liftedGlass, liftedLamp, ...
            string(directionText)}; %#ok<SAGROW>
    end
end
disp(results);

%% fcn_INTERNAL_caseMesh
function testMesh = fcn_INTERNAL_caseMesh(caseNumber)
% (a lamp square at height 0 facing up, and the glass of the case)
side = 0.10;
[lampVertices, lampFaces] = fcn_INTERNAL_square(0, side, true);
pieces = {lampVertices, lampFaces, 'light'};
switch caseNumber
    case 1
        [v, f] = fcn_INTERNAL_square(0.001, side, true);  pieces(end+1,:) = {v, f, 'glass'};
    case 2
        [v, f] = fcn_INTERNAL_square(0.001, side, false); pieces(end+1,:) = {v, f, 'glass'};
    case 3
        [v, f] = fcn_INTERNAL_square(0, side, true);      pieces(end+1,:) = {v, f, 'glass'};
    case 4
        [v, f] = fcn_INTERNAL_square(0.005, side, true);  pieces(end+1,:) = {v, f, 'glass'};
        [v, f] = fcn_INTERNAL_square(0.002, side, false); pieces(end+1,:) = {v, f, 'glass'};
    case 5
        [v, f] = fcn_INTERNAL_square(0.005, side, false); pieces(end+1,:) = {v, f, 'glass'};
        [v, f] = fcn_INTERNAL_square(0.002, side, true);  pieces(end+1,:) = {v, f, 'glass'};
    case 6
        % (no glass)
end
partNames = {'body', 'trim', 'glass', 'light', 'wheel'};
vertices = zeros(0,3);
faces = zeros(0,3);
facePart = zeros(0,1);
for ith_piece = 1:size(pieces,1)
    faces = [faces; pieces{ith_piece,2} + size(vertices,1)]; %#ok<AGROW>
    vertices = [vertices; pieces{ith_piece,1}]; %#ok<AGROW>
    facePart = [facePart; repmat(find(strcmp(partNames, pieces{ith_piece,3})), size(pieces{ith_piece,2},1), 1)]; %#ok<AGROW>
end
lampNames = {fcn_CarMesh3D_lampTypes(FigNum=-1).Name}';
numFaces = size(faces,1);
testMesh = struct('Vertices', vertices, 'Faces', faces, 'LabelPartNames', {partNames}, 'LabelFacePart', facePart, ...
    'LabelLampNames', {lampNames}, 'LabelFaceLamp', double(facePart == 4)*find(strcmp(lampNames, 'headlamp')), ...
    'FaceColors', repmat([0.8 0.8 0.8], numFaces, 1), 'FaceAlpha', ones(numFaces,1));
testMesh.FaceAlpha(facePart == 3) = 0.3;
end % Ends fcn_INTERNAL_caseMesh

%% fcn_INTERNAL_square
function [vertices, faces] = fcn_INTERNAL_square(height, side, flagUp)
% (two triangles; facing up when flagUp, by the right-hand rule)
vertices = [0 0 height; side 0 height; side side height; 0 side height] - [side/2 side/2 0];
faces = [1 2 3; 1 3 4];
if ~flagUp
    faces = faces(:, [1 3 2]);
end
end % Ends fcn_INTERNAL_square

%% fcn_INTERNAL_normals
function normals = fcn_INTERNAL_normals(testMesh)
% (the faces' directions from their corner order, stored as a simplified mesh would)
v = testMesh.Vertices;
f = testMesh.Faces;
normals = cross(v(f(:,2),:) - v(f(:,1),:), v(f(:,3),:) - v(f(:,1),:), 2);
normals = normals./max(vecnorm(normals,2,2), eps);
end % Ends fcn_INTERNAL_normals

%% fcn_INTERNAL_way
function textOut = fcn_INTERNAL_way(moveZ)
% (which way faces moved: out (up), in (down), or not)
if isempty(moveZ)
    textOut = '-';
elseif all(moveZ == 0)
    textOut = 'not moved';
elseif all(moveZ >= 0)
    textOut = 'out';
elseif all(moveZ <= 0)
    textOut = 'IN';
else
    textOut = 'mixed';
end
end % Ends fcn_INTERNAL_way
