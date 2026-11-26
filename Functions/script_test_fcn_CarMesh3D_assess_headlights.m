% script_test_fcn_CarMesh3D_assess_headlights.m
% Tests: fcn_CarMesh3D_assess_headlights
%
% A V&V assessment function: its three modes (describe, fingerprint,
% draw), drawn in a figure of its own and in a panel, as the V&V GUI
% draws it. The vehicle is only read, never changed.

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_assess_headlights
%   % * First write (drafted with Claude)

% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_assess_headlights
%   % * Six pictures in two rows, the close-ups below (T76 (B))

% TO-DO:
%
% (none)

%% Set up the workspace
close all
vehicleID = fcn_CarMesh3D_demoVehicle(FlagUsePreference=false, FigNum=-1);   % (the repo's demo vehicle, read only)
vehicle = fcn_CarMesh3D_reviewInput(vehicleID, FigNum=-1);

%% Describe mode: no vehicle, no file, no figure
fprintf(1, 'Describe mode\n');
figuresBefore = numel(findall(groot, 'Type', 'figure'));
described = fcn_CarMesh3D_assess_headlights([], Mode='describe');
assert(isstruct(described) && ~isempty(described));
assert(all(isfield(described, {'Key', 'Title', 'Question', 'Answers', 'ProblemAnswers', 'Help', 'GroupKey', ...
    'GroupTitle', 'GroupHelp'})));
assert(strcmp(described(1).Key, 'headlights') && strcmp(described(1).GroupKey, 'headlights'));
for ith_question = 1:numel(described)
    assert(iscellstr(described(ith_question).Answers) && numel(described(ith_question).Answers) >= 2);
    assert(all(ismember(described(ith_question).ProblemAnswers, described(ith_question).Answers)));
    assert(~isempty(described(ith_question).Question) && ~isempty(described(ith_question).Help));
end
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore);

%% Fingerprint mode: the same data, the same fingerprint; no figure
fprintf(1, 'Fingerprint mode\n');
result = fcn_CarMesh3D_assess_headlights(vehicle, Mode='fingerprint');
assert(ischar(result.Fingerprint) && numel(result.Fingerprint) == 64);
assert(ischar(result.Note) && ~isempty(result.Note));
assert(isfield(result, 'Skip'));
again = fcn_CarMesh3D_assess_headlights(vehicleID, Mode='fingerprint', FigNum=-1);   % (an ID works too)
assert(strcmp(again.Fingerprint, result.Fingerprint));
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore);
% (a changed mesh: a changed fingerprint)
changed = vehicle;
changed.Mesh.Vertices(1, :) = changed.Mesh.Vertices(1, :) + 0.01;
if isempty(result.Skip)
    changedResult = fcn_CarMesh3D_assess_headlights(changed, Mode='fingerprint');
    assert(~strcmp(changedResult.Fingerprint, result.Fingerprint));
end

%% Draw mode, in a figure of its own
fprintf(1, 'Draw mode, in a figure\n');
figNum = 1001;
result = fcn_CarMesh3D_assess_headlights(vehicle, FigNum=figNum);
if isempty(result.Skip)
    assert(numel(findall(figure(figNum), 'Type', 'axes')) == 6);   % (far views, and close-ups below: T76 (B))
    assert(~isempty(findall(figure(figNum), 'Type', 'patch')));
end
close(figure(figNum));

%% Draw mode, in a panel (as the V&V GUI draws it)
fprintf(1, 'Draw mode, in a panel\n');
figureHandle = uifigure('Visible', 'off', 'Position', [50 50 1000 500]);
panel = uipanel(figureHandle, 'Position', [0 0 1000 500]);
uilabel(panel, 'Text', 'left from before');   % (cleared by the function)
result = fcn_CarMesh3D_assess_headlights(vehicle, Parent=panel, FigNum=-1);
if isempty(result.Skip)
    labelsNow = findall(panel, 'Type', 'uilabel');
    assert(~any(strcmp({labelsNow.Text}, 'left from before')));   % (cleared: only its own row labels)
    assert(numel(findall(panel, 'Type', 'axes')) == 6);
    rowLabels = findall(panel, 'Tag', 'assessRowLabel');
    assert(numel(rowLabels) == 2 && any(strcmp({rowLabels.Text}, 'Far view')), 'The rows are labeled');
    % (the close-ups look at the left (+y) lamp: their cameras aim at it)
    allAxes = findall(panel, 'Type', 'axes');
    targets = vertcat(allAxes.CameraTarget);
    assert(sum(targets(:,2) > 0.2) == 3, 'Three close-ups, aimed at the left lamp');
end
delete(figureHandle);

%% Testing errors
fprintf(1, 'Testing errors\n');
try
    fcn_CarMesh3D_assess_headlights('No_Such_Vehicle_ID', Mode='fingerprint');
    error('should have failed');
catch inputError
    assert(startsWith(inputError.identifier, 'CarMesh3D:'));
end

fprintf(1, 'All tests of fcn_CarMesh3D_assess_headlights passed.\n');
