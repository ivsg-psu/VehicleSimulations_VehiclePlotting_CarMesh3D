% script_test_fcn_CarMesh3D_fixFaceDirections.m
% Tests fcn_CarMesh3D_fixFaceDirections
% A window for fixing the direction faces point: colored by direction as
% seen from outside, suggested flips, flips by hand, Undo, Save.

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fixFaceDirections
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

%% DEMO case: a box with one side inside out, and a panel inside it
fprintf(1,'DEMO case: a box with one side inside out, and a panel inside it\n');
[testMesh, sideOfFace] = fcn_INTERNAL_box();
wrongSide = 1;   % (the top: the camera sees it)
testMesh.Faces(sideOfFace == wrongSide,:) = testMesh.Faces(sideOfFace == wrongSide, [1 3 2]);
flipsFile = fullfile(tempdir, 'faceFlips_test_fixFaceDirections.mat');
if isfile(flipsFile)
    delete(flipsFile);
end
[~, ~, window] = fcn_CarMesh3D_fixFaceDirections(testMesh, FlipsFile=flipsFile, FlagVisible=false);

% Check variable types and sizes
assert(isstruct(window) && all(isfield(window, {'Figure','Axes','Patch','State','SetState','Press','Key','CheckLayout', ...
    'ClickAt','DragAt','FaceAt','Flip','FlipSuggested','Undo','Save','Flipped','Suggested','Status','FixedMesh', ...
    'FaceFlips','Sides','SetColorBy','SetBrush','SetSize','Close'})));
assert(isvalid(window.Figure));

% Check variable values: the inside-out side is suggested; the panel
% inside cannot be told; flipping the suggestion fixes the box
assert(isequal(sort(window.Suggested()), find(sideOfFace == wrongSide)));
statusNow = window.Status();
assert(statusNow.NumUnknown == nnz(sideOfFace == 7) && statusNow.NumFlipped == 0 && ~statusNow.Unsaved);
window.FlipSuggested();
assert(isempty(window.Suggested()) && isequal(sort(window.Flipped()), find(sideOfFace == wrongSide)));
assert(fcn_INTERNAL_allOut(window.FixedMesh(), sideOfFace));
assert(window.Status().Unsaved);
window.Undo();
assert(isempty(window.Flipped()) && numel(window.Suggested()) == nnz(sideOfFace == wrongSide));

