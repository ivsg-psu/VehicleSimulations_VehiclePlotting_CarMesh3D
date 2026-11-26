% script_test_fcn_CarMesh3D_assess_realism.m
% Tests: fcn_CarMesh3D_assess_realism
%
% A V&V assessment function: its three modes (describe, fingerprint,
% draw), drawn in a figure of its own and in a panel, as the V&V GUI
% draws it. The vehicle is only read, never changed.

% REVISION HISTORY:
%
% 2026_11_25 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_assess_realism
%   % * First write (drafted with Claude)

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
described = fcn_CarMesh3D_assess_realism([], Mode='describe');
assert(isstruct(described) && ~isempty(described));
assert(all(isfield(described, {'Key', 'Title', 'Question', 'Answers', 'ProblemAnswers', 'Help', 'GroupKey', ...
    'GroupTitle', 'GroupHelp'})));
assert(strcmp(described(1).Key, 'realism') && strcmp(described(1).GroupKey, 'realism'));
for ith_question = 1:numel(described)
    assert(iscellstr(described(ith_question).Answers) && numel(described(ith_question).Answers) >= 2);
    assert(all(ismember(described(ith_question).ProblemAnswers, described(ith_question).Answers)));
    assert(~isempty(described(ith_question).Question) && ~isempty(described(ith_question).Help));
end
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore);

%% Fingerprint mode: the same data, the same fingerprint; no figure
fprintf(1, 'Fingerprint mode\n');
result = fcn_CarMesh3D_assess_realism(vehicle, Mode='fingerprint');
assert(ischar(result.Fingerprint) && numel(result.Fingerprint) == 64);
assert(ischar(result.Note) && ~isempty(result.Note));
assert(isfield(result, 'Skip'));
again = fcn_CarMesh3D_assess_realism(vehicleID, Mode='fingerprint', FigNum=-1);   % (an ID works too)
assert(strcmp(again.Fingerprint, result.Fingerprint));
assert(numel(findall(groot, 'Type', 'figure')) == figuresBefore);
% (a changed mesh: a changed fingerprint)
changed = vehicle;
changed.Mesh.Vertices(1, :) = changed.Mesh.Vertices(1, :) + 0.01;
if isempty(result.Skip)
    changedResult = fcn_CarMesh3D_assess_realism(changed, Mode='fingerprint');
    assert(~strcmp(changedResult.Fingerprint, result.Fingerprint));
end

%% Draw mode, in a figure of its own
fprintf(1, 'Draw mode, in a figure\n');
figNum = 1001;
result = fcn_CarMesh3D_assess_realism(vehicle, FigNum=figNum);
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
result = fcn_CarMesh3D_assess_realism(vehicle, Parent=panel, FigNum=-1);
if isempty(result.Skip)
    assert(isempty(findall(panel, 'Type', 'uilabel')));
    assert(numel(findall(panel, 'Type', 'axes')) == 2);
end
delete(figureHandle);

%% Skipped, with why: a vehicle with no body style (no exemplar)
fprintf(1, 'Skipped: no body style\n');
result = fcn_CarMesh3D_assess_realism('2026_CarMesh3D_Generic_Sedan', Mode='fingerprint');
assert(contains(result.Skip, 'no body style') && strcmp(result.Note, result.Skip));
assert(numel(result.Fingerprint) == 64);
result = fcn_CarMesh3D_assess_realism('2026_CarMesh3D_Generic_Sedan', FigNum=1002);   % (draws nothing)
assert(~isempty(result.Skip) && isempty(findall(groot, 'Type', 'figure', 'Number', 1002)));

%% Skipped, with why: the only exemplar of its style
fprintf(1, 'Skipped: the only exemplar\n');
vanFiles = fcn_CarMesh3D_findVehicleFiles('2014_Ford_TransitConnect_XLTCargoLWB', FigNum=-1);
if vanFiles.HasMesh
    result = fcn_CarMesh3D_assess_realism(vanFiles.ID, Mode='fingerprint');
    assert(contains(result.Skip, 'the only approved exemplar'));
end

%% Compared: a sedan beside the sedans' exemplar
fprintf(1, 'Compared with the exemplar\n');
sedanFiles = fcn_CarMesh3D_findVehicleFiles('2011_Ford_Fusion_Sport', FigNum=-1);
if sedanFiles.HasMesh
    result = fcn_CarMesh3D_assess_realism(sedanFiles.ID, FigNum=1003);
    assert(isempty(result.Skip) && contains(result.Note, 'beside the exemplar'));
    assert(numel(findall(figure(1003), 'Type', 'axes')) == 2);
    close(figure(1003));
end

%% Testing errors
fprintf(1, 'Testing errors\n');
try
    fcn_CarMesh3D_assess_realism('No_Such_Vehicle_ID', Mode='fingerprint');
    error('should have failed');
catch inputError
    assert(startsWith(inputError.identifier, 'CarMesh3D:'));
end

fprintf(1, 'All tests of fcn_CarMesh3D_assess_realism passed.\n');
