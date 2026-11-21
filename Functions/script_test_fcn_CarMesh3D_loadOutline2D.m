% script_test_fcn_CarMesh3D_loadOutline2D.m
% Tests fcn_CarMesh3D_loadOutline2D
% Loads a vehicle's top-down (2D) outlines from its folder in Data.
%
% Run script_demo_CarMesh3D first (or add its Functions and Data folders to the path).

% REVISION HISTORY:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadOutline2D
%   % * First write of the code (drafted with Claude)

% TO-DO:
%
% 2026_11_20 by Sean Brennan, sbrennan@psu.edu
% - In script_test_fcn_CarMesh3D_loadOutline2D
%   % * (fill in items here)


%% Set up the workspace
close all

% A copy of the Prius's folder in a temporary Data folder, to test the
% cases without changing the real one
testData = fullfile(tempdir, 'CarMesh3D_outlineTest');
if isfolder(testData)
    rmdir(testData, 's');
end
mkdir(testData);
realFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four');
testFiles = fcn_CarMesh3D_findVehicleFiles('2013_Toyota_Prius_Four', DataFolder=testData);
mkdir(testFiles.Folder);
copyfile(realFiles.MeshFile, testFiles.MeshFile);

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

%% DEMO case: The Prius's outlines (made from its mesh: no outline file in the copy yet)
figNum = 10001;
titleString = sprintf('DEMO case: The Prius''s outlines (made from its mesh: no outline file in the copy yet)');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

warningState = warning('off','CarMesh3D:outlineMade');
vehicleOutline = fcn_CarMesh3D_loadOutline2D('2013_Toyota_Prius_Four', DataFolder=testData, SaveIfMade=true, FigNum=figNum);
warning(warningState);

% Check variable types
assert(isstruct(vehicleOutline) && strcmp(vehicleOutline.Origin, 'made'));

% Check variable sizes
assert(size(vehicleOutline.Body,2)==2 && numel(vehicleOutline.Wheels)==4);

% Check variable values: saved, so the next load reads the file
assert(isfile(testFiles.OutlineFile));
fromFile = fcn_CarMesh3D_loadOutline2D('2013_Toyota_Prius_Four', DataFolder=testData);
assert(strcmp(fromFile.Origin, 'file') && isequal(fromFile.Body, vehicleOutline.Body) && strcmp(fromFile.VehicleID, '2013_Toyota_Prius_Four'));

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

%% TEST case: The warnings: made from the mesh; older than the mesh
figNum = 20001;
titleString = sprintf('TEST case: The warnings: made from the mesh; older than the mesh');
fprintf(1,'Figure %.0f: %s\n',figNum, titleString);
figure(figNum); close(figNum);

delete(testFiles.OutlineFile);
lastwarn('');
warningState = warning('off','CarMesh3D:outlineMade');
fcn_CarMesh3D_loadOutline2D('2013_Toyota_Prius_Four', DataFolder=testData, SaveIfMade=true);
warning(warningState);
[~, warningID] = lastwarn;
assert(strcmp(warningID, 'CarMesh3D:outlineMade'));
pause(2.5);
loaded = load(testFiles.MeshFile, 'vehicleMesh');
vehicleMesh = loaded.vehicleMesh;
save(testFiles.MeshFile, 'vehicleMesh');                     % (the mesh is now newer)
lastwarn('');
warningState = warning('off','CarMesh3D:oldOutline');
fcn_CarMesh3D_loadOutline2D('2013_Toyota_Prius_Four', DataFolder=testData);
warning(warningState);
[~, warningID] = lastwarn;
assert(strcmp(warningID, 'CarMesh3D:oldOutline'));

%% Fast Mode Tests

%% Basic example - NO FIGURE
figNum = 80001;
fprintf(1,'Figure: %.0f: FAST mode, empty figNum\n',figNum);
warningState = warning('off','CarMesh3D:oldOutline');
vehicleOutline = fcn_CarMesh3D_loadOutline2D('2013_Toyota_Prius_Four', DataFolder=testData, FigNum=[]);
warning(warningState);
assert(numel(vehicleOutline.Wheels)==4);

%% Basic fast mode - NO FIGURE, FAST MODE
figNum = 80002;
fprintf(1,'Figure: %.0f: FAST mode, figNum=-1\n',figNum);
warningState = warning('off','CarMesh3D:oldOutline');
vehicleOutline = fcn_CarMesh3D_loadOutline2D('2013_Toyota_Prius_Four', DataFolder=testData, FigNum=-1);
warning(warningState);
assert(numel(vehicleOutline.Wheels)==4);
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
    fcn_CarMesh3D_loadOutline2D('1999_No_Such_Vehicle');
end

%% FAIL case: No outline file, and not allowed to make one
if 1==0
    fcn_CarMesh3D_loadOutline2D('2013_Toyota_Prius_Four', DataFolder=testData, MakeIfMissing=false);
end
