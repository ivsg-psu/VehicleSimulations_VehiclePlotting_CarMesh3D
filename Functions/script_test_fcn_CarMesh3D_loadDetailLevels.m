% script_test_fcn_CarMesh3D_loadDetailLevels.m
% Tests fcn_CarMesh3D_loadDetailLevels
% Loads a vehicle's detail levels from its folder in Data.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadDetailLevels
%   % * First write of the code (drafted with Claude)
%
% 2026_11_26 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadDetailLevels
%   % * OrientFaces (Q87 (A))

% TO-DO:
%
% 2026_11_19 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadDetailLevels
%   % * (fill in items here)


%% Set up the workspace
close all

% A copy of the Prius's folder in a temporary Data folder, so the test can
% remove and remake its levels file without touching the real one
priusFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
testData = fullfile(tempdir, 'CarMesh3D_testLevelsData');
if isfolder(testData)
    rmdir(testData, 's');
end
testFolder = fullfile(testData, '2013_Toyota_Prius_Four');
mkdir(testFolder);
copyfile(priusFiles.MeshFile, testFolder);
if priusFiles.HasLevels
    copyfile(priusFiles.LevelsFile, testFolder);
end
testFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four', DataFolder=testData);

%% Code demos start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   _____                              ____   __    _____          _
%  |  __ \                            / __ \ / _|  / ____|        | |
%  | |  | | ___ _ __ ___   ___  ___  | |  | | |_  | |     ___   __| | ___
%  | |  | |/ _ \ '_ ` _ \ / _ \/ __| | |  | |  _| | |    / _ \ / _` |/ _ \
%  | |__| |  __/ | | | | | (_) \__ \ | |__| | |   | |___| (_) | (_| |  __/
%  |_____/ \___|_| |_| |_|\___/|___/  \____/|_|    \_____\___/ \__,_|\___|
%
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Demos%20Of%20Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 1

close all;
fprintf(1,'Figure: 1XXXXXX: DEMO cases\n');

