function result = fcn_CarMesh3D_assess_normals(vehicleInput, options)
% fcn_CarMesh3D_assess_normals
% V&V assessment: "Do all faces point outward, with no face in the
% opposite color to its neighbors?" The mesh with each face colored by
% the direction it points (its unit normal n, as the color (n+1)/2), in
% two views the reviewer turns and zooms with the CAD mouse
% (fcn_CarMesh3D_addCadMouse). A face that points the wrong way shows in
% the opposite color to the faces around it (Sean, 2026-11-26 02:35: "the
% errors stand out dramatically. I could spot them instantly"). The
% answer is Accept or Reject, with a score from 0 (bad) to 10 (perfect)
% (Sean, 04:41); the V&V GUI keeps examples to compare with (Q90 (A),
% Q91 (A)).
%
% Every V&V assessment function works the same way (the V&V design file,
% Documentation_CarMesh3D_GUIdesign_VandV.md, section 3):
%   Mode='describe'     no vehicle, no file, no figure: its title,
%                       question, answers and tooltip, for the menus
%   Mode='fingerprint'  the fingerprint of the data it would show, without
%                       drawing (so the V&V GUI can tell an old answer is
%                       out of date)
%   Mode='draw'         (default) draws its pictures into Parent (or a
%                       figure of its own), then returns; it never returns
%                       drawing for the caller to do later. The CAD mouse
%                       lives inside the pictures (rule 2)
%
% FORMAT:
%
%       result = fcn_CarMesh3D_assess_normals(vehicleInput,...
%           (Mode=mode), (Key=key), (Parent=panel), (FigNum=figNum))
%
% INPUTS:
%
%      vehicleInput: a vehicle ID or folder, or the structure
%      fcn_CarMesh3D_reviewInput makes ([] in describe mode).
%
%     (OPTIONAL INPUTS, given as Name=Value pairs)
%
%      Mode: 'draw' (default), 'describe' or 'fingerprint'.
%
%      Key: which question; this one has one ('normals'). Default: the
%      first.
%
%      Parent: the panel to draw in; [] (default) for a figure of its own.
%
%      FigNum: the figure to use with no Parent; -1 for fast mode.
%
% OUTPUTS:
%
%      result: a structure with Key, Title, Question, Detail, Answers,
%      ProblemAnswers, Help, GroupKey, GroupTitle, GroupHelp, Score (the
%      score's range, [0 10]: the V&V GUI asks for one with the answer)
%      and Examples (true: the V&V GUI offers "Compare with examples" and
%      "Save as an example"); and, in the other modes, Fingerprint, Skip
%      and Note.
%
% DEPENDENCIES:
%
%      fcn_CarMesh3D_reviewInput, fcn_CarMesh3D_assessAxes,
%      fcn_CarMesh3D_addCadMouse, fcn_CarMesh3D_fingerprint
%
% EXAMPLES:
%
%       fcn_CarMesh3D_assess_normals('2009_Honda_Fit_Sport', FigNum=1);
%
%       See the script: script_test_fcn_CarMesh3D_assess_normals.m for a
%       full test suite.
%
% This function was written on 2026_11_26 by S. Brennan (drafted with
% Claude)
% Questions or comments? sbrennan@psu.edu

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In fcn_CarMesh3D_assess_normals
%   % * First write (the V&V design file, plan item 14; Sean, 03:12 and
%   %   % 04:41)

% TO-DO:
%
% (none)

arguments
    vehicleInput            % Vehicle ID, folder or reviewInput structure ([] to describe)
    options.Mode = 'draw'   % 'draw', 'describe' or 'fingerprint'
    options.Key = ''        % Which question ('' for the first)
    options.Parent = []     % The panel to draw in
    options.FigNum = []     % A figure of its own; -1 fast mode
end

%% Main code
described = struct('Key', 'normals', 'Title', 'Normals', ...
    'Question', 'Do all faces point outward, with no face in the opposite color to its neighbors?', ...
    'Answers', {{'Accept', 'Reject'}}, 'ProblemAnswers', {{'Reject'}}, ...
    'Help', ['Each face is colored by the direction it points (front red-ish, up blue-ish, left green-ish, and so on), ' ...
    'so neighbors that point alike share a color. A face pointing the wrong way, inward, shows in the opposite ' ...
    'color to the faces around it: a dark or bright speck or sliver. Turn and zoom with the mouse (left-drag ' ...
    'turns, right-drag pans, the wheel zooms). Reject if any such face would show on the vehicle; give a ' ...
    'score from 0 (bad) to 10 (perfect).'], ...
    'Detail', 'Turn the model all the way round. Compare with the saved examples if unsure; do not Accept if unsure.', ...
    'GroupKey', 'normals', 'GroupTitle', 'Normals', ...
    'GroupHelp', 'The faces'' directions: each face colored by where it points', ...
    'Score', [0 10], 'Examples', true);
if strcmpi(options.Mode, 'describe')
    result = described;
    return;
end

vehicle = fcn_CarMesh3D_reviewInput(vehicleInput, FigNum=-1);
mesh = vehicle.Mesh;
result = described;
result.Skip = '';
% (the faces' directions depend on the vertices and on each face's vertex
% order, so both are in the fingerprint)
result.Fingerprint = fcn_CarMesh3D_fingerprint(mesh.Vertices, mesh.Faces);
result.Note = sprintf('%s: %d faces', vehicle.Name, size(mesh.Faces, 1));
if strcmpi(options.Mode, 'fingerprint')
    return;
end

% The pictures: two views, the front from the left and the rear from the
% right, each turned and zoomed with the CAD mouse
faceColors = (fcn_INTERNAL_unitNormals(mesh.Vertices, mesh.Faces) + 1)/2;
captions = {'Front, from the left (drag to turn)', 'Rear, from the right (drag to turn)'};
axesHandles = fcn_CarMesh3D_assessAxes(options.Parent, 2, Captions=captions, FigNum=options.FigNum);
viewAngles = [128 20; -52 20];
for ith_view = 1:2
    patch(axesHandles(ith_view), 'Vertices', mesh.Vertices, 'Faces', mesh.Faces, ...
        'FaceVertexCData', faceColors, 'FaceColor', 'flat', 'EdgeColor', 'none', 'FaceLighting', 'none', ...
        'BackFaceLighting', 'unlit', 'Tag', 'assessNormals');
    axis(axesHandles(ith_view), 'equal', 'off');
    view(axesHandles(ith_view), viewAngles(ith_view, 1), viewAngles(ith_view, 2));
    axesHandles(ith_view).Projection = 'perspective';
end
fcn_CarMesh3D_addCadMouse(axesHandles, FigNum=-1);
end % Ends main function

%% Functions follow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% fcn_INTERNAL_unitNormals
function normals = fcn_INTERNAL_unitNormals(vertices, faces)
% Each face's unit normal, from its first three corners (the right-hand
% rule on the vertex order); [0 0 0] for a face with no area
firstEdge = vertices(faces(:,2),:) - vertices(faces(:,1),:);
secondEdge = vertices(faces(:,3),:) - vertices(faces(:,1),:);
normals = cross(firstEdge, secondEdge, 2);
lengths = sqrt(sum(normals.^2, 2));
flagArea = lengths > 0;
normals(flagArea,:) = normals(flagArea,:)./lengths(flagArea);
normals(~flagArea,:) = 0;
end % Ends fcn_INTERNAL_unitNormals
