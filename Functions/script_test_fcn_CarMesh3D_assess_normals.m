% script_test_fcn_CarMesh3D_assess_normals.m
% Tests: fcn_CarMesh3D_assess_normals
%
% A V&V assessment function: its three modes (describe, fingerprint,
% draw), drawn in a figure of its own and in a panel, as the V&V GUI
% draws it. The vehicle is only read, never changed.

% REVISION HISTORY:
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_assess_normals
%   % * First write (drafted with Claude)

% TO-DO:
%
% (none)

%% Set up the workspace
close all
vehicleID = fcn_CarMesh3D_demoVehicle(UsePreference=false, FigNum=-1);   % (the repo's demo vehicle, read only)
vehicle = fcn_CarMesh3D_reviewInput(vehicleID, FigNum=-1);

%% Describe mode: no vehicle, no file, no figure
fprintf(1, 'Describe mode\n');
figuresBefore = numel(findall(groot, 'Type', 'figure'));
described = fcn_CarMesh3D_assess_normals([], Mode='describe');
assert(isstruct(described) && ~isempty(described));
assert(all(isfield(described, {'Key', 'Title', 'Question', 'Answers', 'ProblemAnswers', 'Help', 'GroupKey', ...
    'GroupTitle', 'GroupHelp'})));
assert(strcmp(described(1).Key, 'normals') && strcmp(described(1).GroupKey, 'normals'));
assert(isequal(described(1).Answers, {'Accept', 'Reject'}) && isequal(described(1).ProblemAnswers, {'Reject'}));
assert(isequal(described(1).Score, [0 10]) && described(1).Examples, 'A score from 0 to 10, and examples (Sean, 04:41)');
for ith_question = 1:numel(described)
    assert(iscellstr(described(ith_question).Answers) && numel(described(ith_question).Answers) >= 2);
    assert(all(ismember(described(ith_question).ProblemAnswers, described(ith_question).Answers)));
    assert(~isempty(described(ith_question).Question) && ~isempty(described(ith_question).Help));
end
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore);

%% Fingerprint mode: the same data, the same fingerprint; no figure
fprintf(1, 'Fingerprint mode\n');
result = fcn_CarMesh3D_assess_normals(vehicle, Mode='fingerprint');
assert(ischar(result.Fingerprint) && numel(result.Fingerprint) == 64);
assert(ischar(result.Note) && ~isempty(result.Note));
assert(isfield(result, 'Skip'));
again = fcn_CarMesh3D_assess_normals(vehicleID, Mode='fingerprint', FigNum=-1);   % (an ID works too)
assert(strcmp(again.Fingerprint, result.Fingerprint));
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore);
% (a changed mesh: a changed fingerprint)
changed = vehicle;
changed.Mesh.Vertices(1, :) = changed.Mesh.Vertices(1, :) + 0.01;
if isempty(result.Skip)
    changedResult = fcn_CarMesh3D_assess_normals(changed, Mode='fingerprint');
    assert(~strcmp(changedResult.Fingerprint, result.Fingerprint));
end

%% Draw mode, in a figure of its own
fprintf(1, 'Draw mode, in a figure\n');
figNum = 1001;
result = fcn_CarMesh3D_assess_normals(vehicle, FigNum=figNum);
if isempty(result.Skip)
    assert(numel(findall(figure(figNum), 'Type', 'axes')) == 2);
    normalsPatch = findall(figure(figNum), 'Type', 'patch', 'Tag', 'assessNormals');
    assert(numel(normalsPatch) == 2);
    % (each face's color is (n+1)/2: within 0 to 1, and a unit normal
    % back from it, for faces with area)
    colors = normalsPatch(1).FaceVertexCData;
    assert(size(colors, 1) == size(vehicle.Mesh.Faces, 1) && all(colors(:) >= 0 & colors(:) <= 1));
    normalLengths = sqrt(sum((2*colors - 1).^2, 2));
    assert(median(normalLengths) > 0.999 && median(normalLengths) < 1.001);
    % (a face turned inward shows in the opposite color)
    turned = vehicle;
    turned.Mesh.Faces(1, :) = turned.Mesh.Faces(1, [1 3 2]);
    fcn_CarMesh3D_assess_normals(turned, FigNum=figNum);
    turnedPatch = findall(figure(figNum), 'Type', 'patch', 'Tag', 'assessNormals');
    assert(max(abs(turnedPatch(1).FaceVertexCData(1,:) - (1 - colors(1,:)))) < 1e-9);
    % (the CAD mouse: the figure's own mouse functions are set)
    assert(~isempty(figure(figNum).WindowScrollWheelFcn) && ~isempty(figure(figNum).WindowButtonDownFcn));
end
close(figure(figNum));

%% Draw mode, in a panel (as the V&V GUI draws it)
fprintf(1, 'Draw mode, in a panel\n');
figureHandle = uifigure('Visible', 'off', 'Position', [50 50 1000 500]);
panel = uipanel(figureHandle, 'Position', [0 0 1000 500]);
uilabel(panel, 'Text', 'left from before');   % (cleared by the function)
result = fcn_CarMesh3D_assess_normals(vehicle, Parent=panel, FigNum=-1);
if isempty(result.Skip)
    assert(isempty(findall(panel, 'Type', 'uilabel')));
    assert(numel(findall(panel, 'Type', 'axes')) == 2);
end
delete(figureHandle);

%% Testing errors
fprintf(1, 'Testing errors\n');
try
    fcn_CarMesh3D_assess_normals('No_Such_Vehicle_ID', Mode='fingerprint');
    error('should have failed');
catch inputError
    assert(startsWith(inputError.identifier, 'CarMesh3D:'));
end

fprintf(1, 'All tests of fcn_CarMesh3D_assess_normals passed.\n');
