% script_test_fcn_CarMesh3D_glassOverLamps.m
% Small meshes of a lamp under glass, built here, to check that finding
% lamp covers (fcn_CarMesh3D_findLampCovers) and lifting overlays
% (fcn_CarMesh3D_separateOverlays) do not depend on the direction faces
% point (Sean, 2026-11-27 02:16 to 02:39: glass built with thickness, or
% with zero thickness very close to the lamp, and faces pointing either
% way).
%
% Each case is a 10 cm square lamp at height 0, facing up (+Z is outside),
% on top of a closed body box (its top 3 cm below the lamp), with glass
% above it:
%   1  zero-thickness glass 1 mm above, facing out
%   2  the same, facing in (flipped)
%   3  zero-thickness glass at the lamp's height (coincident), facing out
%   4  thick glass (2 and 5 mm up), both skins facing out of the glass
%      (the outer skin up, the inner skin down: a correctly built solid)
%   5  thick glass, both skins facing the wrong way
%   6  a lamp with no glass
%   7  coincident glass, with both the glass and the lamp facing in
% Each is run with the faces' directions taken from their corner order (a
% mesh not yet simplified) and with stored FaceNormals (a simplified mesh,
% as in a vehicle's build).
%
% What must hold in every case, whichever way the faces point:
%   - every glass face over the lamp is a cover of it (none in case 6);
%   - the lamp and the body never move;
%   - glass never moves inward, and ends above the lamp (case 3 and 7:
%     lifted off it);
%   - the inner skin of thick glass stays below the outer skin.

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_glassOverLamps
%   % * First write: the cases, and a table of today's results (drafted
%   %   % with Claude)
%   % * Pass/fail checks, after the step 1A fixes: a body box under the
%   %   % lamp (so the mesh has an outside), and case 7 (all faces flipped)

% TO-DO:
%
% (none)

%% Set up the workspace
close all;

caseNames = {'1 thin glass 1 mm above, out', '2 thin glass 1 mm above, flipped', ...
    '3 thin glass coincident, out', '4 thick glass, correct solid', '5 thick glass, both skins wrong', ...
    '6 lamp, no glass', '7 coincident, glass and lamp flipped'};
results = table('Size', [0 7], 'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double', 'string'}, ...
    'VariableNames', {'Case', 'Normals', 'GlassFaces', 'CoverFaces', 'LiftedGlassFaces', 'LiftedLampFaces', 'GlassMovedLampMoved'});

for ith_case = 1:numel(caseNames)
    for flagStored = [false true]
        [testMesh, flagInner, flagOuter] = fcn_INTERNAL_caseMesh(ith_case);
        normalsText = "corner order";
        if flagStored
            testMesh.FaceNormals = fcn_INTERNAL_normals(testMesh);
            normalsText = "stored";
        end
        where = sprintf('case %s, %s normals', caseNames{ith_case}, normalsText);
        glassIndex = find(strcmp(testMesh.LabelPartNames, 'glass'));
        lightIndex = find(strcmp(testMesh.LabelPartNames, 'light'));
        bodyIndex = find(strcmp(testMesh.LabelPartNames, 'body'));
        flagGlass = testMesh.LabelFacePart == glassIndex;
        flagLamp = testMesh.LabelFacePart == lightIndex;
        flagBody = testMesh.LabelFacePart == bodyIndex;

        % Covers: every glass face covers the lamp
        coveredMesh = fcn_CarMesh3D_findLampCovers(testMesh, FigNum=-1);
        numCover = nnz(coveredMesh.LabelFaceCoverLamp > 0);
        assert(numCover == nnz(flagGlass), '%s: %d of %d glass faces are covers', where, numCover, nnz(flagGlass));
        assert(all(coveredMesh.LabelFaceCoverLamp(flagGlass) == testMesh.LabelFaceLamp(find(flagLamp,1))), ...
            '%s: a cover covers the wrong lamp', where);

        % Overlays lifted (on the mesh before covers, as in a build)
        [liftedMesh, ~] = fcn_CarMesh3D_separateOverlays(testMesh, FigNum=-1);
        moved = liftedMesh.Vertices - testMesh.Vertices;
        faceMoveZ = (moved(testMesh.Faces(:,1),3) + moved(testMesh.Faces(:,2),3) + moved(testMesh.Faces(:,3),3))/3;
        liftedGlass = nnz(flagGlass & abs(faceMoveZ) > 0);
        liftedLamp = nnz(flagLamp & abs(faceMoveZ) > 0);
        directionText = sprintf('glass %s, lamp %s', fcn_INTERNAL_way(faceMoveZ(flagGlass)), fcn_INTERNAL_way(faceMoveZ(flagLamp)));
        results(end+1,:) = {string(caseNames{ith_case}), normalsText, nnz(flagGlass), numCover, liftedGlass, liftedLamp, ...
            string(directionText)}; %#ok<SAGROW>

        % The lamp and the body never move; glass never moves inward
        lampCorners = unique(testMesh.Faces(flagLamp,:));
        bodyCorners = unique(testMesh.Faces(flagBody,:));
        glassCorners = unique(testMesh.Faces(flagGlass,:));
        assert(all(all(moved(lampCorners,:) == 0)), '%s: the lamp moved', where);
        assert(all(all(moved(bodyCorners,:) == 0)), '%s: the body moved', where);
        assert(all(moved(glassCorners,3) >= 0) && all(all(moved(glassCorners,1:2) == 0)), '%s: glass moved inward or sideways', where);

        % Glass ends above the lamp; thick glass keeps its inner skin inside
        if ~isempty(glassCorners)
            assert(min(liftedMesh.Vertices(glassCorners,3)) > 0, '%s: glass is not above the lamp', where);
        end
        if any(flagInner)
            innerTop = max(liftedMesh.Vertices(unique(testMesh.Faces(flagInner,:)),3));
            outerBottom = min(liftedMesh.Vertices(unique(testMesh.Faces(flagOuter,:)),3));
            assert(innerTop < outerBottom, '%s: the inner skin of the glass passed the outer skin', where);
        end
    end
