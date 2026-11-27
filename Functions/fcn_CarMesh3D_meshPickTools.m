function tools = fcn_CarMesh3D_meshPickTools(options)
% fcn_CarMesh3D_meshPickTools
% The picking, brush and highlight helpers shared by the windows that work
% on faces with the mouse: the label painter (fcn_CarMesh3D_paintLabels)
% and the face-direction window (step 1E of the plan of 2026-11-27). Taken
% out of the painter (step 1D) so both pick, brush and highlight the same
% way. None of them depends on the direction faces point.
%
% They are returned as a structure of functions, so one call gives them
% all:
%
%   ray = tools.RayAtPixel(axesHandle, pixel, meshSize)
%       The line under a pixel of the window (as its CurrentPoint gives
%       the mouse): 2 x 3, its front (nearest the camera) and back.
%       meshSize: the model's size in meters (how far the line reaches).
%
%   pixel = tools.PixelOf(axesHandle, point)
%       Where a 3D point is drawn in the window, in pixels.
%
%   metersPerPixel = tools.MetersPerPixel(axesHandle, point)
%       How many meters one screen pixel spans at a point (the brush's
%       cone: the same on screen at any zoom).
%
%   hitDistance = tools.RayHits(origin, direction, vertices, faces)
%       How far along the line each triangle is hit (Inf where missed),
%       from either side of the triangle.
%
%   [faces, hitPoint] = tools.FacesOnRay(vertices, faces, candidates, ray,
%           axesHandle, brushPixels, flagSingle)
%       The candidate faces the line hits first (flagSingle), or that face
%       and the candidates around it within brushPixels on the screen, on
%       the near side; [] if the line misses.
%
%   [liftedVertices, liftedFaces] = tools.LiftedFaces(vertices, faces,
%           faceList, lift)
%       Two copies of the listed faces, lift meters off them, one on each
%       side: the first numel(faceList) copies along the corner-order
%       normal, the next against it. One is always in front of the
%       surface, whichever way the face points (the highlight).
%
%   pieceIndex = tools.MeshPieces(faces, codes)
%       Each face's piece: faces with the same code (one number per face,
%       such as its label) that share a corner. All ones: connected faces.
%
%   mirrorFace = tools.MirrorFaces(vertices, faces, tolerance)
%       Each face's mirror image across the centerline (y to -y): the face
%       whose center is nearest the mirrored center, within tolerance
%       meters (0 if none).
%
%   centers = tools.FaceCenters(vertices, faces)
%
%   [nearestIndex, nearestDistance] = tools.Nearest(points, queries)
%       The nearest of points to each query.
%
% FORMAT:
%
%       tools = fcn_CarMesh3D_meshPickTools((FigNum=figNum))
%
% INPUTS:
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      FigNum: not used for plotting (there is nothing to plot); -1 for
%      fast mode, as in the other functions.
%
% OUTPUTS:
%
%      tools: the structure of functions above.
%
% DEPENDENCIES:
%
%      knnsearch (Statistics and Machine Learning Toolbox), if there; else
%      a slower search in blocks
%
% EXAMPLES:
%
%       pick = fcn_CarMesh3D_meshPickTools();
%       ray = pick.RayAtPixel(gca, get(gcf,'CurrentPoint'), 5);
%
%       See the script: script_test_fcn_CarMesh3D_meshPickTools.m for a
%       full test suite.
%
% This function was written on 2026_11_27 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_meshPickTools
%   % * First write: taken out of fcn_CarMesh3D_paintLabels (step 1D of the
%   %   % plan of 2026-11-27), unchanged except that the highlight's copies
%   %   % use the corner-order normal on both sides (step 1C)

% TO-DO:
%
% (none)

arguments
    options.FigNum = []   % Not used for plotting; -1 for fast mode
end %#ok<INUSA>

