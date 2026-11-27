% script_test_fcn_CarMesh3D_fixFaceDirections.m
% Tests fcn_CarMesh3D_fixFaceDirections
% A window for fixing the direction faces point: colored by direction as
% seen from outside; select (Ctrl+click, Ctrl+double-click, Ctrl+drag,
% the suggested faces), Apply, Undo, Revert to start, Save.

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_fixFaceDirections
%   % * First write (drafted with Claude)
%   % * The painter's flow (T96): select, Apply, Undo, Revert to start,
%   %   % Esc; Ctrl+double-click a region; the pick report

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
    'ClickAt','DoubleClickAt','DragAt','FaceAt','Select','SelectSuggested','ClearSelection','Apply','Revert', ...
    'Flip','FlipSuggested','Undo','Save','Selected','Flipped','Suggested','Status','LastPick','FixedMesh', ...
    'FaceFlips','Sides','SetColorBy','SetBrush','SetSize','Close'})));
assert(isvalid(window.Figure));

% Check variable values: the inside-out side is suggested; the panel
% inside cannot be told; flipping the suggestion fixes the box
assert(isequal(sort(window.Suggested()), find(sideOfFace == wrongSide)));
statusNow = window.Status();
assert(statusNow.NumUnknown == nnz(sideOfFace == 7) && statusNow.NumFlipped == 0 && ~statusNow.Unsaved);
% (select the suggestion: nothing flips until Apply)
window.SelectSuggested();
assert(isequal(sort(window.Selected()), find(sideOfFace == wrongSide)) && isempty(window.Flipped()));
window.Apply();
assert(isempty(window.Selected()) && isempty(window.Suggested()) && isequal(sort(window.Flipped()), find(sideOfFace == wrongSide)));
assert(fcn_INTERNAL_allOut(window.FixedMesh(), sideOfFace));
assert(window.Status().Unsaved);
% (Undo takes back the Apply: the faces are selected again, not flipped;
% Undo again takes back the selection)
window.Undo();
assert(isempty(window.Flipped()) && isequal(sort(window.Selected()), find(sideOfFace == wrongSide)));
window.Undo();
assert(isempty(window.Selected()) && numel(window.Suggested()) == nnz(sideOfFace == wrongSide));

