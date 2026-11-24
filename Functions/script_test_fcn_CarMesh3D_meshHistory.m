% script_test_fcn_CarMesh3D_meshHistory.m
% Tests fcn_CarMesh3D_meshHistory

% REVISION HISTORY:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_meshHistory
%   % * First write

% TO-DO:
%
% 2026_11_22 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_meshHistory
%   % * (none yet)

%% Set up the workspace: a vehicle folder of its own, in a temporary folder
close all;
testID = '2000_Test_Vehicle_History';
testFolder = fullfile(tempname, testID);
mkdir(testFolder);
cleanupFolder = onCleanup(@() rmdir(fileparts(testFolder), 's'));
fid = fopen(fullfile(testFolder, 'LICENSE.txt'), 'w');
fprintf(fid, 'License: Free Standard\nLicense meaning: use worldwide\nSource website: https://example.com/model\nAuthor: Someone\n');
fclose(fid);
vehicleMesh = struct('Vertices', zeros(3,3), 'Faces', [1 2 3], ...
    'BuildInfo', struct('Date', '2026-11-22 05:54', 'Script', 'script_x.m', 'MeshVersion', '2026_11_21d'));
meshFile = fullfile(testFolder, sprintf('vehicleMesh_%s.mat', testID));
save(meshFile, 'vehicleMesh');

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _____                              ____   __    _____          _
% |  __ \                            / __ \ / _|  / ____|        | |
% | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
% | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
% | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
% |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DEMO case: A mesh built, never reviewed
fprintf(1,'DEMO case: a mesh built, never reviewed\n');
history = fcn_CarMesh3D_meshHistory(meshFile);
assert(strcmp(history.ID, testID));
assert(strcmp(history.License.Name, 'Free Standard') && strcmp(history.License.Author, 'Someone'));
assert(strcmp(history.Built.Date, '2026-11-22 05:54'));
assert(strcmp(history.Review.Status, 'not reviewed'));
assert(height(history.Entries) == 1 && history.Entries.Action(1) == "built");   % (the build, from BuildInfo)
assert(contains(history.FinePrint, 'NOT REVIEWED') && contains(history.FinePrint, 'Free Standard'));
assert(~isfile(history.HistoryFile));                                          % (reading writes nothing)

%% Test cases start here. These are very simple, usually trivial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______ ______  _____ _______ _____
% |__   __|  ____|/ ____|__   __/ ____|
%    | |  | |__  | (___    | | | (___
%    | |  |  __|  \___ \   | |  \___ \
%    | |  | |____ ____) |  | |  ____) |
%    |_|  |______|_____/   |_| |_____/
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=TESTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TEST case: Label edits, then a review: reviewed and current
fprintf(1,'TEST case: label edits, then a review\n');
fcn_CarMesh3D_meshHistory(testFolder, Action='label edits saved', Details='12 faces changed, with "quotes", and commas', Who='painter');
pause(1.1);
history = fcn_CarMesh3D_meshHistory(testFolder, Action='reviewed: approved', Who='sean');
assert(isfile(history.HistoryFile));
assert(strcmp(history.Review.Status, 'approved') && strcmp(history.Review.By, 'sean') && history.Review.Current);
assert(strcmp(history.LastChange.Action, 'label edits saved') && strcmp(history.LastChange.Who, 'painter'));
assert(any(history.Entries.Details == "12 faces changed, with ""quotes"", and commas"));  % (read back as written)
assert(contains(history.FinePrint, 'Reviewed (approved) by sean') && ~contains(history.FinePrint, 'CHANGED SINCE'));

%% TEST case: A change after the review: the review is no longer current
fprintf(1,'TEST case: a change after the review\n');
pause(1.1);
history = fcn_CarMesh3D_meshHistory(testFolder, Action='label edits saved', Details='3 faces', Who='painter');
assert(strcmp(history.Review.Status, 'approved') && ~history.Review.Current);
assert(contains(history.FinePrint, 'CHANGED SINCE'));
% (a note is not a change)
pause(1.1);
fcn_CarMesh3D_meshHistory(testFolder, Action='reviewed: rejected', Who='sean');
history = fcn_CarMesh3D_meshHistory(testFolder, Action='note', Details='looked again');
assert(strcmp(history.Review.Status, 'rejected') && history.Review.Current);

%% TEST case: A timestamped copy elsewhere finds the vehicle's history by its ID (or none)
fprintf(1,'TEST case: a timestamped copy elsewhere\n');
copyFolder = fullfile(fileparts(testFolder), 'copies');
mkdir(copyFolder);
copyFile = fullfile(copyFolder, sprintf('vehicleMesh_%s_20261122130000.mat', testID));
copyfile(meshFile, copyFile);
copyHistory = fcn_CarMesh3D_meshHistory(copyFile);
assert(strcmp(copyHistory.ID, testID));            % (the ID, without the time stamp)
assert(strcmp(copyHistory.Built.Date, '2026-11-22 05:54'));

%% TEST case: The vehicles' own (read only): every one has a license and a status
fprintf(1,'TEST case: the Fit''s history (read only)\n');
fitHistory = fcn_CarMesh3D_meshHistory(fcn_CarMesh3D_demoVehicle(UsePreference=false, FigNum=-1));   % (the repo's demo vehicle)
assert(~isempty(fitHistory.License.Name) && ~isempty(fitHistory.FinePrint));

%% Fail conditions
if 1==0
    %% FAIL case: not text
    fcn_CarMesh3D_meshHistory(42);
end

clear cleanupFolder;
fprintf(1,'All tests of fcn_CarMesh3D_meshHistory passed\n');
