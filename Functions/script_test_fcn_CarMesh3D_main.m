% script_test_fcn_CarMesh3D_main.m
% Tests fcn_CarMesh3D_main
% The main window: the steps and their marks, the working copy (resume,
% set aside, Discard, Commit), one editor at a time, any number of
% viewers, the saved view. Every test runs on a demo copy of the vehicle,
% with the working copies in a temporary folder: nothing is written to a
% real vehicle or to the repo's Working folder.

% REVISION HISTORY:
%
% 2026_11_27 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_main
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

%% DEMO case: open on a demo copy of the Fit; a fresh working copy, nothing changed
fprintf(1,'DEMO case: open; a fresh working copy\n');
testRoot = tempname;
vehicleID = '2009_Honda_Fit_Sport';
demoFiles = fcn_CarMesh3D_makeDemoCopy(vehicleID, DemoFolder=fullfile(testRoot, 'vehicle'), FigNum=-1);
workingRoot = fullfile(testRoot, 'Working');
[~, window] = fcn_CarMesh3D_main(demoFiles.Folder, WorkingRoot=workingRoot, FlagVisible=false);

% Check variable types and sizes
assert(isstruct(window) && all(isfield(window, {'Figure','State','Press','Key','CheckLayout','Marks','Step','Build', ...
    'Commit','Discard','Changes','Children','WorkingFolder','VehicleFolder','Refresh','SaveView','Close'})));
assert(isvalid(window.Figure));

% Check variable values
workFolder = window.WorkingFolder();
assert(strcmp(workFolder, fullfile(workingRoot, vehicleID)) && isfolder(workFolder));
assert(strcmp(window.VehicleFolder(), demoFiles.Folder));
assert(isempty(window.Changes()));
marks = window.Marks();
assert(numel(marks) == 10 && strcmp(marks{1}, 'done') && strcmp(marks{10}, 'done'));
assert(any(strcmp(marks{5}, {'done', 'outOfDate'})));   % (out of date if the script changed after the last build)
for tag = {'mainMenu', 'mainCommit', 'mainDiscard', 'mainSaveView', 'mainStatus', 'mainHint', 'mainStep0', 'mainStep9', 'mainChecksWhich'}
    assert(~isempty(findall(window.Figure, 'Tag', tag{1})), 'no control tagged %s', tag{1});
end

%% TEST case: a saved edit shows as a change, and makes the build out of date
fprintf(1,'TEST case: an edit makes the build out of date\n');
pause(1.1);   % (file times have one-second steps on some disks)
faceFlips = struct('Points', [0 0 1], 'Normals', [0 0 1], 'NumFaces', 1, 'Who', 'TST', 'SavedOn', 'now'); %#ok<NASGU>
save(fullfile(workFolder, sprintf('faceFlips_%s.mat', vehicleID)), 'faceFlips');
window.Refresh();
assert(isequal(window.Changes(), {sprintf('faceFlips_%s.mat', vehicleID)}));
marks = window.Marks();
assert(strcmp(marks{5}, 'outOfDate') && strcmp(marks{10}, 'notDone'));
assert(any(strcmp(marks{4}, {'done', 'outOfDate'})));

%% TEST case: viewers, any number; one editor at a time, and an editor closes V&V
fprintf(1,'TEST case: viewers and editors\n');
window.Step(7);
window.Step(7);
kinds = {window.Children().Kind};
assert(nnz(strcmp(kinds, 'viewer')) >= 2);
window.Step(3);   % (face directions)
kinds = {window.Children().Kind};
assert(nnz(strcmp(kinds, 'faces')) >= 1);
window.Step(2);   % (the painter: the face window closes)
kinds = {window.Children().Kind};
assert(~any(strcmp(kinds, 'faces')) && any(strcmp(kinds, 'painter')));
assert(nnz(strcmp(kinds, 'viewer')) >= 2);   % (viewers stay open)
window.Step(8);   % (V&V: the painter closes)
kinds = {window.Children().Kind};
assert(~any(strcmp(kinds, 'painter')) && any(strcmp(kinds, 'review')));
window.Step(6);   % (lamp functions: V&V closes)
kinds = {window.Children().Kind};
assert(~any(strcmp(kinds, 'review')) && any(strcmp(kinds, 'lampFunctions')));