%% TEST case: Ctrl+click selects one face; Ctrl+double-click the region; Ctrl+Shift unselects; Ctrl+drag the brush; Esc; Undo
fprintf(1,'TEST case: Ctrl+click, Ctrl+double-click, Ctrl+Shift, Ctrl+drag, Esc, Undo\n');
% (a face of the wrong side the camera sees: a click there picks it)
wrongFaces = find(sideOfFace == wrongSide);
visibleWrong = wrongFaces(arrayfun(@(face) isequal(window.FaceAt(face), face), wrongFaces));
assert(~isempty(visibleWrong));
window.ClickAt(visibleWrong(1), {'control'});
assert(isequal(window.Selected(), visibleWrong(1)) && isempty(window.Flipped()));   % (one face, selected)
pickNow = window.LastPick();
assert(isequal(pickNow.Face, visibleWrong(1)) && contains(pickNow.Text, 'red'));
window.ClickAt(visibleWrong(1), {'control', 'shift'});
assert(isempty(window.Selected()));                                                % (unselected)
window.DoubleClickAt(visibleWrong(1), {'control'});
assert(isequal(sort(window.Selected()), wrongFaces));   % (the whole red region: the side's faces)
% (Esc unselects all; Undo puts them back)
window.Key('escape');
assert(isempty(window.Selected()));
window.Undo();
assert(isequal(sort(window.Selected()), wrongFaces));
window.Apply();
assert(isequal(sort(window.Flipped()), wrongFaces) && isempty(window.Selected()));
window.Undo();
window.ClearSelection();
assert(isempty(window.Flipped()) && isempty(window.Selected()));
% (a Ctrl+drag over the side: some of its faces, each selected once; one
% Undo takes back the stroke)
window.SetBrush('Large');
stepsBefore = window.Status().UndoSteps;
window.DragAt(visibleWrong(:), {'control'});
assert(~isempty(window.Selected()) && isempty(window.Flipped()));
assert(window.Status().UndoSteps == stepsBefore + 1);
window.Undo();
assert(isempty(window.Selected()));
% (a click beside the model, outside its faces: nothing picked)
window.ClickAt([5 5 5], {'control'});
assert(isempty(window.Selected()));

%% TEST case: Save writes the flips by position; Undo after Save says not saved; Revert to start; a new window reads them back
fprintf(1,'TEST case: Save, Undo after Save, Revert to start, then read back\n');
window.FlipSuggested();
window.Save();
assert(~window.Status().Unsaved);
window.Undo();   % (takes back the Apply in the window: not saved now)
assert(window.Status().Unsaved && isempty(window.Flipped()));
window.Apply();  % (the faces were selected again by the Undo)
assert(~window.Status().Unsaved);
assert(~window.Status().Unsaved && isfile(flipsFile));
loaded = load(flipsFile, 'faceFlips');
assert(size(loaded.faceFlips.Points,1) == numel(wrongFaces) && loaded.faceFlips.NumFaces == size(testMesh.Faces,1));
assert(isequal(size(loaded.faceFlips.Normals), [numel(wrongFaces) 3]));
% (the build replays them: the box comes out right, and again changes nothing)
[replayed, replayInfo] = fcn_CarMesh3D_applyFaceFlips(testMesh, flipsFile, FigNum=-1);
assert(replayInfo.NumTurned == numel(wrongFaces) && fcn_INTERNAL_allOut(replayed, sideOfFace));
[~, againInfo] = fcn_CarMesh3D_applyFaceFlips(replayed, flipsFile, FigNum=-1);
assert(againInfo.NumTurned == 0);
window.Close();
assert(~isvalid(window.Figure));
[fixedMesh, faceFlips, window] = fcn_CarMesh3D_fixFaceDirections(testMesh, FlipsFile=flipsFile, FlagVisible=false);
assert(isequal(sort(window.Flipped()), wrongFaces) && ~window.Status().Unsaved);
assert(fcn_INTERNAL_allOut(fixedMesh, sideOfFace));
assert(size(faceFlips.Points,1) == numel(wrongFaces));
% (Revert to start: back to the flips read at the start, after changes;
% Undo takes it back)
window.Flip(wrongFaces(1:2));
window.Select(wrongFaces(3));
assert(window.Status().Unsaved);
window.Revert();
assert(isequal(sort(window.Flipped()), wrongFaces) && isempty(window.Selected()) && ~window.Status().Unsaved);
window.Undo();
assert(numel(window.Flipped()) == numel(wrongFaces) - 2 && isequal(window.Selected(), wrongFaces(3)));
window.Revert();
window.Close();
% (opened on the mesh with the flips already replayed: nothing shows
% flipped, and saving again keeps the saved flips)
[~, ~, window] = fcn_CarMesh3D_fixFaceDirections(replayed, FlipsFile=flipsFile, FlagVisible=false);
assert(isempty(window.Flipped()) && isempty(window.Suggested()));
window.Save();
loaded = load(flipsFile, 'faceFlips');
assert(size(loaded.faceFlips.Points,1) == numel(wrongFaces));
window.Close();
[~, ~, window] = fcn_CarMesh3D_fixFaceDirections(testMesh, FlipsFile=flipsFile, FlagVisible=false);

%% TEST case: Color by labels; the controls have tags; closing leaves nothing
fprintf(1,'TEST case: color by labels, tags, close\n');
window.SetColorBy('labels');
assert(isequal(window.Patch.FaceVertexCData, testMesh.FaceColors));
window.SetColorBy('normals');
normalColors = window.Patch.FaceVertexCData;
assert(all(normalColors(:) >= 0 & normalColors(:) <= 1));
bottomFaces = find(sideOfFace == 2);   % (the bottom: its normal points down, z = -1, so no blue)
assert(all(abs(normalColors(bottomFaces,3)) < 1e-9));
window.SetColorBy('direction');
assert(~isequal(window.Patch.FaceVertexCData, testMesh.FaceColors));
assert(strcmp(window.Status().ColorBy, 'direction'));
assert(contains(findall(window.Figure, 'Tag', 'facesStatus').Text, 'Not saved') || ~window.Status().Unsaved);
for tag = {'facesMenu', 'facesUndo', 'facesRevert', 'facesSave', 'facesStatus', 'facesSelectSuggested', 'facesApply', ...
        'facesClearSelection', 'facesSelection', 'facesColorBy', 'facesBrush', 'facesHint'}
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