%% DEMO case: Load the Prius's levels (made and saved first if missing)
figNum = 10001;
titleString = sprintf('DEMO case: Load the Prius''s levels (made and saved first if missing)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); clf;

warningState = warning('off','CarMesh3D:detailLevelsMade');
detailLevels = fcn_CarMesh3D_loadDetailLevels('2013_Toyota_Prius_Four', DataFolder=testData, FlagSaveIfMade=true, FigNum=figNum);
warning(warningState);

% Check variable types
assert(isstruct(detailLevels) && isstruct(detailLevels.Levels));

% Check variable sizes
assert(numel(detailLevels.Levels) >= 5);

% Check variable values
assert(strcmp(detailLevels.VehicleID, '2013_Toyota_Prius_Four'));
assert(any(strcmp(detailLevels.Source, {'file','made'})));
assert(detailLevels.Levels(end).IsBox && detailLevels.FormatVersion==1);
assert(isfile(testFiles.LevelsFile));

% Make sure plot opened up
assert(isequal(get(gcf,'Number'),figNum));

%% Test cases start here
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  _______        _
% |__   __|      | |
%    | | ___  ___| |_
%    | |/ _ \/ __| __|
%    | |  __/\__ \ |_
%    |_|\___||___/\__|
%
% See: https://patorjk.com/software/taag/#p=display&f=Big&t=Test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 2

close all;
fprintf(1,'Figure: 2XXXXXX: TEST cases\n');

%% TEST case: From the file; the same as made
figNum = 20001;
titleString = sprintf('TEST case: From the file; the same as made');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

fromFile = fcn_CarMesh3D_loadDetailLevels('2013_Toyota_Prius_Four', DataFolder=testData);
assert(strcmp(fromFile.Source,'file'));
loaded = load(testFiles.MeshFile, 'vehicleMesh');
madeNow = fcn_CarMesh3D_makeDetailLevels(loaded.vehicleMesh);
assert(isequal([fromFile.Levels.Faces], [madeNow.Levels.Faces]));

% Make sure plot did NOT open up
figHandles = get(groot, 'Children');
assert(~any(figHandles==figNum));

%% TEST case: No levels file: made (with a warning) and not saved by default
figNum = 20002;
titleString = sprintf('TEST case: No levels file: made (with a warning) and not saved by default');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

delete(testFiles.LevelsFile);
lastwarn('');
warningState = warning('off','CarMesh3D:detailLevelsMade');
madeLevels = fcn_CarMesh3D_loadDetailLevels('2013_Toyota_Prius_Four', DataFolder=testData);
warning(warningState);
[~, warningID] = lastwarn;
assert(strcmp(madeLevels.Source,'made') && strcmp(warningID,'CarMesh3D:detailLevelsMade'));
assert(~isfile(testFiles.LevelsFile));

%% TEST case: A levels file older than the mesh gives a warning
figNum = 20003;
titleString = sprintf('TEST case: A levels file older than the mesh gives a warning');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

detailLevels = madeLevels;
save(testFiles.LevelsFile, 'detailLevels');
pause(2.2);
loaded = load(testFiles.MeshFile, 'vehicleMesh');
vehicleMesh = loaded.vehicleMesh;
save(testFiles.MeshFile, 'vehicleMesh');                    % the mesh is now newer
lastwarn('');
warningState = warning('off','CarMesh3D:oldDetailLevels');
remadeLevels = fcn_CarMesh3D_loadDetailLevels('2013_Toyota_Prius_Four', DataFolder=testData);
warning(warningState);
[~, warningID] = lastwarn;
assert(strcmp(warningID,'CarMesh3D:oldDetailLevels'));
assert(strcmp(remadeLevels.Source, 'remade'), 'Older levels are made again (Q73 (B))');
assert(isequal([remadeLevels.Levels.Faces], [madeLevels.Levels.Faces]), 'The same mesh: the same levels');

%% TEST case: OrientFaces (Q87 (A), 2026-11-26): each level's faces turned, as on loading the full mesh
figNum = 20004;
fprintf(1,'Figure %.0f: TEST case: OrientFaces\n', figNum);
warningState = warning('off','CarMesh3D:oldDetailLevels');
asSaved = fcn_CarMesh3D_loadDetailLevels('2013_Toyota_Prius_Four', DataFolder=testData, FlagOrientFaces=false);
turned = fcn_CarMesh3D_loadDetailLevels('2013_Toyota_Prius_Four', DataFolder=testData);
warning(warningState);
assert(all(asSaved.FacesTurned == 0) && numel(turned.FacesTurned) == numel(turned.Levels));
for ith_level = 1:numel(turned.Levels)
    if turned.Levels(ith_level).IsBox
        assert(turned.FacesTurned(ith_level) == 0, 'The box is left as it is');
        continue;
    end
    expected = fcn_CarMesh3D_orientFaces(asSaved.Levels(ith_level).Mesh, FigNum=-1);
    assert(isequal(turned.Levels(ith_level).Mesh.Faces, expected.Faces), 'Level %d: the faces after fcn_CarMesh3D_orientFaces', ith_level);
    assert(isequal(sort(turned.Levels(ith_level).Mesh.Faces, 2), sort(asSaved.Levels(ith_level).Mesh.Faces, 2)), 'Only the corners'' order changes');
end

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
warningState = warning('off','CarMesh3D:oldDetailLevels');
detailLevels = fcn_CarMesh3D_loadDetailLevels('2013_Toyota_Prius_Four', DataFolder=testData, FigNum=[]);
warning(warningState);
assert(detailLevels.Levels(end).IsBox);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
warningState = warning('off','CarMesh3D:oldDetailLevels');
detailLevels = fcn_CarMesh3D_loadDetailLevels('2013_Toyota_Prius_Four', DataFolder=testData, FigNum=-1);
warning(warningState);
assert(detailLevels.Levels(end).IsBox);
rmdir(testData, 's');

%% BUG cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  ____  _    _  _____
% |  _ \| |  | |/ ____|
% | |_) | |  | | |  __    ___ __ _ ___  ___  ___
% |  _ <| |  | | | |_ |  / __/ _` / __|/ _ \/ __|
% | |_) | |__| | |__| | | (_| (_| \__ \  __/\__ \
% |____/ \____/ \_____|  \___\__,_|___/\___||___/
%
% See: http://patorjk.com/software/taag/#p=display&v=0&f=Big&t=BUG%20cases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figures start with 9

% close all;

%% BUG

%% Fail conditions
% Each block below should throw an error. Change 1==0 to 1==1 to run them.

%% FAIL case: A vehicle with no folder
if 1==0
    fcn_CarMesh3D_loadDetailLevels('1999_No_Such_Vehicle');
end

%% FAIL case: No levels file, and not allowed to make them
if 1==0
    delete(testFiles.LevelsFile);
    fcn_CarMesh3D_loadDetailLevels('2013_Toyota_Prius_Four', DataFolder=testData, FlagMakeIfMissing=false);
end