tools = struct( ...
    'RayAtPixel', @fcn_INTERNAL_rayAtPixel, ...
    'PixelOf', @fcn_INTERNAL_pixelOf, ...
    'MetersPerPixel', @fcn_INTERNAL_metersPerPixel, ...
    'RayHits', @fcn_INTERNAL_rayHits, ...
    'FacesOnRay', @fcn_INTERNAL_facesOnRay, ...
    'LiftedFaces', @fcn_INTERNAL_liftedFaces, ...
    'MeshPieces', @fcn_INTERNAL_meshPieces, ...
    'MirrorFaces', @fcn_INTERNAL_mirrorFaces, ...
    'FaceCenters', @fcn_INTERNAL_faceCenters, ...
    'Nearest', @fcn_INTERNAL_nearest);

end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   ______                _   _
%  |  ____|              | | (_)
%  | |__ _   _ _ __   ___| |_ _  ___  _ __  ___
%  |  __| | | | '_ \ / __| __| |/ _ \| '_ \/ __|
%  | |  | |_| | | | | (__| |_| | (_) | | | \__ \
%  |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_camera
function [box, viewDirection, distance, rightward, upward, pixelsPerMeter] = fcn_INTERNAL_camera(axesHandle)
% The axes' camera: its box in pixels, view direction, distance, the
% screen's right and up directions, and pixels per meter at the target.
% The camera's view angle spans the shorter side of the axes' box
% (checked against real clicks, 2026-11-24).
box = getpixelposition(axesHandle, true);
viewDirection = axesHandle.CameraTarget - axesHandle.CameraPosition;
distance = norm(viewDirection);
viewDirection = viewDirection/max(distance, eps);
rightward = cross(viewDirection, axesHandle.CameraUpVector);
rightward = rightward/norm(rightward);
upward = cross(rightward, viewDirection);
halfSpan = distance*tand(axesHandle.CameraViewAngle/2);
pixelsPerMeter = min(box(3), box(4))/(2*max(halfSpan, eps));
end % Ends fcn_INTERNAL_camera

%% fcn_INTERNAL_pixelOf
function pixel = fcn_INTERNAL_pixelOf(axesHandle, point)
% Where a 3D point is drawn in the window, in pixels (as the window's
% CurrentPoint gives the mouse); for an orthographic camera
[box, ~, ~, rightward, upward, pixelsPerMeter] = fcn_INTERNAL_camera(axesHandle);
offset = point - axesHandle.CameraTarget;
pixel = box(1:2) + box(3:4)/2 + pixelsPerMeter*[dot(offset, rightward), dot(offset, upward)];
end % Ends fcn_INTERNAL_pixelOf

%% fcn_INTERNAL_rayAtPixel
function ray = fcn_INTERNAL_rayAtPixel(axesHandle, pixel, meshSize)
% The line under a pixel of the window, through the model's axes: 2 x 3,
% its front (nearest the camera) and back
[box, viewDirection, distance, rightward, upward, pixelsPerMeter] = fcn_INTERNAL_camera(axesHandle);
offset = (pixel(:)' - (box(1:2) + box(3:4)/2))/pixelsPerMeter;
pointOnTarget = axesHandle.CameraTarget + offset(1)*rightward + offset(2)*upward;
reach = 10*max(meshSize, 1) + distance;
if strcmp(axesHandle.Projection, 'perspective')
    direction = pointOnTarget - axesHandle.CameraPosition;
    direction = direction/norm(direction);
    ray = [axesHandle.CameraPosition; axesHandle.CameraPosition + reach*direction];
else
    ray = [pointOnTarget - reach*viewDirection; pointOnTarget + reach*viewDirection];
end
end % Ends fcn_INTERNAL_rayAtPixel

%% fcn_INTERNAL_metersPerPixel
function metersPerPixel = fcn_INTERNAL_metersPerPixel(axesHandle, point)
% How many meters one screen pixel spans at a point: perspective, it grows
% with the point's distance from the camera; orthographic, the same
% everywhere (the brush's cone, T86)
box = getpixelposition(axesHandle, true);
viewDirection = axesHandle.CameraTarget - axesHandle.CameraPosition;
distance = norm(viewDirection);
viewDirection = viewDirection/max(distance, eps);
if strcmp(axesHandle.Projection, 'perspective')
    depth = max((point - axesHandle.CameraPosition)*viewDirection', eps);
else
    depth = distance;
end
metersPerPixel = 2*depth*tand(axesHandle.CameraViewAngle/2)/max(min(box(3), box(4)), 1);
end % Ends fcn_INTERNAL_metersPerPixel

%% fcn_INTERNAL_rayHits
function hitDistance = fcn_INTERNAL_rayHits(origin, direction, vertices, faces)
% How far along the line (origin + t*direction) it hits each triangle; Inf
% where it misses (the Moller-Trumbore test, for all triangles at once,
% from either side of each triangle)
numFaces = size(faces,1);
corner1 = vertices(faces(:,1),:);
edge1 = vertices(faces(:,2),:) - corner1;
edge2 = vertices(faces(:,3),:) - corner1;
directions = repmat(direction, numFaces, 1);
pVector = cross(directions, edge2, 2);
determinant = sum(edge1.*pVector, 2);
flagValid = abs(determinant) > 1e-12;
inverse = 1./determinant;
tVector = origin - corner1;
u = sum(tVector.*pVector, 2).*inverse;
qVector = cross(tVector, edge1, 2);
v = sum(directions.*qVector, 2).*inverse;
hitDistance = sum(edge2.*qVector, 2).*inverse;
flagHit = flagValid & u >= -1e-9 & v >= -1e-9 & u + v <= 1 + 1e-9 & hitDistance > 0;
hitDistance(~flagHit) = Inf;
end % Ends fcn_INTERNAL_rayHits

%% fcn_INTERNAL_facesOnRay
function [pickedFaces, hitPoint] = fcn_INTERNAL_facesOnRay(vertices, faces, candidates, ray, axesHandle, brushPixels, flagSingle)
% The candidate faces under a line: the one it hits first (flagSingle),
% or that face and the candidates whose centers lie within the brush of
% the point hit, on the near side of the model. The brush is brushPixels
% on the screen, turned into meters at the point hit (a cone from the
% eye: the same on screen at any zoom, T86). [] if the line misses.
pickedFaces = [];
hitPoint = [];
if isempty(candidates)
    return;
end
candidates = candidates(:);
direction = ray(2,:) - ray(1,:);
direction = direction/norm(direction);
hitDistance = fcn_INTERNAL_rayHits(ray(1,:), direction, vertices, faces(candidates,:));
[firstHit, hitIndex] = min(hitDistance);
if isinf(firstHit)
    return;   % (the line misses the model)
end
hitFace = candidates(hitIndex);
hitPoint = ray(1,:) + firstHit*direction;
if flagSingle
    pickedFaces = hitFace;
    return;
end
centers = fcn_INTERNAL_faceCenters(vertices, faces(candidates,:));
brush = brushPixels*fcn_INTERNAL_metersPerPixel(axesHandle, hitPoint);
nearHit = candidates(vecnorm(centers - hitPoint, 2, 2) < brush & ...
    (centers - ray(1,:))*direction' < firstHit + 0.05);
pickedFaces = unique([hitFace; nearHit(:)]);
end % Ends fcn_INTERNAL_facesOnRay

%% fcn_INTERNAL_liftedFaces
function [liftedVertices, liftedFaces] = fcn_INTERNAL_liftedFaces(vertices, faces, faceList, lift)
% Two copies of the listed faces, lift meters off them, one on each side
% (step 1C: a highlight lifted along a backward face's normal sank behind
% the surface)
liftedVertices = zeros(0,3);
liftedFaces = zeros(0,3);
if isempty(faceList)
    return;
end
faceList = faceList(:);
corner1 = vertices(faces(faceList,1),:);
corner2 = vertices(faces(faceList,2),:);
corner3 = vertices(faces(faceList,3),:);
normals = cross(corner2 - corner1, corner3 - corner1, 2);
normals = normals./max(vecnorm(normals,2,2), eps);
numFaces = numel(faceList);
liftedVertices = zeros(6*numFaces,3);
for ith_side = 1:2
    sideLift = lift*(3 - 2*ith_side);   % (+lift, then -lift)
    firstRow = 3*numFaces*(ith_side - 1);
    liftedVertices(firstRow + (1:3:3*numFaces),:) = corner1 + sideLift*normals;
    liftedVertices(firstRow + (2:3:3*numFaces),:) = corner2 + sideLift*normals;
    liftedVertices(firstRow + (3:3:3*numFaces),:) = corner3 + sideLift*normals;
end
liftedFaces = reshape(1:6*numFaces, 3, [])';
end % Ends fcn_INTERNAL_liftedFaces

%% fcn_INTERNAL_meshPieces
function pieceIndex = fcn_INTERNAL_meshPieces(faces, codes)
% Each face's piece: faces with the same code that share a corner are in
% one piece (numbered by one of its faces)
numFaces = size(faces,1);
codes = codes(:);
parent = 1:numFaces;
faceList = repmat((1:numFaces)', 3, 1);
[vertexList, order] = sort(faces(:));
faceList = faceList(order);
for ith_entry = 2:numel(vertexList)
    if vertexList(ith_entry) == vertexList(ith_entry-1)
        faceA = faceList(ith_entry);
        faceB = faceList(ith_entry-1);
        if codes(faceA) == codes(faceB)
            rootA = faceA;
            while parent(rootA) ~= rootA
                parent(rootA) = parent(parent(rootA));
                rootA = parent(rootA);
            end
            rootB = faceB;
            while parent(rootB) ~= rootB
                parent(rootB) = parent(parent(rootB));
                rootB = parent(rootB);
            end
            if rootA ~= rootB
                parent(rootA) = rootB;
            end
        end
    end
end
pieceIndex = zeros(numFaces,1);
for ith_face = 1:numFaces
    root = ith_face;
    while parent(root) ~= root
        root = parent(root);
    end
    pieceIndex(ith_face) = root;
end
end % Ends fcn_INTERNAL_meshPieces

%% fcn_INTERNAL_mirrorFaces
function mirrorFace = fcn_INTERNAL_mirrorFaces(vertices, faces, tolerance)
% Each face's mirror image across the centerline (y to -y): the face whose
% center is nearest the mirrored center, within tolerance (0 if none)
centers = fcn_INTERNAL_faceCenters(vertices, faces);
mirrored = centers.*[1 -1 1];
[mirrorFace, distance] = fcn_INTERNAL_nearest(centers, mirrored);
mirrorFace(distance > tolerance) = 0;
end % Ends fcn_INTERNAL_mirrorFaces

%% fcn_INTERNAL_faceCenters
function centers = fcn_INTERNAL_faceCenters(vertices, faces)
centers = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
end % Ends fcn_INTERNAL_faceCenters

%% fcn_INTERNAL_nearest
function [nearestIndex, nearestDistance] = fcn_INTERNAL_nearest(points, queries)
% The nearest of points to each query (knnsearch if there, else in blocks)
if exist('knnsearch', 'file') == 2
    [nearestIndex, nearestDistance] = knnsearch(points, queries);
    return;
end
numQueries = size(queries,1);
nearestIndex = zeros(numQueries,1);
nearestDistance = zeros(numQueries,1);
blockSize = 500;
for first = 1:blockSize:numQueries
    rows = first:min(numQueries, first+blockSize-1);
    squaredDistance = sum(queries(rows,:).^2,2) + sum(points.^2,2)' - 2*queries(rows,:)*points';
    [minimum, index] = min(squaredDistance, [], 2);
    nearestIndex(rows) = index;
    nearestDistance(rows) = sqrt(max(minimum,0));
end
end % Ends fcn_INTERNAL_nearest
