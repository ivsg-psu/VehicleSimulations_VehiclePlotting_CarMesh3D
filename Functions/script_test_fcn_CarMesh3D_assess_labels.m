% script_test_fcn_CarMesh3D_assess_labels.m
% Tests: fcn_CarMesh3D_assess_labels
%
% A V&V assessment function: its three modes (describe, fingerprint,
% draw), drawn in a figure of its own and in a panel, as the V&V GUI
% draws it. The vehicle is only read, never changed.

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_assess_labels
%   % * First write (drafted with Claude)
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu (drafted with Claude)
% - In script_test_fcn_CarMesh3D_assess_labels
%   % * The legend under the pictures (Sean, T62)

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
described = fcn_CarMesh3D_assess_labels([], Mode='describe');
assert(isstruct(described) && ~isempty(described));
assert(all(isfield(described, {'Key', 'Title', 'Question', 'Answers', 'ProblemAnswers', 'Help', 'GroupKey', ...
    'GroupTitle', 'GroupHelp'})));
assert(strcmp(described(1).Key, 'labels') && strcmp(described(1).GroupKey, 'labels'));
for ith_question = 1:numel(described)
    assert(iscellstr(described(ith_question).Answers) && numel(described(ith_question).Answers) >= 2);
    assert(all(ismember(described(ith_question).ProblemAnswers, described(ith_question).Answers)));
    assert(~isempty(described(ith_question).Question) && ~isempty(described(ith_question).Help));
end
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore);

%% Fingerprint mode: the same data, the same fingerprint; no figure
fprintf(1, 'Fingerprint mode\n');
result = fcn_CarMesh3D_assess_labels(vehicle, Mode='fingerprint');
assert(ischar(result.Fingerprint) && numel(result.Fingerprint) == 64);
assert(ischar(result.Note) && ~isempty(result.Note));
assert(isfield(result, 'Skip'));
again = fcn_CarMesh3D_assess_labels(vehicleID, Mode='fingerprint', FigNum=-1);   % (an ID works too)
assert(strcmp(again.Fingerprint, result.Fingerprint));
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore);
% (a changed mesh: a changed fingerprint)
changed = vehicle;
changed.Mesh.Vertices(1, :) = changed.Mesh.Vertices(1, :) + 0.01;
if isempty(result.Skip)
    changedResult = fcn_CarMesh3D_assess_labels(changed, Mode='fingerprint');
    assert(~strcmp(changedResult.Fingerprint, result.Fingerprint));
end

%% Draw mode, in a figure of its own
fprintf(1, 'Draw mode, in a figure\n');
figNum = 1001;
result = fcn_CarMesh3D_assess_labels(vehicle, FigNum=figNum);
if isempty(result.Skip)
    assert(numel(findall(figure(figNum), 'Type', 'axes')) == 2);
    assert(~isempty(findall(figure(figNum), 'Type', 'patch')));
end
close(figure(figNum));

%% Draw mode, in a panel (as the V&V GUI draws it)
fprintf(1, 'Draw mode, in a panel\n');
figureHandle = uifigure('Visible', 'off', 'Position', [50 50 1000 500]);
panel = uipanel(figureHandle, 'Position', [0 0 1000 500]);
uilabel(panel, 'Text', 'left from before');   % (cleared by the function)
result = fcn_CarMesh3D_assess_labels(vehicle, Parent=panel, FigNum=-1);
if isempty(result.Skip)
    labels = findall(panel, 'Type', 'uilabel');
    assert(~any(strcmp({labels.Text}, 'left from before')), 'The panel cleared');
    assert(isscalar(findall(panel, 'Tag', 'assessLegend')), 'The legend of the label colors (Sean, T62)');
    assert(numel(findall(panel, 'Type', 'axes')) == 2);
end
delete(figureHandle);

%% Testing errors
fprintf(1, 'Testing errors\n');
try
    fcn_CarMesh3D_assess_labels('No_Such_Vehicle_ID', Mode='fingerprint');
    error('should have failed');
catch inputError
    assert(startsWith(inputError.identifier, 'CarMesh3D:'));
end

fprintf(1, 'All tests of fcn_CarMesh3D_assess_labels passed.\n');