%% TEST case: Ctrl+click flips the region; Ctrl+Shift+click one face; Ctrl+drag the brush; Undo takes each back
fprintf(1,'TEST case: Ctrl+click, Ctrl+Shift+click, Ctrl+drag, Undo\n');
% (a face of the wrong side the camera sees: a click there picks it)
wrongFaces = find(sideOfFace == wrongSide);
visibleWrong = wrongFaces(arrayfun(@(face) isequal(window.FaceAt(face), face), wrongFaces));
assert(~isempty(visibleWrong));
window.ClickAt(visibleWrong(1), {'control'});
assert(isequal(sort(window.Flipped()), wrongFaces));   % (the whole red region: the side's faces)
window.Undo();
window.ClickAt(visibleWrong(1), {'control', 'shift'});
assert(isequal(window.Flipped(), visibleWrong(1)));    % (one face)
window.Undo();
assert(isempty(window.Flipped()));
% (a Ctrl+drag over the side: some of its faces, each flipped once; one Undo)
window.SetBrush('Large');
window.DragAt(visibleWrong(:), {'control'});
assert(~isempty(window.Flipped()));
window.Undo();
assert(isempty(window.Flipped()));

%% TEST case: Save writes the flips by position; a new window reads them back
fprintf(1,'TEST case: Save, then read back\n');
window.FlipSuggested();
window.Save();
assert(~window.Status().Unsaved && isfile(flipsFile));
loaded = load(flipsFile, 'faceFlips');
assert(size(loaded.faceFlips.Points,1) == numel(wrongFaces) && loaded.faceFlips.NumFaces == size(testMesh.Faces,1));
window.Close();
assert(~isvalid(window.Figure));
[fixedMesh, faceFlips, window] = fcn_CarMesh3D_fixFaceDirections(testMesh, FlipsFile=flipsFile, FlagVisible=false);
assert(isequal(sort(window.Flipped()), wrongFaces) && ~window.Status().Unsaved);
assert(fcn_INTERNAL_allOut(fixedMesh, sideOfFace));
assert(size(faceFlips.Points,1) == numel(wrongFaces));

%% TEST case: Color by labels; the controls have tags; closing leaves nothing
fprintf(1,'TEST case: color by labels, tags, close\n');
window.SetColorBy('labels');
assert(isequal(window.Patch.FaceVertexCData, testMesh.FaceColors));
window.SetColorBy('direction');
assert(~isequal(window.Patch.FaceVertexCData, testMesh.FaceColors));
assert(strcmp(window.Status().ColorBy, 'direction'));
for tag = {'facesMenu', 'facesUndo', 'facesSave', 'facesStatus', 'facesFlipSuggested', 'facesColorBy', 'facesBrush', 'facesHint'}
    assert(~isempty(findall(window.Figure, 'Tag', tag{1})), 'no control tagged %s', tag{1});
end
window.SetSize(900, 600);
window.Close();
assert(~isvalid(window.Figure));
delete(flipsFile);

%% TEST case: a vehicle mesh with no labels still opens
fprintf(1,'TEST case: no labels\n');
plainMesh = struct('Vertices', testMesh.Vertices, 'Faces', testMesh.Faces);
[~, ~, window] = fcn_CarMesh3D_fixFaceDirections(plainMesh, FlagVisible=false);
assert(numel(window.Suggested()) == nnz(sideOfFace == wrongSide));
window.FlipSuggested();
window.Save();   % (no flips file: kept in the window only)
assert(~window.Status().Unsaved);
window.Close();

%% Fail conditions
if 1==0
    %% Not a mesh
    fcn_CarMesh3D_fixFaceDirections(3);
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

%% fcn_INTERNAL_box
function [testMesh, sideOfFace] = fcn_INTERNAL_box()
% A 1 m box centered at the origin, each side 2 x 2 squares (8 triangles)
% facing out, labeled body; and a square panel inside it at z = 0 (side 7)
% that cannot be told from the shape
sides = {[-0.5 -0.5  0.5], [1 0 0], [0 1 0];    % top (+z)
         [-0.5  0.5 -0.5], [1 0 0], [0 -1 0];   % bottom (-z)
         [ 0.5 -0.5 -0.5], [0 1 0], [0 0 1];    % +x
         [-0.5  0.5 -0.5], [0 -1 0], [0 0 1];   % -x
         [ 0.5  0.5 -0.5], [-1 0 0], [0 0 1];   % +y
         [-0.5 -0.5 -0.5], [1 0 0], [0 0 1];    % -y
         [-0.3 -0.3  0.0], [0.6 0 0]/1, [0 0.6 0]/1};   % (inside)
vertices = zeros(0,3);
faces = zeros(0,3);
sideOfFace = zeros(0,1);
for ith_side = 1:size(sides,1)
    origin = sides{ith_side,1};
    axisU = sides{ith_side,2};
    axisV = sides{ith_side,3};
    [u, v] = ndgrid([0 0.5 1]);
    sideVertices = origin + u(:)*axisU + v(:)*axisV;
    sideFaces = zeros(0,3);
    for ith_u = 1:2
        for ith_v = 1:2
            corner = ith_u + (ith_v - 1)*3;
            sideFaces(end+1,:) = [corner, corner + 1, corner + 4]; %#ok<AGROW>
            sideFaces(end+1,:) = [corner, corner + 4, corner + 3]; %#ok<AGROW>
        end
    end
    faces = [faces; sideFaces + size(vertices,1)]; %#ok<AGROW>
    vertices = [vertices; sideVertices]; %#ok<AGROW>
    sideOfFace = [sideOfFace; repmat(ith_side, size(sideFaces,1), 1)]; %#ok<AGROW>
end
numFaces = size(faces,1);
testMesh = struct('Vertices', vertices, 'Faces', faces, 'LabelPartNames', {{'body','trim','glass','light','wheel'}}, ...
    'LabelFacePart', ones(numFaces,1), 'FaceColors', repmat([0.2 0.3 0.8], numFaces, 1));
end % Ends fcn_INTERNAL_box

%% fcn_INTERNAL_allOut
function flagOut = fcn_INTERNAL_allOut(vehicleMesh, sideOfFace)
% (every face of the box's six sides points away from its middle)
vertices = vehicleMesh.Vertices;
faces = vehicleMesh.Faces(sideOfFace <= 6,:);
normals = cross(vertices(faces(:,2),:) - vertices(faces(:,1),:), vertices(faces(:,3),:) - vertices(faces(:,1),:), 2);
centers = (vertices(faces(:,1),:) + vertices(faces(:,2),:) + vertices(faces(:,3),:))/3;
flagOut = all(sum(normals.*centers, 2) > 0);
end % Ends fcn_INTERNAL_allOut