%% TEST case: closing keeps the working copy; reopening resumes it; Resume=false sets it aside
fprintf(1,'TEST case: resume and set aside\n');
viewState = window.SaveView();
assert(strcmp(viewState.Vehicle, vehicleID) && ~isempty(viewState.Windows));
window.Close();
assert(~isvalid(window.Figure));
assert(~isempty(dir(fullfile(workingRoot, 'views', sprintf('mainView_%s_*.mat', vehicleID)))));
[~, window] = fcn_CarMesh3D_main(demoFiles.Folder, WorkingRoot=workingRoot, FlagVisible=false);
assert(any(strcmp(window.Changes(), sprintf('faceFlips_%s.mat', vehicleID))));   % (resumed; V&V also wrote its review record)
window.Close();
[~, window] = fcn_CarMesh3D_main(demoFiles.Folder, WorkingRoot=workingRoot, Resume=false, FlagVisible=false);
assert(isempty(window.Changes()));   % (a new one)
setAside = dir(fullfile(workingRoot, sprintf('%s_setAside_*', vehicleID)));
assert(numel(setAside) == 1 && isfile(fullfile(setAside(1).folder, setAside(1).name, sprintf('faceFlips_%s.mat', vehicleID))));

%% TEST case: Discard throws the changes away
fprintf(1,'TEST case: Discard\n');
copyfile(fullfile(setAside(1).folder, setAside(1).name, sprintf('faceFlips_%s.mat', vehicleID)), workFolder);
window.Refresh();
assert(~isempty(window.Changes()));
window.Discard();
assert(isempty(window.Changes()) && ~isfile(fullfile(workFolder, sprintf('faceFlips_%s.mat', vehicleID))));

%% TEST case: Commit puts a change into the vehicle's folder (here the demo copy), with a row in its change log
fprintf(1,'TEST case: Commit\n');
lampFile = fullfile(workFolder, sprintf('lampFunctions_%s.csv', vehicleID));
lampText = fileread(lampFile);
fid = fopen(lampFile, 'w');
fwrite(fid, [lampText sprintf('\n')]);   % (a change that does not make the build out of date)
fclose(fid);
window.Refresh();
assert(isequal(window.Changes(), {sprintf('lampFunctions_%s.csv', vehicleID)}));
window.Commit();
assert(isempty(window.Changes()));
assert(strcmp(fileread(fullfile(demoFiles.Folder, sprintf('lampFunctions_%s.csv', vehicleID))), [lampText sprintf('\n')]));
historyText = fileread(fullfile(demoFiles.Folder, sprintf('meshHistory_%s.csv', vehicleID)));
assert(contains(historyText, 'committed'));

%% TEST case: Build runs the script in the working copy, and the build is done again
fprintf(1,'TEST case: Build (about a minute)\n');
pause(1.1);
save(fullfile(workFolder, sprintf('faceFlips_%s.mat', vehicleID)), 'faceFlips');
window.Refresh();
marks = window.Marks();
assert(strcmp(marks{5}, 'outOfDate'));
meshBefore = dir(fullfile(demoFiles.Folder, sprintf('vehicleMesh_%s.mat', vehicleID)));
window.Build();
marks = window.Marks();
assert(strcmp(marks{5}, 'done'), 'the build did not finish: see %s', fullfile(workFolder, 'buildLog.txt'));
meshAfter = dir(fullfile(demoFiles.Folder, sprintf('vehicleMesh_%s.mat', vehicleID)));
assert(isequal(meshBefore.datenum, meshAfter.datenum));   % (the vehicle's own mesh did not change)

%% TEST case: a second call brings the open window forward (hidden: a new one is allowed for tests)
window.Close();
assert(isempty(getappdata(groot, 'CarMesh3D_mainWindow')) || ~isvalid(getappdata(groot, 'CarMesh3D_mainWindow')));

%% TEST case: a copy of a vehicle keeps its working copy beside it, never in CarMesh3D\Working
fprintf(1,'TEST case: a copy''s working copy stays beside the copy\n');
[~, window] = fcn_CarMesh3D_main(demoFiles.Folder, FlagVisible=false);
assert(startsWith(window.WorkingFolder(), fullfile(testRoot, 'vehicle', 'Working')));
window.Close();

%% Clean up
rmdir(testRoot, 's');

%% Fail conditions
if 1==0
    %% Not a vehicle
    fcn_CarMesh3D_main(3);
end