end
disp(results);
fprintf(1,'script_test_fcn_CarMesh3D_glassOverLamps: all %d checks passed\n', height(results));

%% fcn_INTERNAL_caseMesh
function [testMesh, flagInner, flagOuter] = fcn_INTERNAL_caseMesh(caseNumber)
% (a lamp square at height 0 facing up, on a closed body box, and the
% glass of the case; flagInner and flagOuter mark the skins of thick glass)
side = 0.10;
lampUp = caseNumber ~= 7;
[lampVertices, lampFaces] = fcn_INTERNAL_square(0, side, lampUp);
[boxVertices, boxFaces] = fcn_INTERNAL_box([-0.3 -0.3 -0.5], [0.3 0.3 -0.03]);
pieces = {boxVertices, boxFaces, 'body', 0; lampVertices, lampFaces, 'light', 0};
switch caseNumber
    case 1
        [v, f] = fcn_INTERNAL_square(0.001, side, true);  pieces(end+1,:) = {v, f, 'glass', 0};
    case 2
        [v, f] = fcn_INTERNAL_square(0.001, side, false); pieces(end+1,:) = {v, f, 'glass', 0};
    case 3
        [v, f] = fcn_INTERNAL_square(0, side, true);      pieces(end+1,:) = {v, f, 'glass', 0};
    case 4
        [v, f] = fcn_INTERNAL_square(0.005, side, true);  pieces(end+1,:) = {v, f, 'glass', 2};
        [v, f] = fcn_INTERNAL_square(0.002, side, false); pieces(end+1,:) = {v, f, 'glass', 1};
    case 5
        [v, f] = fcn_INTERNAL_square(0.005, side, false); pieces(end+1,:) = {v, f, 'glass', 2};
        [v, f] = fcn_INTERNAL_square(0.002, side, true);  pieces(end+1,:) = {v, f, 'glass', 1};
    case 6
        % (no glass)
    case 7
        [v, f] = fcn_INTERNAL_square(0, side, false);     pieces(end+1,:) = {v, f, 'glass', 0};
end
partNames = {'body', 'trim', 'glass', 'light', 'wheel'};
vertices = zeros(0,3);
faces = zeros(0,3);
facePart = zeros(0,1);
faceSkin = zeros(0,1);
for ith_piece = 1:size(pieces,1)
    faces = [faces; pieces{ith_piece,2} + size(vertices,1)]; %#ok<AGROW>
    vertices = [vertices; pieces{ith_piece,1}]; %#ok<AGROW>
    numPieceFaces = size(pieces{ith_piece,2},1);
    facePart = [facePart; repmat(find(strcmp(partNames, pieces{ith_piece,3})), numPieceFaces, 1)]; %#ok<AGROW>
    faceSkin = [faceSkin; repmat(pieces{ith_piece,4}, numPieceFaces, 1)]; %#ok<AGROW>
end
flagInner = faceSkin == 1;
flagOuter = faceSkin == 2;
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

%% fcn_INTERNAL_box
function [vertices, faces] = fcn_INTERNAL_box(low, high)
% (a closed box of 12 triangles, facing out)
[x, y, z] = ndgrid([low(1) high(1)], [low(2) high(2)], [low(3) high(3)]);
vertices = [x(:) y(:) z(:)];
% (corners: 1 ---, 2 +--, 3 -+-, 4 ++-, 5 --+, 6 +-+, 7 -++, 8 +++)
faces = [1 3 4; 1 4 2; 5 6 8; 5 8 7; 1 2 6; 1 6 5; 3 7 8; 3 8 4; 1 5 7; 1 7 3; 2 4 8; 2 8 6];
end % Ends fcn_INTERNAL_box

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
