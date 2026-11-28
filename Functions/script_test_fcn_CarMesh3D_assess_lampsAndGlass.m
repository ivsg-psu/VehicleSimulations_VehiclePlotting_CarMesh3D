% script_test_fcn_CarMesh3D_assess_lampsAndGlass.m
% Tests fcn_CarMesh3D_assess_lampsAndGlass (the main window's Validate
% Import question). Runs on a demo copy of the Fit; nothing is saved to it.

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_assess_lampsAndGlass
%   % * First write (drafted with Claude)

%% Set up the workspace
close all;

%% DEMO case: the pictures, in a figure of its own
fprintf(1,'DEMO case: the pictures\n');
demoFiles = fcn_CarMesh3D_makeDemoCopy('2009_Honda_Fit_Sport', DemoFolder=tempname, FigNum=-1);
figNum = 10001;
result = fcn_CarMesh3D_assess_lampsAndGlass(demoFiles.Folder, FigNum=figNum);
assert(strcmp(result.Key, 'lampsAndGlass') && isempty(result.Skip));
assert(contains(result.Note, 'glass faces') && contains(result.Note, 'lamp faces'));
assert(numel(findall(figure(figNum), 'Type', 'axes')) >= 2);

%% TEST case: check mode: the gate's automatic half
fprintf(1,'TEST case: check\n');
checked = fcn_CarMesh3D_assess_lampsAndGlass(demoFiles.Folder, Mode='check');
assert(islogical(checked.Pass) && checked.Pass && contains(checked.CheckText, 'PASS'));
% (no lamps marked: the automatic check fails; no glass alone does not,
% as an open car has none: the import report's gate, Sean 2026-11-27 02:42)
noLamps = fcn_CarMesh3D_reviewInput(demoFiles.Folder, FigNum=-1);
noLamps.Mesh.LabelFaceLamp(:) = 0;
checked = fcn_CarMesh3D_assess_lampsAndGlass(noLamps, Mode='check');
assert(~checked.Pass && contains(checked.CheckText, 'STOP'), 'no lamps: the automatic check fails');

%% TEST case: describe mode needs no vehicle
fprintf(1,'TEST case: describe\n');
described = fcn_CarMesh3D_assess_lampsAndGlass([], Mode='describe');
assert(all(isfield(described, {'Key','Title','Question','Detail','Answers','ProblemAnswers','Help','GroupKey','GroupTitle','GroupHelp'})));
assert(isequal(described.Answers, {'Yes', 'No'}) && isequal(described.ProblemAnswers, {'No'}));

%% TEST case: the fingerprint changes when a glass or lamp label changes, and not otherwise
fprintf(1,'TEST case: the fingerprint\n');
first = fcn_CarMesh3D_assess_lampsAndGlass(demoFiles.Folder, Mode='fingerprint');
again = fcn_CarMesh3D_assess_lampsAndGlass(demoFiles.Folder, Mode='fingerprint');
assert(strcmp(first.Fingerprint, again.Fingerprint));
vehicle = fcn_CarMesh3D_reviewInput(demoFiles.Folder, FigNum=-1);
glassIndex = find(strcmp(cellstr(vehicle.Mesh.LabelPartNames), 'glass'));
bodyIndex = find(strcmp(cellstr(vehicle.Mesh.LabelPartNames), 'body'));
glassFace = find(vehicle.Mesh.LabelFacePart == glassIndex, 1);
vehicle.Mesh.LabelFacePart(glassFace) = bodyIndex;
changed = fcn_CarMesh3D_assess_lampsAndGlass(vehicle, Mode='fingerprint');
assert(~strcmp(first.Fingerprint, changed.Fingerprint));

%% TEST case: asked alone in the V&V window, its answer is saved and the vehicle's other answers kept
fprintf(1,'TEST case: asked alone in the V&V window\n');
[~, reviewWindow] = fcn_CarMesh3D_reviewVehicle(demoFiles.Folder, Assessments={@fcn_CarMesh3D_assess_labels}, Reviewer='TST', FlagVisible=false);
hooks = reviewWindow.UserData;
hooks.Answer('Yes', '');
delete(reviewWindow);
[~, reviewWindow] = fcn_CarMesh3D_reviewVehicle(demoFiles.Folder, Assessments={@fcn_CarMesh3D_assess_lampsAndGlass}, Reviewer='TST', FlagVisible=false);
hooks = reviewWindow.UserData;
hooks.Answer('Yes', '');
reviewFile = hooks.ReviewFile();
delete(reviewWindow);
saved = load(reviewFile, 'vvAnswers');
assert(any(saved.vvAnswers.Key == "lampsAndGlass" & saved.vvAnswers.Answer == "Yes"));
assert(any(saved.vvAnswers.Key == "labels" & saved.vvAnswers.Answer == "Yes"), 'the other assessment''s answer is kept');

%% Clean up
close all;
rmdir(fileparts(demoFiles.Folder), 's');

fprintf(1, 'All tests of fcn_CarMesh3D_assess_lampsAndGlass passed.\n');
