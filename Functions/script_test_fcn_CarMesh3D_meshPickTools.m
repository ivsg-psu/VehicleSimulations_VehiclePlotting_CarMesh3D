% script_test_fcn_CarMesh3D_meshPickTools.m
% Tests fcn_CarMesh3D_meshPickTools
% The picking, brush and highlight helpers shared by the label painter and
% the face-direction window.

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_meshPickTools
%   % * First write (drafted with Claude)

% TO-DO:
%
% (none)

%% Set up the workspace
close all;

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DEMO case: pick a face under a pixel, brush around it, and highlight both sides
figNum = 10001;
titleString = sprintf('DEMO case: pick a face under a pixel, brush around it, and highlight both sides');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

pick = fcn_CarMesh3D_meshPickTools();
[vertices, faces] = fcn_INTERNAL_grid(10);   % (a 1 m square of 200 faces at z = 0, facing up)
axesHandle = axes(figure(figNum));
patch(axesHandle, 'Vertices', vertices, 'Faces', faces, 'FaceColor', [0.8 0.8 0.8]);
axis(axesHandle, 'equal');
view(axesHandle, 0, 90);   % (looking straight down)
drawnow;

% Check variable types and sizes
assert(isstruct(pick));
assert(all(isfield(pick, {'RayAtPixel','PixelOf','MetersPerPixel','RayHits','FacesOnRay','LiftedFaces','MeshPieces','MirrorFaces','FaceCenters','Nearest'})));

% Check variable values: the pixel of a face's center gives a line through
% that face; a single pick finds it; a brush finds it and its neighbors
centers = pick.FaceCenters(vertices, faces);
target = 95;
pixel = pick.PixelOf(axesHandle, centers(target,:));
ray = pick.RayAtPixel(axesHandle, pixel, 1);
assert(isequal(size(ray), [2 3]));
picked = pick.FacesOnRay(vertices, faces, (1:size(faces,1))', ray, axesHandle, 5, true);
assert(isequal(picked, target));
brushed = pick.FacesOnRay(vertices, faces, (1:size(faces,1))', ray, axesHandle, 40, false);
assert(numel(brushed) > 1 && ismember(target, brushed));
assert(all(vecnorm(centers(brushed,:) - centers(target,:), 2, 2) < 40*pick.MetersPerPixel(axesHandle, centers(target,:)) + 0.1));
% (the highlight: two copies of the picked faces, 1.5 mm above and below)
[liftedVertices, liftedFaces] = pick.LiftedFaces(vertices, faces, brushed, 0.0015);
assert(isequal(size(liftedFaces), [2*numel(brushed) 3]));
liftedZ = reshape(liftedVertices(:,3), 3*numel(brushed), 2);
assert(all(abs(liftedZ(:,1) - 0.0015) < 1e-12) && all(abs(liftedZ(:,2) + 0.0015) < 1e-12));
patch(axesHandle, 'Vertices', liftedVertices, 'Faces', liftedFaces, 'FaceColor', [1 0.8 0]);
title(axesHandle, titleString, 'Interpreter', 'none');

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% TEST case: picking does not depend on the way faces point
figNum = 20001;
titleString = sprintf('TEST case: picking does not depend on the way faces point');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[vertices, faces] = fcn_INTERNAL_grid(4);
flippedFaces = faces(:, [1 3 2]);
origin = [0.3 0.4 1];
direction = [0 0 -1];
hitUp = pick.RayHits(origin, direction, vertices, faces);
hitDown = pick.RayHits(origin, direction, vertices, flippedFaces);
assert(isequal(hitUp, hitDown) && nnz(isfinite(hitUp)) == 1 && abs(min(hitUp) - 1) < 1e-12);
% (the highlight of a flipped face still has a copy on each side)
[liftedVertices, ~] = pick.LiftedFaces(vertices, flippedFaces, 1, 0.002);
assert(any(liftedVertices(:,3) > 0) && any(liftedVertices(:,3) < 0));

% Make sure plot did NOT open up
assert(isempty(findobj('Number',figNum)));

%% TEST case: pieces, by code; mirror faces; nearest
figNum = 20002;
titleString = sprintf('TEST case: pieces, by code; mirror faces; nearest');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

% (two squares apart: two pieces; one square split by code: two pieces)
[verticesA, facesA] = fcn_INTERNAL_grid(2);
verticesB = verticesA + [2 0 0];
vertices = [verticesA; verticesB];
faces = [facesA; facesA + size(verticesA,1)];
pieces = pick.MeshPieces(faces, ones(size(faces,1),1));
assert(numel(unique(pieces)) == 2);
assert(numel(unique(pieces(1:size(facesA,1)))) == 1);
codes = ones(size(faces,1),1);
codes(1:2) = 2;
assert(numel(unique(pick.MeshPieces(faces, codes))) == 3);
% (a square and its mirror image across y = 0: each face has a mirror
% image; the square's own faces only, none)
[halfVertices, halfFaces] = fcn_INTERNAL_grid(4);
halfVertices(:,2) = halfVertices(:,2) + 0.1;
assert(all(pick.MirrorFaces(halfVertices, halfFaces, 0.02) == 0));
vertices = [halfVertices; halfVertices.*[1 -1 1]];
faces = [halfFaces; halfFaces(:,[1 3 2]) + size(halfVertices,1)];
mirrorFace = pick.MirrorFaces(vertices, faces, 0.02);
assert(all(mirrorFace > 0));
centers = pick.FaceCenters(vertices, faces);
assert(max(vecnorm(centers(mirrorFace,:) - centers.*[1 -1 1], 2, 2)) < 1e-9);
[nearestIndex, nearestDistance] = pick.Nearest([0 0 0; 1 0 0], [0.9 0 0; 0.2 0 0]);
assert(isequal(nearestIndex(:)', [2 1]) && max(abs(nearestDistance(:)' - [0.1 0.2])) < 1e-12);

% Make sure plot did NOT open up
assert(isempty(findobj('Number',figNum)));

%% TEST case: a line that misses picks nothing
figNum = 20003;
titleString = sprintf('TEST case: a line that misses picks nothing');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);

[vertices, faces] = fcn_INTERNAL_grid(2);
[picked, hitPoint] = pick.FacesOnRay(vertices, faces, (1:size(faces,1))', [5 5 1; 5 5 -1], [], 5, true);
assert(isempty(picked) && isempty(hitPoint));
assert(isempty(pick.FacesOnRay(vertices, faces, [], [0.5 0.5 1; 0.5 0.5 -1], [], 5, true)));

% Make sure plot did NOT open up
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
pick = fcn_CarMesh3D_meshPickTools(FigNum=[]);
assert(isstruct(pick));
assert(isempty(findobj('Number',figNum)));

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
pick = fcn_CarMesh3D_meshPickTools(FigNum=-1);
assert(isstruct(pick));
assert(isempty(findobj('Number',figNum)));

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% (none yet)

%% Fail conditions
if 1==0
    %% An option that does not exist
    fcn_CarMesh3D_meshPickTools(Size=3);
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
% A 1 m square at z = 0 from (0,0) to (1,1), numSide x numSide cells of two
% triangles each, facing up (+z)
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
